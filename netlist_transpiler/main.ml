open Netlist
open Format

let compile filename =
  try
    let p = Netlist.read_file filename in
		Compiler.compile_program (Scheduler.schedule p) filename
  with
    | Netlist.Parse_error s -> 		   eprintf "An error accurred: %s@." s; exit 2
		| Scheduler.Combinational_cycle -> eprintf "The netlist has a combinational cycle"; exit 2

let () = Arg.parse [] compile "usage : neatlist file.net"

