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
