exception Cycle
type mark = NotVisited | InProgress | Visited

type 'a graph =
    { mutable g_nodes : 'a node list }
and 'a node = {
  n_label : 'a;
  mutable n_mark : mark;
  mutable n_link_to : 'a node list;
  mutable n_linked_by : 'a node list;
}

let mk_graph () = { g_nodes = [] }

let add_node g x =
  let n = { n_label = x; n_mark = NotVisited; n_link_to = []; n_linked_by = [] } in
  g.g_nodes <- n::g.g_nodes

let node_for_label g x =
  List.find (fun n -> n.n_label = x) g.g_nodes

let add_edge g id1 id2 =
  let n1 = node_for_label g id1 in
  let n2 = node_for_label g id2 in
  n1.n_link_to <- n2::n1.n_link_to;
  n2.n_linked_by <- n1::n2.n_linked_by

let clear_marks g =
  List.iter (fun n -> n.n_mark <- NotVisited) g.g_nodes

let find_roots g =
  List.filter (fun n -> n.n_linked_by = []) g.g_nodes

let has_cycle g =
	clear_marks g;
	let rec aux x = match x.n_mark with
		| NotVisited -> x.n_mark <- InProgress; let res = List.exists aux x.n_link_to in x.n_mark
<- Visited; res
		| Visited -> false
		| InProgress -> true in
	let roots = find_roots g in
	let res = roots = [] || List.exists aux roots in
	clear_marks g;
	res	

let topological g =
	let res = ref [] in
	clear_marks g;
	let rec aux x =
		if x.n_mark = NotVisited then begin x.n_mark <-
Visited; List.iter (fun y -> aux y) x.n_link_to; res := (x.n_label)::(!res) end in
	List.iter (fun x -> if x.n_mark <> Visited then aux
	x) g.g_nodes;
	clear_marks g;
	!res

