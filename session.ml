(**
	Game session for card deck.
	Represented as a session table and card-session relation.

	@since 2012-11-25
	@author Olle Harstedt
*)

exception SessionException of string;;
exception NoCardsLeftException;;

type session = {
	deck_id : int;
	user_id : int;
	id : int;
	datetime : string;
	deck : Deck.deck;	(* Same as deck, but nr in cards corresponds to cards left after draw. *)
};;

(**
	Start a session of type ? for this user.

	@param db
	@param deck	deck type
	@param user_id	int
	@raise		db exception?
	@return		session_id

*)
let start_session db deck user_id =

	(* Create session head in db *)
	let query = "INSERT INTO ds_session(deck_id, datetime, user_id) VALUES(?,?,?)" in
	let args = [|string_of_int(Deck.get_id deck); Misc.get_datetime(); string_of_int(user_id)|] in
	let stmt = Db.create_stmt db query in
	ignore(Db.execute_stmt stmt args);
	let session_id = Db.insert_id stmt in
	Db.close_stmt stmt;

	(* Create a card entry for every card in deck *)
	List.iter (fun card ->
		let query = "INSERT INTO ds_session_card(session_id, card_id, nr) VALUES(?,?,?)" in
		let args = [|Int64.to_string session_id; string_of_int(Card.get_id card);string_of_int(Card.get_nr card)|] in
		let stmt = Db.create_stmt db query in
		ignore (Db.execute_stmt stmt args);
		Db.close_stmt stmt;
		) (Deck.get_cards deck);
	session_id;;

(**
	Get session specific deck, with nr drawn.

	@param db
	@param user_id		int
	@param session_id	int
	@return			deck type
*)
let get_session_deck db user_id deck_id session_id =
	let tmp_deck = Deck.get_deck db user_id deck_id in
	(* Open deck module so we can use deck type *)
	let open Deck in
	(* Return a deck with updated cards *)
	{tmp_deck with cards = List.map (fun card ->
		let query = "
			SELECT
				nr
			FROM
				ds_session_card
			WHERE
				session_id = ? AND
				card_id = ?
		" in
		let args = [|string_of_int session_id; string_of_int (Card.get_id card)|] in
		let stmt = Db.create_stmt db query in
		let result = Db.execute_stmt stmt args in
		let row = (match (Db.fetch_row result) with Some row -> row | None -> raise (SessionException "Found no row for session_card")) in
		(* Open card module so we can use card type *)
		let open Card in
		(* Return card with updated nr *)
		let card = {card with nr = (match row.(0) with Some nr -> int_of_string nr | None -> raise (SessionException "Found no nr for session_card"))} in
		Db.close_stmt stmt;
		card) (get_cards tmp_deck)
	};;


(**
	Get a session from a row from a db result

	@param row
	@return session type
*)
let session_of_row db row =
	try
		
		let deck_id = (match row.(0) with Some d_id -> int_of_string d_id | None -> raise (SessionException "Found no deck id of session")) in
		let user_id = (match row.(1) with Some u_id -> int_of_string u_id | None -> raise (SessionException "Found no user_id of session")) in
		let id = (match row.(2) with Some id -> int_of_string id | None -> raise (SessionException "Found no id of session")) in
		{
			deck_id = deck_id;
			user_id = user_id;
			id = id;
			datetime = (match row.(1) with Some dt -> dt | None -> raise (SessionException "Found no datetime of session"));
			deck = get_session_deck db user_id deck_id id;
		}
	with Invalid_argument msg -> failwith ("Could not construct session of row, check your query: " ^ msg);;

(**
	Get session for this session

	@param db
	@param session_id	int
	@param user_id		int
	@raise 			Not_found if no session is found for this user.
*)
let get_session db session_id user_id =
	let query = "
		SELECT
			deck_id,
			user_id,
			id,
			datetime
		FROM
			ds_session
		WHERE
			id = ? AND
			user_id = ?
	" in
	let args = [|string_of_int session_id; string_of_int user_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let row = Db.fetch_row result in
	Db.close_stmt stmt;
	let session = session_of_row db (match row with 
		Some row -> row
		| None -> raise Not_found) in
	session;;

(**
	Delete a session from db

	@param session_id	Id of session to delete
	@return			unit
	@raise			Possibly db error
*)
let delete db session =
	(* Delete session cards *)
	let query = "DELETE FROM ds_session_card WHERE session_id = ?" in
	let args = [|string_of_int session.id|] in
	let stmt = Db.create_stmt db query in
	ignore (Db.execute_stmt stmt args);
	Db.close_stmt stmt;

	(* Delete session head *)
	let query = "DELETE FROM ds_session WHERE id = ?" in
	let stmt = Db.create_stmt db query in
	ignore (Db.execute_stmt stmt args);
	Db.close_stmt stmt;;

(**
	Draw a random card from this session deck, return the card and the session with card drawn.
	Also modify session in db to changes.

	@param db 
	@param session	Session type, from get_session
	@raise		?
	@return		card * session, drawn card and modified session.
*)
let draw_random_card db session =
	Random.self_init();
	(* Calculate total cards left *)
	let cards = Deck.get_cards session.deck in
	let nr_list = List.map (fun card -> Card.get_nr card) cards in
	let cards_left_in_deck = List.fold_left (+) 0 nr_list in

	(* Abort if there is no cards left *)
	if cards_left_in_deck = 0 then raise NoCardsLeftException;

	let random = Random.int cards_left_in_deck in

	(* Little recursive helper function to draw card *)
	let rec draw_card' cards rand = match cards with
		| [] -> raise (SessionException "No cards?")	(* Should not happen *)
		| card::[] -> card	(* Only one card left to chose from, so pick this *)
		| card::cards -> 
			let open Card in 
			if rand - card.nr < 0 then 
				card 
			else 
				(draw_card' cards (rand - card.nr))
		in

	(* Get drawn card *)
	let drawn_card = draw_card' cards random in

	(* Decrease value in db *)
	let query = "UPDATE ds_session_card SET nr = nr - 1 WHERE card_id = ? AND session_id = ?" in
	let args = [|string_of_int (Card.get_id drawn_card); string_of_int session.id|] in
	let stmt = Db.create_stmt db query in
	ignore (Db.execute_stmt stmt args);
	Db.close_stmt stmt;

	(* Construct a new session from old session but with card drawn *)
	let new_cards = List.map (fun card -> 
		let open Card in
		if card.id = drawn_card.id then 
			{card with nr = (card.nr - 1)} 
		else 
			card) cards in

	let open Deck in
	let new_deck = {session.deck with cards = new_cards} in
	
	(* Return tuple *)
	(drawn_card, {session with deck = new_deck});;



