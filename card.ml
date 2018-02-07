(**
	A card.
	Belongs to one or many decks, and/or a game session.

	@since 2012-11-25
*)

exception CardException of string;;

(**
	The card type
	Corresponding to table ds_card.
	Connected with one or many decks through table ds_deck_card.
*)
type card = {
	id : int;
	title: string;
	text : string;
	img : string;			(* Img name, e.g. myfamily.jpg *)
	img_server : string option;	(* File location of img on server, e.g. /tmp/netcgi234029 *)
	sound : string;
	sound_server : string option;	(* File location of sound on server *)
	dir : string;			(* dir to save uploaded files in, usually username *)
	script : string;
	user_id : int;
	nr : int 			(* Number of cards in the deck (if any) *)
} and
card_list = card list with json;;	(* json-tc syntax extension *)

(* Some getters *)
let get_id card = card.id;;
let get_nr card = card.nr;;
let get_img card = card.img;;
let get_img_server card = match card.img_server with
	Some is -> is
	| None -> raise Not_found;;
let get_sound card = card.sound;;
let get_sound_server card = match card.sound_server with
	Some ss -> ss
	| None -> raise Not_found;;
let get_text card = card.text;;
let get_user_id card = card.user_id;;
let get_title card = card.title;;
let get_text card = card.text;;

(**
	Card form html, to add card
*)
let card_form () =
	let open Jg_types in
	Jg_template.from_file "/home/d37433/templates/card_form.tmpl" 

(**
	Card form html to edit card

	@param card		card to be edited
	@param user		user; owner of card
*)
let edit_card_form card user =
	let open Jg_types in
	Jg_template.from_file "/home/d37433/templates/edit_card.tmpl" 
		~models:[
			("id", Tint card.id);
			("title", Tstr card.title);
			("text", Tstr card.text);
			("username", Tstr user.User.username);
			("img", Tstr card.img);
		]

(**
	Option of card, to be used in html <select> tag.
*)
let option_of_card card =
	let length = String.length card.title in
	let length = if length < 50 then length else 50 in
	Printf.sprintf "<option value=%i >%s</option>"
		card.id
		(String.sub card.title 0 length)
	;;

(**
	Table row <tr> of a card
*)
let table_row_of_card card user i =
	Printf.sprintf "
		<tr>
			<td>&nbsp;</td>
			<td>Title:</td>
			<td>%s</td>
			<td>Text:</td>
			<td>%s</td>
			<td>&nbsp;</td>
			<td>Copies:</td>
			<td>%i</td>
			<td><img style='width: 35px;' src='/drakskatten/upload/%s/%s' /></td>
		</tr>
	" card.title card.text card.nr (User.get_username user) card.img;;

(**
	Make a card out of a POSTed form.
*)
let card_of_cgi (cgi : < argument_value : ?default:string -> string -> string; argument_value_noescape : ?default:string -> string -> string; argument : string -> Netcgi.cgi_argument; .. >) user_id user_name =
	let title = cgi#argument_value "title" in
	
	(* Abort if no text is found *)
	if (title = "") then raise (CardException "No text");

	let img = cgi#argument "img" in
	let img_name = img#filename in 
	let img_server = (match img#store with
		`File fn -> fn
		| `Memory -> raise (CardException "Image not stored in file")) in
	{
		id = -1;	(* Not yet present *)
		title = cgi#argument_value "title";
		text = cgi#argument_value "text";
		img = (match img_name with
			Some fn -> fn
			| None -> "");
		img_server = Some img_server;
		sound = ""; (* TODO *)
		sound_server = None;
		dir = user_name;
		script = cgi#argument_value_noescape "script";
		user_id = user_id;
		nr = 0;
	};;

(**
	Make a card out of a database row from Db.fetch_row

	@param row 	Row from a Db.fetch_row
	@return		A card
	@raise		CardException if id, text or user_id is missing.
*)
let card_of_row row =
	assert(Array.length row > 6);
	try
	{
		id = (match row.(0) with Some i -> (int_of_string i) | None -> raise (CardException "No id"));
		text = (match row.(1) with Some t -> t | None -> raise (CardException "No text"));
		script = ""; 	(* Not set here, fetched from game *)
		img = (match row.(2) with Some i -> i | None -> "");
		img_server = None;
		sound = (match row.(3) with Some s -> s | None -> "");
		sound_server = None;
		user_id = (match row.(4) with Some id -> (int_of_string id) | None -> raise (CardException "No user id"));
		title = (match row.(5) with Some t -> t | None -> raise (CardException "No title found for card"));
		dir = (match row.(6) with Some d -> d | None -> raise (CardException "card_of_row: Found no dir"));
		(* Nr must always be last, field joined from ds_deck_card *)
		nr = (if Array.length row > 7 then
				(match row.(7) with Some nr -> (int_of_string nr) | None -> 0)
			else
				0);
	}
	with
		Invalid_argument msg -> failwith ("Could not construct card of row, check your query: " ^ msg)
		| int_of_string  -> failwith "Could not construct card of row, int_of_string";;

