open Borrow_lambda
open Utils

let should_pass =
  [
    ( "can return a reference that lives long enough",
      fun () ->
        Passes.borrow_check
          {| 
        let x = 0 in
        let z = (let y = &x in y) in
        unit
      |}
    );
    ( "can pop from natvec multiple times",
      fun () ->
        Passes.borrow_check
          {| 
        let x = natvec_make(0, succ 0, succ (succ 0)) in
        let a = natvec_pop(&mut x) in
        let b = natvec_pop(&mut x) in
        let c = natvec_pop(&mut x) in
        a
      |}
    );
  ]
  |> List.map Utils.check_pass |> List.map Utils.make_test

let should_fail =
  [
    ( "can't mutably borrow twice",
      Borrow_check.BorrowError
        "Cannot mutably borrow 'x' while it is already borrowed",
      fun () ->
        Passes.borrow_check
          {| 
        let x = 0 in
        let y = &mut x in
        let z = &mut x in
        unit
      |}
    );
    ( "can't immutably borrow while mutably borrowed",
      Borrow_check.BorrowError "Cannot borrow 'x' while it is mutably borrowed",
      fun () ->
        Passes.borrow_check
          {| 
        let x = 0 in
        let y = &mut x in
        let z = &x in
        unit
      |}
    );
    ( "can't return an escaping reference",
      Borrow_check.BorrowError
        "Cannot return reference because it does not live long enough",
      fun () ->
        Passes.borrow_check
          {| 
        let x = 0 in
        let z = &x in
        z
      |} );
    ( "natvec push while mutably borrowed",
      Borrow_check.BorrowError
        "Cannot mutably borrow 'x' while it is already borrowed",
      fun () ->
        Passes.borrow_check
          {| 
        let x = natvec_make(0, succ 0, succ (succ 0)) in
        let elem = natvec_get_mut(&mut x, succ 0) in
        natvec_push(&mut x, 0)
      |}
    );
  ]
  |> List.map Utils.check_fail |> List.map Utils.make_test

let suite = should_pass @ should_fail
let () = ()
