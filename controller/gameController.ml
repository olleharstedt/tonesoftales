(* 
	Game module controller code
*)

open Operation
open Game

let _ =
	(* Some aliases (default module name) *)
	let add_op_login_allow = add_op_login "game" in
	let add_op_login = add_op_login ~allow_guests:false "game" in
	let add_op_ajax_login = add_op_ajax_login ~allow_guests:false "game" in
	let add_op_ajax = add_op_ajax "game" in

      (* Game form *)
      add_op_login 
				"add_game_form"
				(fun args user ->
					args.echo (game_form())
				);

      (* Save new game in db *)
      add_op_login
            "add_game"
            (fun args user ->
							let user_id = (User.get_user_id user) in
							let game = game_of_cgi args.cgi user_id in
							ignore(add_game args.db game user_id);
							(*args.echo ("Game desc = " ^ (Db.decode game.description) ^ "<br>");*)
							args.echo "Game added<br />";
            );

	(* Edit game form *)
	add_op_login
		"edit_game"
		(fun args user ->
			let game_id = int_of_string (args.cgi#argument_value "game_id") in
			let game = get_game args.db (User.get_user_id user) game_id in
			args.echo (edit_game_form game)
		)
	;

	add_op_login
		"save_game"
		(fun args user ->
			let user_id = User.get_user_id user in
			let game_id = int_of_string (args.cgi#argument_value "game_id") in
			let cgi = args.cgi in
			let description = cgi#argument_value "description" in
			let max_players = cgi#argument_value "max_players" in
			let min_players = cgi#argument_value "min_players" in
			let player_slots = int_of_string (cgi#argument_value "player_slots") in
			let table_slots = int_of_string (cgi#argument_value "table_slots") in
			let gadgets = int_of_string (cgi#argument_value "gadgets") in
			let public = cgi#argument_value "public" in
			let game = get_game args.db user_id game_id in
			update_game args.db {game with
				description = description;
				max_players = int_of_string (max_players);
				min_players = int_of_string (min_players);
				player_slots;
				table_slots;
				gadgets;
				public = (public = "1");
			};
			args.echo "Game updated";
		)
	;

	(* Add deck to game form *)
	add_op_login
		"add_deck_to_game_form"
		(fun args user ->
				let user_id = User.get_user_id user in
				args.echo (deck_to_game_form args.db user_id)
		);

	(* Add a deck to a game
	   Deck could be owned by user or be public/final *)
	add_op_login
		"add_deck_to_game"
		(fun args user ->
			let game_id = args.cgi#argument_value "game_id" in
			let deck_id = args.cgi#argument_value "deck_id" in
			let game = get_game args.db (User.get_user_id user) (int_of_string game_id) in 
			let deck = Deck.get_public_deck args.db (int_of_string deck_id) user.User.id in
			add_deck_to_game args.db deck game;
			args.echo "Added deck to game";
		);
	
	(*
		Choose a card for a game and edit its script.
	*)
	add_op_login
		"choose_script_card"
		(fun args user ->
			let user_id = User.get_user_id user in
			args.echo (choose_script_card_form args.db user_id);
		);

	(**
		Edit script for card in game
	*)
	add_op_login "edit_card_script_form" (fun args user ->
		let game_id = int_of_string (args.cgi#argument_value "game_id") in
		let card_id = int_of_string (args.cgi#argument_value "card_id") in
		let game = get_game args.db (User.get_user_id user) game_id in
		let card = Card.get_any_card args.db card_id in
		let card_owner_id = Card.get_user_id card in
		let card_owner = User.get_user_by_id args.db card_owner_id in
            let card_has_script = (try 
                        Some (get_card_has_script args.db (Card.get_id card) (Misc.get_opt game.id))
                  with
                        Not_found -> None) in
		args.echo (edit_card_script_form card game card_owner card_has_script);
	);

      add_op_login "edit_init_script_form" (fun args user ->
            args.echo 
                  (edit_init_script_form args.db 
                        (User.get_user_id user));
            );

	(* Start a new game session *)
	add_op_login_allow "new_game" (fun args user ->
            args.echo "
                  <a href='?op=new_own_game&module=game'>Create session from one of your games<a/><br />
			<a href='?op=search_game&module=game'>Search other games</a><br />
            ";
	);

	(* List own games for session starting *)
	add_op_login "new_own_game" (fun args user ->
		let open Jg_types in
		let games = Game.list_of_games args.db (User.get_user_id user) in
		(*let games_string = List.fold_left (^) "" games_links in*)
		let t_games = Tlist (List.map (fun g -> 
				Tobj [
					("name", Tstr g.name);
					("id", Tint (Misc.get_opt g.id));
				]
			)
			games
		) in

		let template_string = Jg_template.from_file "/home/d37433/templates/new_own_game.tmpl" ~models:[("games", t_games)] in
		args.echo template_string;
		(*
		args.echo (Printf.sprintf "
		"
			games_string);
		*)
	);

	add_op_login_allow "new_other_game" (fun args user ->
		let open Jg_types in
		let game_id = int_of_string (args.cgi#argument_value "game_id") in
		let game = get_public_game args.db game_id in 
		let template_string = Jg_template.from_file 
			"/home/d37433/templates/new_other_game.tmpl" 
			~models:[
				("game_name", Tstr game.name);
				("game_id", Tint (Misc.get_opt game.id));
			] 
		in
		args.echo template_string;
		(*
		args.echo (Printf.sprintf "
			"
			game.name
			(Misc.get_opt game.id)
		);
		*)
	);

	add_op_login "edit_game_choose" (fun args user ->
		let games = Game.list_of_games args.db (User.get_user_id user) in
		let option_of_game game =
			"<option value=" ^ (string_of_int (Misc.get_opt game.id)) ^ " >" ^ game.name ^ "</option>"
		in
		let options = Misc.implode_list (List.map (fun game -> option_of_game game) games) in
		args.echo (Printf.sprintf "
			<fieldset>
				<legend>Choose game to edit</legend>
				<form method=post action=drakskatten>
					<input type=hidden name=op value=edit_game />
					<input type=hidden name=module value=game />
					<p>Game:
					<select name=game_id>%s</select>
					<input type=submit value=Edit />
					</p>
				</form>
			</fieldset>
		"
			options
		);
	);

	(* Choose game to list *)
	add_op_login "list_games_choose" (fun args user ->
		let games = Game.list_of_games args.db (User.get_user_id user) in
		let option_of_game game =
			"<option value=" ^ (string_of_int (Misc.get_opt game.id)) ^ " >" ^ game.name ^ "</option>"
		in
		let options = Misc.implode_list (List.map (fun game -> option_of_game game) games) in
		args.echo (Printf.sprintf "
			<fieldset>
				<legend>Choose game to list</legend>
				<form method=post action=drakskatten>
					<input type=hidden name=op value=list_game />
					<input type=hidden name=module value=game />
					<p>Game: <select name=game_id>%s</select>
					<input type=submit value=List class='button' /> 
					</p>
				</form>
			</fieldset>
		"
			options
		);
	);

	(* List details about own game *)
	add_op_login "list_game" (fun args user ->
		let game_id = int_of_string (args.cgi#argument_value "game_id") in
		(*let game = get_game args.db (User.get_user_id user) game_id in*)
		let decks = Lua.get_decks args.db game_id in
		let table_row_of_card card =
			Printf.sprintf "
				<tr>
					<td></td>
					<td>Card</td>
					<td>%s</td>
				</tr>
				<tr>
					<td></td>
					<td></td>
					<td>onpickup = </td>
					<td>%s</td>
				</tr>" 
				card.Lua.c_title
				card.Lua.c_onpickup
		in
		let table_row_of_deck deck cards =
			Printf.sprintf "<tr><td>Deck</td><td>%s</td></tr>%s"
				deck.Deck.name
				(Misc.implode_list (List.map (fun lua_card -> table_row_of_card lua_card) cards))
		in
		args.echo "<table>";
		args.echo (Misc.implode_list (List.map (fun decks -> table_row_of_deck (fst(decks)) (snd(decks))) decks));
		args.echo "</table>";
		()
	);

	(**
		Search for other users public games
		For now, just list all public games.
	*)
	add_op_login_allow "search_game" (fun args user ->
		let game_list = get_public_games args.db in
		let html = Misc.implode_list 
			(List.map 
				(fun g -> 
					Printf.sprintf 
					"<a href='?op=new_other_game&module=game&game_id=%d'>%s</a><br /><pre>%s</pre><br /><br />" 
					(Misc.get_opt g.id) 
					g.name
					g.description
				) 
				game_list) 
		in
		args.echo "<h2>Games available for play</h2>";
		args.echo html
	);

  (* Ajax ops below *)

	(**
		Saving script for a card and game.
		Ajax.
	*)
	add_op_ajax_login
		"save_card_has_script"
		(fun args user ->
                  let card_id = int_of_string (args.cgi#argument_value "card_id") in
                  let game_id = int_of_string (args.cgi#argument_value "game_id") in
                  (*let card = Card.get_any_card args.db card_id in*)
                  (* Make sure user owns game *)
                  let game = get_game args.db (User.get_user_id user) game_id in
                  let game_id = Misc.get_opt game.id in
                  let card_has_script = Game.card_has_script_of_cgi args.cgi game_id card_id in
                  save_card_has_script args.db card_has_script;
                  args.echo "\"Script saved\"";
		);

      (**
       *    Get init script etc for chosen game.
       *)
      add_op_ajax_login "get_init_script" (fun args user ->
				let game_id = int_of_string (args.cgi#argument_value "game_id") in
				let game = get_game args.db (User.get_user_id user) game_id in
				let game = if game.onplay_all = "" then {game with onplay_all = "function onplay_all(player, card)\nend"} else game in
				let game = if game.onpickup_all = "" then {game with onpickup_all = "function onpickup_all(player, deck)\nend"} else game in
				let game = if game.onbeginturn = "" then {game with onbeginturn = "function onbeginturn(player)\nend"} else game in
				let game = if game.onendturn = "" then {game with onendturn = "function onendturn(player)\nend"} else game in
				let game_json = json_of_game game in
				let json_string = Json_io.string_of_json game_json in
				args.echo json_string;
			);

	(* Get source code for game marked as open source *)
	add_op_ajax "get_opensource" (fun args ->
			let game_id = int_of_string (args.cgi#argument_value "game_id") in
      let game = get_opensource_game args.db game_id in
			let game = if game.onplay_all = "" then {game with onplay_all = "function onplay_all(player, card)\nend"} else game in
			let game = if game.onpickup_all = "" then {game with onpickup_all = "function onpickup_all(player, deck)\nend"} else game in
			let game = if game.onbeginturn = "" then {game with onbeginturn = "function onbeginturn(player)\nend"} else game in
			let game = if game.onendturn = "" then {game with onendturn = "function onendturn(player)\nend"} else game in
			let game_json = json_of_game game in
			let json_string = Json_io.string_of_json game_json in
			args.echo json_string;
	);

	(* Aux; echo decks for a game *)
	let get_game_info args game_id =
		let game_has_decks = GameHasDeck.get_game_has_decks args.db game_id in
		let decks = List.map (fun g -> 
			Deck.get_any_deck args.db g.GameHasDeck.deck_id) game_has_decks in
			
		(* Temporary module for json tuple deck_id * deck_name *)
		let module M = struct
			type t = {deck_id : int; deck_name : string; deck_nr : int} and 
			t_list = t list with json
		end in
		let tuples = List.combine game_has_decks decks in	(* tuple GameHasDeck * Deck *)
		let ms = List.mapi (fun i t -> {
			M.deck_id = (fst(t)).GameHasDeck.deck_id; 
			deck_name = (snd(t)).Deck.name;
			deck_nr = i + 1;		(* TODO: double check *)
		}) tuples in
		let json = M.json_of_t_list ms in
		let json_string = Json_io.string_of_json json in
		args.echo json_string
	in

	add_op_ajax_login
		"get_game_info"
		(fun args user ->
			let game_id = int_of_string (args.cgi#argument_value "game_id") in
			get_game_info args game_id;
		);

	add_op_ajax "get_game_info_opensource" (fun args ->
		let game_id = int_of_string (args.cgi#argument_value "game_id") in
		let game = get_opensource_game args.db game_id in
		get_game_info args (Misc.get_opt game.id)
	);

	(** Save init script for game from editor *)
	add_op_ajax_login "save_init_script" (fun args user ->
		let init_script = args.cgi#argument_value_noescape "init_script" in
		let onplay_all = args.cgi#argument_value_noescape "onplay_all" in
		let onendturn = args.cgi#argument_value_noescape "onendturn" in
		let onbeginturn = args.cgi#argument_value_noescape "onbeginturn" in
		let onpickup_all = args.cgi#argument_value_noescape "onpickup_all" in
		let game_id = int_of_string (args.cgi#argument_value "game_id") in
		let game = get_game args.db (User.get_user_id user) game_id in
		let game = {game with 
			init_script; 
			onplay_all;
			onendturn;
			onbeginturn;
			onpickup_all;
		} in
		update_game args.db game;
		(*
		let query = "
			UPDATE ds_game SET
				init_script = ?,
				onplay_all = ?,
				onendturn = ?,
				onbeginturn = ?,
				onpickup_all = ?
			WHERE
				user_id = ? AND
				id = ?
		" in
		args.log init_script;
		let query_args = [|
			init_script;
			onplay_all;
			onendturn;
			onbeginturn;
			onpickup_all;
			string_of_int user.User.id;
			string_of_int (Misc.get_opt game.id);
		|] in
		let stmt = Db.create_stmt args.db query in
		ignore (Db.execute_stmt stmt query_args);
		Db.close_stmt stmt;
		*)
		args.echo "\"Script saved\"";
	);;
