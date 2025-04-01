type tm =
  | Var of string
  | Lam of string * tm
  | App of tm * tm
  | Borrow of tm
  | BorrowMut of tm
  | IfElse of tm * tm * tm
  | LetIn of string * tm * tm
  | LetMutIn of string * tm * tm
  | Assign of tm * tm
  | Zero
  | Succ of tm
  | Pred of tm
  | True
  | False
  | IsZero of tm
  | Unit

type lifetime = Scope of int

type tp =
  | Nat
  | Bool
  | Unit
  | Arrow of tp * tp
  | Ref of lifetime * tp
  | RefMut of lifetime * tp
