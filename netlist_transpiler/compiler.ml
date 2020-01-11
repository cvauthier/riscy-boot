open Netlist_ast
open Format

type vflag = | Input | Output | Local
type var_info = int * vflag (* size, output *)

type env = { vars : (string,var_info) Hashtbl.t;
						 regs : (string,var_info) Hashtbl.t;
						 mems : (string,int*int) Hashtbl.t; (* nb of addr, bytes / word *)
						 
						 inputs : (string*var_info) list;
						 outputs : (string*var_info) list } 

let length_arg env = function | Avar id -> fst (Hashtbl.find env.vars id)
															| Aconst (VBit _) -> 1
															| Aconst (VBitArray v) -> ((Array.length v) + 7) / 8

let print_var_ident fmt (id,(_,vf)) = 
	fprintf fmt "%s%s" (match vf with | Local -> "v_" | Input -> "in_" | Output -> "out_") id

let var_to_int var =
	let res = ref 0 in
	for i = 0 to (Array.length var)-1 do
		res := (2 * !res) + (if var.(i) then 1 else 0)
	done; !res

let byte_of_var i fmt (id,(size,vf)) =
	let v = id,(size,vf) in
	if (vf = Output) && (size = 1) then fprintf fmt "*%a" print_var_ident v
	else if size > 1 then fprintf fmt "%a[%d]" print_var_ident v i
	else fprintf fmt "%a" print_var_ident v

let print_var_decl fmt (id,(size,vf)) = byte_of_var size fmt (id,(size,vf)) 

let byte_of_arg env i fmt = function
	| Avar id -> byte_of_var i fmt (id,Hashtbl.find env.vars id)
	| Aconst (VBit b) -> fprintf fmt "%d" (if b then 1 else 0)
	| Aconst (VBitArray v) -> fprintf fmt "%d" (var_to_int (Array.sub v (i*8) 8)) 

let val_of_arg env fmt = function
	| Avar id -> begin
			let (size,vf) = Hashtbl.find env.vars id in
			let aux fmt i = byte_of_var i fmt (id,(size,vf)) in
			aux fmt 0;
			if size >= 2 then fprintf fmt "+%a<<8" aux 1;
			if size >= 3 then fprintf fmt "+%a<<16" aux 2;
			if size >= 4 then fprintf fmt "+%a<<24" aux 3
		end
	| Aconst (VBit b) -> fprintf fmt "%d" (if b then 1 else 0)
	| Aconst (VBitArray v) -> fprintf fmt "%d" (var_to_int v)

