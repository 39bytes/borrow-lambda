open Ast

exception MovedValue of string
exception BorrowedValue of string
exception BorrowError of string

module IntSet = Set.Make (Int)

type context = {
  vars : var_id list;
  (* Delta *)
  used : IntSet.t;
  (* F *)
  bound_in_fn : IntSet.t;
  (* B *)
  borrowed : (int * ref_mod) list;
}

let empty_context =
  { vars = []; used = IntSet.empty; bound_in_fn = IntSet.empty; borrowed = [] }

let fail_borrow_move x =
  let msg = Printf.sprintf "Cannot move variable '%s' while it is borrowed" x in
  raise (BorrowedValue msg)

let fail_moved_value x =
  let msg = Printf.sprintf "Use of moved value '%s'" x in
  raise (MovedValue msg)

let copy : tp -> bool = function
  | Nat | Bool | Unit | Ref (_, _, Shr, _) -> true
  | _ -> false

let bound_in_current (ctx : context) (x : var_id) : bool =
  IntSet.exists (( = ) x) ctx.bound_in_fn

let borrow_mod (ctx : context) (x : var_id) : ref_mod option =
  List.assoc_opt x ctx.borrowed

let is_borrowed ctx x = borrow_mod ctx x |> Option.is_some
let moved (ctx : context) (x : var_id) : bool = IntSet.exists (( = ) x) ctx.used

let rec borrow_check_rec (ctx : context) (tm : tp tm) : context =
  match tm with
  | Var (name, id), tp ->
      if copy tp then ctx
      else if is_borrowed ctx id then fail_borrow_move name
      else if IntSet.exists (( = ) id) ctx.used then fail_moved_value name
      else { ctx with used = IntSet.add id ctx.used }
  | Lam ((_, id), body), _ ->
      borrow_check_rec
        { ctx with vars = id :: ctx.vars; bound_in_fn = IntSet.of_list [ id ] }
        body
  | App (t1, t2), _ ->
      let ctx1 = borrow_check_rec ctx t1 in
      borrow_check_rec ctx1 t2
  | Borrow t, _ -> (
      match t with
      | Var (name, id), _ -> (
          if moved ctx id then fail_moved_value name
          else
            match borrow_mod ctx id with
            | Some Mut ->
                raise
                  (BorrowError
                     (Printf.sprintf
                        "Cannot borrow '%s' while it is mutably borrowed" name))
            | _ when bound_in_current ctx id ->
                { ctx with borrowed = (id, Shr) :: ctx.borrowed }
            | _ ->
                raise
                  (BorrowError
                     (Printf.sprintf "Cannot borrow captured variable '%s'" name))
          )
      | _ -> raise (BorrowError "Cannot borrow non-variable term"))
  | BorrowMut t, _ -> (
      match t with
      | Var (name, id), _ -> (
          if moved ctx id then fail_moved_value name
          else
            match borrow_mod ctx id with
            | Some _ ->
                raise
                  (BorrowError
                     (Printf.sprintf
                        "Cannot mutably borrow '%s' while it is already \
                         borrowed"
                        name))
            | _ when bound_in_current ctx id ->
                { ctx with borrowed = (id, Mut) :: ctx.borrowed }
            | _ ->
                raise
                  (BorrowError
                     (Printf.sprintf "Cannot borrow captured variable '%s'" name))
          )
      | _ -> raise (BorrowError "Cannot borrow non-variable term"))
  | Deref t, tp ->
      let ctx' = borrow_check_rec ctx t in
      if copy tp then ctx'
      else
        raise
          (BorrowError
             (Printf.sprintf "Cannot dereference non-copyable type '%s'"
                (string_of_tp tp)))
  | IfElse (t1, t2, t3), _ ->
      let ctx1 = borrow_check_rec ctx t1 in
      let ctx2 = borrow_check_rec ctx1 t2 in
      let ctx3 = borrow_check_rec ctx1 t3 in
      { ctx1 with used = IntSet.union ctx2.used ctx3.used }
  | LetIn ((_, id), t1, t2), tp -> (
      let ctx1 = borrow_check_rec ctx t1 in
      let ctx2 =
        borrow_check_rec
          {
            ctx1 with
            vars = id :: ctx1.vars;
            bound_in_fn = IntSet.add id ctx1.bound_in_fn;
            (* all borrows that occur in the binding have ended by the time
               we evaluate t2, UNLESS a reference is bound *)
            borrowed =
              (match tag t1 with
              | Ref (_, _, ref_mod, Some var_id) ->
                  (var_id, ref_mod) :: ctx.borrowed
              | _ -> ctx.borrowed);
            (* ctx.borrowed; *)
          }
          t2
      in
      match tp with
      | Ref (Scope a, _, _, _) when a >= List.length ctx1.vars ->
          raise
            (BorrowError
               "Cannot return reference because it does not live long enough")
      (* scope ended, so the borrowed variables are the same as when we came in*)
      | _ -> { ctx2 with borrowed = ctx.borrowed })
  | Assign ((name, id), t), _ ->
      if is_borrowed ctx id then
        raise
          (BorrowedValue
             (Printf.sprintf "Cannot assign of borrowed value '%s'" name))
      else
        let ctx' = borrow_check_rec ctx t in
        (* x has a value again, so we can use it once more *)
        { ctx' with used = IntSet.remove id ctx'.used }
  | DerefAssign ((_, _), t), _ -> borrow_check_rec ctx t
  | Zero, _ -> ctx
  | Succ t, _ -> borrow_check_rec ctx t
  | Pred t, _ -> borrow_check_rec ctx t
  | True, _ -> ctx
  | False, _ -> ctx
  | IsZero t, _ -> borrow_check_rec ctx t
  | UnitTerm, _ -> ctx
  | NatVecMake ts, _ -> List.fold_left borrow_check_rec ctx ts
  | NatVecGet (t1, t2), _ ->
      let ctx1 = borrow_check_rec ctx t1 in
      borrow_check_rec ctx1 t2
  | NatVecGetMut (t1, t2), _ ->
      let ctx1 = borrow_check_rec ctx t1 in
      borrow_check_rec ctx1 t2
  | NatVecPush (t1, t2), _ ->
      let ctx1 = borrow_check_rec ctx t1 in
      borrow_check_rec ctx1 t2
  | NatVecPop t, _ -> borrow_check_rec ctx t
  | Annotated (_, _), _ ->
      failwith "should not have annotated term at borrow check pass"

let borrow_check = borrow_check_rec empty_context
