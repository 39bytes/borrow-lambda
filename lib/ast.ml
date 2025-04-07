type lifetime = LifetimeVar of string | Scope of int
type ref_mod = Mut | Shr
type var_id = string * int

type tp =
  | Nat
  | Bool
  | Unit
  | Arrow of tp * tp
  | Ref of lifetime * tp * ref_mod
  | NatVec

type named_tm =
  | NVar of string
  | NLam of string * named_tm
  | NApp of named_tm * named_tm
  | NBorrow of named_tm
  | NBorrowMut of named_tm
  | NDeref of named_tm
  | NIfElse of named_tm * named_tm * named_tm
  | NLetIn of string * named_tm * named_tm
  | NAssign of string * named_tm
  | NDerefAssign of string * named_tm
  | NZero
  | NSucc of named_tm
  | NPred of named_tm
  | NTrue
  | NFalse
  | NIsZero of named_tm
  | NUnit
  | NNatVecMake of named_tm list
  | NNatVecGet of named_tm * named_tm
  | NNatVecGetMut of named_tm * named_tm
  | NNatVecPush of named_tm * named_tm
  | NNatVecPop of named_tm
  | NAnnotated of named_tm * tp

type 'a tm = 'a tm' * 'a

and 'a tm' =
  | Var of var_id
  | Lam of var_id * 'a tm
  | App of 'a tm * 'a tm
  | Borrow of 'a tm
  | BorrowMut of 'a tm
  | Deref of 'a tm
  | IfElse of 'a tm * 'a tm * 'a tm
  | LetIn of var_id * 'a tm * 'a tm
  | Assign of var_id * 'a tm
  | DerefAssign of var_id * 'a tm
  | Zero
  | Succ of 'a tm
  | Pred of 'a tm
  | True
  | False
  | IsZero of 'a tm
  | Unit
  | NatVecMake of 'a tm list
  | NatVecGet of 'a tm * 'a tm
  | NatVecGetMut of 'a tm * 'a tm
  | NatVecPush of 'a tm * 'a tm
  | NatVecPop of 'a tm
  | Annotated of 'a tm * tp

let string_of_lifetime lft =
  "'" ^ match lft with LifetimeVar v -> v | Scope n -> string_of_int n

let rec string_of_tp = function
  | Nat -> "Nat"
  | Bool -> "Bool"
  | Unit -> "Unit"
  | Arrow (t1, t2) ->
      Printf.sprintf "%s -> %s" (string_of_tp t1) (string_of_tp t2)
  | Ref (lft, t, Shr) ->
      Printf.sprintf "&%s %s" (string_of_lifetime lft) (string_of_tp t)
  | Ref (lft, t, Mut) ->
      Printf.sprintf "&%s mut %s" (string_of_lifetime lft) (string_of_tp t)
  | NatVec -> "NatVec"
