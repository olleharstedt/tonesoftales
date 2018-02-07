(**
	From http://blogs.perl.org/users/cyocum/2012/11/writing-state-monads-in-ocaml.html

	@2013-06-13
*)

module type MONAD =
sig
	type 'a t
	val bind : 'a t -> ('a -> 'b t) -> 'b t
	val return : 'a -> 'a t
end


module type STATE =
sig
	type t
	val empty : t
end


module type STATE_MONAD = 
	functor(State : STATE) ->
	sig
		include MONAD
		val access : 'a t -> 'a
		val put : State.t -> unit t
		val get : State.t t
		val test : unit t
	end

module StateMonad : STATE_MONAD =
	functor(State : STATE) ->
	struct
		type state = State.t
		type 'a t = state -> ('a * state)

		let bind m f =
			fun s ->
				match m s with 
				| (x, s') -> f x s'

		let return a = fun s -> (a, s)
		let access m =
			  match m State.empty with
			  | (x, s) -> x
		let put s =
			  fun _ -> ((), s)
		let get =
			  fun s -> (s, s)
		let test =
			  fun _ -> 
			  	print_endline "test";

	end

module IntStateMonad = StateMonad(
	struct
		type t = int
		let empty = 0
	end
)


let return = IntStateMonad.return

open IntStateMonad

let _ =
	  let blah = 
			perform with bind in 
			a <-- return 1;
			b <-- return (succ a);
			test ();
			return b
	  in 
	  print_endline (string_of_int (IntStateMonad.access blah))
