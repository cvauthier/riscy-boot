type ident = string
type label = string
type reg = int
type imm = 
	| Const of int64
	| Label of string

type unop = | Addi | Ori | Andi | Xori
type binop = | Add | Sub | Or | And | Xor
type branch = | Eq | Ne | Lt | Ge

type instruction =
	| Ilui of imm * reg
	| Ijal of label * reg
	| Ilw of reg * imm * reg
	| Isw of reg * reg * imm
	| IBranch of branch * reg * reg * label
	| IUnop of unop * imm * reg * reg
	| IBinop of binop * reg * reg * reg

type program = (label option * instruction) list

