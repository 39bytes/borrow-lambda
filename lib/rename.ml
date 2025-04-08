open Ast

let fresh_var =
  let n = ref 0 in
  fun () ->
    let x = !n in
    n := !n + 1;
    x

exception FreeVariable

module StringMap = Map.Make (String)

let rename (tm : named_tm) : unit tm =
  let rec go tm ctx =
    let term =
      match tm with
      | NVar x -> (
          match StringMap.find_opt x ctx with
          | Some id -> Var (x, id)
          | None -> raise FreeVariable)
      | NLam (x, body) ->
          let id = fresh_var () in
          Lam ((x, id), go body (StringMap.add x id ctx))
      | NApp (t1, t2) -> App (go t1 ctx, go t2 ctx)
      | NBorrow t -> Borrow (go t ctx)
      | NBorrowMut t -> BorrowMut (go t ctx)
      | NDeref t -> Deref (go t ctx)
      | NIfElse (cond, t1, t2) -> IfElse (go cond ctx, go t1 ctx, go t2 ctx)
      | NLetIn (x, t1, t2) ->
          let id = fresh_var () in
          LetIn ((x, id), go t1 ctx, go t2 (StringMap.add x id ctx))
      | NAssign (x, t) -> (
          match StringMap.find_opt x ctx with
          | Some id -> Assign ((x, id), go t ctx)
          | None -> raise FreeVariable)
      | NDerefAssign (x, t) -> (
          match StringMap.find_opt x ctx with
          | Some id -> DerefAssign ((x, id), go t ctx)
          | None -> raise FreeVariable)
      | NZero -> Zero
      | NSucc t -> Succ (go t ctx)
      | NPred t -> Pred (go t ctx)
      | NTrue -> True
      | NFalse -> False
      | NIsZero t -> IsZero (go t ctx)
      | NUnit -> UnitTerm
      | NNatVecMake ts -> NatVecMake (List.map (fun t -> go t ctx) ts)
      | NNatVecGet (t1, t2) -> NatVecGet (go t1 ctx, go t2 ctx)
      | NNatVecGetMut (t1, t2) -> NatVecGetMut (go t1 ctx, go t2 ctx)
      | NNatVecPush (t1, t2) -> NatVecPush (go t1 ctx, go t2 ctx)
      | NNatVecPop t -> NatVecPop (go t ctx)
      | NAnnotated (t, tp) -> Annotated (go t ctx, tp)
    in
    (term, ())
  in
  go tm StringMap.empty
