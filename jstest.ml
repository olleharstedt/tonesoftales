open Lwt

exception JsException of string
exception CoerceException
exception LwtHack		(* Can't raise exception and display it in an Lwt thread *)

let alert s = Dom_html.window##alert (Js.string s)
let document = Dom_html.window##document
let getElementById s = document##getElementById (Js.string s)
let handler = Dom_html.handler
let console = Firebug.console
let log s = console##log (s)
let error s = console##error (s)

(* Short hand *)
let get_select s = Js.coerce_opt 
	(getElementById s)
	Dom_html.CoerceTo.select 
	(fun _ -> error "No card_select found"; raise LwtHack)

(**
	Choose a game when editing card script
	This function will populate a card <select> list
*)
let choosegame () =
	let game_select = Js.coerce_opt (getElementById "game_select") Dom_html.CoerceTo.select (fun _ -> raise (JsException "Found no game_select")) in
	let game_id = game_select##value in
	(* Ajax *)
	let t = XmlHttpRequest.get ("/cgi-bin/drakskatten_ajax?op=list_of_cards_for_game&module=card&game_id=" ^ (Js.to_string game_id)) in
	ignore (Lwt.bind t (fun http_frame -> 
		let content = http_frame.XmlHttpRequest.content in

		(* Clear card list *)
		let card_select = get_select "card_select" in
		card_select##innerHTML <- Js.string "";

		let submit = Js.coerce_opt 
			(getElementById "submit")
			Dom_html.CoerceTo.input 
			(fun _ -> error ("No submit found"); raise LwtHack ) 
		in
		submit##style##display <- Js.string "none";

		let cards = Deriving.Card.from_string content in

		if (List.length cards = 0) then
			begin
				alert "No cards found for this game. Add decks to game first."
			end
		else
			begin
				submit##style##display <- Js.string "inline";
				List.iter (fun c ->
					let opt = Js.coerce 
						(document##createElement(Js.string "option")) 
						Dom_html.CoerceTo.option 
						(fun _ -> 
							error "Could not coerce option";
							raise LwtHack)
					in
					opt##innerHTML <- Js.string c.Deriving.Card.title;
					opt##value <- Js.string (string_of_int c.Deriving.Card.id);
					Dom.appendChild card_select opt;
					)
					cards;
			end;

		Lwt.return ())
	);

	()

(**
	Show and hide menus according to player turn

	TODO: ismouseover to ocaml
*)
(*
let showmenus () =
	let player_turn_nr = Js.Unsafe.variable "player_turn_nr" and
			my_player_nr = Js.Unsafe.variable "my_player_nr" and
			table_decks = (Js.Unsafe.variable "table_decks" :> < deck_nr_ : int Js.prop > Js.t Js.js_array Js.t) and
			hand_ = (Js.Unsafe.variable "hand_" :> unit Js.js_array Js.t)
	in
	if player_turn_nr = my_player_nr then
		begin
			(* OBS: table_decks can contain deck nrs like {3, 10}, not starting from 1/0 *)
			let length = table_decks##length in
			(* Show menus for decks *)
			let iter_deck_menus i = 
				if i <= length then
					begin
					  let deck = Js.Optdef.to_option (Js.array_get table_decks i) in
						let deck_nr = match deck with Some deck -> deck##deck_nr_ | None -> failwith "No deck" in
						let deck_div = getElementById ("deck_" ^ string_of_int deck_nr) in
						let ul = getElementById ("deck_" ^ string_of_int deck_nr ^ "_menu") in
						match Js.Opt.to_option ul, Js.Opt.to_option deck_div with
							| Some ul, Some deck_div -> 
								ul##style##display <- Js.string "none";

								(*let ev_listener = (Dom_html.divElement Js.t, Dom_html.mouseEvent Js.t) Dom_html.event_listener in*)

								deck_div##onmouseover <- handler (fun _ ->
									ul##style##display <- Js.string "block";
									Js.bool true
								);
								deck_div##onmouseout <- handler (fun _ ->
									ul##style##display <- Js.string "none";
									Js.bool true
								)
							| _, _ ->
								error "Found no deck div or deck menu"
					end
				else
					()
			in
			iter_deck_menus 1;

			(* Show menus for cards in hand *)
			let hand_ = (Js.Unsafe.variable "hand_" :> unit Js.js_array Js.t) in
			let length = hand_##length in
			for i = 0 to length - 1 do
				let card_slot = getElementById ("hand1_slot" ^ string_of_int (i + 1)) and
					ul = getElementById ("hand1_slot" ^ string_of_int (i + 1) ^ "_menu") in
				match Js.Opt.to_option ul, Js.Opt.to_option card_slot with
					| Some ul, Some card_slot ->
						ul##style##display <- Js.string "none";
						card_slot##onmouseover <- handler (fun _ ->
							ul##style##display <- Js.string "block";
							Js.bool true
						);
						card_slot##onmouseout <- handler (fun _ ->
							ul##style##display <- Js.string "none";
							Js.bool true	
						);
						(* TODO: ismouseover *)
					| _, _ ->
						error "Found no card_slot or ul";
			done;

			(* Show menus for player slots *)
			let rec iter_slot i = 
				let my_player_nr = Js.Unsafe.variable "my_player_nr" in
				let slot = getElementById ("player" ^ string_of_int my_player_nr ^ "_slot" ^ string_of_int i) and
						ul = getElementById ("player" ^ string_of_int my_player_nr ^ "_slot" ^ string_of_int i ^ "_menu") in
				match Js.Opt.to_option slot, Js.Opt.to_option ul with
					| Some slot, Some ul ->
						ul##style##display <- Js.string "none";
						slot##onmouseover <- handler (fun _ ->
							ul##style##display <- Js.string "block";
							Js.bool true
						);
						slot##onmouseout <- handler (fun _ ->
							ul##style##display <- Js.string "none";
							Js.bool true
						);
						(*TODO: ismouseover *)
						iter_slot (i + 1)
					| _, _ ->
						()
			in
			iter_slot 1;

		end
	(* Not my turn, hide stuff *)
	else
		begin
			(* Hide deck menus *)
			let length = table_decks##length in
			log ("hide deck, length = " ^ string_of_int length);
			for i = 0 to length - 1 do
					let deck = Js.Optdef.to_option (Js.array_get table_decks i) in
					let deck_nr = match deck with Some deck -> deck##deck_nr_ | None -> failwith ("No deck for i = " ^ string_of_int i) in
					let deck_div = getElementById ("deck_" ^ string_of_int deck_nr) in
					let ul = getElementById ("deck_" ^ string_of_int deck_nr ^ "_menu") in
					match Js.Opt.to_option ul, Js.Opt.to_option deck_div with
						| Some ul, Some deck_div ->
							deck_div##onmouseover <- handler (fun _ -> Js.bool false);
							deck_div##onmouseout <- handler (fun _ -> Js.bool false);
							ul##style##display <- Js.string "none";
						| _, _ ->
							error "Found no deck_div or ul";
			done;

			(* Hide hand menus *)
			log "hide hand";
			let length = hand_##length in
			for i = 0 to length - 1 do
				let card_slot = getElementById ("hand1_slot" ^ string_of_int (i + 1)) and
					ul = getElementById ("hand1_slot" ^ string_of_int (i + 1) ^ "_menu") in
				match Js.Opt.to_option card_slot, Js.Opt.to_option ul with
					| Some card_slot, Some ul ->
						card_slot##onmouseover <- handler (fun _ -> Js.bool false);
						card_slot##onmouseout <- handler (fun _ -> Js.bool false);
						ul##style##display <- Js.string "none";
					| _, _ ->
						error "Found no card_slot or ul";
			done;

			(* Hide slot menus *)
			let rec iter_slot i = 
				let my_player_nr = Js.Unsafe.variable "my_player_nr" in
				let slot = getElementById ("player" ^ string_of_int my_player_nr ^ "_slot" ^ string_of_int i) and
						ul = getElementById ("player" ^ string_of_int my_player_nr ^ "_slot" ^ string_of_int i ^ "_menu")
				in
				match Js.Opt.to_option slot, Js.Opt.to_option ul with
					| Some slot, Some ul ->
						slot##onmouseout <- handler (fun _ -> Js.bool false);
						slot##onmouseover <- handler (fun _ -> Js.bool false);
						ul##style##display <- Js.string "none";
						iter_slot (i + 1)
					| _, _ ->
						()
			in
			iter_slot 1;


		end

