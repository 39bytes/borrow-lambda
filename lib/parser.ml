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
    "nat_vec_make";
    "nat_vec_get";
    "nat_vec_get_mut";
    "nat_vec_push";
    "nat_vec_pop";
  ]

let space =
  skip_while (function ' ' | '\t' | '\n' | '\r' -> true | _ -> false)

let ident_like =
  satisfy is_alpha >>= fun c ->
  many (satisfy is_ident_char) >>= fun cs ->
  return (make_string (c :: cs)) <* space

let ident =
  ident_like >>= fun i ->
  if List.mem i keywords then fail "failed to parse identifier" else return i

let keyword s =
  ident_like >>= fun i ->
  if i = s then return () else fail "did not match keyword"

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
        mk_ref
        <$> syntax "&" *> lifetime
        <*> option Shr (keyword "mut" *> return Mut)
        <*> type_
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
let mk_nat_vec_make ts = NNatVecMake ts
let mk_nat_vec_get t1 t2 = NNatVecGet (t1, t2)
let mk_nat_vec_get_mut t1 t2 = NNatVecGetMut (t1, t2)
let mk_nat_vec_push t1 t2 = NNatVecPush (t1, t2)
let mk_nat_vec_pop t1 = NNatVecPop t1

let term : named_tm t =
  fix (fun term ->
      let var = mk_var <$> ident in
      let lambda =
        mk_lam
        <$> (syntax "\\" <|> syntax "λ") *> ident
        <* char '.' <* space <*> term
      in
      let borrow = mk_borrow <$> syntax "&" *> term in
      let borrow_mut = mk_borrow_mut <$> syntax "&mut " *> term in
      let deref = mk_deref <$> syntax "*" *> term in
      let if_then_else =
        mk_if
        <$> keyword "if" *> term
        <*> keyword "then" *> term
        <*> keyword "else" *> term
      in
      let let_in =
        mk_let
        <$> keyword "let" *> ident
        <*> syntax "=" *> term
        <*> keyword "in" *> term
      in
      let assign = mk_assign <$> ident <*> syntax ":=" *> term in
      let deref_assign =
        mk_deref_assign <$> char '*' *> ident <*> syntax ":=" *> term
      in
      let _zero = char '0' *> space *> return NZero in
      let succ = mk_succ <$> keyword "succ" *> term in
      let pred = mk_pred <$> keyword "pred" *> term in
      let _true = keyword "true" *> return NTrue in
      let _false = keyword "false" *> return NFalse in
      let is_zero = mk_is_zero <$> keyword "iszero" *> term in
      let _unit = keyword "unit" *> return NUnit in
      let nat_vec_make =
        mk_nat_vec_make
        <$> keyword "nat_vec_make" *> parens (sep_by (syntax ",") term)
      in
      let nat_vec_get =
        keyword "nat_vec_get"
        *> parens (mk_nat_vec_get <$> term <* syntax "," <*> term)
      in
      let nat_vec_get_mut =
        keyword "nat_vec_get_mut"
        *> parens (mk_nat_vec_get_mut <$> term <* syntax "," <*> term)
      in
      let nat_vec_push =
        keyword "nat_vec_push"
        *> parens (mk_nat_vec_push <$> term <* syntax "," <*> term)
      in
      let nat_vec_pop =
        mk_nat_vec_pop <$> keyword "nat_vec_pop" *> parens term
      in

      let exp0 =
        var <|> lambda <|> borrow <|> borrow_mut <|> deref <|> if_then_else
        <|> let_in <|> assign <|> deref_assign <|> _zero <|> succ <|> pred
        <|> _true <|> _false <|> is_zero <|> _unit <|> nat_vec_make
        <|> nat_vec_get <|> nat_vec_get_mut <|> nat_vec_push <|> nat_vec_pop
        <|> parens term
      in

      let app = mk_app <$> exp0 <* space <*> exp0 in
      let exp = app <|> exp0 in
      exp)

let parse_term input =
  match parse_string ~consume:All term input with
  | Ok res -> res
  | Error err -> failwith "Parse error"
