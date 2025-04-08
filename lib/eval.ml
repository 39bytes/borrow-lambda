open Ast

module VarIdMap = Map.Make (struct
  type t = var_id

  let compare = compare
end)

type value =
  | VZero
  | VSucc of value
  | VTrue
  | VFalse
  | VUnit
  | VRef of var_id
  | VNatVec of value list
  | VLam of var_id * tp tm (* var, body *)

(* convert Nats to OCaml integers to use with the underlying list representation of NatVec *)
let nat_to_int (nat : value) : int =
  let rec go nat n = match nat with VZero -> n | VSucc t -> go t (n + 1) in
  go nat 0

let rec eval (env : value VarIdMap.t) (tm : tp tm) : value =
  match fst tm with
  | Zero -> VZero
  | Succ t -> VSucc (eval env t)
  | True -> VTrue
  | False -> VFalse
  | UnitTerm -> VUnit
  | IfElse (t1, t2, t3) -> (
      match eval env t1 with VTrue -> eval env t2 | VFalse -> eval env t3)
  | IsZero t -> ( match eval env t with VZero -> VTrue | VSucc _ -> VFalse)
  | Pred t -> ( match eval env t with VZero -> VZero | VSucc t' -> t')
  | Borrow t | BorrowMut t -> ( match fst t with Var (_, id) -> VRef id)
  | Lam ((_, id), b) -> VLam (id, b)
  | App (t1, t2) -> (
      let t1' = eval env t1 in
      let t2' = eval env t2 in
      match t1' with
      | VLam (id, b) ->
          let env' = VarIdMap.add id t2' env in
          eval env' b)
  | LetIn ((_, id), t1, t2) ->
      let t1' = eval env t1 in
      let env' = VarIdMap.add id t1' env in
      eval env' t2
  | NatVecMake tms -> VNatVec (List.map (eval env) tms)
  | NatVecGet (t1, t2) | NatVecGetMut (t1, t2) -> (
      let vec = eval env t1 in
      let idx = eval env t2 in
      match vec with VNatVec vs -> List.nth vs (nat_to_int idx))
  | Annotated (t, _) -> eval env t
