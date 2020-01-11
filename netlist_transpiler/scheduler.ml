open Netlist_ast
open Graph

exception Combinational_cycle

let read_exp e =
	let res = ref [] in
	let process_arg = function
		| Avar(id) -> res := id::(!res)
		| _ -> () in
	let process_args = List.iter process_arg in
	let aux = function
		| Earg(a) | Enot(a) | Erom(_,_,a) | Eslice(_,_,a) 
		| Eselect(_,a) -> process_arg a

		| Eram(_,_,a1,a2,a3,_) 
		| Emux(a1,a2,a3) -> process_args [a1;a2;a3]
		
		| Econcat(a1,a2) 
		| Ebinop(_,a1,a2) -> process_args [a1;a2]
		
		| Ereg(_) -> () in 
	aux (snd e);
	!res

let schedule p =
	let g = mk_graph() in
	List.iter (fun (id,ex) -> add_node g id) p.p_eqs;
	let aux (id,ex) =
		let used_vars = List.sort_uniq String.compare (read_exp (id,ex)) in
		List.iter (fun id2 -> try add_edge g id2 id with | Not_found ->
		()) used_vars
		in
	List.iter aux p.p_eqs;
	if has_cycle g then raise Combinational_cycle;
	let sorted_eqs = topological g in
	let actual_eqs = List.map (fun x -> (x,List.assoc x p.p_eqs))
	sorted_eqs in
	{p_eqs = actual_eqs; p_inputs = p.p_inputs; p_outputs = p.p_outputs;
	p_vars = p.p_vars}

