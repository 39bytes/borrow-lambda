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

let rec syn (ctx : context) (t : tm_syn) : context * tp =
  match t with
    | Var s -> 
      begin
        let tp = List.assoc s (ctx.vars) in
        if copy tp then (ctx, tp)
        else if List.exists (fun (name, _) -> String.equal name s) ctx.borrowed then
          let ctx' = { ctx with used = StringSet.add s ctx.used } in
          (ctx', tp)
        else raise TypeError
      end
    | App (t1, t2) -> 
      begin
        let (ctx1, ft) = syn ctx t1 in
        match ft with
        | Arrow (tp1, tp2) ->
          begin
            let ctx2 = check ctx1 t2 tp1 in
            (ctx2, tp2)
          end
        | _ -> raise TypeError
      end
    | IsZero t ->
      begin
        let (ctx', tp) = syn ctx t in
        match tp with
        | Nat -> (ctx', Bool)
        | _ -> raise TypeError
      end
    | Pred t -> 
      begin
        let (ctx', tp) = syn ctx t in
        match tp with
        | Nat -> (ctx', Nat)
        | _ -> raise TypeError
      end
and check (ctx : context) (tm : tm_chk) (t : tp) : context = 
  match tm with
    | CVar s ->
      begin
        let (ctx', t') = syn ctx s in
        if t <> t' then raise TypeError else ctx'
      end
    | Zero -> if t <> Nat then raise TypeError else ctx
    | Succ s -> let ctx' = check ctx s Nat in if t <> Nat then raise TypeError else ctx'
    | True | False -> if t <> Bool then raise TypeError else ctx
    | Unit -> if t <> Unit then raise TypeError else ctx
    | Lam (x, b) ->
      begin
        match t with
        | Arrow(t1, t2) ->
          begin
            let ctx' = { ctx with vars = (x, t1) :: ctx.vars } in
            let ctx'' = check ctx' b t2 in
            ctx''
          end
        | _ -> raise TypeError
      end
    | IfElse (t1, t2, t3) ->
      begin
        let (ctx1, ct) = syn ctx t1 in
        match ct with
        | Bool ->
          begin
            let ctx2 = check ctx1 t2 t in
            let ctx3 = check ctx1 t3 t in
            { ctx1 with used = StringSet.union ctx2.used ctx3.used }
          end
        | _ -> raise TypeError
      end
    | LetIn (x, t1, t2) ->
      begin
       ctx (* ??? *)
      end
