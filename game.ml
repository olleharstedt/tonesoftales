(**

	Game module

	@since 2013-02-21
	@author Olle Harstedt <olle.harstedt@yahoo.com>

*)

exception GameException of string;;

(**
	A game owned by a player.
	If the game is public, all users can start game sessions with this game.
*)
type game = {
	id : int option;
	user_id : int;
	name : string;
	description : string;
	max_players : int;
	min_players : int;
	(* global_script : string;*)
	public : bool;          (* Whether other players can play this game *)
      hands : int;            (* Nr of hands each player have *)
      player_slots : int;     (* Nr of slots in front of each player *)
	tables: int;		(* Nr of tables *)
      table_slots : int;      (* Nr of slots belonging to each table *)
	init_script : string;	(* The init function run when game session starts (e.g shuffle decks) *)
	onpickup_all : string;  (* Script run on pickup, all cards *)
	onplay_all : string;	(* Script run on play, all cards *)
	onendturn : string;
	onbeginturn : string;
	gadgets : int;
} with json, value, type_of;;

(**
	Script for a card in a game
*)
type card_has_script = {
      game_id : int;
      card_id : int;
	onpickup : string;
	onplay : string;
} with  value, type_of;;

let get_name game = game.name

(**
	Wrapper module for ds_game_has_deck
*)
module GameHasDeck = struct
	type game_has_deck = {
		game_id : int;
		deck_id : int;
		nr : int;
	} and 
	game_has_deck_list = game_has_deck list 
	with json, value, type_of

	(**
		Get all deck ids for a game id

		@param db 		The db returned by open_db
		@param game_id	int
		@return 		game_has_deck list
	*)
	let get_game_has_decks db game_id =
		Db.select_list
			db
			type_of_game_has_deck
			game_has_deck_of_value
			[("game_id", string_of_int game_id)]
end

(*
(* tmp *)
let make_card_has_script = {
      game_id = 2;
      card_id = 6;
      onpickup = "bla bladderi"
};;

(* tmp *)
let make_game = 
      {
            id = None;
            user_id = 13;
            name = "wasda";
            description = "asd";
            max_players = 2;
            min_players = 1;
            init_script = "232";
            public = false;
      };;
*)

(**
 *    Create a game object out of CGI post.
 *
 *    @param cgi        cgi
 *    @param user_id    int
 *    @return game 
 *)
