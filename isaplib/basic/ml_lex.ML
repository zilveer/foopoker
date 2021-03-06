(*  Title:      Pure/ML/ml_lex.ML
    Author:     Makarius

Lexical syntax for SML.
*)

signature ML_LEX =
sig
  datatype token_kind =
    Keyword | Ident | LongIdent | TypeVar | Word | Int | Real | Char | String |
    Space | Comment | Error of string | EOF
  eqtype token
  val stopper: token Scan.stopper
  val is_regular: token -> bool
  val is_improper: token -> bool
  val pos_of: token -> string
  val kind_of: token -> token_kind
  val content_of: token -> string
  val keywords: string list
  val source: (Symbol.symbol, 'a) Source.source ->
    (token, (SymbolPos.T, Position.T * (Symbol.symbol, 'a) Source.source)
      Source.source) Source.source
end;

structure ML_Lex: ML_LEX =
struct

(** tokens **)

(* datatype token *)

datatype token_kind =
  Keyword | Ident | LongIdent | TypeVar | Word | Int | Real | Char | String |
  Space | Comment | Error of string | EOF;

datatype token = Token of Position.range * (token_kind * string);


(* position *)

fun position_of (Token ((pos, _), _)) = pos;
fun end_position_of (Token ((_, pos), _)) = pos;

val pos_of = Position.str_of o position_of;


(* control tokens *)

fun mk_eof pos = Token ((pos, Position.none), (EOF, ""));
val eof = mk_eof Position.none;

fun is_eof (Token (_, (EOF, _))) = true
  | is_eof _ = false;

val stopper =
  Scan.stopper (fn [] => eof | toks => mk_eof (end_position_of (List.last toks))) is_eof;


(* token content *)

fun content_of (Token (_, (_, x))) = x;
fun token_leq (tok, tok') = content_of tok <= content_of tok';

fun kind_of (Token (_, (k, _))) = k;

fun is_regular (Token (_, (Error _, _))) = false
  | is_regular (Token (_, (EOF, _))) = false
  | is_regular _ = true;

fun is_improper (Token (_, (Space, _))) = true
  | is_improper (Token (_, (Comment, _))) = true
  | is_improper _ = false;



(** scanners **)

open BasicSymbolPos;

fun !!! msg = SymbolPos.!!! ("SML lexical error: " ^ msg);


(* blanks *)

val scan_blank = Scan.one (Symbol.is_ascii_blank o symbol);
val scan_blanks1 = Scan.repeat1 scan_blank;


(* keywords *)

val keywords = ["#", "(", ")", ",", "->", "...", ":", ":>", ";", "=",
  "=>", "[", "]", "_", "{", "|", "}", "abstype", "and", "andalso", "as",
  "case", "datatype", "do", "else", "end", "eqtype", "exception", "fn",
  "fun", "functor", "handle", "if", "in", "include", "infix", "infixr",
  "let", "local", "nonfix", "of", "op", "open", "orelse", "raise", "rec",
  "sharing", "sig", "signature", "struct", "structure", "then", "type",
  "val", "where", "while", "with", "withtype"];

val lex = Scan.make_lexicon (map explode keywords);
fun scan_keyword x = Scan.literal lex x;


(* identifiers *)

local

val scan_letdigs =
  Scan.many ((Symbol.is_ascii_letter orf Symbol.is_ascii_digit orf Symbol.is_ascii_quasi) o symbol);

val scan_alphanumeric = Scan.one (Symbol.is_ascii_letter o symbol) -- scan_letdigs >> op ::;

val scan_symbolic = Scan.many1 (member (op =) (explode "!#$%&*+-/:<=>?@\\^`|~") o symbol);

in

val scan_ident = scan_alphanumeric || scan_symbolic;

val scan_longident =
  (Scan.repeat1 (scan_alphanumeric @@@ $$$ ".") >> flat) @@@ (scan_ident || $$$ "=");

val scan_typevar = $$$ "'" @@@ scan_letdigs;

end;


(* numerals *)

local

val scan_dec = Scan.many1 (Symbol.is_ascii_digit o symbol);
val scan_hex = Scan.many1 (Symbol.is_ascii_hex o symbol);
val scan_sign = Scan.optional ($$$ "~") [];
val scan_decint = scan_sign @@@ scan_dec;

in

val scan_word =
  $$$ "0" @@@ $$$ "w" @@@ $$$ "x" @@@ scan_hex ||
  $$$ "0" @@@ $$$ "w" @@@ scan_dec;

val scan_int = scan_sign @@@ ($$$ "0" @@@ $$$ "x" @@@ scan_hex || scan_dec);

val scan_exp = ($$$ "E" || $$$ "e") @@@ scan_decint;

val scan_real =
  scan_decint @@@ $$$ "." @@@ scan_dec @@@ Scan.optional scan_exp [] ||
  scan_decint @@@ scan_exp;

end;


(* chars and strings *)

local

val scan_escape =
  Scan.one (member (op =) (explode "\"\\abtnvfr") o symbol) >> single ||
  $$$ "^" @@@ (Scan.one (fn (s, _) => ord "@" <= ord s andalso ord s <= ord "_") >> single) ||
  Scan.one (Symbol.is_ascii_digit o symbol) --
    Scan.one (Symbol.is_ascii_digit o symbol) --
    Scan.one (Symbol.is_ascii_digit o symbol) >> (fn ((a, b), c) => [a, b, c]);

val scan_str =
  Scan.one (fn (s, _) => Symbol.is_printable s andalso s <> "\"" andalso s <> "\\") >> single ||
  $$$ "\\" @@@ !!! "bad escape character in string" scan_escape;

val scan_gap = $$$ "\\" @@@ scan_blanks1 @@@ $$$ "\\";
val scan_gaps = Scan.repeat scan_gap >> flat;

in

val scan_char =
  $$$ "#" @@@ $$$ "\"" @@@ scan_gaps @@@ scan_str @@@ scan_gaps @@@ $$$ "\"";

val scan_string =
  $$$ "\"" @@@ !!! "missing quote at end of string"
    ((Scan.repeat (scan_gap || scan_str) >> flat) @@@ $$$ "\"");

end;


(* token source *)

local

fun token k ss = Token (SymbolPos.range ss, (k, SymbolPos.implode ss));

val scan = !!! "bad input"
 (scan_char >> token Char ||
  scan_string >> token String ||
  scan_blanks1 >> token Space ||
  SymbolPos.scan_comment !!! >> token Comment ||
  Scan.max token_leq
   (scan_keyword >> token Keyword)
   (scan_word >> token Word ||
    scan_real >> token Real ||
    scan_int >> token Int ||
    scan_longident >> token LongIdent ||
    scan_ident >> token Ident ||
    scan_typevar >> token TypeVar));

fun recover msg =
  Scan.many (((not o Symbol.is_blank) andf Symbol.is_regular) o symbol)
  >> (fn cs => [token (Error msg) cs]);

in

fun source src =
  SymbolPos.source (Position.line 1) src
  |> Source.source SymbolPos.stopper (Scan.bulk scan) (SOME (false, recover));

end;

end;

