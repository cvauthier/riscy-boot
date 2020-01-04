{
	open Lexing
	open Netlist_parser
	exception Eof
}

let chiffre = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z' '_']
let ident = alpha (alpha | chiffre)*
let hexa = ['0'-'9' 'a'-'f' 'A'-'F']
let entier = chiffre+ | ("0x" | "0X") hexa+

rule token = parse
  | '\n' 			        { new_line lexbuf; token lexbuf }     (* skip blanks *)
  | [' ' '\t'] 				{ token lexbuf }     (* skip blanks *)
  | entier as s 			{ CONST (Int64.of_string (String.lowercase s)) } 
  | ident as s 				{ IDENT s }
  | "%r" (entier as s) { REG (Int64.to_int (Int64.of_string (String.lowercase s))) }											
  | "," { COMMA }
  | ":" { DPOINT }
	| ";" { comment lexbuf }
  | eof { EOF }
  | _ as c { raise (Lexing_error (String.make 1 c)) }

and comment = parse
	| '\n' { new_line lexbuf; token lexbuf }
	| eof  { EOF }
	| _    { comment lexbuf }

