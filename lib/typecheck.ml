open Ast

let copy : tp -> bool = function
  | Nat | Bool | Unit | Ref (_, _, Shr) -> true
  | _ -> false

module StringSet = Set.Make (String)

exception TypeError
exception NotImplemented

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

let rec syn (ctx : context) (t : tm_syn) : context * tp =
  match t with
  | Var s ->
      let tp = List.assoc s ctx.vars in
      if copy tp then (ctx, tp)
      else if List.exists (fun (name, _) -> String.equal name s) ctx.borrowed
      then
        let ctx' = { ctx with used = StringSet.add s ctx.used } in
        (ctx', tp)
      else raise TypeError
  | App (t1, t2) -> (
      let ctx1, ft = syn ctx t1 in
      match ft with
      | Arrow (tp1, tp2) ->
          let ctx2 = check ctx1 t2 tp1 in
          (ctx2, tp2)
      | _ -> raise TypeError)
  | Borrow t -> raise NotImplemented
  | BorrowMut t -> raise NotImplemented
  | Pred t -> (
      let ctx', tp = syn ctx t in
      match tp with Nat -> (ctx', Nat) | _ -> raise TypeError)
  | IsZero t -> (
      let ctx', tp = syn ctx t in
      match tp with Nat -> (ctx', Bool) | _ -> raise TypeError)
  | NatVecGet (t1, t2) -> raise NotImplemented
  | NatVecGetMut (t1, t2) -> raise NotImplemented
  | NatVecPush (t1, t2) -> raise NotImplemented
  | NatVecPop t -> raise NotImplemented

and check (ctx : context) (tm : tm_chk) (t : tp) : context =
  match tm with
  | Syn s ->
      let ctx', t' = syn ctx s in
      if t <> t' then raise TypeError else ctx'
  | Lam (x, b) -> (
      match t with
      | Arrow (t1, t2) ->
          let ctx' = { ctx with vars = (x, t1) :: ctx.vars } in
          let ctx'' = check ctx' b t2 in
          ctx''
      | _ -> raise TypeError)
  | IfElse (t1, t2, t3) -> (
      let ctx1, ct = syn ctx t1 in
      match ct with
      | Bool ->
          let ctx2 = check ctx1 t2 t in
          let ctx3 = check ctx1 t3 t in
          { ctx1 with used = StringSet.union ctx2.used ctx3.used }
      | _ -> raise TypeError)
  | LetIn (x, t1, t2) -> ctx (* ??? *)
  | Assign (x, t) -> raise NotImplemented
  | DerefAssign (x, t) -> raise NotImplemented
  | Zero -> if t <> Nat then raise TypeError else ctx
  | Succ s ->
      let ctx' = check ctx s Nat in
      if t <> Nat then raise TypeError else ctx'
  | True | False -> if t <> Bool then raise TypeError else ctx
  | Unit -> if t <> Unit then raise TypeError else ctx
  | NatVecMake ts -> raise NotImplemented