(* Compile le ième octet d'une expression *)
let compile_expr_byte env resvar i fmt = function
	| Earg a -> byte_of_arg env i fmt a
	| Ereg id -> fprintf fmt "st->reg_%s" id  
  | Enot a -> fprintf fmt "~%a" (byte_of_arg env i) a
  | Ebinop(op,a1,a2) -> 
		fprintf fmt "%s(%a%s%a)" (match op with | Or | And | Xor -> "" | Nand -> "~")
								 (byte_of_arg env i) a1
								 (match op with | Or -> "|" | And | Nand -> "&" | Xor -> "^")
								 (byte_of_arg env i) a1
  | Emux(a,a1,a2) -> fprintf fmt "%a ? %a : %a" (byte_of_arg env 0) a
												  (byte_of_arg env i) a1
												  (byte_of_arg env i) a2
  | Erom(_,_,raddr) 
  | Eram(_,_,raddr,_,_,_) ->
			fprintf fmt "st->mem_%s[%a][%d]" resvar (val_of_arg env) raddr i
  | Econcat(a1,a2) -> begin
			let l = length_arg env a1 in
			if i >= l then byte_of_arg env (i-l) fmt a2
			else byte_of_arg env i fmt a1
		end
	| Eselect(i1,a) 
  | Eslice(i1,_,a) -> begin
			if i1 mod 8 = 0 then byte_of_arg env (i + (i1/8)) fmt a
			else begin
				let r = i1 mod 8 and q = i1 / 8 in 
				fprintf fmt "((%a>>%d)+(%a>>%d))&255" (byte_of_arg env (i + q)) a r
																							(byte_of_arg env (i + q + 1)) a (8-r)
			end
		end

let compile_eq fmt env (id,expr) = 
	let size,vf = Hashtbl.find env.vars id in
	for i = 0 to size-1 do
		fprintf fmt "@,%a = %a;" (byte_of_var i) (id,(size,vf)) (compile_expr_byte env id i) expr
	done

let compile_updates fmt env eqs =
	let aux (id,expr) = match expr with
		| Eram(_,wsize,_,we,waddr,data) -> begin
				let l = (wsize+7) / 8 in
				fprintf fmt "@,if (%a)@,@[<v 2>{" (byte_of_arg env 0) we;
				for i = 0 to l-1 do
					fprintf fmt "@,st->mem_%s[%a][%d] = %a;" id (val_of_arg env) waddr i (byte_of_arg env i) data
				done;
				fprintf fmt "@]@,}"
			end
		| Earg _ | Ereg _ | Enot _ | Ebinop _ | Emux _ | Erom _ | Econcat _ | Eselect _ | Eslice _ -> () in

	Hashtbl.iter (fun id vinfo -> fprintf fmt "@,st->reg_%s = %a;" id (byte_of_var 0) (id,vinfo)) env.regs; 
	List.iter aux eqs

let build_env prog =
	let env = { vars = Hashtbl.create 17; regs = Hashtbl.create 17; mems = Hashtbl.create 17;
							inputs = []; outputs = []; } in
	
	(* Variables *)
	let length = function | TBit -> 1 | TBitArray n -> (n+7)/8 in 
	Env.iter (fun id ty -> Hashtbl.replace env.vars id ((length ty),Local)) prog.p_vars;
	
	(* Entrées / sorties *)
	let aux1 flag id = let s,_ = Hashtbl.find env.vars id in Hashtbl.replace env.vars id (s,flag) in
	let aux2 id = id,(Hashtbl.find env.vars id) in
	List.iter (aux1 Input) prog.p_inputs;
	List.iter (aux1 Output) prog.p_outputs;
	let env = { env with inputs = List.map aux2 prog.p_inputs; outputs = List.map aux2 prog.p_outputs } in
	
	(* Mémoires / registres *)
	let process_eq (id,expr) = match expr with
		| Ereg id -> Hashtbl.replace env.regs id (Hashtbl.find env.vars id)
		| Erom(asize,wsize,_) | Eram(asize,wsize,_,_,_,_) -> Hashtbl.replace env.mems id (1 lsl asize, (wsize+7)/8)
		| Earg _ | Enot _ | Ebinop _ | Emux _ | Econcat _ | Eselect _ | Eslice _ -> () in
	List.iter process_eq prog.p_eqs;
	env

let compile_prototype fmt env = 
	let print_var fmt (id,(size,vf)) =
		fprintf fmt ", char %a" print_var_decl (id,(size,vf)) in	

	fprintf fmt "void compute_cycle(State *st";
	List.iter (print_var fmt) env.inputs;
	List.iter (print_var fmt) env.outputs;
	fprintf fmt ")"

let compile_source name env prog out =
	let fmt = Format.formatter_of_out_channel out in
	let aux id (size,vf) = if vf = Local then fprintf fmt "@,char %a;" print_var_decl (id,(size,vf)) in

	fprintf fmt "@[<v 0>#include \"%s.h\"@,@,%a@,@[<v 2>{" name compile_prototype env;
	Hashtbl.iter aux env.vars;
	List.iter (compile_eq fmt env) prog.p_eqs;
	compile_updates fmt env prog.p_eqs;
	fprintf fmt "@]@,}@,@,@]@?"

let compile_header name env out =
	let fmt = Format.formatter_of_out_channel out in
	let name = String.uppercase_ascii name in
	
	let print_struct fmt () = 
		Hashtbl.iter (fun s (nb_addr,nb_bytes) -> fprintf fmt "@,char **mem_%s; // Intended size : %d x %d" s nb_addr nb_bytes) env.mems;
		Hashtbl.iter (fun s _ -> fprintf fmt "@,char reg_%s;" s) env.regs in

	fprintf fmt "@[<v 0>#ifndef %s_H@,#define %s_H@,@," name name;
	fprintf fmt "struct State@,@[<v 2>{%a@]@,};@,@,typedef struct State State;@,@," print_struct ();
	fprintf fmt "%a;@,@,#endif@,@]@?" compile_prototype env

let compile_program prog filename =
	let env = build_env prog in
	let chopped = Filename.remove_extension filename in
	let name = Str.global_replace (Str.regexp "[^a-zA-Z_]+") "" (Filename.basename chopped) in
	let out_h = open_out (chopped^".h") and out_c = open_out (chopped^".c") in
	compile_header name env out_h;
	compile_source name env prog out_c;
	close_out out_h;
	close_out out_c


