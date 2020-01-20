open Netlist_ast
open Format

type vflag = | Input | Output | Local
type var_info = int * vflag (* size, output *)

type env = { vars : (string,var_info) Hashtbl.t;
						 regs : (string,int) Hashtbl.t;
						 mems : (string,int*int) Hashtbl.t; (* nb of addr, bytes / word *)
						 
						 inputs : (string*var_info) list;
						 outputs : (string*var_info) list } 

let length n = (n + 7) / 8
let size_arg env = function | Avar id -> (fst (Hashtbl.find env.vars id))
														| Aconst (VBit _) -> 1
														| Aconst (VBitArray v) -> (Array.length v)
let var_to_int var =
	let res = ref 0 in
	for i = 0 to (Array.length var)-1 do
		res := (2 * !res) + (if var.(i) then 1 else 0)
	done; !res

(* Pareil mais inversé pour correspondre au format des données *)
let var_to_val var = 
	let res = ref 0 in
	for i = (Array.length var)-1 downto 0 do
		res := (2 * !res) + (if var.(i) then 1 else 0)
	done; !res


(* Fonctions pour afficher des variables/arguments *)

let print_var_ident fmt (id,(_,vf)) = 
	fprintf fmt "%s%s" (match vf with | Local -> "v_" | Input -> "in_" | Output -> "out_") id

let print_var_byte i fmt (id,(size,vf)) =
	let v = id,(size,vf) in
	let l = length size in
	if (vf = Output) && (l = 1) then fprintf fmt "(*%a)" print_var_ident v
	else if l > 1 then fprintf fmt "%a[%d]" print_var_ident v i
	else fprintf fmt "%a" print_var_ident v

let print_var_decl fmt (id,(size,vf)) = print_var_byte (length size) fmt (id,(size,vf)) 

let print_mask fmt l = if l < 8 then fprintf fmt "&%d" ((1 lsl l) - 1)

let print_arg_byte env i fmt = function
	| Avar id -> print_var_byte i fmt (id,Hashtbl.find env.vars id)
	| Aconst (VBit b) -> fprintf fmt "%d" (if b then 1 else 0)
	| Aconst (VBitArray v) -> fprintf fmt "%d" (var_to_val (Array.sub v (i*8) 8)) 

let print_arg_slice env i1 i2 fmt a =
	let q = i1 / 8 and r = i1 mod 8 and l = i2-i1+1 in
	if r = 0 then
		fprintf fmt "%a%a" (print_arg_byte env q) a print_mask l
	else if 8-r >= l then
		fprintf fmt "(%a>>%d)%a" (print_arg_byte env q) a r print_mask l
	else
		fprintf fmt "((%a>>%d)|(%a<<%d))%a" (print_arg_byte env q) a r
																			 	 (print_arg_byte env (q+1)) a (8-r) print_mask l

let int_of_arg env fmt = function
	| Avar id -> begin
			let (size,vf) = Hashtbl.find env.vars id in
			let l = length size in 
			let aux fmt i = print_var_byte i fmt (id,(size,vf)) in
			aux fmt 0;
			if l >= 2 then fprintf fmt "+(%a<<8)" aux 1;
			if l >= 3 then fprintf fmt "+(%a<<16)" aux 2;
			if l >= 4 then fprintf fmt "+(%a<<24)" aux 3
		end
	| Aconst (VBit b) -> fprintf fmt "%d" (if b then 1 else 0)
	| Aconst (VBitArray v) -> fprintf fmt "%d" (var_to_int v)

