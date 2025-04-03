type tm =
  | Var of string
  | Lam of string * tm
  | App of tm * tm
  | Borrow of tm
  | BorrowMut of tm
  | IfElse of tm * tm * tm
  | LetIn of string * tm * tm
  | Assign of string * tm
  | DerefAssign of string * tm
  | Zero
  | Succ of tm
  | Pred of tm
  | True
  | False
  | IsZero of tm
  | Unit
  | NatVecMake of tm list
  | NatVecGet of tm * tm
  | NatVecGetMut of tm * tm
  | NatVecPush of tm * tm
  | NatVecPop of tm

type lifetime = Scope of int
type ref_mod = Mut | Shr

type tp =
  | Nat
  | Bool
  | Unit
  | Arrow of tp * tp
  | Ref of lifetime * tp * ref_mod

let copy : tp -> bool = function
  | Nat | Bool | Unit | Ref (_, _, Shr) -> true
  | _ -> false

module StringSet = Set.Make (String)

type gamma = (string * tp) list
type delta = StringSet.t
type fn_ctx = StringSet.t
type borrow_ctx = (string * ref_mod) list
