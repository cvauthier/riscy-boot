%{
  open Ast
	open Format

	let err msg = raise (Syntax_error msg)

	let test cond msg = if not cond then err msg
%}

%token <int> CONST
%token <int> REG
%token <string> IDENT
%token COMMA DPOINT LF
%token EOF

%start program
%type <Ast.program> program

%%
program:
  | LF* ilist = labeled_ins* EOF { ilist }

labeled_ins:
  | l = IDENT DPOINT LF* ins = instruction { (Some l,ins) }
  | ins = instruction { (None,ins) }

instruction:
	| i = inner_instruction LF+ { i }

inner_instruction:
  | opcode = IDENT rs1 = REG COMMA rs2 = REG COMMA rd = REG 
    {
      let op = match opcode with 
        | "add" -> Add | "sub" -> Sub
        | "or" -> Or   | "and" -> And
        | "xor" -> Xor | _ -> err (sprintf "%s is not a binary arithmetical operation" opcode) in
      IBinop(op,rs1,rs2,rd) 
    }
	| opcode = IDENT r2 = REG COMMA n = CONST COMMA r1 = REG
		{ test (opcode = "sw") "expected sw"; Isw(r2,r1,n) }
  | opcode = IDENT n = CONST COMMA r1 = REG COMMA r2 = REG
    {
      match opcode with
        | "lw" -> Ilw(r1,n,r2)
        | "jalr" -> Ijalr(n,r1,r2)
        | _ -> begin
              let op = match opcode with
                | "addi" -> Addi | "xori" -> Xori | "andi" -> Andi | "ori" -> Ori
                | _ -> err (sprintf "%s is not an unary arithmetical operation" opcode) in
               IUnop(op,n,r1,r2)
           end
    }
  | opcode = IDENT r1 = REG COMMA r2 = REG COMMA lbl = IDENT
    {
      let branch = match opcode with
        | "beq" -> Eq | "bne" -> Ne | "blt" -> Lt | "bge" -> Ge
        | _ -> err (sprintf "%s is not a conditional branching instruction" opcode) in IBranch(branch,r1,r2,lbl)
    }
  | opcode = IDENT n = CONST COMMA rd = REG { test (opcode = "lui") "expected lui"; Ilui(n,rd) }
  | opcode = IDENT lbl = IDENT COMMA rd = REG { test (opcode = "jal") "expected jal"; Ijal(lbl,rd) }
	| opcode = IDENT { test (opcode == "nop") "expected nop"; Inop } 

