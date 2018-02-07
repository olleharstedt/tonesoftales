module M : sig 
	type ('s, 't) t
	type empty = unit * unit
	type empty_t = (unit, unit) t
	type any = [`table | `string | `number | `bool | `fn]

	(* New Lua state with empty stack *)
	val newstate : unit -> (unit, unit) t

	(* Get table *)
	val gettable : empty_t -> ([`table], empty) t

	val getglobal : ('a, 'b) t -> ([< any], 'a * 'b) t

	(* Get array index and put "anything" on top of stack *)
	val rawgeti : ([`table], 'a) t -> ([< any], [`table] * 'a) t

	(* String on top of stack *)
	val tostring : ([`string], 'a) t -> string

	(* Table or array-table on top of stack *)
	val objlen : ([< `table], 'a) t -> int

	(* Pop first element on stack; won't compile for empty stacks *)
	val pop : ('a, 'b * 'c) t -> ('b, 'c) t

	(* Get Lua function *)
	val getfn : empty_t -> string -> ([`fn], empty) t

	(*val setarg_number : ([`fn], 'a) t -> float -> ([`arg], [`fn] * 'a) t	(* Set arg, float *)*)

end = struct
	type ('s, 't) t = string	(* Should really be Lua_api.Lua.state *)
	type empty = unit * unit
	type empty_t = (unit, unit) t
	type any = [`table | `string | `number | `bool | `fn]

	(* Dummy implementations *)
	let newstate () = "state"
	let gettable s = s
	let getarray s = s
	let rawgeti s = s
	let tostring s = "Hello phantom world!"
	let objlen s = 10
	let pop s = s
	let getfn s str = s
	let getglobal s = s
end

