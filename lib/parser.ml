open Ast
open Angstrom

let is_alpha = function 'a' .. 'z' -> true | 'A' .. 'Z' -> true | _ -> false
let is_digit = function '0' .. '9' -> true | _ -> false
let is_ident_char_start c = is_alpha c || c = '_'
let is_ident_char c = is_digit c || is_ident_char_start c

exception NotImplemented

let make_string (cs : char list) : string = String.of_seq (List.to_seq cs)

let keywords =
  [
    (* types *)
    "nat";
    "bool";
    "unit";
    "natvec";
    "mut";
    (* terms *)
    "if";
    "then";
    "else";
    "let";
    "in";
    "succ";
    "pred";
    "true";
    "false";
    "iszero";
    "unit";
    "natvec_make";
    "natvec_get";
    "natvec_get_mut";
    "natvec_push";
    "natvec_pop";
  ]

let space =
  skip_while (function ' ' | '\t' | '\n' | '\r' -> true | _ -> false)

let ident_like =
  satisfy is_alpha >>= fun c ->
  many (satisfy is_ident_char) >>= fun cs ->
  return (make_string (c :: cs)) <* space

let ident =
  ident_like
  >>= (fun i ->
  if List.mem i keywords then fail "Expected identifier but got keyword"
  else return i)
  <?> "identifier"

let keyword s =
  ident_like >>= fun i ->
  if i = s then return ()
  else
    fail (Printf.sprintf "Expected keyword '%s' but got '%s'" s i)
    <?> "keyword '" ^ s ^ "'"

let syntax s = string s *> space
let parens p = syntax "(" *> p <* syntax ")"

(* Can only parse lifetime variables *)
let mk_lifetime_var name = LifetimeVar name
let lifetime : lifetime t = mk_lifetime_var <$> syntax "'" *> ident
let mk_arrow t1 t2 = Arrow (t1, t2)
let mk_ref lft ref_mod tp = Ref (lft, tp, ref_mod)

let type_ : tp t =
  fix (fun type_ ->
      let nat = keyword "nat" *> return Nat in
      let bool = keyword "bool" *> return Bool in
      let unit = keyword "unit" *> return Unit in
      let natvec = keyword "natvec" *> return NatVec in
      let ref =
        fix (fun ref ->
            mk_ref
            <$> syntax "&" *> lifetime
            <*> option Shr (keyword "mut" *> return Mut)
            <*> (nat <|> bool <|> unit <|> natvec <|> ref <|> parens type_))
      in
      let base_type =
        nat <|> bool <|> unit <|> natvec <|> ref <|> parens type_
      in
      let arrow = mk_arrow <$> base_type <* syntax "->" <*> base_type in
      arrow <|> base_type <?> "Invalid type")

let mk_var x = NVar x
let mk_lam x t = NLam (x, t)
let mk_app t1 t2 = NApp (t1, t2)
let mk_borrow x = NBorrow x
let mk_borrow_mut x = NBorrowMut x
let mk_deref t = NDeref t
let mk_if t1 t2 t3 = NIfElse (t1, t2, t3)
let mk_let x t1 t2 = NLetIn (x, t1, t2)
let mk_assign x t = NAssign (x, t)
let mk_deref_assign x t = NDerefAssign (x, t)
let mk_succ t = NSucc t
let mk_pred t = NPred t
let mk_is_zero t = NIsZero t
let mk_natvec_make ts = NNatVecMake ts
let mk_natvec_get t1 t2 = NNatVecGet (t1, t2)
let mk_natvec_get_mut t1 t2 = NNatVecGetMut (t1, t2)
let mk_natvec_push t1 t2 = NNatVecPush (t1, t2)
let mk_natvec_pop t1 = NNatVecPop t1
let mk_annotated t1 tp = NAnnotated (t1, tp)

let term : named_tm t =
  fix (fun term ->
      let var = mk_var <$> ident <?> "variable" in
      let _zero = char '0' *> space *> return NZero <?> "zero" in
      let _true = keyword "true" *> return NTrue <?> "true" in
      let _false = keyword "false" *> return NFalse <?> "false" in
      let _unit = keyword "unit" *> return NUnit <?> "unit" in
      let natvec_make =
        mk_natvec_make
        <$> keyword "natvec_make" *> parens (sep_by (syntax ",") term)
        <?> "natvec_make"
      in
      let natvec_get =
        keyword "natvec_get"
        *> parens (mk_natvec_get <$> term <* syntax "," <*> term)
        <?> "natvec_get"
      in
      let natvec_get_mut =
        keyword "natvec_get_mut"
        *> parens (mk_natvec_get_mut <$> term <* syntax "," <*> term)
        <?> "natvec_get_mut"
      in
      let natvec_push =
        keyword "natvec_push"
        *> parens (mk_natvec_push <$> term <* syntax "," <*> term)
        <?> "natvec_push"
      in
      let natvec_pop =
        mk_natvec_pop <$> keyword "natvec_pop" *> parens term <?> "natvec_pop"
      in

      let exp6 =
        var <|> _zero <|> _true <|> _false <|> _unit <|> natvec_make
        <|> natvec_get <|> natvec_get_mut <|> natvec_push <|> natvec_pop
        <|> parens term
      in

      let borrow = mk_borrow <$> syntax "&" *> exp6 <?> "immutable borrow" in
      let borrow_mut =
        mk_borrow_mut <$> syntax "&mut " *> exp6 <?> "mutable borrow"
      in
      let deref = mk_deref <$> syntax "*" *> exp6 <?> "dereference" in

      let exp5 = borrow <|> borrow_mut <|> deref <|> exp6 in

      let app = mk_app <$> exp5 <* space <*> exp5 in

      let exp4 = app <|> exp5 in

      let succ = mk_succ <$> keyword "succ" *> exp4 <?> "succ" in
      let pred = mk_pred <$> keyword "pred" *> exp4 <?> "pred" in
      let is_zero = mk_is_zero <$> keyword "iszero" *> exp4 <?> "iszero" in

      let exp3 = succ <|> pred <|> is_zero <|> exp4 in

      let exp2 = borrow <|> borrow_mut <|> deref <|> exp3 in

      let assign =
        mk_assign <$> ident <*> syntax ":=" *> exp2 <?> "assignment"
      in
      let deref_assign =
        mk_deref_assign
        <$> char '*' *> ident
        <*> syntax ":=" *> exp2
        <?> "deref assignment"
      in

      let annotated = mk_annotated <$> exp2 <* syntax ":" <*> type_ in

      let exp1 = annotated <|> exp2 in

      let exp0 = assign <|> deref_assign <|> exp1 in

      let exp =
        fix (fun exp ->
            let lambda =
              mk_lam
              <$> (syntax "\\" <|> syntax "λ") *> ident
              <* char '.' <* space <*> exp <?> "lambda abstraction"
            in
            let if_then_else =
              mk_if
              <$> keyword "if" *> exp
              <*> keyword "then" *> exp
              <*> keyword "else" *> exp
              <?> "if-then-else"
            in
            let let_in =
              mk_let
              <$> keyword "let" *> ident
              <*> syntax "=" *> exp
              <*> keyword "in" *> exp
              <?> "let-in"
            in
            if_then_else <|> let_in <|> lambda <|> exp0)
      in
      let exp = annotated <|> exp in
      exp <?> "term")

let parse p input = parse_string ~consume:All p (String.trim input)
let parse_term = parse term
