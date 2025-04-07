open Ast
open Typecheck

let var (x, id) = (Var (x, id), ())
let lam (x, t) = (Lam (x, t), ())
let app (t1, t2) = (App (t1, t2), ())
let borrow x = (Borrow x, ())
let borrow_mut x = (BorrowMut x, ())
let deref t = (Deref t, ())
let if_ (t1, t2, t3) = (IfElse (t1, t2, t3), ())
let let_in (x, t1, t2) = (LetIn (x, t1, t2), ())
let assign (x, t) = (Assign (x, t), ())
let deref_assign (x, t) = (DerefAssign (x, t), ())
let zero = (Zero, ())
let succ t = (Succ t, ())
let pred t = (Pred t, ())
let true_ = (True, ())
let false_ = (False, ())
let iszero t = (IsZero t, ())
let unit = (Unit, ())
let annotated t tp = (Annotated (t, tp), ())

let%test "checking against simple lambda" =
  let ast = lam (("x", 0), succ (var ("x", 0))) in
  check [] ast (Arrow (Nat, Nat)) |> ignore;
  true

let%test "checking against if expression" =
  let ast =
    lam (("x", 0), if_ (iszero (var ("x", 0)), succ zero, var ("x", 0)))
  in
  check [] ast (Arrow (Nat, Nat)) |> ignore;
  true

let%test "checking lambda with ref arg" =
  let ast = lam (("x", 0), var ("x", 0)) in
  let tp =
    Arrow (Ref (LifetimeVar "a", Nat, Shr), Ref (LifetimeVar "a", Nat, Shr))
  in
  check [] ast tp |> ignore;
  true

let%test
    "checking lambda with shared ref arg but mutable ref return should fail" =
  let ast = lam (("x", 0), var ("x", 0)) in
  let tp =
    Arrow (Ref (LifetimeVar "a", Nat, Shr), Ref (LifetimeVar "a", Nat, Mut))
  in
  match check [] ast tp with
  | exception TypeError _ -> true
  | (exception _) | _ -> false

let%test "checking let/in" =
  let ast =
    let_in (("x", 0), iszero (succ zero), let_in (("y", 1), zero, var ("y", 1)))
  in
  let tp = Nat in
  check [] ast tp |> ignore;
  true

let%test "checking borrowing bound variables" =
  let ast =
    let_in
      ( ("x", 0),
        succ zero,
        let_in (("y", 1), borrow (var ("x", 0)), var ("y", 1)) )
  in
  let tp = Ref (Scope 0, Nat, Shr) in
  check [] ast tp |> ignore;
  true

let%test "checking borrowing bound variables against a lifetime variable" =
  let ast =
    let_in
      ( ("x", 0),
        succ zero,
        let_in (("y", 1), borrow (var ("x", 0)), var ("y", 1)) )
  in
  let tp = Ref (LifetimeVar "a", Nat, Shr) in
  check [] ast tp |> ignore;
  true

let%test "reassigning a reference with a smaller lifetime should fail" =
  let ast =
    let_in
      ( ("x", 0),
        succ zero,
        let_in
          ( ("y", 1),
            borrow (var ("x", 0)),
            let_in (("z", 2), zero, assign (("y", 1), borrow (var ("z", 2)))) )
      )
  in
  let tp = Ref (Any, Nat, Shr) in
  match check [] ast tp with
  | exception TypeError _ -> true
  | (exception _) | _ -> false

let%test
    "can reassign a mutable reference to an immutable one with a smaller \
     lifetime" =
  let ast =
    let_in
      ( ("x", 0),
        succ zero,
        let_in
          ( ("y", 1),
            zero,
            let_in
              ( ("z", 2),
                borrow (var ("y", 1)),
                assign (("z", 2), borrow_mut (var ("x", 0))) ) ) )
  in
  check [] ast Unit |> ignore;
  true

(* let%test "true check against not bool" = *)
(*   match check empty_context False Nat = empty_context with *)
(*   | exception TypeError _ -> true *)
(*   | (exception _) | _ -> false *)
(**)
(* let%test "succ synthesis" = *)
(*   let _, inferred = syn empty_context (Succ (Succ (Succ Zero))) in *)
(*   inferred = Nat *)
(**)
(* let%test "succ synthesis checks argument" = *)
(*   match syn empty_context (Succ (Succ (Succ True))) with *)
(*   | exception TypeError _ -> true *)
(*   | (exception _) | _ -> false *)
(**)
(* let%test "pred synthesis" = *)
(*   let _, inferred = syn empty_context (Pred (Succ Zero)) in *)
(*   inferred = Nat *)
(**)
(* let%test "iszero synthesis" = *)
(*   let _, inferred = syn empty_context (IsZero (Succ Zero)) in *)
(*   inferred = Bool *)
(**)
(* let%test "iszero synthesis with non-s" = *)
(*   let _, inferred = syn empty_context (IsZero (Succ Zero)) in *)
(*   inferred = Bool *)
(**)
(* let%test "basic move semantics" = *)
(*   let ast = Lam ("x", LetIn ("y", Var "x", LetIn ("z", Var "x", Unit))) in *)
(*   match check empty_context ast (Arrow (Nat, Unit)) with *)
(*   | exception MovedValue _ -> true *)
(*   | (exception _) | _ -> false *)
