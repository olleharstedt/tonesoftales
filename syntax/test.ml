(* Test of pa_wx *)

let ls = ([] : int list)

let fn = function
	| i when true -> Printf.printf "Yey!"
	| _ -> Printf.printf "Ney?"
;;

let _ =
	let l = [1;2;3] in
	module l -> List in
	Printf.printf "Hello, %d\n" l-->length
;;
