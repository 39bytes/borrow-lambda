open Borrow_lambda
open Utils

let check_fail (name, exn, f) =
  (name, fun () -> Alcotest.check_raises name exn (fun () -> f () |> ignore))

(* Tests *)

let should_pass =
  [
    ( "basic lambda check",
      fun () -> Passes.typecheck {| (\x. succ x) : nat -> nat |} );
    ( "lambda with ref arg",
      fun () -> Passes.typecheck {| (\x. x) : &'a nat -> &'a nat |} );
    ( "if expression",
      fun () ->
        Passes.typecheck {| (\x. if iszero x then succ 0 else x) : nat -> nat |}
    );
    ( "let/in",
      fun () ->
        Passes.typecheck {| (let x = iszero (succ 0) in let y = 0 in y) : nat |}
    );
    ( "borrowing bound variables",
      fun () ->
        Passes.typecheck {| (let x = succ 0 in let y = &x in y) : &'a nat |} );
  ]
  |> List.map Utils.check_pass |> List.map Utils.make_test

let should_fail =
  [
    ( "checking lambda with shared ref arg but mutable ref return should fail",
      Typecheck.TypeError "Expected type '&'a mut nat', got type '&'a nat'",
      fun () -> Passes.typecheck {| (\x. x) : &'a nat -> &'a mut nat |} );
    ( "reassigning a reference with a smaller lifetime should fail",
      Typecheck.TypeError "Expected type '&'0 nat', got type '&'2 nat'",
      fun () ->
        Passes.typecheck
          {| (let x = succ 0 in let y = &x in let z = 0 in y := &z) : &'a nat |}
    );
  ]
  |> List.map check_fail |> List.map Utils.make_test

let suite = should_pass @ should_fail
let () = ()
