(*  Title:      Pure/General/markup.ML
    Author:     Makarius

Common markup elements.
*)

signature MARKUP =
sig
  type T = string * Properties.T
  val none: T
  val is_none: T -> bool
  val properties: (string * string) list -> T -> T
  val nameN: string
  val name: string -> T -> T
  val groupN: string
  val theory_nameN: string
  val idN: string
  val kindN: string
  val internalK: string
  val property_internal: Properties.property
  val lineN: string
  val columnN: string
  val offsetN: string
  val end_lineN: string
  val end_columnN: string
  val end_offsetN: string
  val fileN: string
  val position_properties': string list
  val position_properties: string list
  val positionN: string val position: T
  val locationN: string val location: T
  val indentN: string
  val blockN: string val block: int -> T
  val widthN: string
  val breakN: string val break: int -> T
  val fbreakN: string val fbreak: T
  val tclassN: string val tclass: string -> T
  val tyconN: string val tycon: string -> T
  val fixed_declN: string val fixed_decl: string -> T
  val fixedN: string val fixed: string -> T
  val const_declN: string val const_decl: string -> T
  val constN: string val const: string -> T
  val fact_declN: string val fact_decl: string -> T
  val factN: string val fact: string -> T
  val dynamic_factN: string val dynamic_fact: string -> T
  val local_fact_declN: string val local_fact_decl: string -> T
  val local_factN: string val local_fact: string -> T
  val tfreeN: string val tfree: T
  val tvarN: string val tvar: T
  val freeN: string val free: T
  val skolemN: string val skolem: T
  val boundN: string val bound: T
  val varN: string val var: T
  val numeralN: string val numeral: T
  val literalN: string val literal: T
  val inner_stringN: string val inner_string: T
  val inner_commentN: string val inner_comment: T
  val sortN: string val sort: T
  val typN: string val typ: T
  val termN: string val term: T
  val propN: string val prop: T
  val attributeN: string val attribute: string -> T
  val methodN: string val method: string -> T
  val ML_sourceN: string val ML_source: T
  val doc_sourceN: string val doc_source: T
  val antiqN: string val antiq: T
  val ML_antiqN: string val ML_antiq: string -> T
  val doc_antiqN: string val doc_antiq: string -> T
  val keyword_declN: string val keyword_decl: string -> T
  val command_declN: string val command_decl: string -> string -> T
  val keywordN: string val keyword: string -> T
  val commandN: string val command: string -> T
  val identN: string val ident: T
  val stringN: string val string: T
  val altstringN: string val altstring: T
  val verbatimN: string val verbatim: T
  val commentN: string val comment: T
  val controlN: string val control: T
  val malformedN: string val malformed: T
  val tokenN: string val token: T
  val command_spanN: string val command_span: string -> T
  val ignored_spanN: string val ignored_span: T
  val malformed_spanN: string val malformed_span: T
  val stateN: string val state: T
  val subgoalN: string val subgoal: T
  val sendbackN: string val sendback: T
  val hiliteN: string val hilite: T
  val taskN: string
  val unprocessedN: string val unprocessed: T
  val runningN: string val running: string -> T
  val failedN: string val failed: T
  val finishedN: string val finished: T
  val disposedN: string val disposed: T
  val editsN: string val edits: string -> T
  val editN: string val edit: string -> string -> T
  val pidN: string
  val sessionN: string
  val promptN: string val prompt: T
  val no_output: output * output
  val default_output: T -> output * output
  val add_mode: string -> (T -> output * output) -> unit
  val output: T -> output * output
  val enclose: T -> output -> output
  val markup: T -> string -> string
end;

structure Markup: MARKUP =
struct

(* basic markup *)

type T = string * Properties.T;

val none = ("", []);

fun is_none ("", _) = true
  | is_none _ = false;


fun properties more_props ((elem, props): T) =
  (elem, fold_rev Properties.put more_props props);

fun markup_elem elem = (elem, (elem, []): T);
fun markup_string elem prop = (elem, fn s => (elem, [(prop, s)]): T);
fun markup_int elem prop = (elem, fn i => (elem, [(prop, Int.toString i)]): T);


(* name *)

val nameN = "name";
fun name a = properties [(nameN, a)];

val groupN = "group";
val theory_nameN = "theory_name";


(* kind *)

val kindN = "kind";

val internalK = "internal";
val property_internal = (kindN, internalK);


(* position *)

val lineN = "line";
val columnN = "column";
val offsetN = "offset";
val end_lineN = "end_line";
val end_columnN = "end_column";
val end_offsetN = "end_offset";
val fileN = "file";
val idN = "id";

val position_properties' = [end_lineN, end_columnN, end_offsetN, fileN, idN];
val position_properties = [lineN, columnN, offsetN] @ position_properties';

val (positionN, position) = markup_elem "position";
val (locationN, location) = markup_elem "location";


(* pretty printing *)

