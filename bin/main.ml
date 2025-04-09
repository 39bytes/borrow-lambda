open Borrow_lambda

let prompt = "λ> "

let parse input =
  Parser.parse_term input |> Result.map_error (fun err -> "Parse error: " ^ err)

let rename ast =
  try Ok (Rename.rename ast)
  with Rename.FreeVariable -> Error "Error: Free variable"

let typecheck ast =
  try Ok (Typecheck.syn [] ast) with
  | Typecheck.TypeError msg -> Error ("Type error: " ^ msg)
  | Typecheck.TypeAnnotationRequired msg -> Error ("Type error: " ^ msg)

let borrow_check ast =
  try Ok (Borrow_check.borrow_check ast) with
  | Borrow_check.BorrowError msg -> Error ("Borrow error: " ^ msg)
  | Borrow_check.BorrowedValue msg -> Error ("Borrow error: " ^ msg)
  | Borrow_check.MovedValue msg -> Error ("Move error: " ^ msg)

let eval ast =
  try Ok (Eval.eval ast)
  with Eval.RuntimeError msg -> Error ("Runtime error: " ^ msg)

let run (input : string) : (Eval.value, string) result =
  let ( let* ) = Result.bind in
  let* ast = parse input in
  let* renamed = rename ast in
  let* typed = typecheck renamed in
  let* _ = borrow_check typed in
  let* v = eval typed in
  Ok v

let rec repl () =
  let () = print_string prompt in
  let s = read_line () in
  let () =
    match run s with
    | Ok v -> print_endline (Eval.string_of_value v)
    | Error msg -> print_endline msg
  in
  repl ()

let () = repl ()
