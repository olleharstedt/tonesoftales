(**
	Compile with:
		ocamlfind ocamlc -syntax camlp4o -package monad-custom monad.ml
*)

module File : sig
	type ('a, 'st) t
	type open_st = Open
	type close_st = Close

	val bind : ('a, 's1) t -> ('a -> ('b, 's2) t) -> ('b, 's2) t

	val open_ : string -> (unit, open_st) t
	val read : (string, open_st) t
	val close : (unit, close_st) t

	val run : ('a, close_st) t -> 'a
end = struct
	type ('a, 'st) t = unit -> 'a
	type open_st = Open
	type close_st = Close

	let run m = m ()

	let bind m f = fun () ->
		let x = run m in
		run (f x)

	let close = fun () ->
		print_endline "[lib] close"

	let read = fun () ->
		let result = "toto" in
		print_endline ("[lib] read " ^ result);
		result

	let open_ path = fun () -> 
		print_endline ("[lib] open " ^ path)
end    

(*
let test =
	let open File in
	let (>>=) = bind in
	run begin
		open_ "/tmp/foo" >>= fun () ->
		read >>= fun content ->
		print_endline ("[user] read " ^ content);
		close
	end
*)

open File

let _ =
	let what = (perform
		s <-- read;
		open_ "path";
		close;
	) in
	run what;
	()



