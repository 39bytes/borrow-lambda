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
  | VRef of (var_id * int option)
  | VNatVec of value Dynarray.t
  | VLam of var_id * tp tm (* var, body *)

(* convert Nats to OCaml integers to use with the underlying list representation of NatVec *)
let nat_to_int (nat : value) : int =
  let rec go nat n =
    match nat with
    | VZero -> n
    | VSucc t -> go t (n + 1)
    | _ -> failwith "impossible"
  in
  go nat 0

let eval (tm : tp tm) : value =
  let env = ref VarIdMap.empty in
  let lookup id offset =
    match (VarIdMap.find id !env, offset) with
    | VNatVec ns, Some offset -> Dynarray.get ns offset
    | v, _ -> v
  in
  let write_value id offset v =
    match (VarIdMap.find id !env, offset) with
    | VNatVec ns, Some offset -> Dynarray.set ns offset v
    | _, _ -> env := VarIdMap.add id v !env
  in
  let rec go (tm : tp tm) : value =
    match fst tm with
    | Zero -> VZero
    | Succ t -> VSucc (go t)
    | True -> VTrue
    | False -> VFalse
    | UnitTerm -> VUnit
    | Var (_, id) -> lookup id None
    | Deref t -> (
        match go t with
        | VRef (id, offset) -> lookup id offset
        | _ -> failwith "impossible")
    | Assign ((_, id), t) ->
        let v = go t in
        write_value id None v;
        VUnit
    | DerefAssign ((_, _), t) -> (
        let v = go t in
        match v with
        | VRef (id, offset) ->
            write_value id offset v;
            VUnit
        | _ -> failwith "impossible")
    | IfElse (t1, t2, t3) -> (
        match go t1 with
        | VTrue -> go t2
        | VFalse -> go t3
        | _ -> failwith "impossible")
    | IsZero t -> (
        match go t with
        | VZero -> VTrue
        | VSucc _ -> VFalse
        | _ -> failwith "impossible")
    | Pred t -> (
        match go t with
        | VZero -> VZero
        | VSucc t' -> t'
        | _ -> failwith "impossible")
    | Borrow t | BorrowMut t -> (
        match fst t with
        | Var (_, id) -> VRef (id, None)
        | _ -> failwith "impossible")
    | Lam ((_, id), b) -> VLam (id, b)
    | App (t1, t2) -> (
        let t1' = go t1 in
        let t2' = go t2 in
        match t1' with
        | VLam (id, b) ->
            write_value id None t2';
            go b
        | _ -> failwith "impossible")
    | LetIn ((_, id), t1, t2) ->
        let t1' = go t1 in
        write_value id None t1';
        go t2
    | NatVecMake tms ->
        let arr = Dynarray.create () in
        List.iter (fun v -> Dynarray.add_last arr (go v)) tms;
        VNatVec arr
    | NatVecGet (t1, t2) | NatVecGetMut (t1, t2) -> (
        let vec_ref = go t1 in
        let idx = go t2 in
        match vec_ref with
        | VRef (id, _) -> (
            match lookup id None with
            | VNatVec _ -> VRef (id, Some (nat_to_int idx))
            | _ -> failwith "impossible")
        | _ -> failwith "impossible")
    | NatVecPush (t1, t2) -> (
        let vec_ref = go t1 in
        let v = go t2 in
        match vec_ref with
        | VRef (id, _) -> (
            match lookup id None with
            | VNatVec vs ->
                Dynarray.add_last vs v;
                VUnit
            | _ -> failwith "impossible")
        | _ -> failwith "impossible")
    | NatVecPop t -> (
        let vec_ref = go t in
        match vec_ref with
        | VRef (id, _) -> (
            match lookup id None with
            | VNatVec vs -> Dynarray.pop_last vs
            | _ -> failwith "impossible")
        | _ -> failwith "impossible")
    | _ -> failwith "not implemented"
  in
  go tm

(* | NatVecMake tms -> VNatVec (List.map (eval env) tms) *)
(* | NatVecGet (t1, t2) | NatVecGetMut (t1, t2) -> ( *)
(*     let vec = eval env t1 in *)
(*     let idx = eval env t2 in *)
(*   match vec with VRef id ->  *)
(*       match VarIdMap.find id env with  *)
(*       | VNatVec vs -> List.nth  *)
(**)
(*     match vec with VNatVec vs -> List.nth vs (nat_to_int idx)) *)
(* | Annotated (t, _) -> eval env t *)
