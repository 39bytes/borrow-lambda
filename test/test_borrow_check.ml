open Borrow_lambda
open Utils

let should_pass =
  [
    ( "can use basic types more than once",
      fun () ->
        Passes.borrow_check
          {| 
        let a = 0 in
        let b = a in
        let c = a in
        let d = true in
        let e = d in
        let f = d in
        let g = unit in
        let h = g in
        let i = g in
        let j = &g in
        let k = j in
        let l = j in
        unit
      |}
    );
    ( "can return a reference that lives long enough",
      fun () ->
        Passes.borrow_check
          {| 
        let x = 0 in
        let y = 0 in
        let z = (let b = &y in let c = &x in c) in
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
    ( "can't use a natvec more than once",
      Borrow_check.MovedValue "Use of moved value 'x'",
      fun () ->
        Passes.borrow_check
          {| 
        let x = natvec_make(0, succ 0, succ (succ 0)) in
        let y = x in
        let z = x in
        unit
      |}
    );
    ( "can't use a natvec more than once when used conditionally",
      Borrow_check.MovedValue "Use of moved value 'x'",
      fun () ->
        Passes.borrow_check
          {| 
        let x = natvec_make(0, succ 0, succ (succ 0)) in
        let y = (if true then x else natvec_make(0)) : natvec in
        let z = x in
        unit
      |}
    );
    ( "move into closure",
      Borrow_check.MovedValue "Use of moved value 'x'",
      fun () ->
        Passes.borrow_check
          {| 
        let x = natvec_make(0, succ 0, succ (succ 0)) in
        let y = (\v. x) : unit -> natvec in
        let z = x in
        unit
      |}
    );
    ( "no captured borrows",
      Borrow_check.BorrowError "Cannot borrow captured variable 'x'",
      fun () ->
        Passes.borrow_check
          {| 
        let x = 0 in
        let y = (\v. let z = &x in v) : unit -> unit in
        y
      |}
    );
    ( "can't use a mutable reference more than once",
      Borrow_check.MovedValue "Use of moved value 'y'",
      fun () ->
        Passes.borrow_check
          {| 
        let x = 0 in
        let y = &mut x in
        let z = y in
        let a = y in
        unit
      |}
    );
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
