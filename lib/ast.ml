type lifetime = int
type ref_mod = Mut | Shr

type tm =
  | Var of string
  | Lam of string * tm
  | App of tm * tm
  | Borrow of tm
  | BorrowMut of tm
  | Deref of tm
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
  | Annotated of tm * tp

and tp =
  | Nat
  | Bool
  | Unit
  | Arrow of tp * tp
  | Ref of lifetime * tp * ref_mod
  | NatVec

let rec string_of_tp = function
  | Nat -> "Nat"
  | Bool -> "Bool"
  | Unit -> "Unit"
  | Arrow (t1, t2) ->
      Printf.sprintf "%s -> %s" (string_of_tp t1) (string_of_tp t2)
  | Ref (n, t, Shr) -> Printf.sprintf "&'%d %s" n (string_of_tp t)
  | Ref (n, t, Mut) -> Printf.sprintf "&'%d mut %s" n (string_of_tp t)
  | NatVec -> "NatVec"
