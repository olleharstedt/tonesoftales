(**
	Controller code for deck ops

	@since 2013-02-26
*)
open Operation
open Deck

let _ =
	(* Short hand *)
	let add_op_login = add_op_login ~allow_guests:false "deck" in

	(* User form *)
	add_op_login "add_deck_form" (fun args user -> 
		args.echo (deck_form()));

	(**
		Choose which deck to edit
	*)
	add_op_login "edit_deck_choose" (fun args user ->
		let decks = list_of_decks args.db user.User.id in
		let deck_option_list = List.map (fun deck ->
			Printf.sprintf "<option value=%d>%s</option>"
				deck.id
				deck.name
		) decks in
		let deck_options = Misc.implode_list deck_option_list in
		args.echo (Printf.sprintf "
			<form method=post action=drakskatten>
				<input type=hidden name=module value=deck />
				<input type=hidden name=op value=edit_deck_form />
				Select deck:<select name=deck_id>%s</select>
				<input type=submit value='Edit deck' />
			</form>
		"
			deck_options
		)
	);

	(* Edit deck form *)
	add_op_login "edit_deck_form" (fun args user ->
		let deck_id = int_of_string (args.cgi#argument_value "deck_id") in
		let deck = get_deck args.db (User.get_user_id user) deck_id in
		args.echo (edit_deck_form deck user)
	);

	(* Save deck that has been edited *)
	add_op_login "save_edit_deck" (fun args user ->
		let deck_id = int_of_string (args.cgi#argument_value "deck_id") in
		let public = ((args.cgi#argument_value "public") = "1") in
		let deck = get_deck args.db (User.get_user_id user) deck_id in
		let new_deck = {
			deck with public = public
		} in
		update_deck args.echo args.db new_deck user.User.id;
		args.echo (Printf.sprintf "public = %b, user_id = %d" public user.User.id)
	);

	(* Save deck in db *)
	add_op_login "add_deck" (fun args user ->
		let deck_name = args.cgi#argument_value "name" in
		(*let public = (args.cgi#argument_value "public") = "1" in*)
		add_deck args.db args.login deck_name;
		args.echo "Deck added<br>");

	add_op_login "add_card_deck_form" (fun args user ->
		try 
			args.echo (card_deck_form args.db user);
		with 
			(* Fetch exception if no decks or cards were found *)
			| DeckException msg -> args.echo (msg ^ "<br>")
			| Card.CardException msg -> args.echo (msg ^ "<br>")
			| e -> raise e
	);

	(*
		Add a card to a specific deck
	*)
	add_op_login "add_card_deck" (fun args user ->
		let card_id = args.cgi#argument_value "card_id" in
		let deck_id = args.cgi#argument_value "deck_id" in
		let nr = 
			(try 
				int_of_string (args.cgi#argument_value "nr")
			with
				Failure msg -> raise (DeckException "No number found")) in
		let card = Card.get_card args.db (User.get_user_id user) (int_of_string card_id) in
		let deck = get_deck args.db (User.get_user_id user) (int_of_string deck_id) in
		add_card_deck args.db card deck nr;
		args.echo "Added card to deck";
	);

	(*
		Get an overview over decks and their belonging cards
	*)
	add_op_login "list_decks" (fun args user ->
		let deck_list = list_of_decks args.db (User.get_user_id user) in
		args.echo "<table>";
		List.iter (fun deck -> args.echo (table_row_of_deck deck user)) deck_list;
		args.echo "</table>";
	)

