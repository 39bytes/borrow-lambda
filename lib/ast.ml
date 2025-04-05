(* type tm =
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
  | NatVecPop of tm *)

type tm_syn =
  | Var of string
  | App of tm_syn * tm_chk
  | Pred of tm_syn
  | IsZero of tm_syn
and tm_chk =
  | CVar of tm_syn
  | Lam of string * tm_chk
  | IfElse of tm_syn * tm_chk * tm_chk
  | LetIn of string * tm_chk * tm_syn
  | Zero
  | Succ of tm_chk
  | True
  | False
  | Unit

type lifetime = Scope of int
type ref_mod = Mut | Shr

type tp =
  | Nat
  | Bool
  | Unit
  | Arrow of tp * tp
  | Ref of lifetime * tp * ref_mod
