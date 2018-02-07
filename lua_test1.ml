(*
 *    Test Lua API for drakskatten card page
 *
 *    We want to be able to run a script for each card when that card is played.
 *
 *    
 *
 *    @since 2013-02-04
 *    @author Olle Harstedt
 *)
open Lua_api;;

type stack_top = Table | Nil

type lua_state = State of string * stack_top

let i = ref 0

let get_opt opt = function 
	Some v -> v
	| None -> raise Not_found

let _ =
      let state = LuaL.newstate() in
      LuaL.openlibs state;
      print_endline "1";

	Lua.pushcfunction state (fun state ->
		i := !i + 1;
		0	(* Number of results *)
	);
	Lua.setglobal state "end_turn";
      
      (* Push a global variabel into the Lua state *)
      Lua.pushnumber state 13.3;
      Lua.setglobal state "testval";

      (* Push string to Lua state *)
      Lua.pushstring state "hello world";
      Lua.setglobal state "teststring";

      (* Push table to Lua state, like player1 = {life = 50, magic = 40} *)
      let setfield index value = 
            Lua.pushstring state index;
            Lua.pushnumber state value;
            Lua.settable state (-3);
      in

	(**
		Assuming table is on top of stack
	*)
	let set_string index value =
            Lua.pushstring state index;
            Lua.pushstring state value;
            Lua.settable state (-3);
	in

      (* Push function in table to Lua, like player1 = {onpickup = function () do_something end } *)
      let setfunc index func_string =
            Lua.pushstring state index;
            LuaL.loadstring state func_string;
            Lua.pcall state 0 1 0;
            Lua.settable state (-3);
      in

	(**
		Assuming table is on top of stack

	*)
	let get_float state key =
		let field = Lua.getfield state (-1) key in
		if not (Lua.isnumber state (-1)) then
			failwith ("Not number in table field " ^ key);
		let n = Lua.tonumber state (-1) in
		Lua.pop state 1;
		n
	in

	(**
		Assuming table is on top of stack
	*)
	let get_string state key =
		let field = Lua.getfield state (-1) key in
		if not (Lua.isstring state (-1)) then
			failwith ("Not string in table field " ^ key);
		match Lua.tostring state (-1) with
			Some s -> 
				Lua.pop state 1;
				s
			| None -> 
				Lua.pop state 1;
				failwith ("Found no string in table field " ^ key)
	in

	(** 
		Test define function from OCaml, with table as argument
	*)
	Lua.pushcfunction state (fun s' ->
            let arg1 = (try int_of_float (Lua_api.LuaL.checknumber s' 1) with _ -> -1) in
		(try Lua_api.LuaL.checktype s' 2 Lua_api_lib.LUA_TTABLE with _ -> 
			print_endline "fn2: arg2 not a table"
		);
		print_endline (Printf.sprintf "arg1 = %d" arg1);
		Lua.getfield s' (2) "card_nr";
		(*Lua.rawgeti s' (2) 3;*)
		let arg2_2 = Lua.tonumber s' (-1) in
		print_endline (Printf.sprintf "arg2[2] = %f" arg2_2);
		0
	);
	Lua.setglobal state "fn2";


	(* Add table player1 *)
      Lua.newtable state;
      setfield "life" 50.;
      setfield "magic" 40.;
	set_string "test" "bla bla";
      setfunc "func" "return function() print('hej') end";
	Lua.pushstring state "subtable";
	Lua.newtable state;
	set_string "asd" "hello subtable";
	Lua.settable state (-3);
      Lua.setglobal state "player1";

      let ts = LuaL.loadbuffer state "
		local i = 8; 
		print(teststring); 
		print(player1.life); 
		player1.func();
		decks = {
			deck1 = {1, 2, 3},
			deck2 = {4, 5, 6}
		};
		function tablelength(t)
			local count = 0
		    	for _ in pairs(t) do count = count + 1 end
			return count
		end
            function fn()
                  print(\"fn\")
            end
		fn2(333, {bla = 12, card_nr = 13})
		print(tablelength(decks))
		print(player1.subtable.asd)
		end_turn()
		end_turn()
		arr = {'a', 'b', 'c'}
	" "chunkname" in

      (* Run Lua state and check for errors *)
      let thread_state = Lua.pcall state 0 0 0 in
      (match thread_state with
            Lua.LUA_OK -> ()
            | err -> 
			let err_msg = Lua.tostring state (-1) in
			Lua.pop state 1;  (* Pop message from stack *)
			failwith ("bla " ^ (match err_msg with Some s -> s | None ->
				raise Not_found))
	);

	(* Test array insertal and removal *)
	(* Lua.getglobal state "arr";*)

      (* Calling Lua from OCaml *)
      Lua.getglobal state "fn";
      let thread_state = Lua.pcall state 0 0 0 in
      (match thread_state with
            Lua.LUA_OK -> ()
            | err -> 
                        begin
                              let err_msg = Lua.tostring state (-1) in
                              Lua.pop state 1;  (* Pop message from stack *)
                              failwith (match err_msg with Some s -> s | None ->
                                    raise Not_found)
                        end);

	Lua.getglobal state "player1";
	(if Lua.istable state (-1) then
		print_endline "is table"
	else
		print_endline "not table");

	let life = get_float state "life" in
	print_endline ("life = " ^ string_of_float life);

	let test = get_string state "test" in
	print_endline ("test = " ^ test);

	(* Put subtable on stack *)
	let field = Lua.getfield state (-1) "subtable" in
	let subtable_asd = get_string state "asd" in
	print_endline ("subtable.asd = " ^ subtable_asd);
	Lua.pop state 1;  (* Pop subtable from stack *)

	Unix.sleep 1;

	print_endline ("i = " ^ (string_of_int !i));


()
