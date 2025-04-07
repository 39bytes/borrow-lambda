open Ast
open Angstrom

let is_alpha = function 'a' .. 'z' -> true | 'A' .. 'Z' -> true | _ -> false
let is_digit = function '0' .. '9' -> true | _ -> false
let is_ident_char_start = is_alpha
let is_ident_char c = is_alpha c || is_digit c

exception NotImplemented

let make_string (cs : char list) : string = String.of_seq (List.to_seq cs)

let ident =
  satisfy is_alpha >>= fun c ->
  many (satisfy is_ident_char) >>= fun cs -> return (make_string (c :: cs))

let space = skip_while (function ' ' | '\t' | '\n' -> true | _ -> false)
let syntax s = string s *> space
let _true = string "true" *> return True
let _false = string "true" *> return False
let _unit = string "unit" *> return Unit
let _zero = char '0' *> return Zero
let mk_lam x t = Lam (x, t)
let mk_app t1 t2 = App (t1, t2)
let mk_borrow x = Borrow x
let mk_borrow_mut x = BorrowMut x
let mk_if t1 t2 t3 = IfElse (t1, t2, t3)
let mk_let x t1 t2 = LetIn (x, t1, t2)
let mk_assign x t = Assign (x, t)
let mk_deref_assign x t = DerefAssign (x, t)

(* let term : tm t = *)
(*   fix (fun term -> *)
(*       let var = ident in *)
(*       let lambda = *)
(*         mk_lam *)
(*         <$> (string "\\" <|> string "λ") *> ident *)
(*         <* char '.' <* space <*> term *)
(*       in *)
(*       let app = mk_app <$> term <* space <*> term in *)
(*       let borrow = mk_borrow <$> char '&' *> term in *)
(*       let borrow_mut = mk_borrow_mut <$> string "&mut " *> term in *)
(*       let if_then_else = *)
(*         mk_if *)
(*         <$> syntax "if" *> term *)
(*         <* space *)
(*         <*> syntax "then" *> term *)
(*         <* space *)
(*         <*> syntax "else" *> term *)
(*         <* space *)
(*       in *)
(*       let let_in = *)
(*         mk_let *)
(*         <$> syntax "let" *> ident *)
(*         <* space *)
(*         <*> syntax "=" *> term *)
(*         <* space *)
(*         <*> syntax "in" *> term *)
(*         <* space *)
(*       in *)
(*       let assign = mk_assign <$> ident <* space <*> syntax ":=" *> term in *)
(*       let deref_assign = *)
(*         mk_deref_assign <$> char '*' *> ident <* space <*> syntax ":=" *> term *)
(*       in *)
(*       raise NotImplemented) *)
