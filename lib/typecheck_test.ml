open Ast
open Typecheck

let%test "true check against bool" =
  check empty_context True Bool = empty_context

let%test "false check against bool" =
  check empty_context False Bool = empty_context

let%test "true check against not bool" =
  match check empty_context False Nat = empty_context with
  | exception TypeError _ -> true
  | (exception _) | _ -> false

let%test "succ synthesis" =
  let _, inferred = syn empty_context (Succ (Succ (Succ Zero))) in
  inferred = Nat

let%test "succ synthesis checks argument" =
  match syn empty_context (Succ (Succ (Succ True))) with
  | exception TypeError _ -> true
  | (exception _) | _ -> false

let%test "pred synthesis" =
  let _, inferred = syn empty_context (Pred (Succ Zero)) in
  inferred = Nat

let%test "iszero synthesis" =
  let _, inferred = syn empty_context (IsZero (Succ Zero)) in
  inferred = Bool

let%test "iszero synthesis with non-s" =
  let _, inferred = syn empty_context (IsZero (Succ Zero)) in
  inferred = Bool

let%test "basic move semantics" =
  let ast = Lam ("x", LetIn ("y", Var "x", LetIn ("z", Var "x", Unit))) in
  match check empty_context ast (Arrow (Nat, Unit)) with
  | exception MovedValue _ -> true
  | (exception _) | _ -> false
