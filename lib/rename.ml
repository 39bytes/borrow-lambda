open Ast

let fresh_var =
  let n = ref 0 in
  fun () ->
    let x = !n in
    n := !n + 1;
    x

exception FreeVariable

module StringMap = Map.Make (String)

let rec rename (tm : named_tm) (ctx : int StringMap.t) : unit tm =
  let term =
    match tm with
    | NVar x -> (
        match StringMap.find_opt x ctx with
        | Some id -> Var (x, id)
        | None -> raise FreeVariable)
    | NLam (x, body) ->
        let id = fresh_var () in
        Lam ((x, id), rename body (StringMap.add x id ctx))
    | NApp (t1, t2) -> App (rename t1 ctx, rename t2 ctx)
    | NBorrow t -> Borrow (rename t ctx)
    | NBorrowMut t -> BorrowMut (rename t ctx)
    | NDeref t -> Deref (rename t ctx)
    | NIfElse (cond, t1, t2) ->
        IfElse (rename cond ctx, rename t1 ctx, rename t2 ctx)
    | NLetIn (x, t1, t2) ->
        let id = fresh_var () in
        LetIn ((x, id), rename t1 ctx, rename t2 (StringMap.add x id ctx))
    | NAssign (x, t) -> (
        match StringMap.find_opt x ctx with
        | Some id -> Assign ((x, id), rename t ctx)
        | None -> raise FreeVariable)
    | NDerefAssign (x, t) -> (
        match StringMap.find_opt x ctx with
        | Some id -> DerefAssign ((x, id), rename t ctx)
        | None -> raise FreeVariable)
    | NZero -> Zero
    | NSucc t -> Succ (rename t ctx)
    | NPred t -> Pred (rename t ctx)
    | NTrue -> True
    | NFalse -> False
    | NIsZero t -> IsZero (rename t ctx)
    | NUnit -> Unit
    | NNatVecMake ts -> NatVecMake (List.map (fun t -> rename t ctx) ts)
    | NNatVecGet (t1, t2) -> NatVecGet (rename t1 ctx, rename t2 ctx)
    | NNatVecGetMut (t1, t2) -> NatVecGetMut (rename t1 ctx, rename t2 ctx)
    | NNatVecPush (t1, t2) -> NatVecPush (rename t1 ctx, rename t2 ctx)
    | NNatVecPop t -> NatVecPop (rename t ctx)
    | NAnnotated (t, tp) -> Annotated (rename t ctx, tp)
  in
  (term, ())
