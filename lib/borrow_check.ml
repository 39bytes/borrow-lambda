open Ast

exception MovedValue of string
exception BorrowedValue of string
exception BorrowError of string

module IntSet = Set.Make (Int)

type context = {
  (* Delta *)
  used : IntSet.t;
  (* F *)
  bound_in_fn : IntSet.t;
  (* B *)
  borrowed : (int * ref_mod) list;
}

let empty_context =
  { used = IntSet.empty; bound_in_fn = IntSet.empty; borrowed = [] }

let fail_borrow_move x =
  let msg = Printf.sprintf "Cannot move variable '%s' while it is borrowed" x in
  raise (BorrowedValue msg)

let fail_moved_value x =
  let msg = Printf.sprintf "Use of moved value '%s'" x in
  raise (MovedValue msg)

let copy : tp -> bool = function
  | Nat | Bool | Unit | Ref (_, _, Shr) -> true
  | _ -> false

let bound_in_current (ctx : context) (x : var_id) : bool =
  IntSet.exists (( = ) x) ctx.bound_in_fn

let borrow_mod (ctx : context) (x : var_id) : ref_mod option =
  List.assoc_opt x ctx.borrowed

let is_borrowed ctx x = borrow_mod ctx x |> Option.is_some
let moved (ctx : context) (x : var_id) : bool = IntSet.exists (( = ) x) ctx.used

let rec borrow_check (ctx : context) (tm : tp tm) : context =
  match tm with
  | Var (name, id), tp ->
      if copy tp then ctx
      else if is_borrowed ctx id then fail_borrow_move name
      else if IntSet.exists (( = ) id) ctx.used then fail_moved_value name
      else { ctx with used = IntSet.add id ctx.used }
  | Lam (_, _), _ -> failwith "not implemented"
  | App (t1, t2), _ ->
      let ctx1 = borrow_check ctx t1 in
      borrow_check ctx1 t2
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
      let ctx' = borrow_check ctx t in
      if copy tp then ctx'
      else
        raise
          (BorrowError
             (Printf.sprintf "Cannot dereference non-copyable type '%s'"
                (string_of_tp tp)))
  | IfElse (t1, t2, t3), _ ->
      let ctx1 = borrow_check ctx t1 in
      let ctx2 = borrow_check ctx1 t2 in
      let ctx3 = borrow_check ctx1 t3 in
      { ctx1 with used = IntSet.union ctx2.used ctx3.used }
  | LetIn ((_, id), t1, t2), _ ->
      let ctx1 = borrow_check ctx t1 in
      borrow_check { ctx1 with bound_in_fn = IntSet.add id ctx1.bound_in_fn } t2
  | Assign ((name, id), t), _ ->
      if is_borrowed ctx id then
        raise
          (BorrowedValue
             (Printf.sprintf "Cannot assign of borrowed value '%s'" name))
      else
        let ctx' = borrow_check ctx t in
        (* x has a value again, so we can use it once more *)
        { ctx' with used = IntSet.remove id ctx'.used }
  | Zero, _ -> ctx
  | Succ t, _ -> borrow_check ctx t
  | Pred t, _ -> borrow_check ctx t
  | True, _ -> ctx
  | False, _ -> ctx
  | IsZero t, _ -> borrow_check ctx t
  | Unit, _ -> ctx
  | Annotated (_, _), _ ->
      failwith "should not have annotated term at borrow check pass"
  | _ -> failwith "not implemented"
