exception Syntax_error of string

type ident = string
type label = string
type reg = int
type imm = int

type unop = | Addi | Ori | Andi | Xori
type binop = | Add | Sub | Or | And | Xor
type branch = | Eq | Ne | Lt | Ge

type instruction =
	| Inop
	| Ilui of imm * reg
	| Ijal of label * reg
  | Ijalr of imm * reg * reg
  | Ilw of reg * imm * reg
	| Isw of reg * reg * imm
	| IBranch of branch * reg * reg * label
	| IUnop of unop * imm * reg * reg
	| IBinop of binop * reg * reg * reg

type program = (label option * instruction) list

