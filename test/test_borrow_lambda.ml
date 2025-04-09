let () =
  Alcotest.run "borrow_lambda"
    [
      ("Typecheck", Test_typecheck.suite);
      ("Borrow check", Test_borrow_check.suite);
    ]
