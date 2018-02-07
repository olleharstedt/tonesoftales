(**
	Wrapper for Lua states etc

	@since 2013-03-22
*)

exception LuaException of string

let escape = Netencoding.Html.encode ~in_enc:`Enc_utf8 ~unsafe_chars:Netencoding.Html.unsafe_chars_html4 ()

open Lua_api

let (|>) x g = g x
let (<|) g x = g x

(** Game state *)
type lua = {
	state : Lua_api_lib.state
}

(**
	Representation of how cards look in the lua state
*)
type lua_card = {
	c_cardname : string;	(* Like card1, card2 ... *)
	c_deck_id : int;
	c_card_id : int;
	c_nr : int;
	c_onpickup : string;
	c_onplay : string;
	c_title : string;
	c_text : string;
	c_img : string;
	c_sound : string;
      c_dir : string;
}

let log str = 
	ignore (Lwt_io.eprintl str)

(**
	Wrapper module for table ds_api and ds_api_param
*)
module Api = struct

	exception ApiException of string
	exception Api_not_found

	(**
		Param = parameter, argument to api function 
	*)
	type param = {
		api_id : int;
		param_name : string;
		param_desc : string;
		param_type : string;
	(**
		Api function with doc
	*)
	} and api = {
		id : int;
		name : string;
		script : string;
		active : bool;
		version : int;
		signature : string;
		desc : string;
		internal : bool;
		params : param list;
	} with value, type_of

	let html_of_api_param ap =
		Printf.sprintf "
			<tr><td></td><td><b>&#149;&nbsp;</b></td><td class=param>%s</td><td>:</td><td class=type>%s</td><td> %s</td>
			"
			ap.param_name
			ap.param_type
			ap.param_desc

	let html_of_api api =
		Printf.sprintf "
			<span class='func_sig'>%s</span><span class=internal>%s</span><br />
			<div class='func_desc'>
				<p>%s</p>
				%s		<!-- Description -->
				%s		<!-- Params -->
				%s		<!-- Table end tag -->
				<br />
			</div>
			"
			api.signature
			(if api.internal then "&nbsp;-&nbsp;Internal!" else "")
			api.desc
			(if List.length api.params > 0 then 
				"
				<p style='color: rgb(92, 101, 133);'>Parameters:</p>
				<table>
				"
				else
					""
			)
			(Misc.implode_list (List.map (fun ap -> html_of_api_param ap) api.params))
			(if List.length api.params > 0 then "</table>" else "")

	let html_of_apis apis =
		let html_list = List.map (fun api -> html_of_api api) apis in
		Misc.implode_list html_list

	let api_of_row row = 
		assert(Array.length row = 8);
		let get fn n = match row.(n) with 
			| Some i -> fn i 
			| None -> raise Api_not_found 
		in
		let get' = get (fun x -> x) in
		try
			{
				id = get int_of_string 0;
				name = get' 1;
				script = get' 2;
				active = get (fun x -> x = "1") 3;
				version = get int_of_string 4;
				signature = get' 5;
				desc = get' 6;
				internal  = get (fun x -> x = "1") 7;
				params = []
			}
		with
			_ -> raise (ApiException "Could not contruct api of row")

	let api_param_of_row row =
		assert(Array.length row = 4);
		let get fn n = match row.(n) with 
			| Some i -> fn i 
			| None -> raise Api_not_found 
		in
		let get' = get (fun x -> x) in
		try
			{
				api_id = get int_of_string 0;
				param_name = get' 1;
				param_desc = get' 2;
				param_type = get' 3;
			}
		with
			_ -> raise (ApiException "Could not contruct api param of row")

	
	(**
		Get all api functions and its docs.

		@param db 		the db returned by open_db
		@return		api list
	*)
	let get_apis db =
		let query = "
			SELECT
				id,
				name,
				script,
				active,
				version,
				signature,
				`desc`,
				internal
			FROM
				ds_api
			ORDER BY
				name ASC
		" in
		let stmt = Db.create_stmt db query in
		let result = Db.execute_stmt stmt [||] in
		let apis = Db.list_of_result result api_of_row in
		
		let query = "
			SELECT
				api_id,
				name,
				`desc`,
				type
			FROM
				ds_api_param
		" in
		let stmt = Db.create_stmt db query in
		let result = Db.execute_stmt stmt [||] in
		let api_params = Db.list_of_result result api_param_of_row in
		
		(* Traverse params once for each api. Better than call DB once for each api function? *)
		ExtLib.List.map (fun api ->
			let my_params = ExtLib.List.filter (fun param ->
				param.api_id = api.id
			) api_params in
			{api with params = my_params}
		) apis

end

module Api_datastructure = struct

	exception ApiStructureException of string
	exception Api_datastructure_not_found

	(**
		Param = parameter, argument to api function 
	*)
	type elem = {
		api_id : int;
		elem_name : string;
		elem_desc : string;
		elem_type : string;
	(**
		Api function with doc
	*)
	} and api_datastructure = {
		id : int;
		name : string;
		desc : string;
		elems : elem list;
	}

	let html_of_api_elem ap =
		Printf.sprintf "
			<tr><td></td><td><b>&#149;&nbsp;</b></td><td class=param>%s</td><td>:</td><td class=type>%s</td><td> %s</td>
			"
			ap.elem_name
			ap.elem_type
			ap.elem_desc

	let html_of_api_datastructure api =
		Printf.sprintf "
			<span class='func_sig'>%s</span><br />
			<div class='func_desc'>
				<p>%s</p>
				%s		<!-- Table begin -->
				%s		<!-- Elems -->
				%s		<!-- Table end tag -->
				<br />
			</div>
			"
			api.name
			api.desc
			(if List.length api.elems > 0 then 
				"
				<p style='color: rgb(92, 101, 133);'>Elements:</p>
				<table>
				"
				else
					""
			)
			(Misc.implode_list (List.map (fun ap -> html_of_api_elem ap) api.elems))
			(if List.length api.elems > 0 then "</table>" else "")

	let html_of_api_datastructures apis =
		let html_list = List.map (fun api -> html_of_api_datastructure api) apis in
		Misc.implode_list html_list

	let api_of_row row = 
		assert(Array.length row = 3);
		let get fn n = match row.(n) with 
			| Some i -> fn i 
			| None -> raise Api_datastructure_not_found
		in
		let get' = get (fun x -> x) in
		try
			{
				id = get int_of_string 0;
				name = get' 1;
				desc = get' 2;
				elems = []
			}
		with
			_ -> raise (ApiStructureException "Could not contruct api of row")

	let api_elem_of_row row =
		assert(Array.length row = 4);
		let get fn n = match row.(n) with 
			| Some i -> fn i 
			| None -> raise Api_datastructure_not_found
		in
		let get' = get (fun x -> x) in
		try
			{
				api_id = get int_of_string 0;
				elem_name = get' 1;
				elem_desc = get' 2;
				elem_type = get' 3;
			}
		with
			_ -> raise (ApiStructureException "Could not contruct api param of row")

	
	(**
		Get all API data structures

		@param db 		the db returned by open_db
		@return		api list
	*)
	let get_apis db =
		let query = "
			SELECT
				id,
				name,
				`desc`
			FROM
				ds_api_datastructure
		" in
		let stmt = Db.create_stmt db query in
		let result = Db.execute_stmt stmt [||] in
		let apis = Db.list_of_result result api_of_row in
		
		let query = "
			SELECT
				api_datastructure_id,
				name,
				`desc`,
				type
			FROM
				ds_api_datastructure_elem
		" in
		let stmt = Db.create_stmt db query in
		let result = Db.execute_stmt stmt [||] in
		let api_elems = Db.list_of_result result api_elem_of_row in
		
		(* Traverse elems once for each api. Better than call DB once for each api function? *)
		ExtLib.List.map (fun api ->
			let my_elems = ExtLib.List.filter (fun elem ->
				elem.api_id = api.id
			) api_elems in
			{api with elems = my_elems}
		) apis
end



(**
 *    Peano numbers, to statically check `assert(n > 0)` and the like
 *	Experimental.
 *
 *    @since 2013-03-29
 *)
module Nat : sig
      type z = Z
      type 'n s = S of 'n

	type ('n) nat = 
              Zero : (z) nat
            | Succ : ('n) nat -> ('n s) nat
	type some_nat = Some : 'n nat -> some_nat

	val inc : ( 'n) nat -> ( 'n s) nat
	val dec : ('n s) nat -> 'n nat
	val to_int : ( 'n) nat -> int

	val d0 : z nat
	val d1 : z s nat
	val d2 : z s s nat
	val d3 : z s s s nat

end = struct	
      type z = Z
      type 'n s = S of 'n
	type ( 'n) nat = 
              Zero : ( z) nat
            | Succ : ( 'n) nat -> ( 'n s) nat
	type some_nat = Some : 'n nat -> some_nat

	let inc n = Succ n
	let dec (Succ n) = n

	let rec to_int : type n . n nat -> int = function 
		| Succ a -> 1 + (to_int a)
		| Zero -> 0
	
	let rec of_int = function 
		0 -> Some Zero
		| n -> 
			let (Some nat) = of_int (n - 1) in
			Some (Succ nat)

	let d0 = Zero
	let d1 = inc d0
	let d2 = inc d1
	let d3 = inc d2
end

(**
 *    Generates an lua error @msg on state @s
 *    This will halt the Lua state
 *
 *    @param s    raw state (no LUA)
 *    @param msg  string; error message
 *)
let error s msg = 
	Lua_api.Lua.pushstring s msg;
	Lua_api.Lua.error s

(**
	Linear type module for adding new table to Lua state, etc
	The state of the stack will be represented by phantom types.
      The order of operations will be controlled statically.
	Thus it's not possible to push a number or string on the stack before pushing an index for that table.

	Usage:
		let s = newstate() in
		let s = newtable s in
		...
		setglobal s "table_name"

	[< `foo | `bar ]
		foo ELLER bar ELLER foo och bar
		"something is a subset of this"
	[> `foo | `bar]
		foo och bar, ELLER foo och bar och annat
		måste ha både foo och bar, minst
		"this is a subsut of something"

	@since 2013-03-27
*)
module LUA: sig
	(* Possible types on stack *)
	type ('s, 't) t			(* type *)
	type empty = unit * unit
	type empty_t = (unit, unit) t
	type any_atomic = [`string | `number | `bool]
	type any = [`string | `number | `bool | `table | `fn | `nil | `fn_res]

	(* Basics *)
	(*val newstate : unit -> empty t*)
	val newstate : unit -> (unit, unit) t
      val endstate : (unit, unit) t -> unit
	val to_lua : (unit, unit) t -> Lua_api.Lua.state
	val of_lua : Lua_api.Lua.state -> (unit, unit) t
	val error : (('a, 'b) t) -> string -> unit

	(* Interacting with tables *)
	val pushindex : ([`table], 'a) t -> string -> ([`string], [`table] * 'a) t
	(*val pushstring : ([`index], [`table] * 'a) t -> string -> ((string, 's n_table index) value) t*)
	val pushstring : ('a, 'b) t -> string -> ([`string], 'a * 'b) t
	(*val pushnumber : ('s n_table string) t -> float -> ((float, 's n_table string) value) t*)
	val pushnumber : ('a, 'b) t -> float ->  ([`number], 'a * 'b) t
	val pushnumber2 : ('a, 'b) t -> float -> ([`number], 'a * 'b) t
	val pushboolean : ('a, 'b) t -> bool ->  ([`bool], 'a * 'b) t
	(*val settable : (('a, 's n_table string) value) t -> ('s n_table) t*)
	val settable : ([< any], [`string] * ([`table] * 'a)) t -> ([`table], 'a) t
	val setsubtable : ([`table], [`table] * 'a) t -> ([`table], 'a) t
	val istable : ([`table], 'a) t -> bool
	val newtable : ('a, 'b) t -> ([`table], ('a * 'b)) t
	val newsubtable : ([`table], 'a) t -> string -> ([`table], [`table] * 'a) t
	val setglobal : ([< any], 'a * 'b) t -> string -> ('a, 'b) t
	val setmetatable : ([`table], [`table] * 'a) t -> ([`table], 'b) t

	(* getglobal pushes an "any value" on the stack, since we, at compile time, don't know what it is *)
	val getglobal : ('a, 'b) t -> string -> ([< any], 'a * 'b) t
	val gettable : ('a, 'b) t -> string -> ([`table], 'a * 'b) t

	(* Pop first element from stack *)
	val pop : ('a, 'b * 'c) t -> ('b, 'c) t

	val getfield : ([`table], 'b) t -> string -> ([< any], [`table] * 'b) t
	val setfield : ([< any], ([`table] * 'a)) t -> string -> ([`table], 'a) t

	val setnumber : ([`table], 'a) t -> string * float -> ([`table], 'a) t
	val getnumber : ([`table], 'a) t -> string -> ([`table], 'a) t * float
	val getint : ([`table], 'a) t -> string -> ([`table], 'a) t * int
	val tonumber : ([`number], 'a) t -> ([`number], 'a) t * float
	val toint : ([`number], 'a) t -> ([`number], 'a) t * int
	val setstring : ([`table], 'a) t -> string * string -> ([`table], 'a) t
	val getstring : ([`table], 'a) t -> string -> ([`table], 'a) t * string
	val tostring : ([`string], 'a) t -> ([`string], 'a) t * string
	val setboolean : ([`table], 'a) t -> string * bool -> ([`table], 'a) t
	val getboolean : ([`table], 'a) t -> string -> ([`table], 'a) t * bool
	val setfunc : ([`table], 'a) t -> string * string -> ([`table], 'a) t
	val runstring : empty_t -> string -> string -> empty_t
	val objlen : ([`table], 'a) t -> ([`table], 'a) t * int
	val ref_ : ([< any], 'a * 'b) t -> int -> ('a, 'b) t * int

	(** Check type of item at top of stack *)
	val checktype : ('a, 'b) t -> Lua_api_lib.lua_type -> unit
	val isnil : ('a, 'b) t -> bool
	val typename : ('a, 'b) t -> string

	(* Iterate array table *)
	(* Not done *)
	val push_dummykey : ([`table], 'a) t -> ([`string], [`table] * 'a) t
	val pushnil : ('a, 'b) t -> ([`nil], 'a * 'b) t
	(*val next : 's*)
	(*val iter_array : 'string table t -> (unit -> unit) -> 's table t *)

	val pushcfunction : empty_t ->  string -> Lua_api.Lua.oCamlFunction -> unit
	val pushcfunction0 : empty_t ->  string -> (empty_t -> int) -> unit
	val pushcfunction1 : empty_t ->  string -> (([< any], empty) t -> int) -> unit
	val pushcfunction2 : empty_t ->  string -> (([< any], [< any] * empty) t -> int) -> unit
	val pushcfunction3 : empty_t ->  string -> (([< any], [< any] * ([< any] * empty)) t -> int) -> unit
	val pushcfunction4 : empty_t ->  string -> (([< any], [< any] * ([< any] * ([< any] * empty))) t -> int) -> unit
	(*val to_lua : empty t -> Lua_api_lib.state*)
	val loadbuffer : empty_t -> string -> string -> empty_t
	(*val pcall : empty_t -> int -> int -> int -> empty_t*)

	(* Calling Lua functions *)
	val getfn : empty_t -> string -> ([`fn], empty) t		(* Set Lua function name to call *)
	(*val setarg_number : ([`fn], 'a) t -> float -> ([`arg], [`fn] * 'a) t	(* Set arg, float *)*)
	(*val setarg_table : ([`fn], 'a) t -> string -> ([`arg], [`fn] * 'a) t	(* Set arg, table *)*)
	(*val setarg_subtable : ('s fn) t -> string -> string -> ('s arg fn) t	(* Set arg, table *)*)
	(* val fnargs_toint : ? TODO: Use GADT for this? Overkill? Left as excercise... *)
	val pcall_fn1 : ([< any], [`fn] * 'a) t -> ([< any], 'a) t			(* Call Lua function TODO: Will accept pcall_fn3 too, since 's! *)
	val pcall_fn2 : ([< any], ([< any] * ([`fn] * 'a))) t -> ([< any], 'a) t
	val pcall_fn2_noresult : ([< any], ([< any] * ([`fn] * empty))) t -> empty_t
	val pcall_fn1_noresult : ([< any], ([`fn] * empty)) t -> empty_t
	val pcall_fn0_noresult : ([`fn], 'a * 'b) t -> ('a, 'b) t
	val pcall_fn3 : ([< any], ([< any] * ([< any] * ([`fn] * empty)))) t -> ([< any], empty) t
	val pcall_fn3_noresult : ([< any], ([< any] * ([< any] * ([`fn] * empty)))) t -> empty_t
	val pcall_fn4_noresult : ([< any], ([< any] * ([< any] * ([< any] * ([`fn] * empty))))) t -> empty_t
	val fn_getnumber : ([`fn_res], empty) t -> empty_t * float	(* Get result, float *)
	val fn_getstring : ([`fn_res], empty) t -> empty_t * string		(* Get result, string *)
	val fn_getbool : ([`fn_res], empty) t -> empty_t * bool

	(* Removes element at -2 from stack *)
	val remove_second : ('a, 'b * ('c * 'd)) t -> ('a, 'c * 'd) t

	(* Array operations *)
	val rawgeti : ([`table], 'a) t -> int -> ([< any], [`table] * 'a) t
	val rawgeti_registryindex : ('a, 'b) t -> int -> ([< any], 'a * 'b) t
	val rawseti : ([< any], [`table] * ('a * 'b)) t -> int -> ([`table],  'a * 'b) t
	val loop_rawgeti : ([`table] , 'a) t -> (([`table], 'a) t -> ([`table], 'a) t) -> unit
	val fold_rawgeti : ([`table], 'a) t -> (([< any], [`table] * 'a) t -> (([< any], [`table] * 'a) t * 'b)) -> 'b list
	(*val fold_with_rawgeti : *)

end = struct
	type ('s, 't) t = Lua_api_lib.state
      (*type (_, _) t = data * lua_state and data = Array of ... | Stack of ...*)
	type empty = unit * unit
	type empty_t = (unit, unit) t
	type any_atomic = [`string | `number | `bool]
	type any = [`string | `number | `bool | `table | `fn | `nil | `fn_res]

	let to_lua s = s
	let of_lua s = s

	(** Get new lua state and open libs *)
	let newstate () = 
		let state = LuaL.newstate() in
		LuaL.openlibs state;
		state

      (**
       *    Consumes an empty state and return unit
       *
       *    @param state      empty t
       *    @return           unit
       *)
      let endstate state =
            ()

	let error s msg = 
		Lua_api.Lua.pushstring s msg;
		Lua_api.Lua.error s

	(** Prepare stack for new table *)
	let newtable state =
		Lua.newtable state;
		state

	(** Add a subtable to a table field *)
	let newsubtable state table_name =
		Lua.pushstring state table_name;
		Lua.newtable state;
		state

	(** Index on table on stack, e.g. {string = value} *)
	let pushindex state str =
		Lua.pushstring state str;
		state

	(** Value for an index *)
	let pushstring state str =
		Lua.pushstring state str;
		state

	(** Value for an index *)
	let pushnumber state n =
		Lua.pushnumber state n;
		state

	let pushnumber2 state n =
		Lua.pushnumber state n;
		state

      let pushboolean state b =
            Lua.pushboolean state b;
            state

	(** 
		Push a function to a table index 

		@param state	see val in sig
		@param func		string, like "return function() bla end"
		@return state
	*)
	(*
	let pushfunc state func =
		let ts = LuaL.loadstring state func in
		(match thread_state with
			| Lua.LUA_OK -> ()
			| err -> 
				let err_msg = Lua.tostring state (-1) in
				Lua.pop state 1;  (* Pop message from stack *)
				failwith ("pushfunc: LuaL.loadstring: " ^ (match err_msg with Some s -> s | None ->
				raise Not_found))
		);
		Lua.pcall state 0 1 0;
		state
		*)

	(** Pops index/value pair from stack and push it to table *)
	let settable state =
		ignore (Lua.settable state (-3));
		state

	(** Set subtable on table *)
	let setsubtable state =
		ignore(Lua.settable state (-3));
		state

	(** Pops table from stack and push it to lua state *)
	let setglobal state table_name =
		Lua.setglobal state table_name;
		state
	
	(** 	Assumes stack -1 => metatable, -2 => table
		Pops metatable from stack, and set it as metatable for table at index -2 *)
	let setmetatable s =
		ignore(Lua.setmetatable s (-2));	(* 5.1 return int, 5.2 return void *)
		s

	(** Get existing table from state and push it to stack *)
	let getglobal state table_name =
		Lua.getglobal state table_name;
		state
	
	let gettable s str =
		Lua.getglobal s str;
		s
		(*
		if Lua.istable s (-1) then
			s
		else
			raise error ("Not a table: " ^ str))
		*)

	(** Pop 1 element from stack *)
	let pop state =
		Lua.pop state 1;
		state

	(** Pop subtable table from stack *)
	let popsubtable state =
		Lua.pop state 1;
		state

	(**
		Assuming table is on top of stack

		Set string
	*)
	let setstring s (index, value) =
		let s = pushindex s index in
		let s = pushstring s value in
		settable s

	(**
	 *    Table on stack
	 *    Set boolean value
	 *)
	let setboolean s (index, value) =
		let s = pushstring s index in
		let s = pushboolean s value in
		settable s

	(**
		Assuming table is on top of stack
		Push field to table in lua state

		@param s		lua state from LUA module
		@param index	string
		@param value	float
		@return		unit
	*)
	let setnumber s (index, value) = 
		let s = pushindex s index in
		let s = pushnumber s value in
		settable s

	(** Internal function. Handle thread state after pcall or loadstring *)
	let check_thread ts state = match ts with
		| Lua.LUA_OK -> ()
		| err -> 
			let err_msg = Lua.tostring state (-1) in
			Lua.pop state 1;  (* Pop message from stack *)
			failwith ("pushfunc: LuaL.loadstring: " ^ (match err_msg with Some s -> s | None -> raise Not_found))
		
		
	(** 
		Push function in table to Lua, like player1 = {onpickup = function () do_something end } 
	*)
		let setfunc s (index, func_string) =
			let s = pushstring s index in
			check_thread (LuaL.loadstring s ("return " ^ (match func_string with "" -> " function () end" | s -> s))) s;
			check_thread (Lua.pcall s 0 1 0) s;
			ignore(Lua.settable s (-3));	(* TODO: Why this return int in OCaml version? *)
			s

	(**
		Push field from table on top of stack
	*)
	let getfield s key =
		Lua.getfield s (-1) key;
		s

	(** Assumes stack: -1 => value, -2 => table
			t[k] = v
			Pops value, leaving stack: -1 => table *)
	let setfield s key =
		Lua.setfield s (-2) key;
		s

	(**
		Return float value from table.

		@param state	lua state
		@param key		string, key in table
		@return		(state, float)
	*)
	let getnumber state key =
		Lua.getfield state (-1) key;
		if not (Lua.isnumber state (-1)) then
			error state ("Not number in table field " ^ key);
		let n = Lua.tonumber state (-1) in
		Lua.pop state 1;
		(state, n)

	(** As above, but returns int *)
	let getint state key =
		Lua.getfield state (-1) key;
		if not (Lua.isnumber state (-1)) then
			error state ("Not number in table field " ^ key);
		let n = Lua.tonumber state (-1) in
		Lua.pop state 1;
		(state, int_of_float n)

	(* Return number on top of stack, NO POP *)
	let tonumber s =
		if not (Lua.isnumber s (-1)) then
			error s "tonumber: no number";
		let nr = Lua.tonumber s (-1) in
		(s, nr)

	(* Return number to int on top of stack, NO POP *)
	let toint s =
		if not (Lua.isnumber s (-1)) then
			error s "tonumber: no number";
		let nr = Lua.tonumber s (-1) in
		(s, int_of_float nr)

	let istable state =
		Lua.istable state (-1)

	(**
		Return string field from table.

		@param state	lua state
		@param key		string, key in table
		@return		string
	*)
	let getstring state key =
		Lua.getfield state (-1) key;
		if not (Lua.isstring state (-1)) then
			error state ("Not string in table field " ^ key);
		match Lua.tostring state (-1) with
			| Some s -> 
				Lua.pop state 1;
				(state, escape s)
			| None -> 
				Lua.pop state 1;
				error state ("Found no string in table field " ^ key)

	(** Return string, if top of stack is string, AND DOES NOT POP *)
	let tostring state =
		if not (Lua.isstring state (-1)) then
			failwith ("Not string at top of stack");
		match Lua.tostring state (-1) with 
			| Some s ->
				(state, escape s)
			| None ->
				failwith ("Found no string at top of stack")

	(**
	 *    Return boolean field from table on stack
	 *)
	let getboolean state key =
		Lua.getfield state (-1) key;
		if not (Lua.isboolean state (-1)) then
			failwith ("Not bool in table field " ^ key);
		let n = Lua.toboolean state (-1) in
		Lua.pop state 1;
		(state, n)

	(** Push an OCaml function into state, so it can be executed by the lua script *)
	let pushcfunction state name func =
		Lua.pushcfunction state func;
		Lua.setglobal state name

	(** Push a function which takes zero arg in Lua *)
	let pushcfunction0 state name func =
		Lua.pushcfunction state func;
		Lua.setglobal state name

	(** Push a function which takes one arg in Lua *)
	let pushcfunction1 state name func =
		Lua.pushcfunction state func;
		Lua.setglobal state name
		
	(** Push a function which takes two args in Lua *)
	let pushcfunction2 state name func =
		Lua.pushcfunction state func;
		Lua.setglobal state name
		
	(** Push a function which takes three args in Lua *)
	let pushcfunction3 state name func =
		Lua.pushcfunction state func;
		Lua.setglobal state name
		
	(** Push a function which takes three args in Lua *)
	let pushcfunction4 state name func =
		Lua.pushcfunction state func;
		Lua.setglobal state name
		
	(** 
		Execute a lua string

		@param state
		@param str		string; string to execute
		@param chunkname	string; name of chunk (will appear in error message)
		@return state
		@raise		fail if thread state not ok
	*)
	let runstring state str chunkname =
		(* Push the traceback function on the stack *)
		let traceback s =
			Lua.getfield s Lua_api_lib.globalsindex "debug";
			Lua.getfield s (-1) "traceback";
			Lua.pushvalue s 1;
			Lua.pushinteger s 2;
			Lua.call s 2 1;
			(*
			(match ts with
						| Lua.LUA_OK -> 
									()
						| err ->
									begin
												log "traceback: could not run debug.traceback";
									end
			);
			*)
			let trace = (match Lua.tostring s (-1) with
						| Some s -> s
						| None -> "No trace"
			) in
			(* Replace \n with <br />, etc *)
			let regexp = Str.regexp "\\\n" in
			let trace = Str.global_replace regexp "<br />" trace in
			let regexp = Str.regexp "\\\t" in
			let trace = Str.global_replace regexp "&nbsp;&nbsp;&nbsp;&nbsp;" trace in
			let trace = "<pre>" ^ trace ^ "</pre>" in
			Lua.pop state 1;
			Lua.pushstring state trace;
			1
		in
		Lua.pushcfunction state traceback;
		let ts = LuaL.loadbuffer state str chunkname in
		(match ts with 
			| Lua.LUA_OK -> 
						()
			| err -> 
				begin
					let err_msg = Lua.tostring state (-1) in
					Lua.pop state 1;
					raise (LuaException ("runstring: Could not loadbuffer script " ^ chunkname ^ ": " ^ (match err_msg with Some s -> s | None ->
						raise Not_found)))
				end
		);
		(*let thread_state = Lua.pcall state 0 0 ((Lua.gettop state) - 1) in*)
		let thread_state = Lua.pcall state 0 0 (-2) in
		match thread_state with
			| Lua.LUA_OK -> 
				state
			| err -> 
				begin
					let err_msg = match Lua.tostring state (-1) with
						| Some s -> s
						| None ->
									raise (LuaException "runstring: Could no find err_mgs")
					in
					Lua.pop state 1;
					raise (LuaException ("runstring: Could not pcall lua script " ^ chunkname ^ ": " ^ err_msg))
				end

	(**
		Length of table
	*)
	let objlen s =
		let i = Lua.objlen s (-1) in
		(s, i)

	(** Get a unique int ref, preferebly used with the registry index *)
	let ref_ s i =
		let j = Lua_api.LuaL.ref_ s i in
		(s, j)
		

	(** Check type of item at top of stack *)
	let checktype s t =
		LuaL.checktype s (-1) t

	let isnil s =
		Lua.isnil s (-1)

	let typename s =
		LuaL.typename s (-1)

	(**
		Push a dummy key before using next first time

		@param s 		Lua state
	*)
	let push_dummykey s = 
		Lua.pushnil s;
		s

	let pushnil s = 
		Lua.pushnil s;
		s


	(**
		Push next key/value pair on stack.
		Assumes key/dummykey
	*)
	(*
	let next s =
		Lua.next s (-2);
		s
		*)
	
	(**
		Iterates through an array-like table @l times, and run @fn for each value
		Assumes the table to iterate is top of stack

		@param s 		Lua state
		@param l		length; timer to iterate
		@param fn		unit -> unit; function run on each value
	*)
	(*
	let iter_array s l fn =
		let s = push_dummykey s' in		(* stack: -1 => nil, -2 => hand, -3 => player *)
		let rec iter s' n =
			if n > l then
				[]
			else
				begin
					Lua_api.Lua.next s' (-2);	(* stack: -1 => value/card, -2 => key/array index, -3 => hand, -4 => player *)
					let field = Lua_api.Lua.getfield s' (-1) "card_id" in (* stack: -1 => card_id, -2 => value/card, -3 => key/array index, -4 => hand, -5 => player *)
					if not (Lua_api.Lua.isnumber s' (-1)) then
						failwith ("Not number in table field card_id");
					let card_id' = Lua_api.Lua.tonumber s' (-1) in
					Lua_api.Lua.pop s' 2;	(* stack: -1 => key/array index, -2 => hand, -3 => player *)
					card_id' :: get_card_ids (n + 1)
				end
		in
		let _ = iter s' 1 in
		Lua_api.Lua.pop s' 2
	*)

	(** 
		Loads lua script/buffer into state 

		@param state 	lua state
		@param buffer	string; lua code
	*)
	let loadbuffer state buffer chunkname = 
		check_thread (LuaL.loadbuffer state buffer chunkname) state;
		state

	(**
		Run lua code in buffer

		@param state 	lua state
		@param i j k	?
		@return 		state
		@raise		failwith if thread state != LUA_OK after call; raise Not_found if no error message was found
	*)
	let pcall state i j k =
		let thread_state = Lua.pcall state i j k in
		(match thread_state with
			Lua.LUA_OK -> state
			| err -> 
					begin
						let err_msg = Lua.tostring state (-1) in
						Lua.pop state 1;  (* Pop message from stack *)
						raise (LuaException (match err_msg with Some s -> s | None -> raise Not_found))
					end)

	(** 
		Set function name on stack, to call Lua from OCaml
	*)
	let getfn state fn_name =
		Lua.getglobal state fn_name;
		state

	(**
		Push table onto stack, as argument to function 

		@param state
		@param t		string; table name
	*)
	let setarg_table state t =
		Lua.getglobal state t;
		state

	let setarg_subtable state t subt =
		Lua.getglobal state t;
            Lua.getfield state (-1) subt;
            Lua.remove state (-2);
		state

	(**
		Removes element at -2 from stack.
	*)
	let remove_second s =
		Lua.remove s (-2);
		s

	
	(**
		Call Lua function with 3 args on stack, 1 result value
	*)
	let pcall_fn3 state =
		let thread_state = Lua.pcall state 3 1 0 in	(* 3 args, 1 result *)
		(match thread_state with
			Lua.LUA_OK -> state
			| err -> 
					begin
						let err_msg = Lua.tostring state (-1) in
						Lua.pop state 1;  (* Pop message from stack *)
						raise (LuaException (match err_msg with Some s -> s | None -> raise Not_found))
					end)
	
	let pcall_fn3_noresult state =
		let thread_state = Lua.pcall state 3 0 0 in	(* 3 args, 0 result *)
		(match thread_state with
			Lua.LUA_OK -> state
			| err -> 
					begin
						let err_msg = Lua.tostring state (-1) in
						Lua.pop state 1;  (* Pop message from stack *)
						raise (LuaException (match err_msg with Some s -> s | None -> raise Not_found))
					end)
	
	(**
		As above, with 1 arg, 1 result
	*)
	let pcall_fn1 state =
		let thread_state = Lua.pcall state 1 1 0 in	(* 1 args, 1 result *)
		(match thread_state with
			| Lua.LUA_OK -> state
			| err -> 
					begin
						let err_msg = Lua.tostring state (-1) in
						Lua.pop state 1;  (* Pop message from stack *)
						raise (LuaException (match err_msg with Some s -> s | None -> raise Not_found))
					end)
	
	(**
		As above, with 2 arg, 1 result
	*)
	let pcall_fn2 state =
		let thread_state = Lua.pcall state 2 1 0 in	(* 2 args, 1 result *)
		(match thread_state with
			Lua.LUA_OK -> state
			| err -> 
					begin
						let err_msg = Lua.tostring state (-1) in
						Lua.pop state 1;  (* Pop message from stack *)
						raise (LuaException (match err_msg with Some s -> s | None -> raise Not_found))
					end)

	let pcall_fn4_noresult s = 
		let thread_state = Lua.pcall s 4 0 0 in	(* 4 args, 0 result *)
		(match thread_state with
			Lua.LUA_OK -> s
			| err -> 
					begin
						let err_msg = Lua.tostring s (-1) in
						Lua.pop s 1;  (* Pop message from stack *)
						raise (LuaException (match err_msg with Some s -> s | None -> raise Not_found))
					end)

	(**
		Not public

		@param s 		state
		@param i		number of args to function 
		@param j		number of results
	*)
	let pcall s i j =
		(* stack: -1 => arg, .., -i-1 => fn *)
		let traceback s =
			Lua.getfield s Lua_api_lib.globalsindex "debug";
			Lua.getfield s (-1) "traceback";
			Lua.pushvalue s 1;
			Lua.pushinteger s 2;
			Lua.call s 2 1;
			(*
			(match ts with
						| Lua.LUA_OK -> 
									()
						| err ->
									begin
												log "traceback: could not run debug.traceback";
									end
			);
			*)
			let trace = (match Lua.tostring s (-1) with
						| Some s -> s
						| None -> "No trace"
			) in
			(* Replace \n with <br />, etc *)
			let regexp = Str.regexp "\\\n" in
			let trace = Str.global_replace regexp "<br />" trace in
			let regexp = Str.regexp "\\\t" in
			let trace = Str.global_replace regexp "&nbsp;&nbsp;&nbsp;&nbsp;" trace in
			let trace = "<pre>" ^ trace ^ "</pre>" in
			Lua.pop s 1;
			Lua.pushstring s trace;
			1
		in
		Lua.pushcfunction s traceback;	(* stack: -1 => error fn, -2 => arg, ..., -i-1 => fn *)
		Lua.insert s ((-i) - 2);	(* stack: -1 => arg, ..., -i-1 => fn, -i-2 => error fn *)
		let thread_state = Lua.pcall s i j ((-i) - 2) in	(* 1 args, 1 result *)
		(match thread_state with
			Lua.LUA_OK -> s
			| err -> 
					begin
						let err_msg = Lua.tostring s (-1) in
						Lua.pop s 1;  (* Pop message from stack *)
						raise (LuaException ("pcall: " ^ (match err_msg with Some s -> s | None -> raise Not_found)))
					end)

	let pcall_fn2_noresult s = 
		pcall s 2 0
	
	let pcall_fn1_noresult s = 
		pcall s 1 0

	let pcall_fn0_noresult s = 
		pcall s 0 0

	(**
		Get result from Lua function call, number.
	*)
	let fn_getnumber state =
		if not (Lua.isnumber state (-1)) then
			failwith ("fn_getnumber: Not number as result from Lua function call");
		let n = Lua.tonumber state (-1) in
		Lua.pop state 1;
		(state, n)
		
	let fn_getstring state =
		if not (Lua.isstring state (-1)) then
			failwith ("fn_getstring: Not string as result from Lua function call");
		let s = (match Lua.tostring state (-1) with
			Some s -> escape s
			| None -> failwith ("fn_getstring: No string found")) 
		in
		Lua.pop state 1;
		(state, s)

	let fn_getbool state =
		if not (Lua.isboolean state (-1)) then
			failwith ("fn_getbool: Not bool as result from Lua function call");
		let b = Lua.toboolean state (-1) in
		Lua.pop state 1;
		(state, b)
	
	(* Array get index *)
	let rawgeti s i =
		Lua.rawgeti s (-1) i;
		s

	let rawgeti_registryindex s i =
		Lua.rawgeti s Lua.registryindex i;
		s
	
	let rawseti s i =
		Lua.rawseti s (-2) i;
		s

	(** Loop table using rawgeti *)
	let loop_rawgeti s fn =
		let l = Lua_api.Lua.objlen s (-1) in	(* stack: -1 => table *)
		let rec loop i = 
			if i <= l then
				(
					Lua_api.Lua.rawgeti s (-1) i; (* stack: -1 => obj, -2 => table *)
					fn s; 
					Lua_api.Lua.pop s 1;
					loop (i + 1)
				)
			else
				()
		in
		loop 1;
		()
	
	(** Loop table using lua_next *)
	let loop_next s fn =
		()
	
	(**
		Fold a table in Lua using rawgeti.
		@param s 		lua state
		@param fn 	function that returns object to collect
								state -> state * 'a
	*)
	let fold_rawgeti s fn =
		let l = Lua_api.Lua.objlen s (-1) in	(* stack: -1 => table *)
		let rec loop i =
			if i <= l then
				(
					Lua_api.Lua.rawgeti s (-1) i; (* stack: -1 => obj, -2 => table *)
					let (s, elem) = fn s in
					Lua_api.Lua.pop s 1;	(* stack: -1 => table *)
					elem :: loop (i + 1)
				)
			else
				[]
		in
		loop 1;
		
end

(** getnumber from key @k from table top of stack *)
let getnumber s k =
	Lua_api.Lua.getfield s (-1) k;
	let v = Lua_api.Lua.tonumber s (-1) in
	Lua_api.Lua.pop s 1;
	v

(* get string option from field, assumes table on top of stack *)
let getstring s field =
	Lua_api.Lua.getfield s (-1) field;
	let value = Lua_api.Lua.tostring s (-1) in
	Lua_api.Lua.pop s 1;
	match value with
		| Some s -> Some (escape s)
		| None -> None

(**
	Push function in table to Lua, like player1 = {onpickup = function () do_something end } 

	@param s		 state
	@param index	 string
	@param func_string string, like "return function () bla end"
	@param return	 unit
*)
(*
let set_func s (index, func_string) =
	let s = LUA.pushindex s index in
	let s = LUA.pushfunc s func_string in
	LUA.settable s
	(*
	LuaL.loadstring state func_string;
	Lua.pcall state 0 1 0;
	*)
*)

(**
	Dump decks and players in lua @state to a string

	@param state	lua state
	@return string
*)
(*
let dump state =
	(**
		A special function, that only excepts n > 0 (Nat module)
		"type n" means polymorphic recursion over Nat (type z and type 'a s)

		@param 	lua state
		@param 	nat > 0
		@return	deck list
	*)
	(* let rec get_decks' state n = *)
	(*let rec get_decks' : type n . Lua_api_lib.state * n Nat.s Nat.nat (* > 0 *)-> 'a list = function *)
	let rec get_decks' = function 
		| state, n ->
			assert( n > 0);
			let deckname = "deck" ^ (string_of_int (n)) in
			Lua.getglobal state deckname;
			if Lua.istable state (-1) then
				begin
					[] :: get_decks' (state, (n + 1))
				end
			else
				[]
		| _ -> failwith "Lua.dump: Complete FAIL"
	in
	let decks = get_decks' (state, 1) in
	()
*)

(**
	Dump decks from lua state, return pretty string
      Not needed, use dump instead

	@param state 	lua state
	@return		string
*)
(*
let dump_decks state =
	(* Get cards from deck (subtables in deck1, deck2 ...). Assuming table is on top of stack. *)
	let card_nr = ref 1 in
	let rec get_cards' = function 
		| state ->
			let card_name = "card" ^ (string_of_int !card_nr) in
			let state = LUA.getsubtable state card_name in
			if LUA.istable state then
				begin
					card_nr := !card_nr + 1; 
					(*log ("Dumping card " ^ card_name);*)
					(try
						(*let state = LUA.*)
						let (state, c_img) = LUA.getstring state "img" in
						let (state, c_sound) = LUA.getstring state "sound" in
						let (state, c_deck_id) = LUA.getstring state "deck_id" in
						let (state, c_card_id) = LUA.getstring state "card_id" in
						let (state, c_onpickup) = LUA.getstring state "onpickup" in
						let (state, c_nr) = LUA.getstring state "nr" in
						let (state, c_title) = LUA.getstring state "title" in
						let (state, c_text) = LUA.getstring state "text" in
						let card = {
							c_cardname = card_name;
							c_deck_id = int_of_string (c_deck_id);
							c_card_id = int_of_string (c_card_id);
							c_nr = int_of_string (c_nr);
							c_onpickup = c_onpickup;
							c_title = c_title;
							c_text = c_text;
							c_img = c_img;
							c_sound = c_sound;
						} in
						let state = LUA.popsubtable state in
						(*log ("Added " ^ card_name ^ " to deck"); *)
						card :: get_cards' state
					with
						LuaException msg -> 
							card_nr := !card_nr - 1;
							ignore (LUA.popsubtable state);
							[]
						| ex ->
							card_nr := !card_nr - 1;
							let msg = Printexc.to_string ex in
							log ("Error when dumping cards: " ^ msg);
							ignore (LUA.popsubtable state);
							(*card_nr := !card_nr - 1;	(* Reset this, so it's right for looping for next deck *)*)
							[]
					)
				end
			else
				begin
					ignore (LUA.popsubtable state);
					[]
				end
	in
	(** 
       *    Get decks from state. Each deck is a table with name deck1, deck2 ...
       *
       *    @param      state, n
       *    @return     deck list, where deck is < deckname; name; cards; >
       *)
	let rec get_decks' = function 
		| state, n ->
			assert( n > 0);
			let deckname = "deck" ^ (string_of_int (n)) in
			(try
				let state = LUA.getglobal state deckname in     (* Throws LuaException if no @deckname is found *)
				log ("Dumping deck " ^ deckname);
				let (state, name) = LUA.getstring state "name" in
				let cards = get_cards' state in
				log (Printf.sprintf "Cards for %s = %d" deckname (List.length cards));
				let deck = object
					method deckname = deckname
					method name = name
					method cards = cards
				end in
				let state = LUA.poptable state in
				deck :: get_decks' (state, (n + 1)) 
			with
				LuaException msg -> 
					[]
				| ex -> 
					let msg = Printexc.to_string ex in
					log ("Error when dumping decks: " ^ msg);
					[]
			)
		| _ -> failwith "Lua.dump: Complete FAIL"
	in
	let decks = get_decks' (state, 1) in
	let decks_string_list = List.map (fun deck ->
		log (Printf.sprintf "cards for deck %s = %d" deck#deckname (List.length deck#cards));
		let cards = List.map (fun card ->
			Printf.sprintf 
				"\t%s:\n\t\ttitle = %s\n\t\timg = %s\n\t\tonpickup = %s\n" 
				card.c_cardname
				card.c_title
				card.c_img
				card.c_onpickup
		) deck#cards in
		Printf.sprintf 
			"%s:\n\tname = %s\n%s"
			deck#deckname
			deck#name
			(Misc.implode_list cards) 
	) decks in
	Misc.implode_list decks_string_list
      *)

(**
	Call Lua function dump() to dump decks table
*)
let dump s table =
	let s = LUA.getfn s "dump" in
	let s = LUA.getglobal s table in
	let s = LUA.pcall_fn1 s in
	let (s, result) = LUA.fn_getstring s in
	LUA.endstate s;
	result


(**
 *    Dump players from Lua state to string
      Not needed, use dump instead
 *
 *    @param state      LUA.empty t
 *    @return string
 *)
 (*
let dump_players state =
	let rec get_players' = function 
		| state, n ->
			assert( n > 0);
			let player_name = "player" ^ (string_of_int (n)) in
			(try
				let state = LUA.getglobal state player_name in     (* Throws LuaException if no @deckname is found *)
				log ("Dumping player " ^ player_name);
				let (state, name) = LUA.getstring state "name" in
				let player = object
                              method player_name = player_name
					method name = name
					(*method hands = hands*)
				end in
				let state = LUA.poptable state in
				player :: get_players' (state, (n + 1)) 
			with
				LuaException msg -> 
					[]
				| ex -> 
					let msg = Printexc.to_string ex in
					log ("Error when dumping players: " ^ msg);
					[]
			)
		| _ -> failwith "Lua.dump_players: Complete FAIL"
	in
	let players = get_players' (state, 1) in
	let players_string_list = List.map (fun player ->
		Printf.sprintf 
			"%s:\tname = %s\n"
                  player#player_name 
			player#name
	) players in
	Misc.implode_list players_string_list
      *)

(**
	Get decks with cards and scripts etc for a @game_id
	This is the decks that will be pushed into lua state

	@param db 		the db returned by open_db
	@param game_id 	int
	@return		tuple list like so: [(deck record, lua_card list), (...), ...]
*)
let get_decks db game_id =
	let game_has_decks = Game.GameHasDeck.get_game_has_decks db game_id in
	(* Get list of cards for each deck *)
	let decks = List.map (fun game_has_deck ->
		Deck.get_any_deck db game_has_deck.Game.GameHasDeck.deck_id
		) game_has_decks
	in
	let deck_cards = List.map (fun game_has_deck ->
		let query = "
			SELECT
				d.id AS deck_id,
				c.id AS card_id,
				dc.nr,
				IFNULL(chs.onpickup, ''),
				c.title,
				c.text,
				c.img,
				c.sound,
        c.dir,
				IFNULL(chs.onplay, '')
			FROM
				ds_game AS g
				JOIN ds_game_has_deck AS ghd
				JOIN ds_deck AS d ON d.id = ghd.deck_id
				JOIN ds_deck_card AS dc ON dc.deck_id = d.id
				JOIN ds_card AS c ON dc.card_id = c.id
				LEFT JOIN ds_card_has_script AS chs ON chs.card_id = c.id AND chs.game_id = g.id
			WHERE
				g.id = ? AND
				d.id = ?
			GROUP BY
				c.id, d.id
		" in
		let stmt = Db.create_stmt db query in
		let args = [|
			string_of_int game_id; 
			string_of_int game_has_deck.Game.GameHasDeck.deck_id
		|] in
		let result = Db.execute_stmt stmt args in
		let card_of_row row =
			(** Small help function *)
			let get_field n =
				match row.(n) with 
					Some i -> i
					| None -> raise (LuaException (Printf.sprintf "Lua.add_game: Can't find field %d in row for card" n))
			in
			(* Return card record *)
			{
				c_cardname = "";
				c_deck_id = int_of_string (get_field 0);
				c_card_id = int_of_string (get_field 1);
				c_nr = int_of_string (get_field 2);
				c_onpickup = (match row.(3) with
					Some s -> s
					| None -> " function() end");
				c_title = get_field 4;
				c_text = get_field 5;
				c_img = get_field 6;
				c_sound = get_field 7;
                        c_dir = get_field 8;
                        c_onplay = get_field 9;
			}			
		in
		let rows = Db.get_rows result in
		let cards = List.map (fun row ->
			card_of_row row)
		rows in
		Db.close_stmt stmt;
		cards
	) game_has_decks in
	(*log ("Decks fetched = " ^ (string_of_int (List.length decks)));*)
	List.combine decks deck_cards

(**
	Add deck to lua state

	@param state		lua state
	@param deck_with_cards 	tuple (deck record, card objects)
	@param i			deck nr i
	@return			unit
*)
let card_nr2 = ref 1	(* Each card, even cards that are "same"/copies, have a unique number *)
let deck_nr = ref 1	(* Each deck also has a unique number *)
let add_deck state deck_with_cards i =
	let deck_name = "deck" ^ (string_of_int i) in
	(*log ("Adding deck " ^ deck_name); *)
	let s = LUA.newtable state in
	let s = LUA.setstring s ("name", (fst(deck_with_cards)).Deck.name) in
	let s = LUA.setnumber s ("id", (float_of_int (fst(deck_with_cards)).Deck.id)) in
	let s = LUA.setnumber s ("deck_nr", (float_of_int !deck_nr)) in
  let s = LUA.setboolean s ("isdeck", true) in                      (* This is so table_slots can tell cards from decks *)
  let s = LUA.setstring s ("__type", "deck") in                     (* Instead of above *)
	let s = LUA.setglobal s deck_name in
	let card_start_nr = !card_nr2 in	(* add cards to deck.cards from this number *)
	let card_end_nr = ref 0 in	
	List.iter (fun card ->
		for i = 1 to card.c_nr do
			let card_name = "card" ^ (string_of_int !card_nr2) in
			let s = LUA.newtable s in
			let s = LUA.setboolean s ("iscard", true) in           (* This is so table_slots can tell cards from decks *)
			let s = LUA.setstring s ("__type", "card") in          (* This is so table_slots can tell cards from decks *)
			let s = LUA.setnumber s ("deck_id", (float_of_int card.c_deck_id)) in	(* TODO: Not useful, should be deck_nr *)
			let s = LUA.setnumber s ("deck_nr", (float_of_int !deck_nr)) in
			let s = LUA.setnumber s ("id", (float_of_int card.c_card_id)) in	(* Not unique, as in db *)
			let s = LUA.setnumber s ("card_nr", (float_of_int !card_nr2)) in		(* Unique, even for doublets *)
			let s = LUA.setnumber s ("nr", (float_of_int card.c_nr)) in			(* TODO: Needed? Should be "copies". *)
			let s = LUA.setfunc s ("onpickup", card.c_onpickup) in
			let s = LUA.setfunc s ("onplay", card.c_onplay) in
			let s = LUA.setstring s ("title", card.c_title) in
			let s = LUA.setstring s ("text", card.c_text) in
			let s = LUA.setstring s ("img", card.c_img) in
			let s = LUA.setstring s ("sound", card.c_sound) in
			let s = LUA.setstring s ("dir", card.c_dir) in
			let s = LUA.setstring s ("facing", "down") in
			let s = LUA.newsubtable s "position" in       (* TODO: Add support for many hands *)
			let s = LUA.setnumber s ("left", 0.0) in
			let s = LUA.setnumber s ("top", 0.0) in
			let s = LUA.setnumber s ("rotate", 0.0) in
			let s = LUA.setsubtable s in
			let s = LUA.setglobal s card_name in
			(* Create metatable for position *)
			let s = LUA.getglobal s card_name in	(* stack: -1 => card *)
			let s = LUA.getfield s "position" in
			let s = LUA.newtable s in			(* stack: -1 => mt, -2 => position, -3 => card *)
			let s = LUA.setfunc s ("__newindex", "function (t, k, v) error(\"Cannot add new indices to position: \" .. k) end") in
			let s = LUA.setmetatable s in			(* stack: -1 => position, -2 => card *)
			let s = LUA.pop s in
			let s = LUA.pop s in				(* stack: empty *)
			LUA.endstate s;
			card_nr2 := !card_nr2 + 1;
			card_end_nr := !card_nr2;
			()
		done
	) (snd(deck_with_cards));
	(* Add table deck.cards = {cardn, cardn+1, ...} *)
	let rec make_nr_list i =
		if i <= !card_end_nr then
			i :: make_nr_list (i + 1)
		else
			[]
	in
	let nr_list = make_nr_list card_start_nr in
	(*let script = deck_name ^ ".cards = {" ^ (Misc.implode_list (List.mapi (fun i c -> "card" ^ (string_of_int (i + card_start_nr)) ^ ", ") (snd(deck_with_cards)))) ^ "}" in*)
	let script = deck_name ^ ".cards = {" ^ (Misc.implode_list (List.map (fun i -> "card" ^ string_of_int i ^ ", ") nr_list)) ^ "}" in
	let s = LUA.runstring state script ("add cards to " ^ deck_name ^ ".cards") in
	deck_nr := !deck_nr + 1;
	LUA.endstate s

(**
 *    Add a player to Lua state
 *
 *    @param db         db from Db.open()
 *    @param state      lua state
 *    @param user       User.user
 *    @param player_id  int
 *    @return           unit
 *)
let add_player db state user player_id =
      let player_name = "player" ^ (string_of_int player_id) in
      let s = LUA.newtable state in
      let s = LUA.setstring s ("name", (user.User.username)) in
      let s = LUA.setnumber s ("player_id", float_of_int player_id) in
      let s = LUA.setnumber s ("player_nr", float_of_int player_id) in
      let s = LUA.newsubtable s "hand" in       (* TODO: Add support for many hands *)
      let s = LUA.setsubtable s in
      let s = LUA.newsubtable s "slots" in
      let s = LUA.setsubtable s in
      (*let s = LUA.newsubtable s "marked_slots" in
      let s = LUA.setsubtable s in*)
      LUA.endstate (LUA.setglobal s player_name)


(**
	Add a @game to a lua @state
	Game consists of deck with cards.

	@param db 		the db returned by open_db
	@param state	lua state
	@param game		game record
	@return 		unit
*)
let add_game db s game =
	(*let decks_in_game = Deck.*)
	let game_id = Misc.get_opt game.Game.id in
	(* Get tuple list *)
	let decks_with_cards = get_decks db game_id in
	(* Add decks *)
	List.iteri (fun i deck -> add_deck s deck (i + 1)) decks_with_cards;
	(* Add table decks, as decks = {deck1, deck2, ...} *)
	let script = "decks = {" ^ (Misc.implode_list (List.mapi (fun i d -> "deck" ^ (string_of_int (i + 1)) ^ ", ") decks_with_cards)) ^ "}" in
	let s = LUA.runstring s script "add decks table" in
      (* Add table table, representing table slots *)
      let script = "table_slots = {}" in
	let s = LUA.runstring s script "add table_slots table" in
      let script = "cards = {}" in
	let s = LUA.runstring s script "add cards table" in

	LUA.endstate s;
	let s = LUA.to_lua s in

	(* Add ALL cards to cards table, like cards = {card1, card2, card3, ...} *)
	Lua.getglobal s "cards"; 		(* stack: -1 => cards *)

	let rec add_card_to_cards i =
		let card_name = "card" ^ string_of_int i in
		Lua.getglobal s card_name; 		(* stack: -1 => cardN/nil, -2 => cards *)
		if not (Lua.isnil s (-1)) then
			begin
				Lua.rawseti s (-2) i;
				add_card_to_cards (i + 1)
			end
		else
				Lua.pop s 1;		(* stack: -1 => cards, -2 => insert *)
				()
	in
	add_card_to_cards 1;
	Lua.pop s 2;		(* stack: empty *)
	()

(**
	Add online players to lua state

	@param state 	lua state
	@return		unit
*)
(*
let add_players state =
	state
      *)

(**
	Start a lua state game.
	Fetch decks and cards from db and push them into Lua state.

	@param env		environment, like db etc
      @param clients    player_id * user tuple (from clients in lua.ml)
	@return 		lua state
	@raise		A lot of different exceptions
*)
let start env clients =

	(* Reset all globals *)
	card_nr2 := 1;
	deck_nr := 1;

	(* New Lua state *)
  let state = LUA.newstate() in

	(* Add cards, decks, etc *)
	add_game env#db state env#game;

  (* Add players to state *)
  List.iter (fun client -> add_player env#db state (snd(client)) (fst(client))) clients;
	(* Add players table, like players = {player1, player2, ...} *)
	let script = "players = {" ^ (Misc.implode_list (List.mapi (fun i c -> "player" ^ (string_of_int (i + 1)) ^ ", ") clients)) ^ "}" in
	let state = LUA.runstring state script "add players table" in
  state
	(*
	let state = LUA.to_lua state in
      let ts = LuaL.loadbuffer state "local i = 8" "chunkname" in
      let thread_state = Lua.pcall state 0 0 0 in
      match thread_state with
            Lua.LUA_OK -> state
            | err -> 
                        begin
                              let err_msg = Lua.tostring state (-1) in
                              Lua.pop state 1;  (* Why this? *)
                              failwith ("Could not run lua script: " ^ (match err_msg with Some s -> s | None ->
                                    raise Not_found))
                        end
				*)

(**
	Add all common functions to lua state (shuffle etc)

	@param db 		the db returned by open_db
	@param state	lua state
	@param return	unit
*)
let add_common_script db state =
	()

(*
let add_card lua card =
*)
