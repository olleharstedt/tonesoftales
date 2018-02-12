(**
	Controller code for game lobby
*)

open Operation
open Game
open Gamesession

let print = Printf.sprintf;;

let _ =
	(* Some aliases (default module name) *)
	(*let add_op = add_op' "gamesession" in*)
	let add_op_login = add_op_login "gamesession" in
	let add_op_ajax_login = add_op_ajax_login "gamesession" in

	(* Get cards to preload img, in Jingoo template types *)
	let get_preload_imgs args game =
		let open Jg_types in
		let game_has_decks = GameHasDeck.get_game_has_decks args.db (Misc.get_opt game.Game.id) in
		let decks = List.map (fun game_has_deck ->
			Deck.get_any_deck_with_cards args.db game_has_deck.Game.GameHasDeck.deck_id
			) game_has_decks in

		let cards = List.flatten (List.map (fun deck -> deck.Deck.cards) decks) in
		(*let game_owner = (Misc.get_opt (User.get_user_by_id args.db game.Game.user_id)) in*)
		(*Misc.implode_list (List.map (fun card -> "<img src='/drakskatten/upload/" ^ card.Card.dir ^ "/" ^ card.Card.img ^ "' style='display: none;' />") cards)*)
		Tlist (List.map (fun card -> 
			Tobj [
				("dir", Tstr card.Card.dir);
				("img", Tstr card.Card.img);
			])
			cards
		)
	in
		

	(**
		Create lobby HTML, get new port and save it in game_session row.
		Also with Javascript create websocket listener for game session.
	*)
	add_op_login "create_lobby" (fun args user ->
		let user_id = User.get_user_id user in
		(*let game_sessions = list_of_game_session args.db [("user_id", string_of_int user_id)] in*)

		(* Abort if nr session >= 3 for this user *)
		(*
		if List.length game_sessions > 2 then raise (GameSessionException "User can own max three game sessions. Please end your current sessions before creating a new one.");
		*)

		let password = args.cgi#argument_value "password" in
		let public 	= args.cgi#argument_value "public" in
		let comment = args.cgi#argument_value "comment" in
		let game_id = int_of_string (args.cgi#argument_value "game_id") in
		let debug 	= (args.cgi#argument_value "debug") = "on" in
		let own_game = (args.cgi#argument_value "own_game") = "1" in      (* True if session creater owns game *)
		let game 		= if own_game then 
					get_game args.db user_id game_id
		else
					get_public_game args.db game_id
		in
		let preload_imgs = get_preload_imgs args game in

		let query = "CALL new_game_session(?,?,?,?,?,?,@id, @port)" in
		let stmt = Db.create_stmt args.db query in
		let query_args = [|
			string_of_int (User.get_user_id user);
			string_of_int (Misc.get_opt game.Game.id);
			if (password = "") then "" else Db.digest password;
			public;
			comment;
			if debug then "1" else "0";
		|] in
		ignore (Db.execute_stmt stmt query_args);
		Db.close_stmt stmt;
		let session_id = int_of_string (Db.get_stored_out args.db "id") in (* Get results from stored procedure *)
		let port = int_of_string (Db.get_stored_out args.db "port") in

		let open Jg_types in
		let template_string = Jg_template.from_file 
			"/home/d37433/templates/lobby.tmpl" 
			~models:[
				("imgs", preload_imgs);
				("game_name", Tstr game.name);
				("max_players", Tint game.max_players);
				("min_players", Tint game.min_players);
				("addr", Tstr args.addr);
				("port", Tint port);
				("session_id", Tint session_id);
				("use_password", Tbool (password <> ""));
				("debug", Tbool debug);
				("creator", Tbool true);
			] 
		in
		args.echo template_string
	);

	(** Join a lobby *)
	add_op_login "join_lobby" (fun args user ->
		let session_id = int_of_string (args.cgi#argument_value "session_id") in
		(*let user_id = User.get_user_id user in*)
		let game_session = get_game_session args.db session_id in 
		let game = get_any_game args.db game_session.game_id in 
		let preload_imgs = get_preload_imgs args game in

		let open Jg_types in
		let template_string = Jg_template.from_file 
			"/home/d37433/templates/lobby.tmpl" 
			~models:[
				("imgs", preload_imgs);
				("game_name", Tstr game.name);
				("max_players", Tint game.max_players);
				("min_players", Tint game.min_players);
				("addr", Tstr args.addr);
				("port", Tint game_session.port);
				("session_id", Tint session_id);
				("use_password", Tbool (game_session.password <> ""));
				("debug", Tbool false);
				("creator", Tbool false);
			] 
		in
		args.echo template_string;

		(* Find out how many users in lobby *)
		(*let participations = get_participations args.db game_session.id in*)
		
		(*
		let query = "
			IF (SELECT 
				max_players
			FROM
				ds_game AS g
			WHERE
				g.id = ?) 
				>
			(SELECT
				COUNT( * )
			FROM
				ds_participates AS p
			WHERE
				p.game_session_id = ?)
			THEN
				INSERT INTO ds_participates(user_id, game_session_id) VALUES (?,?)
		" in
		let stmt = Db.create_stmt args.db query in
		let args = [|
			string_of_int (Misc.get_opt game.Game.id);
			string_of_int (Misc.get_opt game_session.id);
			string_of_int user_id; 
			string_of_int (Misc.get_opt game_session.id);
			|] in
		let result = Db.execute_stmt stmt args in
		()
		*) 
	);

	(** Search for sessions in lobby state which miss players *)
	add_op_login "session_search" (fun args user ->
		(*
		let query = "
			SELECT
				g.name,
				g.max_players,
				COUNT(p.user_id)
			FROM
				ds_game_session AS gs
				JOIN
				ds_game AS g ON gs.game_id = g.id
				JOIN
				ds_participates AS p ON p.game_session_id = gs.id
			WHERE
				gs.websocket_connected = true
			GROUP BY
				p
			ORDER BY
				gs.created DESC
		" in
		*)
		(* Get all games not started (in lobby) *)
		let game_sessions = list_of_game_session 
			args.db [
				("started", "1900-01-01 00:00:00"); 
				("ended", "1900-01-01 00:00:00");
				("public", "1");
				("websocket_connected", "1");
			]
		in

		(* Get belonging game and user for each game session *)
		(* TODO: Maybe optimize this in special sql query? *)
		let sessions_misc = List.map (fun gs ->
			let game = Game.get_any_game args.db gs.game_id in
			let user = Misc.get_opt (User.get_user_by_id args.db gs.user_id) in
			object
				method game_session = gs
				method game = game
				method user = user
			end
			) game_sessions
		in
		let session_links = List.map (fun o ->
			Printf.sprintf " <a href='drakskatten?op=join_lobby&module=gamesession&session_id=%d'>Game %s created by %s</a><br />"
				(Misc.get_opt o#game_session.id)
				(Game.get_name o#game)
				(User.get_username o#user)
			)
			sessions_misc
		in
		let links_string = List.fold_left (^) "" session_links in
		let links_string = if links_string = "" then "No session found. Start a new one!" else links_string in
		args.echo (Printf.sprintf "
			<fieldset>
				<legend>Search result</legend>
				%s
			</fieldset>
		"
			links_string)
	);

	(* Ajax calls below *)

	(**
		Open up websocket listener for game session
	*)
	add_op_ajax_login "open_new_lobby" (fun args user ->
		(*let port = int_of_string(args.cgi#argument_value "port") in*)
            let game_session_id = int_of_string (args.cgi#argument_value "game_session_id") in
            let game_session = get_game_session args.db game_session_id in
            try
                  let user_id = User.get_user_id user in
                  let game = (try 
                        get_game args.db user_id game_session.game_id                     (* Get owned game *)
                        with 
                              Not_found -> get_public_game args.db game_session.game_id   (* Get public game. TODO: Check a public_game cgi variable instead? *)
                              | ex -> raise ex
                  ) in
                  let game_has_decks = Game.GameHasDeck.get_game_has_decks args.db game_session.game_id in

                  (* Flush output to prevent CGI timeout *)
                  args.echo "\"Ok\"";
                  args.cgi#out_channel#commit_work();
                  args.cgi#out_channel#close_out();

                  (* Environment/state for thread *)
                  let env = object
                        val mutable gs = game_session
                        method db = args.db
                        method addr = args.addr
                        method port = game_session.Gamesession.port
                        method user = user
                        method game = game
                        (*method game_session = game_session*)
                        method get_game_session = game_session
                        method set_game_session game_s = gs <- game_s
                        method game_has_decks = game_has_decks
                  end in

                  (* Start websocket listener *)
                  ignore(Websocket.start_websocket env); 
            with
                  ex ->
												let backtrace = Printexc.get_backtrace () in
                        let msg = Printexc.to_string ex in
                        args.log ("open_new_lobby:" ^ msg);
												args.log ("backtrace: " ^ backtrace);
                        end_game_session args.db game_session

	);

	(** Join quickmatch 
			Can either start a new lobby or join a present one *)
	add_op_login "join_quickmatch" (fun args user ->
		Printexc.record_backtrace true;
		try
			args.log "join_quickmatch\n";

			let game_id = int_of_string (args.cgi#argument_value "game_id") in
			let game = get_public_game args.db game_id in 
			let preload_imgs = get_preload_imgs args game in

			(* Call procedure, joining or starting new session *)
			let query = "CALL join_quickmatch(?,?,@port, @game_session_id, @creator)" in
			let stmt = Db.create_stmt args.db query in
			let query_args = [|
				string_of_int user.User.id;
				string_of_int game_id;
			|] in
			ignore (Db.execute_stmt stmt query_args);
			Db.close_stmt stmt;
			let port = int_of_string (Db.get_stored_out args.db "port") in
			let game_session_id = int_of_string (Db.get_stored_out args.db "game_session_id") in (* Get results from stored procedure *)
			let creator = (Db.get_stored_out args.db "creator") = "1" in

			args.log (print "join_quickmatch: port = %d, game_session_id = %d, creator = %b\n" port game_session_id creator);

			let open Jg_types in
			let template_string = Jg_template.from_file 
				"/home/d37433/templates/lobby.tmpl" 
				~models:[
					("imgs", preload_imgs);
					("game_name", Tstr game.name);
					("max_players", Tint game.max_players);
					("min_players", Tint game.min_players);
					("addr", Tstr args.addr);
					("port", Tint port);
					("session_id", Tint game_session_id);
					("use_password", Tbool false);
					("debug", Tbool false);
					("creator", Tbool creator);
				] 
			in

			args.echo template_string

		with
			ex ->
				let backtrace = Printexc.get_backtrace () in
				let msg = Printexc.to_string ex in
				args.log ("join_quickmatch:" ^ msg ^ backtrace);
	);

	(** Get users waiting in a quickmatch lobby for a specific game *)
	add_op_ajax_login "get_waiting_users" (fun args user ->

		let game_id = args.cgi#argument_value "game_id" in

		(** Get all users waiting in a quickmatch session for this game *)
		let query = "
			SELECT
				u.username
			FROM
				ds_game_session AS gs
				JOIN ds_game AS g ON gs.game_id = g.id
				LEFT JOIN ds_participates AS p ON p.game_session_id = gs.id
				JOIN ds_user AS u ON p.user_id = u.id
			WHERE
				gs.quickmatch = true AND
				gs.started = 0 AND
				gs.ended = 0 AND
				gs.created != 0 AND
				gs.created > DATE_SUB(NOW(), INTERVAL 10 MINUTE) AND	-- Disregard old session
				gs.game_id = ? AND
				(SELECT
					COUNT(*)
				FROM
					ds_participates
				WHERE
					game_session_id = gs.id) < g.max_players
		" in
		let arg = [|game_id|] in
		let stmt = Db.create_stmt args.db query in
		let result = Db.execute_stmt stmt arg in
		let name_of_row row = 
				match row.(0) with Some name -> name | None -> raise Not_found
		in
		let name_list = Db.list_of_result result name_of_row in

		(* Small module for sending waiting result as JSON *)
	  let module Waiter = struct
			type waiter = string list with json

			let get_json name_list = 
				(*let waiters = if List.length name_list = 0 then No_one else Some name_list in*)
				let json = json_of_waiter name_list in
				let json_string = Json_io.string_of_json json in
				json_string

		end in

		let json = Waiter.get_json name_list in
		args.log (print "json: %s" json);

		args.echo json;

		(*args.log ("get_waiting_users: " ^ (List.fold_left (^) "" name_list));*)

	);

	()

;;
