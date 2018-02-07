open Lua_api;;

let _ =
	print_endline "1";;
	let ls = LuaL.newstate () in
	print_endline "2";;
