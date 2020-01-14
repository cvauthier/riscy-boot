open Ast 

let ins_size = 4

let rs1_ofs = 15
let rs2_ofs = 20
let rd_ofs = 7
let f7_ofs = 25
let f3_ofs = 12

let opc_lui   = 0b0110111
let opc_jal   = 0b1101111
let opc_jalr  = 0b1100111
let opc_load  = 0b0000011
let opc_store = 0b0100011
let opc_brnch = 0b1100011
let opc_opimm = 0b0010011
let opc_op    = 0b0110011

let extract i1 i2 n = (n lsr i1) land ((1 lsl (i2-i1+1)) - 1)

let compile_ins labels curr = function
  | Inop -> opc_opimm
	| Ilui(n,rd) -> (n lsl 12) lor (rd lsl rd_ofs) lor opc_lui

	| Ijal(lbl,rd) -> let n = (Hashtbl.find labels lbl) - curr in
    ((extract 20 20 n) lsl 31) lor ((extract 1 10 n) lsl 21) lor ((extract 11 11 n) lsl 20) lor ((extract 12 19 n) lsl 12) lor
      (rd lsl rd_ofs) lor opc_jal
	
  | Ijalr(n,rs1,rd) -> ((extract 0 11 n) lsl 20) lor (rs1 lsl rs1_ofs) lor (rd lsl rd_ofs) lor opc_jalr
  
  | Ilw(rs1,n,rd) -> ((extract 0 11 n) lsl 20) lor (rs1 lsl rs1_ofs) lor (0b010 lsl f3_ofs) lor 
												(rd lsl rd_ofs) lor opc_load 
	
  | Isw(rs2,rs1,n) -> ((extract 5 11 n) lsl 25) lor (rs2 lsl rs2_ofs) lor (rs1 lsl rs1_ofs) lor 
												(0b010 lsl f3_ofs) lor ((extract 0 4 n) lsl rd_ofs) lor opc_store

	| IBranch(b,rs1,rs2,lbl) -> 
      let n = (Hashtbl.find labels lbl) - curr in
      let brnch = match b with | Eq -> 0b000 | Ne -> 0b001 | Lt -> 0b100 | Ge -> 0b101 in
      ((extract 12 12 n) lsl 31) lor ((extract 5 10 n) lsl 25) lor (rs2 lsl rs2_ofs) lor (rs1 lsl rs1_ofs) lor (brnch lsl f3_ofs) lor
        ((extract 1 4 n) lsl 8) lor ((extract 11 11 n) lsl 7) lor opc_brnch

	| IUnop(op,n,rs1,rd) ->
      let fct = match op with | Addi -> 0b000 | Xori -> 0b100 | Ori -> 0b110 | Andi -> 0b111 in
      ((extract 0 11 n) lsl 20) lor (rs1 lsl rs1_ofs) lor (fct lsl f3_ofs) lor (rd lsl rd_ofs) lor opc_opimm

	| IBinop(op,rs1,rs2,rd) ->
      let fct3 = match op with | Add | Sub -> 0b000 | Xor -> 0b100 | Or -> 0b110 | And -> 0b111 in
      let fct7 = match op with | Add | Xor | Or | And -> 0b0000000 | Sub -> 0b0100000 in
      (fct7 lsl f7_ofs) lor (rs2 lsl rs2_ofs) lor (rs1 lsl rs1_ofs) lor (fct3 lsl f3_ofs) lor (rd lsl rd_ofs) lor opc_op

let get = function | None -> assert false | Some(x) -> x

let output_code out n =
	output_byte out (n lsr 24); output_byte out (n lsr 16); output_byte out (n lsr 8); output_byte out n

let compile_program prog out =
  let labels = Hashtbl.create 17 in
  let _ = List.fold_left (fun i (x,_) -> if x <> None then Hashtbl.add labels (get x) i; i+ins_size) 0 prog in
  let _ = List.fold_left (fun i (_,ins) -> output_code out (compile_ins labels i ins); i+ins_size) 0 prog in ()

