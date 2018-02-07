(**
	Controller code for card ops

	@since 2013-02-26
*)

open Operation
open Card

let _ =
	let add_op_login = add_op_login ~allow_guests:false "card" in

	(**
		Show form for add card
	*)
	add_op_login "add_card_form" (fun args user ->
		args.echo (card_form())
	);

	(**
		Choose which card to edit
	*)
	add_op_login "edit_card_choose" (fun args user ->
		let cards = list_of_cards args.db user.User.id in
		let card_option_list = List.map (fun card ->
			Printf.sprintf "<option value=%d>%s</option>"
				card.id
				card.title
		) cards in
		let card_options = Misc.implode_list card_option_list in
		args.echo (Printf.sprintf "
			<form method=post action=drakskatten>
				<input type=hidden name=module value=card />
				<input type=hidden name=op value=edit_card_form />
				Select card:<select name=card_id>%s</select>
				<input type=submit value='Edit card' />
			</form>
		"
			card_options
		)
	);

	add_op_login "save_edit_card" (fun args user ->
		let card_id = int_of_string (args.cgi#argument_value "card_id") in
		let new_card = card_of_cgi args.cgi (User.get_user_id user) user.User.username in
		let old_card = get_card args.db user.User.id card_id in
		let new_card = {new_card with 
			id = old_card.id;
			img = if new_card.img <> "" then new_card.img else old_card.img;
			sound = if new_card.sound <> "" then new_card.sound else old_card.sound} in
		
		(* Abort if titles don't match (should not happen unless someone hack) *)
		if new_card.title <> old_card.title then failwith "Error: Titles of new card and old card don't match";
		
		(* New image? *)
		if (new_card.img <> "" && new_card.img <> old_card.img) then
			begin
				(* match return code? *)
				ignore (upload_file new_card.img (get_img_server new_card) user);
				args.echo "Img uploaded<br>";
			end;

		(* New sound? *)
		if (new_card.sound <> "" && new_card.sound <> old_card.sound) then
			begin
				(* match return code? *)
				ignore (upload_file new_card.sound (get_sound_server new_card) user);
				args.echo "Sound uploaded<br>";
			end;

		update_card args.db new_card user.User.id;
		args.echo "Changes saved<br />";
	);

	(**
		Edit card, change text/img etc
	*)
	add_op_login "edit_card_form" (fun args user ->
		let card_id = int_of_string (args.cgi#argument_value "card_id") in
		let card = Card.get_card args.db (User.get_user_id user) card_id in
		args.echo (edit_card_form card user)
	);

	(**
		Save a card from post in db
	*)
	add_op_login "add_card" (fun args user ->
		(* Abort if no title is found *)
		let title = args.cgi#argument_value "title" in
		if (title = "") then raise (CardException "Can't save card: No title found");

		let card = card_of_cgi args.cgi  user.User.id user.User.username in

		let return_code' = ref 0 in

		(* Upload img *)
		if ((get_img card) <> "") then
			begin
				let return_code = upload_file card.img (get_img_server card) user in
				return_code' := return_code;
				(match return_code with
					0 -> args.echo "Img uploaded<br>";
					| 1 -> args.echo "Error: Image didn't upload. Please make sure you have no whitespace in filename<br />"
					| _ -> args.echo "Unknown return code from upload"
				)
			end;

		(* Upload sound *)
		if ((card.sound) <> "") then
			begin
				let return_code = upload_file card.sound (get_sound_server card) user in
				return_code' := return_code;
				(match return_code with
					0 -> args.echo "Sound uploaded<br>";
					| 1 -> args.echo "Error: Sound didn't upload. Please make sure you have no whitespace in filename<br />"
					| _ -> args.echo "Unknown return code from upload"
				)
			end;

		(* Add card to db *)
		if (!return_code' = 0) then
			begin
				add_card args.db args.login card (User.get_user_id user);
				args.echo "Card added";
			end
		else
			args.echo "Did not add card to database<br />"
	);

	(**
		Ajax ops below
	*)

	(**
		Send card list for a game
		Used by choose card to edit script
	*)
	add_op_ajax_login
		"card"
		"list_of_cards_for_game"
		(fun args user ->
			let user_id = User.get_user_id user in
			let game_id = int_of_string (args.cgi#argument_value "game_id") in
			let cards = list_of_cards_for_game args.db user_id game_id in

			let card_list2 = List.map (fun c ->
				{
					Deriving.Card.id = c.id;
					text = c.text;
					title = c.title;
					img = c.img;
					dir = c.dir;
				}
				) cards
			in
			let cards_string2 = Deriving.Card.to_string card_list2 in
			args.log(Deriving.Test.to_string Deriving.Test.l);
			args.log(cards_string2);

			(*let cards_json = json_of_card_list cards in
			let cards_string = Json_io.string_of_json cards_json in*)
			args.echo cards_string2;
		);;
