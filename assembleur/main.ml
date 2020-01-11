open Lexing
open Format

let usage = "usage: riscasm file.s"

let spec = []

let file =
  let file = ref None in
  let set_file s =
    if not (Filename.check_suffix s ".risc") then
      raise (Arg.Bad "no .go extension");
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

    let prog_out = open_out_bin ((String.sub file 0 ((String.length file)-5))^".bin") in 
    Compiler.compile_program prog prog_out;
		close_out prog_out
  with
	  | Lexer.Lexing_error s ->
	    report (lexeme_start_p lb, lexeme_end_p lb);
	    eprintf "lexical error: %s@." s;
	    exit 1
	  | Assert_failure(s,l,c) ->
	    report (lexeme_start_p lb, lexeme_end_p lb);
	    eprintf "assertion failed %s:%d:%d" s l c;
	    exit 2


