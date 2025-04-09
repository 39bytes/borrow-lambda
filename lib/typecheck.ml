open Ast

exception TypeError of string
exception TypeAnnotationRequired of string

type context = (var_id * (tp * lifetime)) list

let rec print_context (ctx : context) =
  let () = print_endline "context:" in
  match ctx with
  | [] -> print_endline "done"
  | (id, (tp, lft)) :: ctx ->
      let () =
        Printf.printf "%d : %s %s\n" id (string_of_tp tp)
          (string_of_lifetime lft)
      in
      print_context ctx

let rec subtype (t1 : tp) (t2 : tp) =
  match (t1, t2) with
  | Ref (alpha, tp1, mod1, _), Ref (beta, tp2, mod2, _) -> (
      let compatible_lifetimes =
        match (alpha, beta) with
        | Scope x, Scope y -> x <= y
        | LifetimeVar a, LifetimeVar b when a <> b -> false
        | Scope _, LifetimeVar _ -> false
        | _ -> true
      in
      if not compatible_lifetimes then false
      else if not (subtype tp1 tp2) then false
      else
        match (mod1, mod2) with
        | Shr, Mut -> false
        | Shr, Shr -> true
        | Mut, Shr -> true
        | Mut, Mut -> true)
  | _, _ -> t1 = t2

let ( <: ) = subtype

let subst_lifetime_vars (tp : tp) (lft_var : string) (lft : lifetime)
    (borrow_id : var_id option) =
  match tp with
  | Ref (LifetimeVar x, ref_tp, ref_mod, _) when x = lft_var ->
      Ref (lft, ref_tp, ref_mod, borrow_id)
  | _ -> tp

(* Exception helpers *)
let fail_tp msg = raise (TypeError msg)

let fail_expected_tp expected actual =
  raise
    (TypeError
       (Printf.sprintf "Expected type '%s', got type '%s'"
          (string_of_tp expected) (string_of_tp actual)))

(* Utilities *)

let find_in_context (ctx : context) (id : int) : tp * lifetime =
  match List.assoc_opt id ctx with
  | Some info -> info
  | None -> failwith "free variable"

let add_to_context (ctx : context) (id : int) (tp : tp) : context =
  (id, (tp, Scope (List.length ctx))) :: ctx

(* Actual typechecking *)