let game_of_cgi (cgi : < argument_value : ?default:string -> string -> string; argument_value_noescape : ?default:string -> string -> string;  .. >) user_id =
	let name = cgi#argument_value "name" in
	let description = cgi#argument_value "description" in
	let min_players = cgi#argument_value "min_players" in
	let max_players = cgi#argument_value "max_players" in
	(*let init_script = cgi#argument_value "init_script" in*)
	let public = cgi#argument_value "public" in
      let player_slots = int_of_string (cgi#argument_value "player_slots") in
      if (player_slots > 20) then raise (GameException "Not more than 20 player slots allowed");
      (*let tables = int_of_string (cgi#argument_value "tables") in*)
      (*if (tables > 20) then raise (GameException "Not more than 20 tables allowed");*)
      let table_slots = int_of_string (cgi#argument_value "table_slots") in
      if (table_slots > 20) then raise (GameException "Not more than 20 table slots allowed");
      (*let hands = int_of_string (cgi#argument_value "hands") in
      if (hands > 20) then raise (GameException "Not more than 20 hands allowed");*)
	let gadgets = int_of_string (cgi#argument_value "gadgets") in
	{
		id = None;
		user_id;
		name;
		description;
		max_players = int_of_string (max_players);
		min_players = int_of_string (min_players);
		init_script = "";
		onpickup_all = "";
		onplay_all = "";
		onbeginturn = "";
		onendturn = "";
		public = (public = "1");
            player_slots = player_slots;
		(*tables = tables;*)
		tables = 1;
            table_slots = table_slots;
            (*hands = hands;*)
		hands = 1;
		gadgets;
	}

(**
*)
let card_has_script_of_cgi (cgi : < argument_value : ?default:string -> string -> string; argument_value_noescape : ?default:string -> string -> string; .. >) game_id card_id=
      (*let onpickup = Netencoding.Html.encode ~in_enc:`Enc_utf8 () (cgi#argument_value "onpickup") in*)
      let onpickup = cgi#argument_value_noescape "onpickup" in
	let onplay = cgi#argument_value_noescape "onplay" in
      {
            game_id = game_id;
            card_id = card_id;
            onpickup = onpickup;
		onplay = onplay;
      }

(**
	Get list of games for this user

	@param db		db
	@param user_id 	int
	@return		game list
*)
let list_of_games db user_id =
      Db.select_list
            db 
            type_of_game
            game_of_value
            [("user_id", string_of_int user_id)]
	
(**
	Get public game, single
	For game search
*)
let get_public_game db game_id =
      Db.select
            db 
            type_of_game
            game_of_value
            [("public", "1"); ("id", string_of_int game_id)]
(**
	Get public games, list
	For game search
*)
let get_public_games db =
      Db.select_list
            db 
            type_of_game
            game_of_value
            [("public", "1")]

(** Get quickmatch games for list on startpage *)
let get_quickmatch db =
	Db.select_list
		db
		type_of_game
		game_of_value
		[("quickmatch", "1")]

(** Return list of open source games *)
let get_opensource db = 
	Db.select_list
		db
		type_of_game
		game_of_value
		[("opensource", "1")]

(** Return one open source game *)
let get_opensource_game db id = 
	Db.select
		db
		type_of_game
		game_of_value
		[("opensource", "1");
		 ("id", string_of_int id);]


(**
	Get game of this user_id and game_id

	@param db		db
	@param user_id 	int
	@param game_id 	int
	@raise 		Not_found if no game was found
*)
let get_game db user_id game_id =
      Db.select 
            db 
            type_of_game
            game_of_value
            [("user_id", string_of_int user_id); ("id", string_of_int game_id)]

(**
	Get any game, without respect to ownership.
*)
let get_any_game db game_id =
      Db.select 
            db 
            type_of_game
            game_of_value
            [("id", string_of_int game_id)]

(**
 *    Updates a game in db
 *
 *    @param db         db from Db.open()
 *    @param game       game
 *    @return           unit
 *)
let update_game db game =
	Db.update
		db
		(value_of_game game)
		[("id", string_of_int (Misc.get_opt game.id))]

(**
 *    Game add form
 *)
let game_form () =
	Jg_template.from_file "/home/d37433/templates/game_form.tmpl" 

(** Edit game form *)
let edit_game_form game =
	let open Jg_types in
	let models = [
		("game_id", Tint (Misc.get_opt game.id));
		("name", Tstr game.name);
		("description", Tstr game.description);
		("max_players", Tint game.max_players);
		("min_players", Tint game.min_players);
		("player_slots", Tint game.player_slots);
		("table_slots", Tint game.table_slots);
		("gadgets", Tint game.gadgets);
		("public", Tint (if game.public then 1 else 0));
	] in
	Jg_template.from_file "/home/d37433/templates/edit_game.tmpl" ~models:models

(**
	Html <select> tag of game
*)
let option_of_game game =
	Printf.sprintf "<option value=%i >%s</option>"
		(Misc.get_opt game.id)
		game.name
	;;

(**
	Form for adding decks to games
*)
let deck_to_game_form db user_id =
	let deck_list = Deck.list_of_decks db user_id in
	let public_deck_list = Deck.list_of_public_decks db in
	let game_list = list_of_games db user_id in

	if (game_list = []) then raise (GameException "deck_to_game_form: No games found");

	let deck_options = (let deck_list = List.map 
			(fun d -> Deck.option_of_deck d) 
			deck_list in
		List.fold_left (^) "" deck_list)
	in
	let public_deck_options = 
		(let deck_list = List.map 
			(fun d -> Deck.option_of_deck d) 
			public_deck_list in
		List.fold_left (^) "" deck_list)
	in
	let game_options = 
		(let game_list = List.map
			(fun c -> option_of_game c)
			game_list in
		List.fold_left (^) "" game_list)
	in

	Printf.sprintf "
	<fieldset>
		<legend>Add deck to game</legend>
		<p>A game can have many decks. In the Lua environment, they will be named deck1, deck2 etc. More info about this will be apparent in the debugging info. A game can include both your own decks, and decks other users have made public, like the standard deck.</p>
		<form method=post action=drakskatten>
			<input type=hidden name=op value=add_deck_to_game />
			<input type=hidden name=module value=game />
			<table>
				<tr>
					<th>Deck</th>
					<td><select name=deck_id>%s</select>	</td>
				</tr>
				<tr>
					<th>Game</th>
					<td><select name=game_id>%s</select>	</td>
				</tr>
				<tr>
					<td></td>
					<td><input class='button' type=submit value='Add deck to game' /></td>
				</tr>
			</table>
		</form>
	</fieldset>
	<br />
	<fieldset>
		<legend>Add public deck to game</legend>
		<p>A public deck is a deck created by another user that you can use for your games.</p>
		<form method=post action=drakskatten>
			<input type=hidden name=op value=add_deck_to_game />
			<input type=hidden name=module value=game />
			<table>
				<tr>
					<th>Deck</th>
					<td><select name=deck_id>%s</select>	</td>
				</tr>
				<tr>
					<th>Game</th>
					<td><select name=game_id>%s</select>	</td>
				</tr>
				<tr>
					<td></td>
					<td><input class='button' type=submit value='Add deck to game' /></td>
				</tr>
			</table>
		</form>
	</fieldset>
	"
		deck_options
		game_options

		public_deck_options
		game_options
	;;

(**
	Form to choose game and card to script.
*)
let choose_script_card_form db user_id =
	let game_list = list_of_games db user_id in
	if (game_list = []) then raise (GameException "deck_to_game_form: No games found");

	Printf.sprintf "
		<fieldset>
			<legend>Choose game and card</legend>
			<form method=post action=drakskatten>
				<input type=hidden name=op value=edit_card_script_form />
				<input type=hidden name=module value=game />
				<p>A cards script is unique for the game it belongs to. Choose first game, then card, then press 'Edit script'</p>
				Game:<select name=game_id onchange='choosegame();' id=game_select /><option value='-1'>Choose</option>%s</select>
				Card:<select name=card_id id=card_select ></select>
				<input id='submit' type=submit value='Edit script for this card' style='display: none;' />
			<form>
		</fieldset>
	"
		(* Make game options *)
		(let game_list = List.map (fun c -> option_of_game c) game_list in
			List.fold_left (^) "" game_list)
	;;

(**
	Form to edit script for card

	@param card		card
	@param game		game
	@param card_owner	user
	@return		string/html
*)
let edit_card_script_form card game card_owner card_has_script =
	Printf.sprintf "
		<fieldset>
			<legend>Edit card script for game %s</legend>
			<form method=post action=drakskatten>
				<input type=hidden name=op value=save_card_has_script />
				<input type=hidden name=module value=game />
				<input type=hidden name=card_id value='%d' />
				<input type=hidden name=game_id value='%d' />
				<h3>Card information</h3>
				Card title:<input type=text name=card_title value='%s' readonly /><br />
				Card text:<textarea cols=50 rows=8 name=card_text readonly>%s</textarea><br />
				<h3>Events</h3>
				onpickup:<textarea id=editor name=onpickup cols=50 rows=8>%s</textarea><br />
				onplay:<textarea id=editor2 name=onplay cols=50 rows=8>%s</textarea><br />
				<input type=button value='Save script' onclick='save_card_has_script();'/><br />
			</form>
		</fieldset>
	"
		game.name
		(Card.get_id card)
		(Misc.get_opt game.id)
		(Card.get_title card)
		(Card.get_text card)
            (match card_has_script with Some c -> c.onpickup | None -> "function(player, deck)\nend")
            (match card_has_script with Some c -> c.onplay | None -> "function(player, card)\nend")
	;;

(**
 *    Form to edit init script for game
 *
 *    @param db         db from Db.open()
 *    @param user_id    int
 *    @return           string/html
 *)
let edit_init_script_form db user_id =
      let games = list_of_games db user_id in
      let game_options = List.map (fun game -> 
            "<option selected value=" ^ (string_of_int (Misc.get_opt game.id)) ^ ">" ^ game.name ^ "</option>") 
            games in
      let game_options_string = "<option value=-1>Choose game</option>" ^ (Misc.implode_list game_options) in
      Printf.sprintf "
            <fieldset>
							<legend>Edit script</legend>
                  <p>The initialization script is run when a game session is
                  started. Use this to put global function used by card events,
                  or global variables. See tutorials for more
                  information.</p>
			<p>Press F11 when editing to enter fullscreen mode. Press F11 or Esc to exit.</p>
			<p>Press Ctrl-S to save the script. Do this often. There is also a save button at the bottom of the page.</p>
			<p>Press Ctrl-F to search for a string, and Ctrl-G to find next occurance.</p>
			<div id=left style='float: left; width: 500px'>
				<form id=init_script_form>
					<input type=hidden name=op value=save_init_script />
					<input type=hidden name=module value=game />
					<select name=game_id id=game_select
					onchange='choose_init_script_game();' >%s</select><input
	type=button value='Load' onclick='choose_init_script_game();'> <br />
					init_script:<textarea id=editor name=init_script ></textarea><br />
					<p>onplay_all is run for <i>every</i> card in the game when it's being played.</p>
					onplay_all:<textarea id=editor2 name=onplay_all ></textarea><br />
					<p>onpickup_all is run for every card in the game when it's being picked up.</p>
					onpickup_all:<textarea id=editor5 name=onpickup_all ></textarea><br />
					<p>onendturn is run when the turn ends, for the ending player.</p>
					onendturn:<textarea id=editor3 name=onendturn></textarea><br />
					<p>onbeginturn is run for the new players turn.</p>
					onbeginturn:<textarea id=editor4 name=onbeginturn></textarea><br />
					<input type=button onclick='save_init_script();' value='Save script' />
				</form>
			</div>
			<div id=right style='float: left; width: 500px; margin-left: 20px;'>
				<p>More info here</p>
			</div>
            </fieldset>
		<script>
			$(document).ready(function() {
				choose_init_script_game();
				codemirror.setSize(700, 500);
				codemirror2.setSize(700, 500);
				codemirror3.setSize(700, 500);
				codemirror4.setSize(700, 500);
				codemirror5.setSize(700, 500);
			});
		</script>
      "
            game_options_string
      ;;

(**
	Get script for card for a game

	@param db 		The db returned by open_db
	@param card_id	int
	@param game_id	int
      @return           card_script option
*)
let get_card_has_script db card_id game_id =
      Db.select 
            db 
            type_of_card_has_script
            card_has_script_of_value
            [("card_id", string_of_int card_id); ("game_id", string_of_int game_id)]

(**
	Save or updates script

	@param db 		The db returned by open_db
	@param card_has_script	record
	@param card_id	int
	@param game_id	int
	@return		unit
*)
let save_card_has_script db card_has_script =
	try 
		begin 
			ignore (Db.select
				db
				type_of_card_has_script
				card_has_script_of_value
				[
					("card_id", string_of_int card_has_script.card_id);
					("game_id", string_of_int card_has_script.game_id);
				]
			);
			(* If no exception is raised, go on with update *)
			Db.update
				db
				(value_of_card_has_script card_has_script)
				[
					("game_id", string_of_int card_has_script.game_id);
					("card_id", string_of_int card_has_script.card_id);
				]
		end
	with 
		Not_found ->
			(* Old value not found, save new *)
			ignore (Db.insert
				db
				(value_of_card_has_script card_has_script))


	

(**
 *    Add game to database for this user
 *    This is only time game record should have id = None
 *
 *    @param db
 *    @param game       game
 *    @param user_id    int
 *)
let add_game db game user_id =
      assert(game.id = None);
      Db.insert db (value_of_game game)

(**
	Add deck to game

	@param db 		The db returned by open_db
	@param deck 	deck
	@param game		game
	@return		unit
*)
let add_deck_to_game db deck game =
	let query = "INSERT INTO ds_game_has_deck(game_id, deck_id) VALUES (?,?)" in
	let deck_id = Deck.get_id deck in
	let args = [|string_of_int (Misc.get_opt game.id); string_of_int deck_id|] in
	let stmt = Db.create_stmt db query in
	ignore (Db.execute_stmt stmt args);
	Db.close_stmt stmt;;

