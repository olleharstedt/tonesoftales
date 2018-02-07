(**
	A deck.
	Belongs to a user.
	Have cards.

	@since 2012-11-25
*)

exception DeckException of string;;

type deck = {
	id : int;
	name : string;
	user_id : int;
	public : bool;
	cards: Card.card list
}

(* Getters *)
let get_name deck = deck.name
let get_id deck = deck.id
let get_cards deck = deck.cards

(**
	Make a deck out of a row from a database result set

	@param row 	Row from a Db.fetch_row
	@return		A deck type object.
	@raise		DeckException if no id, name or user_id is found.
*)
let deck_of_row row =
	try 
	{
		id = (match row.(0) with Some i -> (int_of_string i) | None -> raise (DeckException "No id"));
		name = (match row.(1) with Some n -> n | None -> raise (DeckException "No name"));
		user_id = (match row.(2) with Some ui -> (int_of_string ui) | None -> raise (DeckException "No user id"));
		public = (match row.(3) with Some i -> i = "1" | None -> raise (DeckException "deck_of_row: no public"));
		cards = []
	}
	with Invalid_argument msg -> failwith ("Could not construct deck of row, check your query: " ^ msg);;

(**
	Returns a list of decks for this user

	@return 	A list of all decks belonging to this user.
*)
let list_of_decks db user_id =
	let query = "
		SELECT
			d.id,
			d.name,
			d.user_id,
			d.public
		FROM
			ds_deck AS d
			JOIN ds_user AS u ON d.user_id = u.id
		WHERE
			u.id = ?
		" in
	let args = [|string_of_int user_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let deck_list = Db.list_of_result result deck_of_row in
	Db.close_stmt stmt;
	List.map (fun deck -> 
		{ deck with cards = Card.get_cards db user_id deck.id }
	) deck_list ;;

(**
	Get a list of public/finalized games
*)
let list_of_public_decks db =
	let query = "
		SELECT
			d.id,
			d.name,
			d.user_id,
			d.public
		FROM
			ds_deck AS d
		WHERE
			d.public = true AND
			d.final = true
		" in
	let args = [||] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let deck_list = Db.list_of_result result deck_of_row in
	Db.close_stmt stmt;
	deck_list
;;


(**
	Get deck of this user_id and deck_id.

	@param db		db
	@param user_id 	int
	@param deck_id 	int
	@raise Not_found if no deck was found
*)
let get_deck db user_id deck_id =
	let query = "
		SELECT -- yo yo
			d.id,
			d.name,
			d.user_id,
			d.public
		FROM
			ds_deck AS d
			join ds_user AS u ON d.user_id = u.id
		WHERE
			u.id = ? AND
			d.id = ?
		" in
	let args = [|string_of_int user_id; string_of_int deck_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let row = Db.fetch_row result in
	let deck = (match row with
		None -> raise Not_found
		| Some r -> deck_of_row r) in
	Db.close_stmt stmt;
	{deck with cards = Card.get_cards db user_id deck.id};;

(**
	Get any deck (not user specific)

	@param db 		The db returned by open_db()
	@param deck_id	int
	@return		deck record
	@raise		Not_found?
*)
let get_any_deck db deck_id =
	let query = "
		SELECT -- yo yo
			d.id,
			d.name,
			d.user_id,
			d.public
		FROM
			ds_deck AS d
		WHERE
			d.id = ?
		" in
	let args = [|string_of_int deck_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let row = Db.fetch_row result in
	let deck = (match row with
		None -> raise Not_found
		| Some r -> deck_of_row r) in
	Db.close_stmt stmt;
	deck

(**
	As get_deck, but not specific to user

	@param db 		The db returned by open_db()
	@param deck_id	int
	@return		deck with cards
*)
let get_any_deck_with_cards db deck_id =
	let deck = get_any_deck db deck_id in
	{deck with cards = Card.get_any_cards db deck.id}

(**
	Get deck if its either owned or public (and finalized)
	Used by add_deck_to_game
*)
let get_public_deck db deck_id user_id =
	let query = "
		SELECT -- yo yo
			d.id,
			d.name,
			d.user_id,
			d.public
		FROM
			ds_deck AS d
			JOIN ds_user AS u ON d.user_id = u.id
		WHERE
			d.id = ? AND
			(u.id = ? OR (d.public = true AND d.final = true))
		" in
	let args = [|string_of_int deck_id; string_of_int user_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let row = Db.fetch_row result in
	let deck = (match row with
		None -> raise Not_found
		| Some r -> deck_of_row r) in
	Db.close_stmt stmt;
	deck


(**
	Get all decks by user id, return as a list.

	@param db
	@param user_id	int
	@return		list of decks
*)
(*
let get_decks db user_id =
	let query = "
		SELECT
			d.id,
			d.name,
			d.user_id
		FROM
			ds_deck AS d
			join ds_user AS u ON d.user_id = u.id
		WHERE
			u.id = ? AND
		" in
	let args = [|string_of_int user_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let deck_list = Db.list_of_result result deck_of_row in
	Db.close_stmt stmt;
	deck_list;;
*)

(**
	Html <select> tag of deck
*)
let option_of_deck deck =
	Printf.sprintf "<option value=%i >%s</option>"
		deck.id
		deck.name
	;;

(**
	Returns a table of the deck 
	Should only be used when user is logged in.

	@param login 		login type from user
	@param deck_list	deck list
	@return			string
*)
let html_of_list login deck_list =
	(*if (not login) then raise (DeckException "User must be logged in the view decks");*)
	match login with
		| User.Guest user -> raise (DeckException "Not available for guests")
		|	User.Not_logged_in -> raise (DeckException "User must be logged in to view decks")
		| User.Logged_in _ ->
			let tr_of_deck deck =
				Printf.sprintf "<tr><td>%s</td></tr>" deck.name in
			let trs = List.map tr_of_deck deck_list in
			let trs = List.fold_left (^) "" trs in
			Printf.printf "
				<table>
					%s
				</table>
			" trs;;
(**
	Return html string of deck add form

	@return 	string html
*)
let deck_form () =
	Printf.sprintf "
	<fieldset>
		<legend>Add deck</legend>
		<form method=post action=drakskatten>
			<input type=hidden name=op value=add_deck />
			<input type=hidden name=module value=deck />
			<table>
				<tr>
					<th>Name</th>
					<td><input type=text name=name /></td>
				</tr>
				<tr>
					<td></td>
					<td><input class='button' type=submit value='Create new deck' /></td>
				</tr>
			</table>
		</form>
	</fieldset>
	"

(**
	Edit deck form
*)
let edit_deck_form deck user =
	Printf.sprintf "
	<fieldset>
		<legend>Edit deck</legend>
		<form method=post action=drakskatten>
			<input type=hidden name=op value=save_edit_deck />
			<input type=hidden name=module value=deck />
			<input type=hidden name=deck_id value=%d />
			<table>
				<tr>
					<th>Name</th>
					<td><input type=text readonly value='%s' /></td>
				</tr>
				<tr>
					<th>Public</th>
					<td>
						<select name=public>
						<option value=0>No</option>
						<option value=1>Yes</option>
						</select>
					</td>
				</tr>
				<tr>
					<td></td>
					<td><input class='button' type=submit value='Save changes' /></td>
				</tr>
			</table>
		</form>
	</fieldset>
	"
	deck.id
	deck.name

(**
	Add a new deck to database for this user
	User must be logged in.

	@param db 		The db returned by open_db
	@param login 		login type from user
	@param deck_name	string, name of deck
	@return unit
	@raise			DatabaseException if db goes wrong
*)
let add_deck db login deck_name = match login with
	| User.Guest user -> raise (DeckException "Not available for guests")
	| User.Not_logged_in -> raise (DeckException "User must be logged in to add a deck")
	| User.Logged_in user ->
		begin
			let query = "INSERT INTO ds_deck(name, user_id) VALUES (?, ?)" in
			let args = [|deck_name; (string_of_int (User.get_user_id user))|] in
			let stmt = Db.create_stmt db query in
			ignore (Db.execute_stmt stmt args);
			Db.close_stmt stmt;
		end;;

(**
	Add nr cards to deck

	@param db 		The db returned by open_db
	@param card		Card type, card to add
	@param deck 		Deck type, deck to add card to
	@param nr		Number of card to add to deck
*)
let add_card_deck db card deck nr =
	let query = "INSERT INTO ds_deck_card(card_id, deck_id, nr) VALUES (?,?,?)" in
	let card_id = Card.get_id card in
	let deck_id = deck.id in
	let args = [|string_of_int card_id; string_of_int deck_id; string_of_int nr|] in
	let stmt = Db.create_stmt db query in
	ignore (Db.execute_stmt stmt args);
	Db.close_stmt stmt;;

(**
	Return html of adding card to a deck form
*)
let card_deck_form db user =
	let deck_list = list_of_decks db (User.get_user_id user) in
	let card_list = Card.list_of_cards db (User.get_user_id user) in

	(* Abort if any list is empty *)
	if (deck_list = []) then raise (DeckException "No decks found");
	if (card_list = []) then raise (DeckException "No cards found");

	Printf.sprintf "
	<fieldset>
		<form method=post action=drakskatten>
			<input type=hidden name=op value=add_card_deck />
			<input type=hidden name=module value=deck />
			<table>
				<tr>
					<th>Deck</th>
					<td><select name=deck_id>%s</select>	</td>
				</tr>
				<tr>
					<th>Card</th>
					<td><select name=card_id>%s</select>	</td>
				</tr>
				<tr>
					<th>Copies</th>
					<td><input type=text name=nr maxlength=10 value=1></td>
					<td class='note'>Specify how many copies of this card there will be in the deck.</td>
				</tr>
				<tr>
					<td></td>
					<td><input class='button' type=submit value='Add card to deck' /></td>
				</tr>
			</table>
		</form>
	</fieldset>
	"
		(* Make deck options *)
		(let deck_list = List.map 
			(fun d -> option_of_deck d) 
			deck_list in
		List.fold_left (^) "" deck_list)

		(* Make card options *)
		(let card_list = List.map
			(fun c -> Card.option_of_card c)
			card_list in
		List.fold_left (^) "" card_list)
	;;

(**
	Table row <tr> of deck

	@param deck
	@return 	string/html
*)
let table_row_of_deck deck user =
	let cards = deck.cards in
	let cards_tds = if List.length cards > 0 then
		List.mapi (fun i card -> Card.table_row_of_card card user i) cards
		else
			["<tr><td>&nbsp;</td><td colspan=5>No cards added to this deck</td></tr>"] in
	let cards_tds = List.fold_left (^) "" cards_tds in
	Printf.sprintf "
		<tr>
			<td>%s</td>
			%s
		</tr>
	" deck.name cards_tds;;

(**
	Update deck
*)
let update_deck echo db deck user_id =
	let query = "UPDATE ds_deck SET public=? WHERE id=? AND user_id=?" in
	let args = [|if deck.public then "1" else "0"; string_of_int deck.id; string_of_int user_id|] in
	let stmt = Db.create_stmt db query in
	ignore (Db.execute_stmt stmt args);
	Db.close_stmt stmt
