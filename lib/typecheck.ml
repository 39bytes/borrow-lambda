open Ast

exception TypeError of string
exception FreeVariable
exception NoShadowing
exception NotImplemented

type context = (int * tp) list

(* Type predicates *)

let rec subtype (t1 : tp) (t2 : tp) =
  match (t1, t2) with
  | Ref (alpha, tp1, mod1), Ref (beta, tp2, mod2) -> (
      if alpha <= beta then false
      else if not (subtype tp1 tp2) then false
      else
        match (mod1, mod2) with
        | Shr, Mut -> false
        | Shr, Shr -> true
        | Mut, Shr -> true
        | Mut, Mut -> true)
  | _, _ -> t1 = t2

let ( <: ) = subtype

(* Exception helpers *)
let fail_tp msg = raise (TypeError msg)

let fail_expected_tp expected actual =
  raise
    (TypeError
       (Printf.sprintf "Expected type '%s', got type '%s'"
          (string_of_tp expected) (string_of_tp actual)))

(* Utilities *)

let find_in_context (ctx : context) (x : int) : tp * lifetime =
  let rec go vars x index =
    match vars with
    | [] -> raise FreeVariable
    | (y, tp) :: _ when x = y -> (tp, Scope index)
    | _ :: vars -> go vars x (index + 1)
  in
  go ctx x 0

(* Actual typechecking *)

