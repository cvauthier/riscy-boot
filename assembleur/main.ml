open Lexing
open Format

let usage = "usage: riscasm file.s"

let spec = []

let file =
  let file = ref None in
  let set_file s =
    if not (Filename.check_suffix s ".s") then
      raise (Arg.Bad "no .s extension");
    file := Some s
  in
  Arg.parse spec set_file usage;
  match !file with Some f -> f | None -> Arg.usage spec usage; exit 1

let report (b,e) =
  let l = b.pos_lnum in
  let fc = b.pos_cnum - b.pos_bol + 1 in
  let lc = e.pos_cnum - b.pos_bol + 1 in
  eprintf "File \"%s\", line %d, characters %d-%d:\n" file l fc lc

let () =
  let c = open_in file in
  let lb = Lexing.from_channel c in
  try
    let prog = Parser.program Lexer.token lb in
    close_in c;

    let prog_out = open_out ((String.sub file 0 ((String.length file)-2))^".bin") in 
    Compiler.compile_program prog prog_out;
		close_out prog_out
  with
	  | Ast.Syntax_error s ->
	    report (lexeme_start_p lb, lexeme_end_p lb);
	    eprintf "syntax error: %s@." s;
	    exit 1


