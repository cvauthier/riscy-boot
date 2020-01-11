%{
  open Ast
%}

%token <int> CONST
%token <int> REG
%token <string> IDENT
%token COMMA DPOINT
%token EOF

%start program
%type <Ast.program> program

%%
program:
  | ilist = labeled_ins* EOF { ilist }

labeled_ins:
  | l = IDENT DPOINT ins = instruction { (Some l,ins) }
  | ins = instruction { (None,ins) }

instruction:
  | opcode = IDENT rs1 = REG COMMA rs2 = REG COMMA rd = REG 
    {
      let op = match opcode with 
        | "add" -> Add | "sub" -> Sub
        | "or" -> Or   | "and" -> And
        | "xor" -> Xor | _ -> assert false in
      IBinop(op,rs1,rs2,rd) 
    }
  | opcode = IDENT n = CONST COMMA r1 = REG COMMA r2 = REG
    {
      match opcode with
        | "lw" -> Ilw(r1,n,r2)
        | "sw" -> Isw(r1,r2,n)
        | "jalr" -> Ijalr(n,r1,r2)
        | _ -> begin
              let op = match opcode with
                | "addi" -> Addi | "xori" -> Xori | "andi" -> Andi | "ori" -> Ori
                | _ -> assert false in
               IUnop(op,n,r1,r2)
           end
    }
  | opcode = IDENT r1 = REG COMMA r2 = REG COMMA lbl = IDENT
    {
      let branch = match opcode with
        | "beq" -> Eq | "bne" -> Ne | "blt" -> Lt | "bge" -> Ge
        | _ -> assert false in IBranch(branch,r1,r2,lbl)
    }
  | opcode = IDENT n = CONST COMMA rd = REG { assert (opcode = "lui"); Ilui(n,rd) }
  | opcode = IDENT lbl = IDENT COMMA rd = REG { assert (opcode = "jal"); Ijal(lbl,rd) }

