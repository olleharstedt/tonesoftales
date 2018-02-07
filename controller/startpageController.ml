(**
	Startpage controller
*)

open Operation
open User

let print = Printf.sprintf;;

let _ =
	(* Short hand *)
	let add_op = add_op' "startpage" in
	let add_op_login_no_guests = add_op_login ~allow_guests:false "startpage" in
  let add_op_login = add_op_login "startpage" in
	let add_op_ajax_login = add_op_ajax_login "startpage" in

	(* Startpage *)
  add_op_login "startpage" (fun args user ->
		let open Jg_types in

		(* Get some ads *)
		let ads = Ads.get args.db in

		let day = Misc.get_day () in

		(* Get ads, if any *)
		let ad = if List.length ads > 0 then (
			let i = day mod List.length ads in	(* Circulate ads by mod of day *)
			let ad = List.nth ads i in
			Tobj [
				("company", Tstr ad.Ads.company);
				("uri", Tstr ad.Ads.uri);
			]
		)
		(* No ads found, return empty object *)
		else Tobj [
			("company", Tstr "");
			("uri", Tstr "");
		] in

		(* Get quickmatch games *)
		let games = Game.get_quickmatch args.db in
		let games = Tlist (List.map (fun g -> 
			Tobj [
				("id", Tint (Misc.get_opt g.Game.id));
				("name", Tstr g.Game.name)
			]
		) games) in

		let template_string = Jg_template.from_file "/home/d37433/templates/startpage.tmpl" 
			~models:[
				("ad", ad);
				("quickmatch_games", games);
				("addr", Tstr args.addr);
			]
		in
		args.echo template_string;
	);

	(** Test table/fieldset CSS *)
	(*
	add_op_login "test" (fun args user ->
		let open Jg_types in
		let template_string = Jg_template.from_file "/home/d37433/templates/test.tmpl" in
		args.echo template_string
	);
	*)

	(* Links to create a game *)
	add_op_login_no_guests "create_game" (fun args user -> 
		(*
		let games = Game.list_of_games args.db user.id in
		let games_href = List.map (fun game ->
					let open Game in
					Printf.sprintf
								"<a href='?op=add_script_to_card_form&module=game'>Add script to card for game %s</a><br>"
								game.name
					) games in
		let games_href_string = List.fold_left (^) "" games_href in
		*)
		let open Jg_types in
		let template_string = Jg_template.from_file "/home/d37433/templates/create_game.tmpl" in
		args.echo template_string
		(*
		echo "
					<a href='?op=add_card_form&module=card'>Add card</a>&nbsp;|&nbsp;
					<a href='?op=edit_card_choose&module=card'>Edit card</a>
					<br />
					<a href='?op=add_deck_form&module=deck'>Add deck</a>&nbsp;|&nbsp;
					<a href='?op=edit_deck_choose&module=deck'>Edit deck</a>
					<br />
					<a href='?op=add_card_deck_form&module=deck'>Add card to deck</a><br>
					<br>
					<a href='?op=add_game_form&module=game'>Add game</a> |
					<a href='?op=edit_game_choose&module=game'>Edit game</a><br />
					<a href='?op=add_deck_to_game_form&module=game'>Add deck to game</a><br>
					<a href='?op=edit_init_script_form&module=game'>Edit initialization script for game</a><br>
					<a href='?op=choose_script_card&module=game'>Edit script for card in game</a><br>
					<br>
					<a href='?op=list_decks&module=deck'>List decks</a><br>
					<a href='?op=list_games_choose&module=game'>List games</a><br>
					<!-- Old session (draw card only) <a href='?op=start_session&module=session'>Start session</a><br>-->
			";
			*)
		);

		add_op_login "play_game" (fun args user -> 
		let open Jg_types in
		let template_string = Jg_template.from_file "/home/d37433/templates/play_game.tmpl" in
		args.echo template_string
      );

      (* Enter chat room, port in POST/GET, host in addr config *)
	(* Test
      add_op_login "enter_chat" (fun args user ->
            let port = args.cgi#argument_value "port" in
            args.echo (Printf.sprintf "
                  <fieldset>
                        <legend>Chat</legend>
                        <textarea id=chat cols=50 rows=20 ></textarea>
                        <input type=hidden id=port name=port value=8080 />
                        Say:<input type=text id=chat_message name=message maxlength=500 />
                        <input type=button name=send value='Send'
                        onclick='ws.send($(\"#chat_message\").val());' />
                  </fieldset>
                  <script>

                        // Connect websocket
                        $(document).ready( function () {
                              ws = new WebSocket(\"ws://%s:%s\");
                              ws.onmessage = function(msg) {
                                    $('#chat').append(msg.data + '\\n');
                              };
                        });

                        // Close socket if user leaves page
                        $(window).bind('beforeunload', function () {
                              ws.close();
                        });
                  </script>
            "
                  args.addr
                  port
            );
      );
	*)

	add_op "contact" (fun args ->
		let open Jg_types in
		let template_string = Jg_template.from_file "/home/d37433/templates/about.tmpl" in
		args.echo template_string
	);

	(** Home when you're not logged in. If logged in, 'startpage' is home. *)
	add_op "home" (fun args ->
		let open Jg_types in
		let template_string = Jg_template.from_file "/home/d37433/templates/home.tmpl" in
		args.echo template_string
	);

	add_op "doc" (fun args -> 	
		args.echo "
			<a href='?op=doc_termsusage&module=startpage'>Terms of usage</a><br />
			<a href='?op=doc_faq&module=startpage'>FAQ</a><br />
			<a href='?op=doc_tutorials&module=startpage'>Tutorials</a><br />
			<a href='?op=doc_api&module=startpage'>API</a><br />
			<a href='?op=sourcecode&module=startpage'>Source code</a><br />
			<h2>Documentation</h2>
			<p>Add cards. A card consists of a title, a description, and possible picture and sound. Later you will add script to your cards, when they belong to a game. A card can belong to many decks and games.</p>
			<p>Create a deck of the cards you have added. It's also possible to import other peoples cards into your deck, if those cards are marked as public.</p>
			<p>You create a game, then add a deck or several decks to this game.</p>
			<p>For a certain game, you should script the cards in that game. With Lua script, you can decide what will happen when a user picks up a card, or lays a card. These are called events, on which you hook your scripts.</p>
		"
	);

	add_op "doc_api" (fun args ->
		let api_list = Lua.Api.get_apis args.db in
		let api_html = Lua.Api.html_of_apis api_list in
		let datastructure_list = Lua.Api_datastructure.get_apis args.db in
		let datastructure_html = Lua.Api_datastructure.html_of_api_datastructures datastructure_list in
		args.echo (Printf.sprintf "
			<h2>API</h2>
			<p>This document will describe functions available for the card game maker. Use this as a point of reference. Please see tutorials for more information about how to use different functions and when.<p>
                  <p>You must NOT make functions with the same name as those
                  below. That would cause all sorts of trouble. Instead, please
                  use a namespace table for your own functions (see tutorials
                  for more info)</p>
			<div id=api>
			<hr>
                  <h3>Global variables</h3>
				<p>This is a list of global variables created at session
				startup. Make sure not to make your own global variables with
				the same name.</p>
				<table>
					<tr>
						<td><code>cards</code></td>
						<td>Array-like table with all cards present in all decks, like {card1, card2, ...}</td>
					</tr>
					<tr>
						<td><code>card1, ..., cardN</code></td>
						<td>Each card is stored in a table named card1, card2, etc</td>
					</tr>
					<tr>
						<td><code>decks</code></td>
						<td>Array-like table with decks deck1, deck2, ...</td>
					</tr>
					<tr>
						<td><code>deck1, ..., deckN</code></td>
						<td>Each deck is stored in a table named deck1, deck2, etc</td>
					</tr>
					<tr>
						<td><code>players</code></td>
						<td>Array-like table with players player1, player2, ...</td>
					</tr>
					<tr>
						<td><code>player1, ..., playerN</code></td>
						<td>Each player is stored in a table named player1, player2, etc</td>
					</tr>
					<tr>
						<td><code>table_slots</code></td>
						<td>Array-like table with table slots. Changes at
						game time when decks and cards are placed or picked
						up from the table.</td>
					</tr>
					<tr>
						<td><code>players_turn</code></td>
						<td>Player object of the player whos turn it is.</td>
					</tr>
				</table>
			<hr>
			<h3>Data structures</h3>
				<p>When making a game in Tones of Tales, you will be provided when a bunch of base data structures, representing cards, decks, players, etc. These data structures can be used to add more information relevant to your game. Below is a list available data structures.</p>
				%s
			<hr>
                  <h3>Functions</h3>
			%s
			</div>
			"
			datastructure_html
			api_html
		)
	);

	add_op "doc_termsusage" (fun args ->
		args.echo "
			<h2>Terms of usage</h2>
			<p>The webpage and its software is provided as is, without any warranty.</p>
			<p>The following rules must be obeyd by all users:</p>
			<ul>
				<li>Users may not upload copyrighted material</li>
				<li>Users may not provide malicious software</li>
			</ul>
			<p>If the above criteria is not met, the account will be disabled.</p>
		"
	);

	add_op "doc_faq" (fun args ->
		args.echo "
			<h2>FAQ</h2>
			<i>What is this?</i>
			<p>Tones of tales is a web page where you can make your own card game and play it with your friends or other people online. You can also play games made by others.</p>
			<i>How do I make a card game?</i>
			<p>Card games are programmed using the script language Lua. It's very similar to Javascript, so if you know Javascript, Lua won't be any problems to pick up. Please read the tutorials for more information.</p>
			<i>Do I have to be able to program to make a card game?</i>
			<p>Yes.</p>
			<i>Do I have to be able to program to play a card game?</i>
			<p>No.</p>
			<i>Which browsers does this web site support?</i>
			<p>Tones of tales is tested with Firefox and Chromium, but any browser supporting Websockets should work.</p>
			<i>Who made Tones of tales?</i>
			<p>My name is Olle Härstedt and I live in Uppsala, Sweden.</p>

		"
	);

	add_op "doc_tutorials" (fun args ->
		let open Jg_types in
		let template_string = Jg_template.from_file "/home/d37433/templates/tutorials.tmpl" in
		args.echo template_string
	);

	add_op "sourcecode" (fun args ->
		let open Jg_types in

		(* Get open source games *)
		let games = Game.get_opensource args.db in
		let games = Tlist (List.map (fun g ->
			Tobj [
				("id", Tint (Misc.get_opt g.Game.id));
				("name", Tstr g.Game.name);
			]
		) games) in



		let template_string = Jg_template.from_file "/home/d37433/templates/sourcecode.tmpl" ~models:[("games", games)] in
		args.echo template_string
	);

	(** Global chat *)
	add_op_ajax_login "new_global_chat" (fun args user ->

		(* Flush output to prevent CGI timeout *)
		args.echo "\"Ok\"";
		args.cgi#out_channel#commit_work ();
		args.cgi#out_channel#close_out();

		(* Environment/state for thread *)
		let env = object
			method db = args.db
			method addr = args.addr
			method port = 8079
			method user = user
		end in

		ignore(Chat.start_chat args.addr 8079 env);

		()
	);

      (* Start websocket listening cgi process *)
	(* Test
      add_op_ajax_login
            "start_chat"
            (fun args user ->
                  let port = 8080 in
                  (* Flush output to prevent CGI timeout *)
                  args.echo "\"Ok\"";
                  args.cgi#out_channel#commit_work ();
                  args.cgi#out_channel#close_out();

                  (* Start websocket listener *)
                  ignore(Chat.start_chat_websocket args.addr port);
            )
	*)
;;