let rec syn (ctx : context) (t : var_id option tm) : (var_id option * tp) tm =
  match t with
  | Var x ->
      let tp, _ = find_in_context ctx x in
      (*TODO: add this back*)
      (* if copy tp then (ctx, tp) *)
      if is_borrowed ctx x then fail_borrow_move x
      else if StringSet.exists (( = ) x) ctx.used then fail_moved_value x
      else
        let ctx' = { ctx with used = StringSet.add x ctx.used } in
        (ctx', tp)
  | Lam (_, _) -> raise NotImplemented
  | App (t1, t2) -> (
      let ctx1, ft = syn ctx t1 in
      match ft with
      | Arrow (tp1, tp2) ->
          let ctx2 = check ctx1 t2 tp1 in
          (ctx2, tp2)
      | _ -> fail_tp "Expected function type on left hand side of application")
  | Borrow t -> (
      match t with
      | Var x -> (
          let tp, lft = find_in_context ctx x in
          if moved ctx x then fail_moved_value x
          else
            match borrow_mod ctx x with
            | Some Mut ->
                raise
                  (BorrowError
                     (Printf.sprintf
                        "Cannot borrow '%s' while it is mutably borrowed" x))
            | _ when bound_in_current ctx x ->
                ( { ctx with borrowed = (x, Shr) :: ctx.borrowed },
                  Ref (lft, tp, Shr) )
            | _ ->
                raise
                  (BorrowError
                     (Printf.sprintf "Cannot borrow captured variable '%s'" x)))
      | _ -> raise (BorrowError "Cannot borrow non-variable term"))
  | BorrowMut t -> (
      match t with
      | Var x -> (
          let tp, lft = find_in_context ctx x in
          if moved ctx x then fail_moved_value x
          else
            match borrow_mod ctx x with
            | Some _ ->
                raise
                  (BorrowError
                     (Printf.sprintf
                        "Cannot mutably borrow '%s' while it is already \
                         borrowed"
                        x))
            | _ when bound_in_current ctx x ->
                ( { ctx with borrowed = (x, Mut) :: ctx.borrowed },
                  Ref (lft, tp, Mut) )
            | _ ->
                raise
                  (BorrowError
                     (Printf.sprintf "Cannot borrow captured variable '%s'" x)))
      | _ -> raise (BorrowError "Cannot borrow non-variable term"))
  | Deref t -> (
      let ctx', tp = syn ctx t in
      match tp with
      | Ref (_, ref_tp, _) ->
          if copy ref_tp then (ctx', ref_tp)
          else
            raise
              (TypeError
                 (Printf.sprintf "Cannot dereference non-copyable type '%s'"
                    (string_of_tp ref_tp)))
      | _ ->
          raise
            (TypeError
               (Printf.sprintf "Cannot dereference non-reference type '%s'"
                  (string_of_tp tp))))
  | IfElse (t1, t2, t3) -> (
      let ctx1, ct = syn ctx t1 in
      match ct with
      | Bool ->
          let ctx2, tp1 = syn ctx1 t2 in
          let ctx3, tp2 = syn ctx1 t3 in
          if tp1 <> tp2 then
            fail_tp
              (Printf.sprintf "Mismatched types '%s' and '%s'"
                 (string_of_tp tp1) (string_of_tp tp2))
          else ({ ctx1 with used = StringSet.union ctx2.used ctx3.used }, tp1)
      | t ->
          fail_tp
            (Printf.sprintf
               "Expected type 'Bool' in condition of 'if', got type '%s'"
               (string_of_tp t)))
  | LetIn (x, t1, t2) -> (
      (* Is this already in the context? *)
      match List.assoc_opt x ctx.vars with
      | Some _ -> raise NoShadowing
      | None ->
          let ctx1, tp1 = syn ctx t1 in
          let ctx2, tp2 =
            syn
              {
                ctx1 with
                vars = (x, tp1) :: ctx1.vars;
                bound_in_fn = StringSet.add x ctx1.bound_in_fn;
              }
              t2
          in
          (ctx2, tp2))
  | Assign (x, t) ->
      let tp, _ = find_in_context ctx x in
      if is_borrowed ctx x then
        raise
          (BorrowedValue
             (Printf.sprintf "Cannot assign of borrowed value '%s'" x))
      else
        let ctx' = check ctx t tp in
        (* x has a value again, so we can use it once more *)
        ({ ctx' with used = StringSet.remove x ctx'.used }, Unit)
  | DerefAssign (x, t) -> raise NotImplemented
  | Zero -> (ctx, Nat)
  | Succ t ->
      let ctx' = check ctx t Nat in
      (ctx', Nat)
  | Pred t ->
      let ctx' = check ctx t Nat in
      (ctx', Nat)
  | True -> (ctx, Bool)
  | False -> (ctx, Bool)
  | IsZero t ->
      let ctx' = check ctx t Nat in
      (ctx', Bool)
  | Unit -> (ctx, Unit)
  | NatVecMake ts ->
      (List.fold_left (fun acc t -> check acc t Nat) ctx ts, NatVec)
  | NatVecGet (t1, t2) -> raise NotImplemented
  | NatVecGetMut (t1, t2) -> raise NotImplemented
  | NatVecPush (t1, t2) -> raise NotImplemented
  | NatVecPop t -> raise NotImplemented
  | Annotated (t, tp) ->
      let ctx' = check ctx t tp in
      (ctx', tp)

and check (ctx : context) (tm : tm) (tp : tp) : unit =
  match tm with
  | Var _
  | App (_, _)
  | Zero | Succ _ | Pred _ | True | False | IsZero _ | Unit
  | LetIn (_, _, _)
  | Assign (_, _)
  | DerefAssign (_, _)
  | Borrow _ | BorrowMut _ ->
      let ctx', inferred = syn ctx tm in
      if inferred <> tp then fail_expected_tp inferred tp else ctx'
  | Lam (x, b) -> (
      (* TODO: hard*)
      match tp with
      | Arrow (t1, t2) ->
          let ctx' = { ctx with vars = (x, t1) :: ctx.vars } in
          let ctx'' = check ctx' b t2 in
          ctx''
      | _ ->
          fail_tp
            (Printf.sprintf "Expected function type, got type '%s'"
               (string_of_tp tp)))
  | Assign (x, t) -> raise NotImplemented
  | DerefAssign (x, t) -> raise NotImplemented
  | Borrow t -> raise NotImplemented
  | BorrowMut t -> raise NotImplemented
  | Deref t -> raise NotImplemented
  | IfElse (t1, t2, t3) -> raise NotImplemented
  | NatVecMake ts -> raise NotImplemented
  | NatVecGet (t1, t2) -> raise NotImplemented
  | NatVecGetMut (t1, t2) -> raise NotImplemented
  | NatVecPush (t1, t2) -> raise NotImplemented
  | NatVecPop t1 -> raise NotImplemented
  | Annotated (t, anno_tp) ->
      if tp <> anno_tp then fail_expected_tp tp anno_tp else check ctx t tp
