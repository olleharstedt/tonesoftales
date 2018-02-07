(**
	Simple session, draw a card from deck
	Controller code
*)
open Operation
open Session

(* Very old stuff here...
let _ =
	let add_op = add_op' "session" in
	()
;;


	(* 
		Choose a deck to start a session with (and type of session)
	*)
	add_op "start_session" (fun args ->
		(match args.login with
			User.Logged_in user ->
				begin
					let deck_list = Deck.list_of_decks args.db (User.get_user_id user) in
					args.echo "<table>";
					List.iter (fun deck -> 
						args.echo (Printf.sprintf "<tr><td><a href='?op=start_session_deck&module=session&deck_id=%i'>Start session with deck %s</a></td></tr>" (Deck.get_id deck) (Deck.get_name deck))
						) deck_list;
					args.echo "</table>";
				end
			| User.Not_logged_in -> args.echo "Login first"));

	(*
		Start session with deck
	*)
	add_op "start_session_deck" (fun args ->
		(match args.login with
			User.Logged_in user ->
				begin
					let deck_id = args.cgi#argument_value "deck_id" in
					if (deck_id = "") then raise (SessionException "No deck id found");
					let deck = Deck.get_deck args.db (User.get_user_id user) (int_of_string deck_id) in
					let session_id = start_session args.db deck (User.get_user_id user) in
					args.echo "Session started<br>";
					args.echo (Printf.sprintf "<a href='?op=draw_card&module=session&session_id=%Ld'>Draw card</a><br>" session_id);
				end
			| User.Not_logged_in -> args.echo "Login first"));

	(*
		Draw a card from session
	*)
	add_op "draw_card" (fun args ->
		(match args.login with
			User.Logged_in user ->
				begin
					let session_id = int_of_string (args.cgi#argument_value "session_id") in
					(*let card_id = int_of_string (cgi#argument_value "card_id") in*)
					let session = get_session args.db session_id (User.get_user_id user) in
					(try 
						begin
							let (drawn_card, new_session) = draw_random_card args.db session in
							let card_id = Card.get_id drawn_card in
							args.echo ("Hey, drawn card id = " ^ string_of_int card_id ^ "<br>");
							args.echo ((Card.get_text drawn_card) ^ "<br>");
							args.echo ("<img src='/drakskatten/upload/" ^ (User.get_username user) ^ "/" ^ (Card.get_img drawn_card) ^ "' /><br>");
							args.echo (Printf.sprintf "<a href='?op=draw_card&module=session&session_id=%d'>Draw another card</a><br>" session_id);
							args.echo (Printf.sprintf "<a href='?op=end_session&module=session&session_id=%d'>End session</a><br>" session_id);
						end
					with 
						NoCardsLeftException ->
							args.echo "No cards left in session. Make a new session to start over.<br>";
							delete args.db session);
				end
			| User.Not_logged_in -> args.echo "Must login to draw card"));

	(* 
		End session
	*)
	add_op "end_session" (fun args ->
		(match args.login with
			User.Logged_in user ->
				begin
					let session_id = int_of_string (args.cgi#argument_value "session_id") in
					let session = 
						(try 
							Some (get_session args.db session_id (User.get_user_id user))
						with
							Not_found -> None) in
					(match session with
						Some session -> 
							begin
								delete args.db session;
								args.echo "Session deleted<br>";
							end
						| None -> args.echo "No session with that id was found for this user";)
				end
			| User.Not_logged_in -> args.echo "Must login to end session"))

*)
