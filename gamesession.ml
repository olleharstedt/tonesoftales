(**
	Game session code

	@since 2013-03-11
*)

exception GameSessionException of string;;

type game_session = {
	id : int option;
	user_id : int;			(* Session owner *)
	game_id : int;			(* Game *)
	password : string;
	public : bool;			(* Public for all users online *)
	port : int;				(* Port for websocket *)
	comment : string;
	created : string;			(* When lobby was created *)
	started : string option;	(* When game started *)
	ended : string option;		(* When it ended *)
	debug : bool;			(* Wether this session supports degub operations like dumping lua state etc *)
	websocket_connected : bool;
} with value, type_of

(**
	Returns a valid port number to use for websocket server, from table ds_game_session.
	Not used. Using stored procedure instead, for atomicity.

	@param db 		The db returned by open_db()
	@return		int, new port number
*)
(*
let get_new_port db =
	try 
		let game_session = 
			Db.select 
				db
				type_of_game_session
				game_session_of_value
				[]
				~extras:"ORDER BY created DESC LIMIT 1"
		in
		if game_session.port > 999999 (* Highest port *) then 8080 else game_session.port + 1
	with
		(* No session found? Return standard port 8080 *)
		Not_found -> 8080
		*)

(**
	Inserts a game session in db

	@param db 			The db returned by open_db()
	@param game_session 	game_session record
*)
let add_game_session db game_session =
	Db.insert
		db
		(value_of_game_session game_session)

(**
	Delete game session from db and exit CGI
	Never do this.

	@param db 		The db returned by open_db()
	@id			int; game session id
*)
(*
let delete_game_session db id = 
	(*Lwt_io.eprintl ("delete game session with port " ^ (string_of_int port));*)
	let query = "DELETE FROM ds_game_session WHERE id = ?" in
	let args' = [|string_of_int port|] in
	let stmt = Db.create_stmt db query in
	(try
		ignore(Db.execute_stmt stmt args');
	with _ -> 
		begin
			(* This should definitely not happen... *)
			ignore (Lwt_io.eprintl ("Game session: Could not delete session with port " ^ (string_of_int port)));
			exit 1;
		end);
	exit 0
	*)

(**
	Get a game session record

	@param db 		The db returned by open_db()
	@param session_id	int; game session id
	@return		game session record
*)
let get_game_session db session_id =
	Db.select
		db
		type_of_game_session
		game_session_of_value
		[("id", string_of_int session_id)]

(**
	Set end datetime for @session to now

	@param db 		The db returned by open_db()
	@param session	game session record
	@return		unit
*)
let end_game_session db session =
	(*
	let ended_session = {
		session with ended = Some (Misc.get_datetime())
	} in
	Db.update
		db
		(value_of_game_session ended_session)
		[("id", string_of_int (Misc.get_opt ended_session.id))]
	*)
	let query = "UPDATE ds_game_session SET ended=? WHERE id=?" in
	let args = [|Misc.get_datetime(); string_of_int (Misc.get_opt session.id)|] in
	let stmt = Db.create_stmt db query in
	ignore (Db.execute_stmt stmt args);
	Db.close_stmt stmt
	
(**
	Set start datetime for @session to now

	@param db 		The db returned by open_db()
	@param session	game session record
	@return		unit
*)
let start_game_session db session =
	let query = "UPDATE ds_game_session SET started=? WHERE id=?" in
	let args = [|Misc.get_datetime (); string_of_int (Misc.get_opt session.id)|] in
	let stmt = Db.create_stmt db query in
	ignore (Db.execute_stmt stmt args);
	Db.close_stmt stmt

	(*
	let started_session = {
		session with started = Some (Misc.get_datetime())
	} in
	Db.update
		db
		(value_of_game_session started_session)
		[("id", string_of_int (Misc.get_opt started_session.id))];
	started_session
	*)

(** Update game session *)
(*
let update_game_session db game_session =
	Db.update
		db
		(value_of_game_session game_session)
		[("id", string_of_int (Misc.get_opt game_session.id))]
;;
*)

let websocket_connected db ses =
	let query = "UPDATE ds_game_session SET websocket_connected = true WHERE id=?" in
	let args = [|string_of_int (Misc.get_opt ses.id)|] in
	let stmt = Db.create_stmt db query in
	ignore (Db.execute_stmt stmt args);
	Db.close_stmt stmt

(**
	Return all game sessions for this @search_param

	@param db 			The db returned by open_db()
	@param search_param	List of tuples, like [("id", "23"); ...]
	@return			game_session list
*)
let list_of_game_session db search_param =
	Db.select_list
		db 
		type_of_game_session
		game_session_of_value
		search_param