let rec syn (ctx : context) (tm : unit tm) : tp tm =
  match tm with
  | Var (name, id), _ ->
      let tp, _ = find_in_context ctx id in
      (Var (name, id), tp)
  | Lam (_, _), _ ->
      raise
        (TypeAnnotationRequired
           "Could not infer type of lambda, type annotation required")
  | App (t1, t2), _ -> (
      let tagged_fun = syn ctx t1 in
      match tag tagged_fun with
      | Arrow (tp1, tp2) -> (
          match tp1 with
          (* If the parameter contains a lifetime variable, then we want to instantiate
             it with whatever the argument that it was called with is.
             So we first check the argument against a reference to extract the 
             actual concrete lifetime, then perform the substitution against the return type.
          *)
          | Ref (LifetimeVar alpha, ref_tp, ref_mod, _) -> (
              let tagged_arg =
                check ctx t2 (Ref (Any, ref_tp, ref_mod, None))
              in
              match tag tagged_arg with
              | Ref (lft, _, _, var_id) ->
                  let ret_tp = subst_lifetime_vars tp2 alpha lft var_id in
                  (App (tagged_fun, tagged_arg), ret_tp)
              | _ -> failwith "impossible")
          | _ ->
              let tagged_arg = check ctx t2 tp1 in
              (App (tagged_fun, tagged_arg), tp2))
      | _ -> fail_tp "Expected function type on left hand side of application")
  | Borrow t, _ -> (
      match t with
      | Var (name, id), _ ->
          let tp, lft = find_in_context ctx id in
          let tagged_var = (Var (name, id), tp) in
          (Borrow tagged_var, Ref (lft, tp, Shr, Some id))
      | _ -> raise (TypeError "Cannot borrow non-variable term"))
  | BorrowMut t, _ -> (
      match t with
      | Var (name, id), _ ->
          let tp, lft = find_in_context ctx id in
          let tagged_var = (Var (name, id), tp) in
          (BorrowMut tagged_var, Ref (lft, tp, Mut, Some id))
      | _ -> raise (TypeError "Cannot borrow non-variable term"))
  | Deref t, _ -> (
      let tagged_t = syn ctx t in
      match tag tagged_t with
      | Ref (_, ref_tp, _, _) -> (Deref tagged_t, ref_tp)
      | _ ->
          raise
            (TypeError
               (Printf.sprintf "Cannot dereference non-reference type '%s'"
                  (string_of_tp (tag tagged_t)))))
  | Assign ((name, id), t), _ ->
      let tp, _ = find_in_context ctx id in
      let tagged_rhs = check ctx t tp in
      (Assign ((name, id), tagged_rhs), Unit)
  | DerefAssign ((name, id), t), _ -> (
      let tp, _ = find_in_context ctx id in
      match tp with
      | Ref (_, ref_tp, Mut, _) ->
          let tagged_rhs = check ctx t ref_tp in
          (DerefAssign ((name, id), tagged_rhs), Unit)
      | _ -> raise (TypeError "Cannot assign to non-mutable reference type"))
  | IfElse _, _ ->
      raise
        (TypeAnnotationRequired
           "Could not infer type of if/else, type annotation required")
  | LetIn ((name, id), t1, t2), _ ->
      let tagged_t1 = syn ctx t1 in
      let tagged_t2 = syn (add_to_context ctx id (tag tagged_t1)) t2 in
      (LetIn ((name, id), tagged_t1, tagged_t2), tag tagged_t2)
  | Zero, _ -> (Zero, Nat)
  | Succ t, _ -> (Succ (check ctx t Nat), Nat)
  | Pred t, _ -> (Pred (check ctx t Nat), Nat)
  | True, _ -> (True, Bool)
  | False, _ -> (False, Bool)
  | IsZero t, _ -> (IsZero (check ctx t Nat), Bool)
  | UnitTerm, _ -> (UnitTerm, Unit)
  | NatVecMake ts, _ ->
      let args = List.map (fun t -> check ctx t Nat) ts in
      (NatVecMake args, NatVec)
  | NatVecGet (t1, t2), _ -> (
      let tagged_vec = check ctx t1 (Ref (Any, NatVec, Shr, None)) in
      match tag tagged_vec with
      | Ref (lft, _, _, var_id) ->
          let tagged_index = check ctx t2 Nat in
          (NatVecGet (tagged_vec, tagged_index), Ref (lft, Nat, Shr, var_id))
      | _ -> failwith "impossible")
  | NatVecGetMut (t1, t2), _ -> (
      let tagged_vec = check ctx t1 (Ref (Any, NatVec, Mut, None)) in
      match tag tagged_vec with
      | Ref (lft, _, _, var_id) ->
          let tagged_index = check ctx t2 Nat in
          (NatVecGetMut (tagged_vec, tagged_index), Ref (lft, Nat, Mut, var_id))
      | _ -> failwith "impossible")
  | NatVecPush (t1, t2), _ ->
      let tagged_vec = check ctx t1 (Ref (Any, NatVec, Mut, None)) in
      let tagged_val = check ctx t2 Nat in
      (NatVecPush (tagged_vec, tagged_val), Unit)
  | NatVecPop t, _ ->
      let tagged_vec = check ctx t (Ref (Any, NatVec, Mut, None)) in
      (NatVecPop tagged_vec, Nat)
  | Annotated (t, tp), _ -> check ctx t tp

and check (ctx : context) (tm : unit tm) (tp : tp) : tp tm =
  match tm with
  | Lam ((name, id), body), _ -> (
      match tp with
      | Arrow (t1, t2) ->
          let tagged_body = check (add_to_context ctx id t1) body t2 in
          (Lam ((name, id), tagged_body), tp)
      | _ ->
          fail_tp
            (Printf.sprintf "Expected function type, got type '%s'"
               (string_of_tp tp)))
  | IfElse (t1, t2, t3), _ ->
      let tagged_t1 = check ctx t1 Bool in
      let tagged_t2 = check ctx t2 tp in
      let tagged_t3 = check ctx t3 tp in
      (IfElse (tagged_t1, tagged_t2, tagged_t3), tp)
  | LetIn ((name, id), t1, t2), _ ->
      let tagged_t1 = syn ctx t1 in
      let tagged_t2 = check (add_to_context ctx id (tag tagged_t1)) t2 tp in
      (LetIn ((name, id), tagged_t1, tagged_t2), tag tagged_t2)
  | Annotated (t, anno_tp), _ ->
      if tp <> anno_tp then fail_expected_tp tp anno_tp else check ctx t tp
  | _ ->
      let typed_tm, inferred = syn ctx tm in
      if not (inferred <: tp) then fail_expected_tp tp inferred
      else (typed_tm, inferred)

let typecheck tm = syn [] tm
