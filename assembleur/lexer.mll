{
	open Lexing
  open Parser
	open Ast
}

let chiffre = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z' '_']
let ident = alpha (alpha | chiffre)*
let hexa = ['0'-'9' 'a'-'f' 'A'-'F']
let entier = ("-"? chiffre+) | ("0x" | "0X") hexa+

rule token = parse
  | '\n' 			        { new_line lexbuf; LF }    
  | [' ' '\t'] 				{ token lexbuf }     (* skip blanks *)
  | entier as s 			{ CONST (Int64.to_int (Int64.of_string (String.lowercase_ascii s))) } 
  | ident as s 				{ IDENT s }
  | "%r" ((chiffre+) as s) { let n = Int64.to_int (Int64.of_string (String.lowercase_ascii s)) in
														 if n < 1 || n > 31 then 
														   raise (Syntax_error (Format.sprintf "no register r%d" n));
														 REG n }											
  | "," { COMMA }
  | ":" { DPOINT }
	| ";" { comment lexbuf }
  | eof { EOF }
  | _ as c { raise (Syntax_error ("unexpected character "^(String.make 1 c))) }

and comment = parse
	| '\n' { new_line lexbuf; LF }
	| eof  { EOF }
	| _    { comment lexbuf }