val indentN = "indent";
val (blockN, block) = markup_int "block" indentN;

val widthN = "width";
val (breakN, break) = markup_int "break" widthN;

val (fbreakN, fbreak) = markup_elem "fbreak";


(* logical entities *)

val (tclassN, tclass) = markup_string "tclass" nameN;
val (tyconN, tycon) = markup_string "tycon" nameN;
val (fixed_declN, fixed_decl) = markup_string "fixed_decl" nameN;
val (fixedN, fixed) = markup_string "fixed" nameN;
val (const_declN, const_decl) = markup_string "const_decl" nameN;
val (constN, const) = markup_string "const" nameN;
val (fact_declN, fact_decl) = markup_string "fact_decl" nameN;
val (factN, fact) = markup_string "fact" nameN;
val (dynamic_factN, dynamic_fact) = markup_string "dynamic_fact" nameN;
val (local_fact_declN, local_fact_decl) = markup_string "local_fact_decl" nameN;
val (local_factN, local_fact) = markup_string "local_fact" nameN;


(* inner syntax *)

val (tfreeN, tfree) = markup_elem "tfree";
val (tvarN, tvar) = markup_elem "tvar";
val (freeN, free) = markup_elem "free";
val (skolemN, skolem) = markup_elem "skolem";
val (boundN, bound) = markup_elem "bound";
val (varN, var) = markup_elem "var";
val (numeralN, numeral) = markup_elem "numeral";
val (literalN, literal) = markup_elem "literal";
val (inner_stringN, inner_string) = markup_elem "inner_string";
val (inner_commentN, inner_comment) = markup_elem "inner_comment";

val (sortN, sort) = markup_elem "sort";
val (typN, typ) = markup_elem "typ";
val (termN, term) = markup_elem "term";
val (propN, prop) = markup_elem "prop";

val (attributeN, attribute) = markup_string "attribute" nameN;
val (methodN, method) = markup_string "method" nameN;


(* embedded source text *)

val (ML_sourceN, ML_source) = markup_elem "ML_source";
val (doc_sourceN, doc_source) = markup_elem "doc_source";

val (antiqN, antiq) = markup_elem "antiq";
val (ML_antiqN, ML_antiq) = markup_string "ML_antiq" nameN;
val (doc_antiqN, doc_antiq) = markup_string "doc_antiq" nameN;


(* outer syntax *)

val (keyword_declN, keyword_decl) = markup_string "keyword_decl" nameN;

val command_declN = "command_decl";
fun command_decl name kind : T = (command_declN, [(nameN, name), (kindN, kind)]);

val (keywordN, keyword) = markup_string "keyword" nameN;
val (commandN, command) = markup_string "command" nameN;
val (identN, ident) = markup_elem "ident";
val (stringN, string) = markup_elem "string";
val (altstringN, altstring) = markup_elem "altstring";
val (verbatimN, verbatim) = markup_elem "verbatim";
val (commentN, comment) = markup_elem "comment";
val (controlN, control) = markup_elem "control";
val (malformedN, malformed) = markup_elem "malformed";

val (tokenN, token) = markup_elem "token";

val (command_spanN, command_span) = markup_string "command_span" nameN;
val (ignored_spanN, ignored_span) = markup_elem "ignored_span";
val (malformed_spanN, malformed_span) = markup_elem "malformed_span";


(* toplevel *)

val (stateN, state) = markup_elem "state";
val (subgoalN, subgoal) = markup_elem "subgoal";
val (sendbackN, sendback) = markup_elem "sendback";
val (hiliteN, hilite) = markup_elem "hilite";


(* command status *)

val taskN = "task";

val (unprocessedN, unprocessed) = markup_elem "unprocessed";
val (runningN, running) = markup_string "running" taskN;
val (failedN, failed) = markup_elem "failed";
val (finishedN, finished) = markup_elem "finished";
val (disposedN, disposed) = markup_elem "disposed";


(* interactive documents *)

val (editsN, edits) = markup_string "edits" idN;

val editN = "edit";
fun edit id state_id : T = (editN, [(idN, id), (stateN, state_id)]);


(* messages *)

val pidN = "pid";
val sessionN = "session";

val (promptN, prompt) = markup_elem "prompt";



(* print mode operations *)

val no_output = ("", "");
fun default_output (_: T) = no_output;

local
  val default = {output = default_output};
  val modes = ref (Symtab.make [("", default)]);
in
  fun add_mode name output = CRITICAL (fn () =>
    change modes (Symtab.update_new (name, {output = output})));
  fun get_mode () =
    the_default default (Library.get_first (Symtab.lookup (! modes)) (print_mode_value ()));
end;

fun output m = if is_none m then no_output else #output (get_mode ()) m;

val enclose = output #-> Library.enclose;

fun markup m =
  let val (bg, en) = output m
  in Library.enclose (Output.escape bg) (Output.escape en) end;

end;