(* Compile le ième octet d'une expression *)
let compile_expr_byte env resvar i fmt = function
	| Earg a -> print_arg_byte env i fmt a
	| Ereg id -> fprintf fmt "st->regs[%d]" (Hashtbl.find env.regs id)  
  | Enot a -> fprintf fmt "(~%a)%a" (print_arg_byte env i) a print_mask ((size_arg env a) - 8*i)
  | Ebinop(op,a1,a2) -> 
		fprintf fmt "(%s(%a%s%a))%a" (match op with | Or | And | Xor -> "" | Nand -> "~")
								 (print_arg_byte env i) a1
								 (match op with | Or -> "|" | And | Nand -> "&" | Xor -> "^")
								 (print_arg_byte env i) a2
								 print_mask (if op <> Nand then 8 else ((size_arg env a1) - 8*i))
  | Emux(a,a1,a2) -> fprintf fmt "(%a) ? (%a) : (%a)" 
													(print_arg_byte env 0) a
												  (print_arg_byte env i) a1
												  (print_arg_byte env i) a2
  | Erom(_,_,raddr) 
  | Eram(_,_,raddr,_,_,_) ->
			fprintf fmt "st->mem_%s[%a][%d]" resvar (int_of_arg env) raddr i
  | Econcat(a1,a2) -> begin
			let s1 = size_arg env a1 and s2 = size_arg env a2 in
			if (i+1)*8 > s1 && i*8 < s1 then 
				fprintf fmt "(%a)|((%a)<<%d)" (print_arg_slice env (i*8) (s1-1)) a1 
																			(print_arg_slice env 0 (min (s2-1) ((i+1)*8-s1-1))) a2 (s1 mod 8)
			else if i*8 < s1 then print_arg_byte env i fmt a1
			else print_arg_slice env (i*8-s1) (min (i*8-s1+8) (s2-1)) fmt a2
		end
	| Eselect(i1,a) -> print_arg_slice env i1 i1 fmt a
  | Eslice(i1,i2,a) -> print_arg_slice env (i1+i*8) (min (i1 + i*8 + 7) i2) fmt a  

let compile_eq fmt env (id,expr) = 
	let size,vf = Hashtbl.find env.vars id in
	let l = length size in
	for i = 0 to l-1 do
		fprintf fmt "@,%a = %a;" (print_var_byte i) (id,(size,vf)) (compile_expr_byte env id i) expr
	done

let compile_updates fmt env eqs =
	let aux (id,expr) = match expr with
		| Eram(_,wsize,_,we,waddr,data) -> begin
				let l = (wsize+7) / 8 in
				fprintf fmt "@,if (%a)@,@[<v 2>{" (print_arg_byte env 0) we;
				for i = 0 to l-1 do
					fprintf fmt "@,st->mem_%s[%a][%d] = %a;" id (int_of_arg env) waddr i (print_arg_byte env i) data
				done;
				fprintf fmt "@]@,}"
			end
		| Earg _ | Ereg _ | Enot _ | Ebinop _ | Emux _ | Erom _ | Econcat _ | Eselect _ | Eslice _ -> () in

	Hashtbl.iter (fun id i -> fprintf fmt "@,st->regs[%d] = %a;" i (print_var_byte 0) (id,(Hashtbl.find env.vars id))) env.regs; 
	List.iter aux eqs

let build_env prog =
	let env = { vars = Hashtbl.create 17; regs = Hashtbl.create 17; mems = Hashtbl.create 17;
							inputs = []; outputs = []; } in
	
	(* Variables *)
	let ty_size = function | TBit -> 1 | TBitArray n -> n in 
	Env.iter (fun id ty -> Hashtbl.replace env.vars id ((ty_size ty),Local)) prog.p_vars;
	
	(* Entrées / sorties *)
	let aux1 flag id = let s,_ = Hashtbl.find env.vars id in Hashtbl.replace env.vars id (s,flag) in
	let aux2 id = id,(Hashtbl.find env.vars id) in
	List.iter (aux1 Input) prog.p_inputs;
	List.iter (aux1 Output) prog.p_outputs;
	let env = { env with inputs = List.map aux2 prog.p_inputs; outputs = List.map aux2 prog.p_outputs } in
	
	(* Mémoires / registres *)
	let i = ref 0 in 
	let process_eq (id,expr) = match expr with
		| Ereg id -> if not (Hashtbl.mem env.regs id) then Hashtbl.add env.regs id !i; incr i
		| Erom(asize,wsize,_) | Eram(asize,wsize,_,_,_,_) -> Hashtbl.replace env.mems id (1 lsl asize, (wsize+7)/8)
		| Earg _ | Enot _ | Ebinop _ | Emux _ | Econcat _ | Eselect _ | Eslice _ -> () in
	List.iter process_eq prog.p_eqs;
	env

let compile_prototype fmt env = 
	let print_var fmt (id,(size,vf)) =
		fprintf fmt ", unsigned char %a" print_var_decl (id,(size,vf)) in	

	fprintf fmt "void compute_cycle(State *st";
	List.iter (print_var fmt) env.inputs;
	List.iter (print_var fmt) env.outputs;
	fprintf fmt ")"

let compile_source name env prog out =
	let fmt = Format.formatter_of_out_channel out in
	let aux id (size,vf) = if vf = Local then fprintf fmt "@,unsigned char %a;" print_var_decl (id,(size,vf)) in

	fprintf fmt "@[<v 0>#include \"%s.h\"@,@,%a@,@[<v 2>{" name compile_prototype env;
	Hashtbl.iter aux env.vars;
	List.iter (compile_eq fmt env) prog.p_eqs;
	compile_updates fmt env prog.p_eqs;
	fprintf fmt "@]@,}@,@,@]@?"

let compile_header name env out =
	let fmt = Format.formatter_of_out_channel out in
	let name = String.uppercase name in
	
	let print_struct fmt () = 
		Hashtbl.iter (fun s (nb_addr,nb_bytes) -> fprintf fmt "@,unsigned char **mem_%s; // Intended size : %d x %d" s nb_addr nb_bytes) env.mems;
		fprintf fmt "@,unsigned char *regs; // Intended size : %d" (Hashtbl.length env.regs) in

	fprintf fmt "@[<v 0>#ifndef %s_H@,#define %s_H@,@," name name;
	fprintf fmt "struct State@,@[<v 2>{%a@]@,};@,@,typedef struct State State;@,@," print_struct ();
	fprintf fmt "%a;@,@,#endif@,@]@?" compile_prototype env

let remove_ext f =
	try Filename.chop_extension f
	with | Invalid_argument _ -> f

let compile_program prog filename =
	let env = build_env prog in
	let chopped = remove_ext filename in
	let name = Str.global_replace (Str.regexp "[^a-zA-Z_]+") "" (Filename.basename chopped) in
	let out_h = open_out (chopped^".h") and out_c = open_out (chopped^".c") in
	compile_header name env out_h;
	compile_source name env prog out_c;
	close_out out_h;
	close_out out_c


