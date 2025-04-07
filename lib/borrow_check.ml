open Ast

exception MovedValue of string
exception BorrowedValue of string
exception BorrowError of string

module IntSet = Set.Make (Int)

type context = {
  (* Gamma *)
  vars : (var_id * tp) list;
  (* Delta *)
  used : IntSet.t;
  (* F *)
  bound_in_fn : IntSet.t;
  (* B *)
  borrowed : (var_id * ref_mod) list;
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
  | Nat | Bool | Unit | Ref (_, _, Shr) -> true
  | _ -> false

let bound_in_current (ctx : context) (x : var_id) : bool =
  IntSet.exists (( = ) x) ctx.bound_in_fn

let borrow_mod (ctx : context) (x : var_id) : ref_mod option =
  List.assoc_opt x ctx.borrowed

let is_borrowed ctx x = borrow_mod ctx x |> Option.is_some
let moved (ctx : context) (x : var_id) : bool = IntSet.exists (( = ) x) ctx.used

let borrow_check (ctx : context) (tm : (int option * tp) tm) =
  failwith "not implemented"
(* match tm with *)
(*   | (Var n, tp) ->  *)