(**
	Upload file to /upload/username dir

	@param file_name	filename
	@param server_file 	File location on server
	@param user		User type
	@return			int, return code
	@raise			CardException if cp command doesn't exit normally.
*)
let upload_file file_name server_file user =
	let open Unix in
	(* Copy file *)
	let command = "cp " ^ server_file ^ " /home/d37433/public_html/drakskatten/upload/" ^ (User.get_username user) ^ "/" ^ file_name in
	(* TODO: Save both results? *)
	(match system command with	(* let result = (match ... *)
		| WEXITED i -> ()
		| WSIGNALED i -> raise (CardException "Could not copy img to upload dir")
		| WSTOPPED i -> raise (CardException "Could not copy img to upload dir")
	);
	(* Change mod to prevent 403 *)
	let command = "chmod 755 /home/d37433/public_html/drakskatten/upload/" ^ (User.get_username user) ^ "/" ^ file_name in
	let result = (match system command with
		| WEXITED i -> i
		| WSIGNALED i -> raise (CardException "Could not change chmod of img file")
		| WSTOPPED i -> raise (CardException "Could not change chmod of img file")) in
	result;;
		

(**
	Add card
*)
let add_card db login card user_id = match login with
	| User.Guest user -> raise (CardException "Not available for guests")
	| User.Not_logged_in -> raise (User.UserException "User must be logged in to create a new card");
	| User.Logged_in user ->
		begin
			let query = "INSERT INTO ds_card(title, text, img, sound, user_id, dir) VALUES(?,?,?,?,?,?)" in
			let args = [|card.title; card.text; card.img; card.sound; (string_of_int user_id); card.dir|] in
			let stmt = Db.create_stmt db query in
			ignore (Db.execute_stmt stmt args);
			Db.close_stmt stmt;
		end;;

(**
	Fetch all cards for this user and return them as a list

	@param db 	The db returned by open_db
	@param user_id	User id
	@return		List of cards
*)
let list_of_cards db user_id =
	let query = "
		SELECT
			c.id,
			c.text,
			c.img,
			c.sound,
			c.user_id,
			c.title,
			c.dir
		FROM
			ds_card AS c
			JOIN ds_user AS u ON c.user_id = u.id
		WHERE
			u.id = ?
		" in
	let args = [|string_of_int user_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let card_list = Db.list_of_result result card_of_row in
	Db.close_stmt stmt;
	card_list;;

(**
	Return list of cards belonging to a specific game.
	The cards, nor the decks, don't have to belong to the user. Only the game does.
	Used to choose card to script for a game.

	@param db 	The db returned by open_db
	@param user_id	int
	@oaram game_id	int
	@return		card list, for this game (which belongs to this user).
*)
let list_of_cards_for_game db user_id game_id =
	let query = "
		SELECT
			c.id,
			c.text,
			c.img,
			c.sound,
			c.user_id,
			c.title,
			c.dir
		FROM
			ds_game AS g
			-- Join game with game_has_deck with deck with deck_has_card with card... See diagram for visualization.
			JOIN ds_user AS u ON u.id = g.user_id
			JOIN ds_game_has_deck AS game_has_deck ON game_has_deck.game_id = g.id
			JOIN ds_deck AS d ON game_has_deck.deck_id = d.id
			JOIN ds_deck_card AS deck_has_card ON deck_has_card.deck_id = d.id
			JOIN ds_card AS c ON deck_has_card.card_id = c.id
		WHERE
			g.user_id = ?	-- User owns the game, not necessarily the cards or decks
			AND g.id = ?
		GROUP BY
			c.id	-- No duplicate cards
		" in
	let args = [|string_of_int user_id; string_of_int game_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let card_list = Db.list_of_result result card_of_row in
	Db.close_stmt stmt;
	card_list;;

(**
	List of cards in json
*)
(*
let json_of_card_list cards = 
	List.map (fun c -> json_of_card c) cards;;	(* json_of_card created by json-tc syntax extension *)
	*)

(**
	Get card of card_id for this user_id.

	@param db
	@param user_id
	@param card_id
	@raise Not_found if no card was found
*)
let get_card db user_id card_id =
	let query = "
		SELECT
			c.id,
			c.text,
			c.img,
			c.sound,
			c.user_id,
			c.title,
			c.dir
		FROM
			ds_card AS c
			JOIN ds_user AS u ON c.user_id = u.id
		WHERE
			u.id = ? AND
			c.id = ?
		" in
	let args = [|string_of_int user_id; string_of_int card_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let row = Db.fetch_row result in
	let card = (match row with
		None -> raise Not_found
		| Some r -> card_of_row r) in
	Db.close_stmt stmt;
	card;;

(**
	Get a card belonging to any user.

	@param db 	The db returned by open_db
	@param card_id	int
*)
let get_any_card db card_id =
	let query = "
		SELECT
			c.id,
			c.text,
			c.img,
			c.sound,
			c.user_id,
			c.title,
			c.dir
		FROM
			ds_card AS c
		WHERE
			c.id = ?
	" in
	let args = [|string_of_int card_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let row = Db.fetch_row result in
	let card = (match row with
		None -> raise Not_found
		| Some r -> card_of_row r) in
	Db.close_stmt stmt;
	card;;

(**
	Get all cards belonging to a deck and user

	@param db
	@param user_id	int
	@param deck_id	int
	@return 	list of cards
*)
let get_cards db user_id deck_id =
	let query = "
		SELECT
			c.id,
			c.text,
			c.img,
			c.sound,
			c.user_id,
			c.title,
			c.dir,
			dc.nr	-- This must be last, because use of card_of_row
		FROM
			ds_deck_card AS dc
			JOIN ds_card AS c ON dc.card_id = c.id
			JOIN ds_user AS u ON u.id = c.user_id	-- Card must have an existing user
		WHERE
			dc.deck_id = ? AND
			c.user_id = ?
		" in
	let args = [|string_of_int deck_id; string_of_int user_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let card_list = Db.list_of_result result card_of_row in
	Db.close_stmt stmt;
	card_list;;

(**
	Get all cards belonging to a user

	@param db 		The db returned by open_db
	@param user_id	int
	@return		card list
*)
let get_all_cards db user_id =
	let query = "
		SELECT
			c.id,
			c.text,
			c.img,
			c.sound,
			c.user_id,
			c.title,
			c.dir,
			dc.nr	-- This must be last, because use of card_of_row
		FROM
			ds_deck_card AS dc
			JOIN ds_card AS c ON dc.card_id = c.id
			JOIN ds_user AS u ON u.id = c.user_id	-- Card must have an existing user
		WHERE
			c.user_id = ?
		" in
	let args = [|string_of_int user_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let card_list = Db.list_of_result result card_of_row in
	Db.close_stmt stmt;
	card_list;;

(**
	As get_cards, but not specific to user

	@param db 		The db returned by open_db
	@param deck_id	int
	@return		card list
*)
let get_any_cards db deck_id =
	let query = "
		SELECT
			c.id,
			c.text,
			c.img,
			c.sound,
			c.user_id,
			c.title,
			c.dir,
			dc.nr	-- This must be last, because use of card_of_row
		FROM
			ds_deck_card AS dc
			JOIN ds_card AS c ON dc.card_id = c.id
			JOIN ds_user AS u ON u.id = c.user_id	-- Card must have an existing user
		WHERE
			dc.deck_id = ?
		" in
	let args = [|string_of_int deck_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let card_list = Db.list_of_result result card_of_row in
	Db.close_stmt stmt;
	card_list

(**
	Update card
	Title cannot be updated (unique for user)

	@param db 		The db returned by open_db
	@param card		card with new values
	@return 		unit
*)
let update_card db card user_id =
	let query = "UPDATE ds_card SET text=?, img=?, sound=? WHERE id = ? AND user_id=?" in
	let args = [|card.text; card.img; card.sound; string_of_int card.id; string_of_int user_id|] in
	let stmt = Db.create_stmt db query in
	ignore (Db.execute_stmt stmt args);
	Db.close_stmt stmt;
