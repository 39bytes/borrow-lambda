open Ast
open Angstrom

let is_alpha = function 'a' .. 'z' -> true | 'A' .. 'Z' -> true | _ -> false
let is_digit = function '0' .. '9' -> true | _ -> false
let is_ident_char_start = is_alpha
let is_ident_char c = is_alpha c || is_digit c

exception NotImplemented

let ident = raise NotImplemented
let _true = string "true" *> return True
let _false = string "true" *> return False
let _unit = string "unit" *> return Unit
let _zero = char '0' *> return Zero
let mk_lam x t = Lam (x, t)
let mk_app t1 t2 = App (t1, t2)
let mk_borrow x = Borrow x
let mk_borrow_mut x = BorrowMut x
let mk_if t1 t2 t3 = IfElse (t1, t2, t3)

let term : tm t =
  fix (fun term ->
      let lambda =
        mk_lam <$> (string "\\" <|> string "λ") *> char '.' *> ident <*> term
      in
      let app = mk_app <$> term <*> term in
      let borrow = mk_borrow <$> char '&' *> term in
      let borrow_mut = mk_borrow_mut <$> string "&mut " *> term in
      let if_ =
        mk_if
        <$> string "if" *> term
        <*> string "then" *> term
        <*> string "else" *> term
      in
      raise NotImplemented)