*)

(**
	Commands the server to startup a websocket listener CGI.
	If success, make a websocket that connects to it.

	@param addr		string; Address of server
	@param port		int
	@param game_session_id	int
	@param pwd		boolean; true if password is used for this session
*)
let open_new_lobby addr port session_id pwd =
	let data = [
		("module", "gamesession");
		("op", "open_new_lobby");
		("game_session_id", string_of_int session_id);
	] in
	let thread = XmlHttpRequest.perform_raw_url 
		~post_args:data
		"/cgi-bin/drakskatten_ajax"
	in
	ignore (Lwt.bind thread (fun http_frame -> 
		let content = http_frame.XmlHttpRequest.content in
		(match http_frame.XmlHttpRequest.code with
			| 200 ->
				Js.Unsafe.fun_call (Js.Unsafe.variable "new_websocket") [|
					Js.Unsafe.inject addr;
					Js.Unsafe.inject port;
					Js.Unsafe.inject pwd;
				|];
			| 404 ->
				failwith "Could not open new lobby: 404"
			| c ->
				failwith ("Unknown return code: " ^ string_of_int c)
		);
		Lwt.return ()
	));
	()

(** Add callbacks to window object *)
let _ =
	(Js.Unsafe.coerce Dom_html.window)##choosegame <- Js.wrap_callback choosegame;
	(*(Js.Unsafe.coerce Dom_html.window)##show_menus_ <- Js.wrap_callback showmenus;*)
	(Js.Unsafe.coerce Dom_html.window)##open_new_lobby_ <- Js.wrap_callback open_new_lobby;
	()
