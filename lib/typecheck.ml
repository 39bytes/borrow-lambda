open Ast

let copy : tp -> bool = function
  | Nat | Bool | Unit | Ref (_, _, Shr) -> true
  | _ -> false

module StringSet = Set.Make (String)

exception TypeError

type context = {
  (* Gamma *)
  vars : (string * tp) list;
  (* Delta *)
  used : StringSet.t;
  (* F *)
  bound_in_fn : StringSet.t;
  (* B *)
  borrowed : (string * ref_mod) list;
}
