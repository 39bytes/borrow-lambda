module Passes = struct
  let parse input =
    match Parser.parse_term input with Ok ast -> ast | Error e -> failwith e

  let rename input = parse input |> Rename.rename
  let typecheck input = rename input |> Typecheck.typecheck
  let borrow_check input = typecheck input |> Borrow_check.borrow_check
end
