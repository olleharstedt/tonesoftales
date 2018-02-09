(**
 *    Websocket module
 *
 *    Create a websocket server on a free port, for game and chat communication
 *
 *    @since 2013-03-07
 *)

open Unix
open Lwt
let print = Printf.sprintf;;

Random.self_init()

let escape = Netencoding.Html.encode ~in_enc:`Enc_utf8 ~unsafe_chars:Netencoding.Html.unsafe_chars_html4 ()

exception WebsocketException of string
exception ApiError

(** 
	Client connected with websocket. Can be logged in or not. 
*)
type client = {
	channel_id 	: int;       	(* 1 for first, 2 for second etc *)
	player_id 	: int;        (* Same as channel_id/player_nr, NOT player id in db *)
	channel 		: Lwt_websocket.Channel.t;
	user 				: User.user;	(* When socket logged in, user will be set *)
}

(**
	Different command types

      Commands are the websocket telling the client to do stuffs. Internal for
      the system, not in the API.

      Actions are stuff players can do. External, available for the programmer.

*)
type action_type =            (* Name of actions for add_action/action "interface" (because lack of reflection) *)
	| Pick_card of string	(* Menu text *)
	| Play_card of string	(* Menu text *)
	| Callback of string
and action =                  (* Actions sent from client/js to websocket/action instance *)
	| Pick_card_data of int   	(* deck id *)
	| Play_card_data of int			(* card id? *)
	| Play_slot_card_data of int 	(* slot_nr; Play card from players slot *)
	| Callback_data of int * int * string	(* action_id, slot nr, target (either "player_slot" or "table_slot") *)
	| Mark of marking_slot        (* mark a slot *)
	| Unmark of marking_slot      (* Unmark *)
and action_record = {
	action_id 	: int;
	action_name : string;
	menu_text 	: string;
	target 			: string;
	target_ids 	: int list;
	a_player_nrs: int list;
	a_callback 	: int;						(* Unique int ref *)
}
and add_action = 
	| Add_menu_to_deck of int * action_type * int list 	(* deck nr * action type/name * player nr list *)
	| Add_menu_to_hand of action_type * int list		(* Play_card * player_nrs; Add a menu to all cards in hand, available at player turn for players in int list*)
	| Add_menu_to_player_slot of action_type * int list * int list	(* Play_card * slot ids * player nrs *)
	| Add_callback_to_slot of action_record
and position = {
	left : int;
	top : int;
	rotate : int
}
(** NOT the same card type as in the Card module.
		card type used to send card info with Update_hand *)
and card = {
	card_id : int;	(* TODO: what is this? database id? *)
	card_nr : int;
	dir : string;
	img : string;
}
and card_list = card list

(**	Slots are used for enable_marking and enable_draggable *)
and slot = 
	| Player_slot of int list * int list      (* player nrs * slot nrs *)
	| Table_slot of int list                  (* slot nrs *)
	| Player_hand of int list                 (* player nrs *)

(** Internal representation for enabled gadgets *)
and gadget_spec = 
	| No_spec
	| Select of string list	(* options for select *)
	| Slider of int * int	* int	* int (* range for slider; step; value *)
	| Confirm of string (* title *)
and gadget = {
	gadget_id : int;
	type_ 		: string;
	text 			: string;
	player_nrs: int list;
	callback 	: int; (* Unique int reference to callback in LUA_REGISTRYINDEX *)
	spec 			: gadget_spec (* gadget specialization *)
}

(* As 'slot', but used in animation *)
and slot_type =
	| A_player_slot
	| A_table_slot
	| A_player_hand

(** Location used in animation and droppables *)
and location = {
	slot_type : slot_type;
	slot_nr 	: int;
	player_nr	: int;	(* -1 if not present *)
	index 		: int;	(* -1 if not present *)
}

(* Send this to server when to move card etc *)
and animate = {
	src : location;
	dest : location;
	anim_callback : int;	(* Send this back to server when animation is done *)
}

(** Style for table, width, heigh, cols etc *)
and table_style = {
	width : int;
	height : int;
	cols : int;
	rows : int;
	table_legend : string;	(* table_slots.title *)
}

(** Types used by bind_key *)
and character_code = int
and callback = int
and keybinding = Key_binding of character_code * callback

(* Movable objects, used with 60 fps *)
and movable_object = {
	obj_id : int;		(* unique identifier of object. can be card_nr. *)
	card : card;		(* Needed for img and dir/sprite *)
	x_acc : float;	(* accelleration *)
	y_acc : float;
	x_vel : float; 	(* velocity *)
	y_vel : float;
	x : float;			(* position *)
	y : float;
}
and timestamp = int 

(** Slot used when marking and unmarking from the client *)
and marking_slot = 
	| Marking_player_slot of int * int        (* player nr * slot nr *)
	| Marking_table_slot of int               (* slot nr *)
	| Marking_opponent_hand of int            (* player nr *)
	| Marking_hand_slot of int                (* hand slot nr *)
and table_types = 					(* Types for Update_table and Update_player_slots *)
	| Card_facing_up of int * int * string * string	* position (* card id * card nr * dir * img * pos *)
	| Card_facing_down of position	(* only pos *)
	| Deck of int * int			(* deck id * deck nr *)
	| Stack of table_types list         (* Completely overlayd stack of cards.  Should only stack cards, not other stacks! *)
	| Overlay of table_types list       (* Partially overlayd stack of cards *)
	| Dice of int												(* dice value *)
and command_type = 
	| Chat of string 				(* Chat message *)
	| Close 					(* Close websocket server, e.g. at timeout *)
	| Users_online of (string * int) list 	(* List of all users online and their player ids *)
	| Error of string
	| Login of string * int	* string	(* Login request: username, login session id, session password *)
	| Websocket_connected							(* Mark session as websocket connected *)
	| Add_participate									(* Save participant in db *)
	| Start					(* Go from lobby to game. Only session creator can do this. *)
	| End_game      (* After game_over, send this to all clients *)
	| Play_again		(* Start again after game over *)
	| Dump_decks				(* Dump decks from Lua state in debug dialog (client asks for this) *)
	| Dump_players                      (* Dump players from Lua state *)
	| Dump_table                        (* Dump table from Lua state (which cards/decks are in the table slots) *)
	| Deck_dump of string			(* Actual info send to client *)
	| Player_dump of string             (* Dumped players info *)
	| Table_dump of string              (* Dumped table info *)
	| Execute_lua of string             (* Run arbitrary lua code *)
	| Log of string				(* Print string in debug window (if debug active) *)
	| Build_html of string list * int * int * int * int	(* players_online * hands * player_slots * table_slots * gadgets; build up game table with slots and hands *)
	| Your_id of int				(* Your player id *)
	| Players_turn of int               (* player id *)
	| Show_hand_icon
	| Update_hand of card list 					(* json string; card list? *)
	| Update_all_hands of (int * int) list     (* player_nr * nr of cards; update other players hands; no secret information is sent here *)
	| Update_player_slots of int * table_types list     (* player nr * table_types list *)
	| Update_table of table_types list * table_style (* table json string; update table slots after play card, pick card from table etc*)
	| Action of action                  (* Action sent from client *)

	(* Lua/Javascript interaction *)
	| Place_deck of int * int		(* deck id * table slot *)
	| Place_card_on_table_down of int		(* table slot *)
	| Place_card_on_table_up of string * int	(* card json * table slot *)
	| Add_action of int * add_action          (* action id * action; Add action to HTML/JS environment *)
	| Remove_action of int 			(* action id *)
	| Enable_marking of slot list

	(* Gadget commands *)
	| Add_gadget of gadget
	| Update_gadget of gadget
	| Remove_gadget of int	(* gadget id *)
	| Button_pressed of int	(* gadget id *)
	| Select_changed of int * int (* gadget id, value *)
	| Slider_changed of int * int (* as select *)
	| Input_button_pressed of int * string (* gadget_id, input data *)
	| Confirm_pressed of int * bool (* gadget_id, answer *)

	(* Points table commands *)
	| Update_points_table of (string list) list

	(* Animation commands *)
	| Animate of animate			(* Sent from server to client *)
	| Animate_callback of int	(* callback id; sent from client to server when animation is done *)

	(* Draggable commands *)
	| Enable_draggable of int list * card list * slot list	(* player nrs, draggable cards, droppable slots *)
	| Card_dropped of int	* location	(* card nr, location *)

	(* onclick commands *)
	| Enable_onclick of card list
	| Card_onclick of int	(* card nr *)

	(* bind key commands *)
	| Bind_key of keybinding list
	| Keydown of character_code

	(* canvas commands *)
	| Enable_canvas
	| Disable_canvas

	(* movables commands *)
	| Set_movables of timestamp * movable_object list (* this sets the list of objects that will be animated in 60 fps on the client *)

(** Commands to send to and from client with websocket as JSON *)
and command = {
	command_type : command_type;
	username : string;
} with json

let gadgets = ref ([] : gadget list);

(**	System defined game states *)
type game_state =
      | Init
      | Lobby 
      | Running
      | Game_over

(** 
	List of clients connected to game session. Will never be > max_players 
	First client has player id 1, etc
*)
let clients = ref ([] : client list)

(** Channel id that will increase for each client added *)
let channel_id = ref 0

(** TODO: Use mutex or not? Lwt is not parallell. *)
let clients_mutex = Lwt_mutex.create()
let active_mutex = Lwt_mutex.create()
let animate_callback_mutex = Lwt_mutex.create()

(** Any channel active since last timeout? If not, exit CGI. *)
let active_since_last_timeout = ref true

(** Our Lua state *)
let state = ref (None : Lua.LUA.empty_t option)	(* Lua stack should always be empty at this level *)

(** How many players playing. For now = length of clients *)
let players_online = ref 0

(** Whos players turn it is, 1 for player1 etc (player1 also has channel_id/player_id 1, etc) *)
(* TODO: Add support for observers? *)
let players_turn = ref 0

(* Init, Running, Game_over etc *)
let game_state = ref Init

(**
 *    This is the "state" of what slots/hands have marking enabled
 *)
let enable_marking = ref ([] : slot list)

(** Enabled draggable cards *)
let draggable_cards = ref ([] : card list)

(** Enables droppaple slots *)
let droppable_slots = ref ([] : slot list)

(** Callback for dropping card on slot *)
let draggable_callback = ref 0

(** Draggable objects are enabled for players in this list *)
let draggable_player_nrs = ref ([] : int list)

(** onclick *)
let onclick_callback = ref 0
let onclick_cards = ref ([] : card list)	(* onclick enabled for these cards *)

(** realtime *)
let realtime_callback = ref 0
let realtime_mutex = Lwt_mutex.create()
let realtime_event = ref (None : Lwt_engine.event option)
let timestamp = ref 0		(* increases for each frame, resets to 1 at 999999999 *)

(** bindings for keydown *)
let keydown_bindings = ref ([] : keybinding list) (* charcode, callback reg *)

(** Standard position for cards *)
let standard_position = {
	left = 0;
	top = 0;
	rotate = 0;
}

(** Mark this as true after first connect and updated game session *)
let websocket_connected = ref false

(**
	List of actions added to game
	Check this to see if a player can perform a specific action
	Use of int map, like (action_id * add_action)
*)
exception ActionExists
module ActionMap = Map.Make(struct type t = int let compare = compare end)	(* IntMap *)
let actions = ref ActionMap.empty
let add_action_map id a =
	if ActionMap.exists (fun k a -> k = id) !actions then
		raise ActionExists
	else
		begin
			actions := ActionMap.add id a !actions
		end

(** List of animation callback ids (int Lua ref) *)
let anim_callbacks = ref ([] : int list)
let add_anim_callback id =
	if List.mem id !anim_callbacks then
		failwith "add_anim_callback: id already exists"
	else
		anim_callbacks := id :: !anim_callbacks
;;

(** Error log *)
let log str = ignore (Lwt_io.eprintl str)

(** @param s state
		@param id int
		*)
let remove_anim_callback s id =
	if List.mem id !anim_callbacks then (
		(* TODO: Update ocaml-lua *)
		(* TODO: Really unref? Can't decide which client should signal callback, so let all try *)
		(*Lua_api.LuaL.unref s Lua_api.Lua.registryindex id;			(* Unref callback id *)*)
		anim_callbacks := List.filter (fun i -> i <> id) !anim_callbacks;
	)
	else
		failwith "remove_anim_callback: no such callback"
;;


(** 
	Do stuff with mutex @m on
  Not really needed because lwt is not parallel?
	
	@param m 	mutex
	@param fn 	unit -> unit
	@return	unit
*)
let with_mutex m fn = 
      ignore (Lwt_mutex.lock m);
      let result = fn() in
      ignore (Lwt_mutex.unlock m);
	result

(**
	End session and exits

	@param env		environment, like db etc
*)
let exit_server env =
	Gamesession.end_game_session env#db env#get_game_session;
	exit 0

(**
	Broadcast command to all channels

	@param command	command record
	@return		unit
*)
let broadcast command =
	with_mutex clients_mutex (fun () ->
		for i=0 to List.length !clients - 1 do
			let c = List.nth !clients i in 
			let command_json = json_of_command command in
			let command_string = Json_io.string_of_json command_json in
			ignore(c.channel#write_text_frame command_string)
		done
	)

(**
 *    broadcast_error
 *    Help function 
 *)
let broadcast_error msg =
      broadcast {command_type = Error msg; username = "System"}

let chat msg = 
	broadcast {
		command_type = Chat msg; 
		username = "System"
	}
(**
	End session if there's no clients in client list

	@param env		environment, like db etc
*)
let exit_if_last env =
      if List.length !clients = 0 then 
		exit_server env

(** 
	Add a channel to client list 

	@param channel	unix channel?
	@return		unit
*)
let add_client channel user =
      with_mutex clients_mutex (fun () ->
		(* Increase channel id *)
		channel_id := !channel_id + 1;
		let client = {
			channel_id = !channel_id; 
			player_id = !channel_id; 	(* TODO: Possibly add support for spectators *)
			channel = channel;
			user = user;
		} in
		clients := client :: !clients;
		client
	)

(** 
	Removes client from list

	@param id	client id
*)
let remove_client id env =
	ignore (Lwt_mutex.lock clients_mutex);
	clients := List.filter (fun c -> c.channel_id <> id) !clients;
	exit_if_last env;
	ignore(Lwt_mutex.unlock clients_mutex)
;;

(**
	Return client with @player_id
*)
let get_client player_id =
	let l = List.filter (fun c -> c.player_id = player_id) !clients in
	if (List.length l <> 1) then
		raise (WebsocketException ("get_client: clients length != 1 for player_id = " ^ string_of_int player_id));
	List.hd l

(**
	Get list of usernames from clients
	Used when sending info to client about who's online.

	@return	string list
*)
let username_list_of_clients () =
	with_mutex clients_mutex (fun () ->
		()
	)

(**
	Send @command to @channel as JSON string

	@param channel	channel object
	@param command	command record
*)
let send channel command =
	let command_json = json_of_command command in
	let command_string = Json_io.string_of_json command_json in
	channel#write_text_frame command_string;
	()

(**
	Broadcast users online to all clients
*)
let broadcast_users () =
	let usernames = List.map (fun c -> 
		(c.user.User.username, c.player_id)
	) !clients in
	let command = {
		command_type = Users_online usernames;
		username = "System"
	} in
	broadcast command

(**
 *	Check current Lua state for deck with @deck_nr
 *	Return true if found
 *)
let game_has_deck s deck_nr =
	let s = Lua.LUA.getglobal s "decks" in		(* stack: -1 => decks, ... *)
	let (s, length) = Lua.LUA.objlen s in		(* stack: unchanged *)
	let rec check_for_deck s i =
		if i <= length then (
			let s = Lua.LUA.rawgeti s i in		(* stack: -1 => deck, -2 => decks, ... *)
			let (s, deck_nr') = Lua.LUA.getnumber s "deck_nr" in	
			log (print "deck_nr = %f" deck_nr');
			if int_of_float deck_nr' = deck_nr then 
				let s = Lua.LUA.pop s in		(* stack: -1 => decks, ... *)
				let s = Lua.LUA.pop s in		(* stack: ... *)
				Lua.LUA.endstate s;
				true
			else
				let s = Lua.LUA.pop s in 		(* stack: -1 => decks, ... *)
				check_for_deck s (i + 1)
		)
		else
			false
	in
	check_for_deck s 1
				
(** 	Help function for the below
			Get a function @fname and calls it with current turns player as arg
			@return unit *)
let onturn fname () = 
	let player = "player" ^ (string_of_int !players_turn) in
	match !state with 
		| None -> 
			raise (Lua.LuaException (print "onturn: tried to run %s but found no Lua state" fname))
		| Some s ->
			let s = Lua.LUA.getfn s fname in
			if (Lua.LUA.isnil s) then
				raise (Lua.LuaException ("onturn: " ^ fname ^ " is nil"))
			else
				begin
					let s = Lua.LUA.gettable s player in
					let s = Lua.LUA.pcall_fn1_noresult s in
					state := Some s
				end
;;

let onendturn = onturn "onendturn"
let onbeginturn = onturn "onbeginturn"

(** Reset all markings: players slots, hands, hand slots and table slots.
		Used after player end his/hers turn *)
let unmark_all () =
	let open Lua in
	let s = Misc.get_opt !state in
	let s = LUA.getglobal s "players" in	(* stack: -1 => players *)

	(* Loop through all playeres *)
	LUA.loop_rawgeti s (fun s ->
		(* stack: -1 => player, -2 => players *)

		(* Unmark cards in hand *)
		let s = LUA.getfield s "hand" in
		let s = LUA.setboolean s ("marked", false) in	
		LUA.loop_rawgeti s (fun s ->
			(* stack: -1 => card, -2 => hand, -3 => player, -4 => players *)
			let s = LUA.setboolean s ("marked", false) in
			s
		);
		let s = LUA.pop s in

		(* Unmark player slots *)
		let s = LUA.getfield s "slots" in
		LUA.loop_rawgeti s (fun s ->
			(* stack: -1 => slot, -2 => slots, -3 => player, -4 => players *)
			let s = LUA.setboolean s ("marked", false) in
			s
		);
		let s = LUA.pop s in
		s
	);
	let s = LUA.pop s in	(* stack: empty *)

	(* Loop through table slots *)
	let s = LUA.getglobal s "table_slots" in
	LUA.loop_rawgeti s (fun s ->
		let s = LUA.setboolean s ("marked", false) in
		s
	);
	let s = LUA.pop s in
	LUA.endstate s
;;

let set_players_turn nr =
	let open Lua in
	let s = Misc.get_opt !state in
	(*let s = LUA.pushnumber s (float_of_int !players_turn) in*)
	let s = LUA.gettable s (print "player%d" nr) in
	if LUA.isnil s then LUA.error s (print "set_players_turn: no such player widh id %d" nr);
	assert(not (LUA.isnil s));
	let s = LUA.setglobal s "players_turn" in
	LUA.endstate s

(**
	End turn for active player and send message about it.

	@return unit
 *)
let end_turn () =
	(* Check if this was the last player *)
	if !players_turn >= !players_online then	(* TODO: Assuming all online are players *)
		begin
			(* Run onendturn *)
			onendturn ();

			(* Unmark everything *)
			unmark_all ();

			(* Start over from player 1 *)
			players_turn := 1;
			set_players_turn !players_turn;

			(* Run onbeginturn *)
			onbeginturn ();

			broadcast {
				command_type = Players_turn !players_turn;
				username = "System"
			}
		end
	else
		begin
			(* Run onendturn *)
			onendturn ();

			(* Unmark everything *)
			unmark_all ();

			players_turn := !players_turn + 1;
			set_players_turn !players_turn;

			(* Run onbeginturn *)
			onbeginturn ();

			broadcast {
				command_type = Players_turn !players_turn;
				username = "System"
			}
		end

(**
 *    Help function for action execution from client
 *
 *    @param client     client for this websocket thread
 *    @param fn         lua_state -> unit, actual code to execute
 *    @return           unit
 *)
let action client action_type fn =
      match !state, !game_state with 
            None, _ -> failwith "Action: No lua state"
            | Some s, Running ->
                  if client.channel_id = !players_turn then
                        fn s
			else
				failwith "Action: Not this players turn"
            | Some s, _ ->
                  failwith "Action: Game state not running"

(**
 *    Check debug conditions (session owner, debug on), and execute @fn if ok.
 *    Help function 
 *    
 *    @param fn   Run if all is ok; send debug info to client
 *                state -> unit
 *    @return     unit
 *)
let debug env client fn = 
	if client.user.User.id = env#user.User.id then
		(if (env#get_game_session).Gamesession.debug then
			(match !state with 
				| Some s -> 
					fn s
				| None ->
					send client.channel {command_type = Error "No lua state found. Is game started?"; username = "System"}
			) 
		else
			send client.channel {command_type = Error "Debug tools not activated for this session."; username = "System"}
		)
	else
			send client.channel {command_type = Error "Only session creator can get debug info."; username = "System"}
;;

(* As above, but sends no error message if this is not a debug session (useful for Lua log() function) *)
let debug_silent env client fn =
	if client.user.User.id = env#user.User.id then
		(if (env#get_game_session).Gamesession.debug then
			(match !state with 
				Some s -> 
					fn s
				| None ->
					()
			) 
		)
;;

(**
	Get nr of cards of players hand
*)
let get_hand_length (s : Lua.LUA.empty_t) player =
	let s = Lua.LUA.getfn s "getn" in			(* stack: -1 => get n *)
	let s = Lua.LUA.getglobal s player in		(* stack: -1 => player, -2 => getn *)
	let s = Lua.LUA.getfield s "hand" in		(* stack: -1 => hand, -2 => player, -3 => getn *)
	let s = Lua.LUA.remove_second s in			(* stack: -1 => hand, -2 => getn *)
	let s = Lua.LUA.pcall_fn1 s in			(* stack: -1 => length *)
	let (s, hand_length) = Lua.LUA.fn_getnumber s in
	int_of_float hand_length


(**
	Check if player has card on hand in Lua state

	@param s		Lua state
	@param player	string; like "player1"
	@param card_nr	int; card_nr to look for
	@return 		bool; true if card is found in hand
*)
let has_card s player card_nr =
	(* Get number of cards on hand *)
	let hand_length = get_hand_length s player in

	(* Get list of card nr:s, and traverse hand *)
	(* TODO: Fix LUA wrapper for this... Or do it from Lua, if sandbox is ok. Or use rawgeti. *)
	let s' = Lua.LUA.to_lua s in
	Lua_api.Lua.getglobal s' player;		(* stack: -1 => player *)
	Lua_api.Lua.getfield s' (-1) "hand";	(* stack: -1 => hand, -2 => player *)
	Lua_api.Lua.pushnil s';				(* stack: -1 => nil, -2 => hand, -3 => player *)
	let rec get_card_nrs n =
		if n > hand_length then
			[]
		else
			begin
				(* TODO: Should use rawgeti here *)
				ignore (Lua_api.Lua.next s' (-2));	(* stack: -1 => value/card, -2 => key/array index, -3 => hand, -4 => player *)
				Lua_api.Lua.getfield s' (-1) "card_nr"; (* stack: -1 => card_nr, -2 => value/card, -3 => key/array index, -4 => hand, -5 => player *)
				if not (Lua_api.Lua.isnumber s' (-1)) then
					failwith ("Not number in table field card_nr");
				let card_nr' = Lua_api.Lua.tonumber s' (-1) in
				Lua_api.Lua.pop s' 2;
				(int_of_float card_nr') :: get_card_nrs (n + 1)
			end
	in
	let card_nrs = get_card_nrs 1 in
	Lua_api.Lua.pop s' 3;

	(* Return membership check *)
	List.mem card_nr card_nrs

(**
	Send detailed card info (dump) of hand to client
*)
let update_hand s client =
	(*let player = Lua.dump s ("player" ^ (string_of_int client.player_id)) in*)
	let s = Lua.LUA.getglobal s ("player" ^ string_of_int client.player_id) in
	let s = Lua.LUA.getfield s "hand" in
	let card_list = Lua.LUA.fold_rawgeti s (fun s ->
		(* stack: -1 => card, -2 => hand *)
		let (s, card_nr) = Lua.LUA.getnumber s "card_nr" in
		let (s, card_id) = Lua.LUA.getnumber s "id" in
		let (s, dir) = Lua.LUA.getstring s "dir" in
		let (s, img) = Lua.LUA.getstring s "img" in
		(s, {
			card_nr = int_of_float card_nr; 
			card_id = int_of_float card_id; 
			dir; 
			img;
		})
	) in
	let s = Lua.LUA.pop s in
	let s = Lua.LUA.pop s in
	Lua.LUA.endstate s;
	send client.channel {
		command_type = Update_hand card_list; 
		username = "System"
	};
	unmark_all()

(**
	Update private hands for all players
	Needed after added action play_card from hand, e.g.
*)
let update_all_hands s =
	List.iter (fun c ->
		update_hand s c
	)
	!clients

(**
	Send nr of cards on hand for all players to all players

	Uses global variable players_online (int)
*)
let update_other_hands s =
	let rec get_hands_length s n =
		assert(n > 0);
		if n > !players_online then
			[]
		else
			let player = "player" ^ (string_of_int n) in
			let hand_length = get_hand_length s player in
			Lua.LUA.endstate s;
			(n, hand_length) :: (get_hands_length s (n + 1))
	in
	(try
		let hand_list = get_hands_length s 1 in
		broadcast {command_type = Update_all_hands hand_list; username = "System"};
	with
		_ -> 
			broadcast_error "Could not count hand length";
	)

(**
	Returns a list of table_types (Card_facing_up/Card_facing_down/Overlay/Stack) from a slots collecton (table_slots, player_slots)
	Assuming array-table on top with all the cards/slot types.

	Also dice

	@param s			raw Lua state
	@param slots_name		string; name of array-table 
	@return			
*)
let get_cards_from_slots s =
	let l = Lua_api.Lua.objlen s (-1) in
	(* Help functions - include in LUA? *)
	let getstring k =
		Lua_api.Lua.getfield s (-1) k;
		let v = (match Lua_api.Lua.tostring s (-1) with
			| Some s -> escape s
			| None -> raise (Lua.LuaException "get_cards_from_slots: getstring: found no string")
		) in
		Lua_api.Lua.pop s 1;
		v
	in
	let getnumber k =
		Lua_api.Lua.getfield s (-1) k;
		let v = Lua_api.Lua.tonumber s (-1) in
		Lua_api.Lua.pop s 1;
		v
	in
	(**   Assuming card is on top of stack 
				@return	Card_facing_up or Card_facing_down *)
	let getcard () =
		let card_id = int_of_float (getnumber "id") in
		let card_nr = int_of_float (getnumber "card_nr") in
		let dir = getstring "dir" in
		let img = getstring "img" in
		let facing = getstring "facing" in
		Lua_api.Lua.getfield s (-1) "position";	(* stack: -1 => position, -2 => card *)
		let top = int_of_float (getnumber "top") in
		let left = int_of_float (getnumber "left") in
		let rotate = int_of_float (getnumber "rotate") in
		Lua_api.Lua.pop s 1;				(* stack: -1 => card *)
		let position = {left; top; rotate} in
			(match facing with
				| "up" ->
							Card_facing_up (card_id, card_nr, dir, img, position)
				| "down" ->
							Card_facing_down position
				| facing ->
					Lua.error s ("Wrong facing: " ^ facing)
			)
	in
	(** 	Assuming array-table of cards is on top of stack
		@param i	Always 1
		@param l	Upper limit >= 1
		@return	card list (card = Card_facing_up or Card_facing_down) *)
	let rec get_cards i l = match i with
		| i when i <= l ->
			Lua_api.Lua.rawgeti s (-1) i;			(* stack: -1 => card, -2 => cards, -3 => overlay, ... *)
			let __type = getstring "__type" in		(* stack: unchanged *)
			(match __type with
				| "card" ->
					let card = getcard() in
					Lua_api.Lua.pop s 1;		(* stack: -1 => cards, -2 => stack, -3 => table_slots *)
					card :: get_cards (i + 1) l
				| _ ->
					Lua_api.Lua.pop s 1;		(* stack: -1 => cards, -2 => stack, -3 => table_slots *)
					raise (Lua.LuaException "get_cards_from_slots: Not a card in overlay")
			)
		| _ ->
			[]
	in
	let rec get_slots_content = function
		| i when i <= l ->
			Lua_api.Lua.rawgeti s (-1) i;			(* stack: -1 => card/deck/stack/overlay, -2 => table_slots *)
			let __type = getstring "__type" in		(* stack: unchanged *)
			(match __type with
				| "card" ->
					(* Get id, card_nr, dir, img *)
                              (*
					let card_id = int_of_float (getnumber "id") in
					let card_nr = int_of_float (getnumber "card_nr") in
					let dir = getstring "dir" in
					let img = getstring "img" in
					let facing = getstring "facing" in
					Lua_api.Lua.pop s 1;		(* stack: -1 => table_slots *)
					(match facing with
						"up" ->
							Card_facing_up (card_id, card_nr, dir, img) :: get_slots_content (i + 1)
						| "down" ->
							Card_facing_down :: get_slots_content (i + 1)
						| facing ->
							raise (Lua.LuaException ("update_table: wrong facing: " ^ facing))
					)
                              *)
					let card = getcard () in
					Lua_api.Lua.pop s 1;		(* stack: -1 => table_slots *)
					card :: get_slots_content (i + 1)
				| "deck" ->
					let deck_id = int_of_float (getnumber "id") in		(* stack: unchanged *)
					let deck_nr = int_of_float (getnumber "deck_nr") in	(* stack: unchanged *)
					Lua_api.Lua.pop s 1;		(* stack: -1 => table_slots *)
					Deck (deck_id, deck_nr) :: get_slots_content (i + 1)
				| "overlay" ->
					let l2 = Lua_api.Lua.objlen s (-1) in	(* nr of cards in overlay *)
					let cards = get_cards 1 l2 in
					Lua_api.Lua.pop s 1;		(* stack: -1 => table_slots *)
					Overlay cards :: get_slots_content (i + 1)
				| "stack" ->
					let l2 = Lua_api.Lua.objlen s (-1) in	(* nr of cards in stack *)
					let cards = get_cards 1 l2 in
					Lua_api.Lua.pop s 1;				(* stack: -1 => table_slots *)
					Stack cards :: get_slots_content (i + 1)
				| "dice" ->
					let value = int_of_float (getnumber "value") in
					Lua_api.Lua.pop s 1;
					Dice value :: get_slots_content (i + 1)
				| _ ->
					(* Wrong type, abort *)
					raise (Lua.LuaException ("get_cards_from_slots: Unknown __type: " ^ __type))
			)
		| _ -> []
      in
      let lst = get_slots_content 1 in	(* stack: -1 => table_slots *)
	Lua_api.Lua.pop s 1;			(* stack empty *)
	lst

(**
	Send detailed card info about cards and decks on table

	@param s	Lua state, raw without wrapper
*)
let update_table s =
	Lua_api.Lua.getglobal s "table_slots";	(* stack: -1 => table_slots *)
	let width = int_of_float (Lua.getnumber s "width") in
	let height = int_of_float (Lua.getnumber s "height") in
	let rows = int_of_float (Lua.getnumber s "rows")in
	let cols = int_of_float (Lua.getnumber s "cols") in
	let title = Lua.getstring s "title" in
	let table_style = {
		width;
		height;
		rows;
		cols;
		table_legend = match title with Some s -> String.sub s 0 (if String.length s > 20 then 20 else String.length s) (* maxlength = 20 *) | None -> "";
	} in
	let lst = get_cards_from_slots s in (* TODO: Does this function really leave stack as it were? *)
	Lua_api.Lua.pop s 1;
	broadcast {
		command_type = Update_table (lst, table_style);
		username = "System";
	};
	unmark_all()

(**
	Send info about the cards, stacks, overlays and decks in player slots.
 *)
let update_player_slots s player_nr = 
	Lua_api.Lua.getglobal s ("player" ^ string_of_int player_nr);	(* stack: -1 => player *)
	Lua_api.Lua.getfield s (-1) "slots";					(* stack: -1 => slots, -2 => player *)
	let lst = get_cards_from_slots s in
      Lua_api.Lua.pop s 2;								(* stack: empty *)
	broadcast {
		command_type = Update_player_slots (player_nr, lst);
		username = "System";
	};
	unmark_all()

(**
 *    Add API functions to Lua state
 *
 *    @param state      Lua state
 *    @param env        env
 *    @param client     websocket client
 *)
let add_api s env client =
	(* Log something to game session debug window, if active *)
	let llog msg = 
		debug_silent env client (fun s -> 
			send client.channel {command_type = Log msg; username= "Log"};
		)
	in

	(**
	 *    End turn for active player and set
	 *    variable for next players turn.
	 *
	 *    Called from Lua
	 *)
	Lua.LUA.pushcfunction s "end_turn" (fun _ ->
				end_turn ();
				0	(* Return 0 args *)
	);

	(**	Set whose turn it is, from player nr
			set_turn(player.player_nr) *)
	Lua.LUA.pushcfunction s "set_turn" (fun s ->
		let player_nr = int_of_float (Lua_api.Lua.tonumber s (-1)) in
		(if List.exists (fun client -> client.channel_id = player_nr) !clients then
			begin
				(*onendturn ();*)
				players_turn := player_nr;
				set_players_turn !players_turn;
				(*onbeginturn ();*)
				broadcast {
					command_type = Players_turn !players_turn;
					username = "System"
				};

			end
		else
			Lua.error s ("Found no player with number " ^ string_of_int player_nr)
			(*raise (Lua.LuaException ("No player id " ^ (string_of_int player_nr))));*)
		);
		0
	);

	(**
				Place a deck from game on table, visible.

				place_deck(deck_id, table_slot)

				Called from Lua
	*)
	Lua.LUA.pushcfunction s "place_deck" (fun state' ->
		let deck_nr = (try int_of_float (Lua_api.LuaL.checknumber state' 1) with _ -> -1) in
		let slot_id = (try int_of_float (Lua_api.LuaL.checknumber state' 2) with _ -> -1) in
		let s = Lua.LUA.of_lua state' in
		(match (deck_nr, slot_id) with
			| -1, _ -> broadcast {command_type = Error "Could not place deck: deck nr not a number"; username = "System"}
			| _, -1 -> broadcast {command_type = Error "Could not place deck: slot id not a number"; username = "System"}
			| deck_nr, slot_id ->   (* OBS: Deck id, not nr *)
				(* Check if deck_id and slot_id is in this game *)
				if game_has_deck s deck_nr then
					begin
						if (slot_id <= env#game.Game.table_slots) then
							(* Actually do something *)
							begin
								(* broadcast {command_type = Place_deck (deck_id, slot_id); username = "System"}; *)
								(* 	let script = "table.insert(table_slots, get_deck(" ^ (string_of_int deck_id) ^ "))" in
										log("script = " ^ script);
										let state = Lua.LUA.runstring state script "place deck in table_slots" in *)
								let s = Lua.LUA.getglobal s "table" in	(* stack: -1 => table, ... *)
								let s = Lua.LUA.getfield s "insert" in	(* stack: -1 => insert, -2 => table, ... *)
								let s = Lua.LUA.remove_second s in		(* stack: -1 => insert, ... *)
								let s = Lua.LUA.getglobal s "table_slots" in	(* stack: -1 => table_slots, -2 => insert, ... *)
								let s = Lua.LUA.getglobal s ("deck" ^ (string_of_int deck_nr)) in	(* stack: -1 => deckN, -2 => table_slots, -3 => insert, ... *)
								let s = Lua.LUA.pcall_fn2_noresult s in	(* stack: ... *)
								Lua.LUA.endstate s;
								update_table state';
								()
							end
						else
							broadcast {command_type = Error ("place_deck: No such table slot: " ^ (string_of_int slot_id)); username = "System"};
					end
				else
					broadcast {command_type = Error ("place_deck: No deck with deck nr " ^ (string_of_int deck_nr) ^ " in game"); username = "System"}; 
			);
		0
	);

	(** Help function, get int from field
			Assumes table on top of stack
			@return int *)
	let getint s field =
		Lua_api.Lua.getfield s (-1) field;
		let value = int_of_float (Lua_api.LuaL.checknumber s (-1)) in	
		Lua_api.Lua.pop s 1;
		value
	in

	(** Help function
			Assumes table on top
			@return string option *)
	let getstring s field =
		Lua_api.Lua.getfield s (-1) field;
		let value = Lua_api.Lua.tostring s (-1) in
		Lua_api.Lua.pop s 1;
		match value with
			| Some s -> Some (escape s)
			| None -> None
	in

		(** Add menu item for action @action_name to @target with @id

				Adds an action to the deck menu
				Action object is on top of stack

				Usage:
				local action1 = {
					action_id 	= 1,
					action_name = "play_card",
					target 	= "hand",
					target_ids 	= {1},
					players 	= {player1}
				}
				add_action(action1) *)
		Lua.LUA.pushcfunction s "add_action" (fun s ->
			let action_id = getint s "action_id" in
			let action_name = getstring s "action_name" in
			let target = getstring s "target" in
			let menu_text = getstring s "menu_text" in

			(* Get target ids *)
			Lua_api.Lua.getfield s (-1) "target_ids";	(* stack: -1 => target_ids list, -2 => action *)
			let length = Lua_api.Lua.objlen s (-1) in
			(* Help function to get target ids *)
			let rec get_target_ids i =
				if i <= length then
					begin
						Lua_api.Lua.rawgeti s (-1) i;			(* stack: -1 => target_id, -2 => target_ids, -3 => action *)
						let target_id = int_of_float (Lua_api.LuaL.checknumber s (-1)) in
						Lua_api.Lua.pop s 1;				(* stack: -1 => target_ids, -2 => action *)
						target_id :: get_target_ids (i + 1)
					end
				else
					[]
			in
			let target_ids = get_target_ids 1 in
			Lua_api.Lua.pop s 1;	(* stack: -1 => action *)

			(* Get player nrs *)
			Lua_api.Lua.getfield s (-1) "players";	(* stack: -1 => players, -2 => action *)
			let length = Lua_api.Lua.objlen s (-1) in
			(* Help function to get player nrs *)
			let rec get_player_nrs i =
				if i <= length then
					begin
						Lua_api.Lua.rawgeti s (-1) i;			(* stack: -1 => player, -2 => players, -3 => action *)
						Lua_api.Lua.getfield s (-1) "player_nr";	(* stack: -1 => player_nr, -2 => player, -3 => players, ... *)
						let player_nr = int_of_float (Lua_api.LuaL.checknumber s (-1)) in
						Lua_api.Lua.pop s 2;				(* stack: -1 => players, -2 => action *)
						player_nr :: get_player_nrs (i + 1)
					end
				else
					[]
			in
			let player_nrs = get_player_nrs 1 in
			Lua_api.Lua.pop s 1;	(* stack: -1 => action *)

			if (List.length player_nrs = 0) then
				raise (Lua.LuaException ("add_action: No players specified"));

			(**	Send action to those clients who's in player_nrs list

				@param action	add_action type
				@param player_nrs	int list 	*)
			let send_action action action_id player_nrs =
				List.iter (fun client ->
					if List.mem client.player_id player_nrs then  
						send client.channel {
							command_type = Add_action (action_id, action);
							username = "System";
						}
				)
				!clients

			in

			let state = Lua.LUA.of_lua s in
			(* Check that all inputs are correct *)
			(match target, action_name, target_ids, menu_text with
				| None, _, _, _ -> broadcast_error "add_action: No target specified"
				| _, None, _, _ -> broadcast_error "add_action: No action name specified"
				| _, _, [], _ -> broadcast_error "add_action: Target id not specified"
				| _, _, _, None -> broadcast_error "add_action: menu_text not specified"
				(* Pick card from deck *)
				| Some "deck", Some "pick_card", [deck_nr], Some menu_text ->
					if game_has_deck state deck_nr then
						begin
							let action = Add_menu_to_deck (deck_nr, Pick_card menu_text, player_nrs) in
							add_action_map action_id action;
							send_action action action_id player_nrs;
							update_table s;
						end
					else
						broadcast_error ("add_action: no such deck with deck_nr " ^ (string_of_int deck_nr))
			(* Play card from hand *)
				| Some "hand", Some "play_card", hand_nrs, Some menu_text ->	(* TODO: Support more than 1 hand *)
					let action = Add_menu_to_hand (Play_card menu_text, player_nrs) in
					add_action_map action_id action;
					send_action action action_id player_nrs;
					let s' = Lua.LUA.of_lua s in
					update_all_hands s';
				(* Player card from player slot *)
				| Some "player_slot", Some "play_card", target_ids, Some menu_text ->
					let action = Add_menu_to_player_slot (Play_card menu_text, target_ids, player_nrs) in
					add_action_map action_id action;
					send_action action action_id player_nrs;
					List.iter (fun i -> update_player_slots s i) player_nrs
				| Some target, Some "callback", target_ids, Some menu_text ->
					Lua_api.Lua.getfield s (-1) "callback";	(* stack: -1 => callback, -2 => ... *)
					let a_callback = Lua_api.LuaL.ref_ s Lua_api.Lua.registryindex in	(* stack: -1 => ... *)

					if a_callback = Lua_api.LuaL.refnil then
						Lua.error s "No callback found for action";

					if target <> "table_slot" && target <> "player_slot" then
						Lua.error s "Only target 'table_slot' and 'player_slot' supported for callback action";

					let action_record = {
						action_id;
						action_name = "callback";
						menu_text;
						target;
						target_ids;
						a_player_nrs = player_nrs;
						a_callback;
					} in
					let action = Add_callback_to_slot action_record in
					add_action_map action_id action;
					send_action action action_id player_nrs;
					update_table s;
				(* Unknown action *)
				| Some target, Some action_name, target_ids, Some menu_text ->
					broadcast_error ("add_action: unknown target and action: " ^ target ^ ", " ^ action_name)
			);
			0
		);

	(** 	Remove action from game 
		remove_action(action) 
		action object on top of stack *)
	Lua.LUA.pushcfunction s "remove_action" (fun s ->
		let action_id = getint s "action_id" in

		if ActionMap.exists (fun k a -> k = action_id ) !actions then (
			actions := ActionMap.remove action_id !actions;
			broadcast {
				command_type = Remove_action action_id;
				username = "System";
			};
		)
		else	
			broadcast_error ("No action with action id " ^ string_of_int action_id);
		(*
		| Add_menu_to_deck of int * action_type * int list	(* deck nr * action type/name * player nr list *)
		| Add_menu_to_hand of action_type * int list		(* Play_card * player_nrs; Add a menu to all cards in hand, available at player turn for players in int list*)
		| Add_menu_to_player_slot of action_type * int list * int list	(* Play_card * slot ids * player nrs *)
	*)
		0
	);

	(**	Returns true if an action with this id exists in state 
		action object on top of stack *)
	Lua.LUA.pushcfunction s "action_exists" (fun s ->
		let action_id = getint s "action_id" in

		Lua_api.Lua.pushboolean s (ActionMap.exists (fun k a -> k = action_id) !actions);
		1
	);

      (**
            chat(str)

            Say something in the chat
      *)
      Lua.LUA.pushcfunction s "chat" (fun state' ->
            let open Lua_api in
            (match (try LuaL.checkstring state' 1 with _ -> "") with
                  | "" -> broadcast_error "Not a string to chat()?"
                  | msg -> broadcast {command_type = Chat (escape msg); username = "System"}
            );
            0
      );

	(** Sleep for one second 
			Sleeps for 1 sec if no args; otherwise sleep @milliseconds
			sleep([milliseconds])
	*)
	Lua.LUA.pushcfunction s "sleep" (fun s ->
		let length = Lua_api.Lua.gettop s in
		if length = 0 then
			Unix.sleep 1
		else (
			let milli = Lua_api.LuaL.checknumber s (1) in
			let milli = milli /. 1000. in
			if milli > 1. then
				Lua.error s "sleep: Can't sleep for more than 1000 milliseconds"
			else (
				ignore (Unix.select [] [] [] milli);
			)
		);
		0
	);

      (** 	log(str)

            Print message in the debug window
            Also, should be able to save this in log?  *)
      Lua.LUA.pushcfunction s "log" (fun state' ->
				let open Lua_api in
				(match (try LuaL.checkstring state' 1 with _ -> "") with
					| "" -> 
						debug_silent env client (fun s -> 
							send client.channel {command_type = Log "Error: Log: Not string for argument?"; username= "System"};
						)
					| msg -> 
						debug_silent env client (fun s -> 
							send client.channel {command_type = Log msg; username= "System"};
						)
				);
				0
      );

      (**
       *    Game over!
       *
       *    End game for all participants. Winner
       *    and/or looser should be proclaimed
       *    before calling this.
       *)
      Lua.LUA.pushcfunction s "game_over" (fun s' ->
            let open Lua_api in
            game_state := Game_over;
						state := None;	(* Finish Lua state *)
						(*
						broadcast {		(* To hide menus *)
							command_type = Players_turn 100;
							username = "System" ;
						};
						*)
            broadcast {
                  command_type = Chat "Game over";
                  username = "System" 
            };
						broadcast {
							command_type = End_game;
							username = "System" 
						};
						(* Kill realtime callback *)
						(match !realtime_event with 
							| None ->
								()
							| Some ev ->
								log "stopping realtime event";
								Lwt_engine.stop_event ev
						);
            0
      );

	(**
		Get next free table slot

		get_next_free_table_slot() -> int
	*)
	(*
	Lua.LUA.pushcfunction s "get_free_table_slot" (fun s' ->
	);
	*)

	(**
		Remove card from hand for playing player
		
		Usage:
		remove_card_from_hand(player, card)

		@param player 	player
		@param card		card
		@return		bool
	*)
	Lua.LUA.pushcfunction s "remove_card_from_hand" (fun s ->
		(* stack: -1 => card, -2 => player *)
		(* Get player_id *)
		Lua_api.Lua.getfield s (-2) "player_id";			(* stack: -1 => player_id, -2 => card, -3 => player *)
		let player_id = int_of_float (Lua_api.Lua.tonumber s (-1)) in		(* stack: as above *)
		Lua_api.Lua.pop s 1;						(* stack: -1 => card, -2 => player *)
		Lua_api.Lua.getglobal s "__remove_card_from_hand";	(* stack: -1 => remove_card_from_hand, -2 => card, -3 => player *)
		Lua_api.Lua.insert s (-3);					(* stack: -1 => card, -2 => player, -3 => remove_card_from_hand *)
		let thread_state = Lua_api.Lua.pcall s 2 1 0 in		(* 2 args, 1 result *)
		(match thread_state with
			| Lua_api.Lua.LUA_OK -> ()
			| err -> 
					begin
						let err_msg = Lua_api.Lua.tostring s (-1) in
						Lua_api.Lua.pop s 1;  (* Pop message from stack *)
						raise (Lua.LuaException (match err_msg with Some s -> s | None -> raise Not_found))
					end
		);
		(* Update hand and hands *)
		let s = Lua.LUA.of_lua s in
		update_hand s (get_client player_id);
		update_other_hands s;
		0
	);

	(**
		Remove card from table slot
		
		Usage:
		remove_card_from_table(card)
	*)
	Lua.LUA.pushcfunction s "remove_card_from_table" (fun s ->
		(* stack: -1 => card *)
		Lua_api.Lua.getglobal s "__remove_card_from_table";	(* stack: -1 => __remove_card_from_table, -2 => card *)
		Lua_api.Lua.insert s (-2);					(* stack: -1 => card, -2 => __remove_card_from_table *)
		let thread_state = Lua_api.Lua.pcall s 1 1 0 in		(* 2 args, 1 result *)
		(match thread_state with
			| Lua_api.Lua.LUA_OK -> ()
			| err -> 
					begin
						Lua.error s "remove_card_from_table error";
						(*
						let err_msg = Lua_api.Lua.tostring s (-1) in
						Lua_api.Lua.pop s 1;  (* Pop message from stack *)
						raise (Lua.LuaException (match err_msg with Some s -> s | None -> raise Not_found))
						*)
					end
		);
		update_table s;
		0
	);

	(**
		Updates table slots, show changes etc.

		Usage:
		update_table()
	*)
	Lua.LUA.pushcfunction s "update_table" (fun s ->
		update_table s;
		0
	);

	(**
		Updates slots in front of the player
		Usage:
		update_player_slots(player1)
	*)
	Lua.LUA.pushcfunction s "update_player_slots" (fun s ->
		(* stack: -1 => player *)
		Lua_api.Lua.getfield s (-1) "player_nr";		(* stack: -1 => player_nr, -2 => player *)
		let player_nr = int_of_float (Lua_api.Lua.tonumber s (-1)) in
		Lua_api.Lua.pop s 2;					(* stack: empty *)
		update_player_slots s player_nr;
		0
	);

	(**
		Updates the hand of @player (and makes it visible for others)

		update_hand(player)
	*)
	Lua.LUA.pushcfunction s "update_hand" (fun s ->
		(* stack: -1 => player *)
		Lua_api.Lua.getfield s (-1) "player_id";		(* stack: -1 => player_id, -2 => player *)
		let player_id = Lua_api.Lua.tonumber s (-1) in	(* stack unchanged *)
		Lua_api.Lua.pop s 2;  					(* stack empty *)
		let s = Lua.LUA.of_lua s in
		update_hand s (get_client (int_of_float player_id));
		update_other_hands s;
		0
	);

	(**
		Place card on table

		place_card_on_table(card, table_slot, facing)
		
		@param card		int
		@param table_slot	int > 0
		@param facing	string, "up" or "down"
	*)
	Lua.LUA.pushcfunction s "place_card_on_table" (fun s' ->
            let table_slot = (try int_of_float (Lua_api.LuaL.checknumber s' 2) with _ -> -1) in
            let facing = (try Lua_api.LuaL.checkstring s' 3 with _ -> "") in

		(try Lua_api.LuaL.checktype s' 1 Lua_api_lib.LUA_TTABLE with _ -> 
			(* TODO: What to do? *)
			()
		);
		Lua_api.Lua.getfield s' (1) "card_nr";
		let card_nr = (int_of_float (Lua_api.Lua.tonumber s' (-1))) in
		Lua_api.Lua.pop s' 1;					(* stack: empty *)

		(* Check args *)
		(match card_nr, table_slot, facing with
			| -1, _, _ -> broadcast_error "place_card_on_table: No card_nr specified"
			| _, -1, _ -> broadcast_error "place_card_on_table: No table_slot specified"
			| _, _, "" -> broadcast_error "place_card_on_table: No facing specified"
			| card_nr, table_slot, facing ->

				(* Check if table_slot is free *)
				Lua_api.Lua.getglobal s' "table_slots";				(* stack: -1 => table_slots *)
				Lua_api.Lua.getfield s' (-1) (string_of_int table_slot);	(* stack: -1 => slot, -2 => table_slots *)
				let isnil = Lua_api.Lua.isnil s' (-1) in				(* stack: -1 => slot, -2 => table_slots *)
				Lua_api.Lua.pop s' 2;							(* stack: empty *)

				(* Set table_slots[table_slot] = card *)
				(* WRONG! Use array handling instead, rawseti *)
				let set_table_slot facing =
					let card = "card" ^ (string_of_int card_nr) in
					Lua_api.Lua.getglobal s' "table_slots"; 		(* stack: -1 => table_slots *)
					Lua_api.Lua.getglobal s' card;			(* stack: -1 => card object, -2 => table_slots *)
					Lua_api.Lua.pushstring s' facing;			(* stack: -1 => facing, -2 => card, -3 -> table_slots *)
					Lua_api.Lua.setfield s' (-2) "facing";		(* stack: -1 => card, -2 => table_slots *)
					(* TODO: Which index will be set?? *)
					Lua_api.Lua.rawseti s' (-2) table_slot;		(* stack: -1 => table_slots *)
					Lua_api.Lua.pop s' 1;					(* stack: empty *)
				in

				(* Check facing *)
				(match isnil, facing with 
					| false, _ ->
						broadcast_error "place_card_on_table: table slot is not nil (must be free to place a card there)"
					| _, "up" ->
						set_table_slot "up";
						update_table s';
					| _, "down" ->
						set_table_slot "down";
						update_table s';
					| _, _ ->
						broadcast_error "_place_card_on_table: facing must be either 'up' or 'down'"
				)
		);
		0
	);

	(**
	 *  Enable marking for slots and hands.
	 *  Example:
			slots_list = {
				{
					slot_type 	= "player_slot", 
					players 	= {player1}, 
					slot_nrs 	= {1}
				},
				{
					slot_type 	= "table_slot", 
					slot_nrs 	= {1, 2, 3}
				},
				{
					slot_type 	= "player_hand", 
					players 	= {player1}
				}
			}
			enable_marking(slot_list)
	 *)
	Lua.LUA.pushcfunction s "enable_marking" (fun s ->
		(*
		Lua_api.Lua.getfield s (-1) "__type";		(* stack: -1 => __type, -2 => slot_list *)
		let __type = (match Lua_api.Lua.tostring s (-1) with
			Some s -> s
			| None -> raise (Lua.LuaException "enable_marking: tostring: found no __type")
		) in
		if (__type <> "slot_list") then
			raise (Lua.LuaException "enable_marking: argument not a slot_list? __type should equal 'slot_list'");
		Lua_api.Lua.pop s 1;                            (* stack: -1 => slot_list *)
			*)
		let length = Lua_api.Lua.objlen s (-1) in
		let rec get_slot_list i =
			if i <= length then
				begin
					Lua_api.Lua.rawgeti s (-1) i;			(* stack: -1 => slot, -2 => slot list *)
					Lua_api.Lua.getfield s (-1) "slot_type";	(* stack: -1 => slot_type, -2 => slot, -3 => slot list *)
					let slot_type = (match Lua_api.Lua.tostring s (-1) with
						| Some s -> escape s
						| None -> raise (Lua.LuaException "enable_marking: no slot_type")
					) in
					Lua_api.Lua.pop s 1;				(* stack: -1 => slot, -2 => slot list *)
					(* Pattern match on the three slot types, and fetch relevant fields/data *)
					let slot = (match slot_type with
								| "player_slot" ->
									Lua_api.Lua.getfield s (-1) "players";    (* stack: -1 => players, -2 => slot, -3 => slot list *)
									if not (Lua_api.Lua.istable s (-1)) then
										Lua.error s "No players field found for player_slot slot";
									let length = Lua_api.Lua.objlen s (-1) in
									(* Get player nrs from player list *)
									let rec get_player_nrs i =
										if i <= length then
											begin
														Lua_api.Lua.rawgeti s (-1) i; (* stack: -1 => player, -2 => players, ... *)
														Lua_api.Lua.getfield s (-1) "player_nr";	(* stack: -1 => player_nr, -2 => player, -3 => players, ... *)
														let player_nr = int_of_float (Lua_api.Lua.tonumber s (-1)) in
														Lua_api.Lua.pop s 2;    (* stack: -1 => players, -2 => slot, -3 => slot list *)
														player_nr :: get_player_nrs (i + 1)
											end
										else
											[]
									in
									let player_nrs = get_player_nrs 1 in
									Lua_api.Lua.pop s 1;    (* stack: -1 => slot, -2 => slot list *)
									Lua_api.Lua.getfield s (-1) "slot_nrs";    (* stack: -1 => slot_nrs, -2 => slot, -3 => slot list *)
									if not (Lua_api.Lua.istable s (-1)) then
												Lua.error s "No slot_nrs field found for player_slot slot";
									let length = Lua_api.Lua.objlen s (-1) in
									(* Get slot nrs from slot nr list *)
									let rec get_slot_nrs i =
												if i <= length then
															begin
																		Lua_api.Lua.rawgeti s (-1) i; (* stack: -1 => slot_nr, -2 => slot_nrs, ... *)
																		let slot_nr = int_of_float (Lua_api.Lua.tonumber s (-1)) in
																		Lua_api.Lua.pop s 1;          (* stack: -1 => slot_nrs, -2 => slot, -3 => slot list *)
																		slot_nr :: get_slot_nrs (i + 1)
															end
												else
															[]
									in
									let slot_nrs = get_slot_nrs 1 in
									Lua_api.Lua.pop s 1;          (* stack: -1 => slot, -2 => slot list *)
									Player_slot (player_nrs, slot_nrs)
								| "table_slot" ->
									llog "enable_marking: table_slot";
									Lua_api.Lua.getfield s (-1) "slot_nrs";    (* stack: -1 => slot_nrs, -2 => slot, -3 => slot list *)
									if not (Lua_api.Lua.istable s (-1)) then
												Lua.error s "No slot_nrs field found for table_slot slot";
									let length = Lua_api.Lua.objlen s (-1) in
									(* Get slot nrs from slot nr list *)
									let rec get_slot_nrs i =
												if i <= length then
															begin
																		Lua_api.Lua.rawgeti s (-1) i; (* stack: -1 => slot_nr, -2 => slot_nrs, ... *)
																		let slot_nr = int_of_float (Lua_api.Lua.tonumber s (-1)) in
																		Lua_api.Lua.pop s 1;          (* stack: -1 => slot_nrs, -2 => slot, -3 => slot list *)
																		slot_nr :: get_slot_nrs (i + 1)
															end
												else
															[]
									in
									let slot_nrs = get_slot_nrs 1 in
									Lua_api.Lua.pop s 1;          (* stack: -1 => slot, -2 => slot list *)
									Table_slot slot_nrs
								| "player_hand" ->
									Lua_api.Lua.getfield s (-1) "players";    (* stack: -1 => players, -2 => slot, -3 => slot list *)
									if not (Lua_api.Lua.istable s (-1)) then
												Lua.error s "No players field found for player_hand slot";
									let length = Lua_api.Lua.objlen s (-1) in
									(* Get player nrs from player list *)
									let rec get_player_nrs i =
												if i <= length then
															begin
																		Lua_api.Lua.rawgeti s (-1) i; (* stack: -1 => player, -2 => players, ... *)
																		Lua_api.Lua.getfield s (-1) "player_nr";	(* stack: -1 => player_nr, -2 => player, -3 => players, ... *)
																		let player_nr = int_of_float (Lua_api.Lua.tonumber s (-1)) in
																		Lua_api.Lua.pop s 2;    (* stack: -1 => players, -2 => slot, -3 => slot list *)
																		player_nr :: get_player_nrs (i + 1)
															end
												else
															[]
									in
									let player_nrs = get_player_nrs 1 in
									Lua_api.Lua.pop s 1;    (* stack: -1 => slot, -2 => slot list *)
									Player_hand player_nrs
								| _ ->
											Lua.error s "Unknown slot type"
							) in
				Lua_api.Lua.pop s 1;                      (* stack: -1 => slot list *)
				slot :: get_slot_list (i + 1)
						end
			else
						[]
		in
		let slot_list = get_slot_list 1 in
		enable_marking := slot_list;        (* Set slots enabled state *)
		broadcast {
					command_type = Enable_marking slot_list;
					username = "System" 
		};
		0
	);

	(** Some gadgets functions for customizable GUI *)

	(** Add gadgets to OCaml list. Cast Lua error if already exists *)
	let add_gadget s g = 
		if List.exists (fun g' -> g'.gadget_id = g.gadget_id) !gadgets then 
			Lua.error s (print "The gadget id already exists: %d" g.gadget_id)
		else
			gadgets := g :: !gadgets
	in

	(* Remove gadget from OCaml list, if it exists *)
	let remove_gadget s gadget_id =
		if List.exists (fun g' -> g'.gadget_id = gadget_id) !gadgets then 
			gadgets := List.filter (fun g' -> g'.gadget_id <> gadget_id) !gadgets
		else
			Lua.error s (print "Can't remove gadget: id not found: %d" gadget_id)
	in

	(* aux for add_gadget and update_gadget *)
	(* assumes stack: -1 => gadget *)
	let gadget_of_state s =
		let gadget_id = getint s "gadget_id" in
		let type_ = getstring s "type" in
		let text = getstring s "text" in
		Lua_api.Lua.getfield s (-1) "players";    (* stack: -1 => players, -2 => gadget *)
		(* Abort if no players found *)
		if not (Lua_api.Lua.istable s (-1)) then
			Lua.error s "No players field found for gadget";
		let length = Lua_api.Lua.objlen s (-1) in
		(* Get player nrs from player list *)
		let rec get_player_nrs i =
			if i <= length then
				begin
					Lua_api.Lua.rawgeti s (-1) i; (* stack: -1 => player, -2 => players, ... *)
					Lua_api.Lua.getfield s (-1) "player_nr";	(* stack: -1 => player_nr, -2 => player, -3 => players, ... *)
					let player_nr = int_of_float (Lua_api.Lua.tonumber s (-1)) in
					Lua_api.Lua.pop s 2;    (* stack: -1 => players, -2 => gadget *)
					player_nr :: get_player_nrs (i + 1)
				end
			else
				[]
		in
		let player_nrs = get_player_nrs 1 in
		Lua_api.Lua.pop s 1;    (* stack: -1 => gadget *)
		Lua_api.Lua.getfield s (-1) "callback";	(* stack: -1 => callback, -2 => gadget *)
		(* Store callback as a unique reference in the Lua registry *)
		let callback = Lua_api.LuaL.ref_ s Lua_api.Lua.registryindex in	(* stack: -1 => gadget *)

		match type_, text with
			| Some "button", Some text ->

				(* Abort if type is not supported *)
				(*
				if not (List.mem "button" supported_gadgets) then
					Lua.error s (print "Gadget type not supporter: %s" "button");
				*)

				(* Abort if text is too long *)
				if String.length text > 20 then
					Lua.error s (print "Gadget text too long: %s (max number of characters is 20, this had length %d)" text (String.length text));

				{
					gadget_id; 
					type_ = "button"; 
					text; 
					player_nrs; 
					callback;
					spec = No_spec;
				}
			| Some "select", None ->
				Lua_api.Lua.getfield s (-1) "options";	(* stack: -1 => options, -2 => gadget *)
				let length = Lua_api.Lua.objlen s (-1) in
				let rec get_options i s = 
					if i <= length then (
						Lua_api.Lua.rawgeti s (-1) i; (* stack: -1 => string, -2 => options, -3 => gadgets *)
						let str = Lua_api.Lua.tostring s (-1) in
						Lua_api.Lua.pop s 1;	(* stack: -1 => options, -2 => gadgets *)
						(match str with 
							| Some str -> escape str :: get_options (i + 1) s
							| None -> Lua.error s "Found no string in options"
						)
					) else
						[]
				in
				let options = get_options 1 s in
				Lua_api.Lua.pop s 1;	(* stack: -1 => gadgets *)

				{
					gadget_id;
					type_ = "select";
					text = "";
					player_nrs;
					callback;
					spec = Select options
				} 

			| Some "input", Some text ->
				if String.length text > 20 then
					Lua.error s (print "Gadget text too long: %s (max number of characters is 20, this had length %d)" text (String.length text));

				{
					gadget_id; 
					type_ = "input"; 
					text; 
					player_nrs; 
					callback;
					spec = No_spec;
				}

			| Some "slider", None ->
				(* Get range for slider *)
				Lua_api.Lua.getfield s (-1) "range";	(* stack: -1 => range, -2 => gadget *)
				Lua_api.Lua.rawgeti s (-1) 1; (* stack: -1 => number, -2 => range, -3 => gadget *)
				let bottom = Lua_api.Lua.tonumber s (-1) in
				Lua_api.Lua.pop s 1;	(* stack: -1 => range, -2 => gadget *)
				Lua_api.Lua.rawgeti s (-1) 2; (* stack: -1 => number, -2 => range, -3 => gadget *)
				let top = Lua_api.Lua.tonumber s (-1) in
				Lua_api.Lua.pop s 2;	(* stack: -1 => gadget *)

				Lua_api.Lua.getfield s (-1) "step";	(* stack: -1 => step, -2 => gadget *)
				let step = Lua_api.Lua.tonumber s (-1) in
				let step = if step < 1. then 1. else step in	(* Default step to 1 *)
				Lua_api.Lua.pop s 1; (* stack: -1 => gadget *)

				Lua_api.Lua.getfield s (-1) "value"; (* stack: -1 => value, -2 => gadget *)
				let value = Lua_api.Lua.tonumber s (-1) in
				Lua_api.Lua.pop s 1;	(* stack: -1 => gadget *)

				if bottom < 0. || top < 0. then (
					(* No call stack information here? *)
					(*
					Lua_api.Lua.getfield s Lua_api_lib.globalsindex "debug";
					Lua_api.Lua.getfield s (-1) "traceback";
					Lua_api.Lua.pushvalue s 1;
					Lua_api.Lua.pushinteger s 2;
					Lua_api.Lua.call s 2 1;
					let trace = match Lua_api.Lua.tostring s (-1) with
						| Some s -> s
						| None -> "No traceback found"
					in
					let regexp = Str.regexp "\\\n" in
					let trace = Str.global_replace regexp "<br />" trace in
					let regexp = Str.regexp "\\\t" in
					let trace = Str.global_replace regexp "&nbsp;&nbsp;&nbsp;&nbsp;" trace in
					let trace = "<pre>" ^ trace ^ "</pre>" in
					chat trace;
					*)
					Lua.error s "Could not add gadget slider: range must be above or equal to 0";
				);

				{
					gadget_id;
					type_ = "slider";
					text = "";
					player_nrs;
					callback;
					spec = Slider (int_of_float bottom, int_of_float top, int_of_float step, int_of_float value)
				}
			| Some "confirm", Some text ->

				if String.length text > 2000 then
					Lua.error s "Could not add gadget confirm: text too long (maximum: 2000 characters)";

				let title = match getstring s "title" with
					| Some title -> title
					| None -> ""	(* Default title to empty string *)
				in

				{
					gadget_id;
					type_ = "confirm";
					text;
					player_nrs;
					callback;
					spec = Confirm title;
				}
			| _, _ ->
				Lua.error s "No type or text found for gadget";
	in

	(* List of supported gadgets types *)
	(*let supported_gadgets = ["button"; "select"; "input"] in*)

	(** Adds a gadget to specific user interfaces 

			Example:
			gadget = {
				gadget_id = 1,
				type = "button",
				text = "Tryck",
				players = {player1}
				callback = function() 
					chat("You pressed a button")
				end
			}
			add_gadget(gadget)
	*)
	Lua.LUA.pushcfunction s "add_gadget" (fun s ->
		(* stack: -1 => gadget *)
		if not (Lua_api.Lua.istable s (-1)) then
			Lua.error s "No gadget found"
		else (
			let gadget = gadget_of_state s in
			add_gadget s gadget;

			(* Broadcast new gadget *)
			broadcast {
				command_type = Add_gadget gadget; 
				username = "System"
			}

		);
		0
	);

	(** Updates @gadget 
			Cannot update callback *)
	Lua.LUA.pushcfunction s "update_gadget" (fun s ->
		if not (Lua_api.Lua.istable s (-1)) then
			Lua.error s "No input gadget found"
		else (
			let gadget = gadget_of_state s in
			if List.exists (fun g -> g.gadget_id = gadget.gadget_id) !gadgets then 
				broadcast {
					command_type = Update_gadget gadget; 
					username = "System"
				}
			else 
				Lua.error s (print "update_gadget: Found no gadget with id %d" gadget.gadget_id)
		);
		0
	);

	(** Remove gadget @g from user interface
			Gadget must have correct gadget_id *)
	Lua.LUA.pushcfunction s "remove_gadget" (fun s ->
		if not (Lua_api.Lua.istable s (-1)) then
			Lua.error s "No gadget found as argument";
		let gadget_id = getint s "gadget_id" in
		remove_gadget s gadget_id;
		broadcast {command_type = Remove_gadget gadget_id; username = "System"};
		0
	);

	(** Get location from Lua to OCaml.
			Assumes location is on top of stack
			Return location and pops it from stack *)
	let get_location s =
		(* stack: -1 => location *)
		let slot_type = getstring s "slot_type" in
		(* Fetch different fields depending on slot type *)
		match slot_type with
			| Some "player_slot" -> 
				Lua_api.Lua.getfield s (-1) "player";
				let player_nr = getint s "player_nr" in
				Lua_api.Lua.pop s 1; 
				let slot_nr = getint s "slot_nr" in
				Lua_api.Lua.getfield s (-1) "index";
				(* Index nil? *)
				let isnil = Lua_api.Lua.isnil s (-1) in				(* stack: -1 => slot, -2 => table_slots *)
				Lua_api.Lua.pop s 1;
				let index = if isnil then (-1) else getint s "index" in
				Lua_api.Lua.pop s 1;
				{
					slot_type = A_player_slot;
					player_nr;
					slot_nr;
					index;
				}
			| Some "table_slot" -> 
				let slot_nr = getint s "slot_nr" in
				Lua_api.Lua.getfield s (-1) "index";
				(* Index nil? *)
				let isnil = Lua_api.Lua.isnil s (-1) in				(* stack: -1 => slot, -2 => table_slots *)
				Lua_api.Lua.pop s 1;
				let index = if isnil then (-1) else getint s "index" in
				Lua_api.Lua.pop s 1;
				{
					slot_type = A_table_slot;
					slot_nr;
					index;
					player_nr = (-1);
				}
			| Some "player_hand" -> 
				Lua_api.Lua.getfield s (-1) "player";
				let player_nr = getint s "player_nr" in
				Lua_api.Lua.pop s 1; 
				Lua_api.Lua.getfield s (-1) "slot_nr";	(* player_hand can be with or without slot_nr, depending on src or dest *)
				let isnil = Lua_api.Lua.isnil s (-1) in				(* stack: -1 => slot, -2 => table_slots *)
				Lua_api.Lua.pop s 1;
				let slot_nr = if isnil then (-1) else getint s "slot_nr" in
				Lua_api.Lua.pop s 1;
				{
					slot_type = A_player_hand;
					player_nr;
					slot_nr;
					index = (-1);
				}
			| Some s -> failwith (print "get_location: illegal slot type: %s" s)
			| None -> failwith "get_location: found no slot_type"
	in

	(**	Animation function 
			Second arg can be both slot description or short notation in form of a string, like "player1.hand" or "table_slots[1]"

			Example:
			move_card(card, dest, callback)
			move_card(card, {slot_type = "table_slot", slot_nr = 1}, function() table_slots[1] = card; update_table() end)
			move_card(card, string.format("player%d.slots[%d]", player.player_nr, slot_nr), function() player.slots[slot_nr] = card; update_player_slots(player) end)
			move_card(deck1.cards[0], player1.hand)
	*)
	Lua.LUA.pushcfunction s "move_card" (fun s ->
		(* stack: -1 => callback, -2 => destination/string, -3 => card *)
		let isnil1 = Lua_api.Lua.isnil s (1) in
		let isnil2 = Lua_api.Lua.isnil s (2) in

		if isnil1 || isnil2 then
			Lua.error s "move_card: Missing source (card) or destination (slot) ";

		(* 3 if callback, 2 otherwise *)
		let length = Lua_api.Lua.gettop s in

		(try

			(* Get callback id *)
			let anim_callback = if length = 3 then Some (
				let id = Lua_api.LuaL.ref_ s Lua_api.Lua.registryindex in
				add_anim_callback id;
				id
				) else None in
			if anim_callback = Some Lua_api.LuaL.refnil then
				Lua.error s "No callback found for action";

			(* Get dest *)
			let isstring = Lua_api.Lua.isstring s (-1) in	(* stack: -1 => dest, -2 => card *)
			let dest = if not isstring then get_location s else failwith "move_card: Short notation not implemented" in		(* stack: -1 => card *)

			(* Get src card nr *)
			let card_nr = getint s "card_nr" in

			(* Locate card *)
			Lua_api.Lua.getglobal s "__locate_card";	(* stack: -1 => locate_card, -2 => card *)
			Lua_api.Lua.getglobal s (print "card%d" card_nr);	(* stack: -1 => card, -2 => locate_card, -3 => card *)
			let thread_state = Lua_api.Lua.pcall s 1 1 0 in (* stack: -1 => result/location, -2 => card *)
			(match thread_state with
				| Lua_api.Lua.LUA_OK -> ()
				| err -> 
					let err_msg = Lua_api.Lua.tostring s (-1) in
					Lua_api.Lua.pop s 1;  (* Pop message from stack *)
					log (Misc.get_opt err_msg);
					Lua.error s "move_card: Could not call __locate_card: Check so that you have both arguments to move_card (card, dest_slot, [callback])"
			);
			(* Check result from __locate_card *)
			if not (Lua_api.Lua.istable s (-1)) then
				Lua.error s "No table result from __locate_card";
			(* Get src *)
			let src = get_location s in			(* stack: -1 => card *)

			(*
			let string_of_slot_type = function
				| A_table_slot -> "A_table_slot"
				| A_player_slot -> "A_player_slot"
				| A_player_hand -> "A_player_hand"
			in
			log (print "src = %s, %d, %d, %d" 
				(string_of_slot_type src.slot_type)
				src.slot_nr
				src.index
				src.player_nr
				);
			*)

			broadcast {
				command_type = Animate {
					src;
					dest;
					anim_callback = match anim_callback with Some a -> a | None -> -1;
				};
				username = "System"
			};

		with ex ->
			let backtrace = Printexc.get_backtrace () in
			let msg = Printexc.to_string ex in
			log (print "Error: %s\nBacktrace: %s" msg backtrace);
		);
		(* First find out if short notation is used 
			typeof top of stack 
			if string, parse 
			else get slot_type, slot_nr, index if present, player if present
			get __locate_card of card
			send src and dest to client to animate
			when done, run callback (should contain an update, which hides anim imgs in html)
		*)
		0
	);

	(** Update points table, to see score etc
		Example:
			points_table = {
				{"", "Olle", "Anders"},
				{"Points", "0", "10"},
				{"Fusk", "1", "2"}
			}
			update_points_table(points_table)
	*)
	Lua.LUA.pushcfunction1 s "update_points_table" (fun s ->
		(* Get list of string lists lists *)
		let table = Lua.LUA.fold_rawgeti s (fun s ->
			let lst = Lua.LUA.fold_rawgeti s (fun s ->
				let (s, str) = Lua.LUA.tostring s in
				(s, str)
			) in
			(s, lst)
		) in
		let s = Lua.LUA.pop s in
		Lua.LUA.endstate s;
		broadcast {
			command_type = Update_points_table table;
			username = "System"
		};
		0
	);

	(** Shows the hand icon for all players. Needed to move cards to hand *)
	Lua.LUA.pushcfunction0 s "show_hand_icon" (fun s ->
		broadcast {
			command_type = Show_hand_icon;
			username = "System";
		};
		0
	);

	(** true if @gadget has been added *)
	Lua.LUA.pushcfunction1 s "gadget_exists" (fun s ->
		let (s, gadget_id) = Lua.LUA.getnumber s "gadget_id" in
		let gadget_id = int_of_float gadget_id in
		let exists = List.exists (fun g -> g.gadget_id = gadget_id) !gadgets in
		let s = Lua.LUA.pop s in
		ignore(Lua.LUA.pushboolean s exists);
		1
	);

	(** Get card list
			Assumes card list on top of stack. Does not affect stack *)
	let get_card_list s = 
		let open Lua.LUA in
		fold_rawgeti s (fun s ->
			(* stack: -1 => card, -2 => card list *)
			let (s, card_nr) = getnumber s "card_nr" in
			let (s, card_id) = getnumber s "id" in
			let (s, dir) = getstring s "dir" in
			let (s, img) = getstring s "img" in
			(s, {
				card_nr = int_of_float card_nr; 
				card_id = int_of_float card_id; 
				dir; 
				img;
			})
		) 
	in

	(** Enable draggable cards
		
		Example:
		enable_draggable(players, card_list, slot_list, callback)
	*)
	Lua.LUA.pushcfunction4 s "enable_draggable" (fun s ->
		(* stack: -1 => callback, -2 => slot_list, -3 => card_list, -4 => players *)
		let open Lua.LUA in
		(* Store callback *)
		let (s, callback) = ref_ s Lua_api.Lua.registryindex in		(* stack: -1 => slot_list, -2 => card_list *)
		(* Get slot list *)
		let slot_list = fold_rawgeti s (fun s ->
			(* stack: -1 => slot, -2 => slot_list *)
			let (s, slot_type) = getstring s "slot_type" in
			let (s, slot_type) = match slot_type with
				| "table_slot" ->
					(* Get table slots *)
					let s = getfield s "slot_nrs" in	(* stack: -1 => slot_nrs, -2 => slot, -3 => slot_list *)
					let slot_nrs = fold_rawgeti s (fun s ->
						(* stack: -1 => slot_nr, -2 => slot_nrs, -3 => slot, -4 => slot_list  *)
						let (s, slot_nr) = tonumber s in
						(s, int_of_float slot_nr)
					) in
					let s = pop s in	(* stack: -1 => slot, -2 => slot_list *)
					(s, Table_slot slot_nrs)
				| "player_slot" ->
					(* Get player slots *)
					let s = getfield s "players" in
					let player_nrs = fold_rawgeti s (fun s ->
						let (s, player_nr) = getnumber s "player_nr" in
						(s, int_of_float player_nr)
					) in
					let s = pop s in
					let s = getfield s "slot_nrs" in
					let slot_nrs = fold_rawgeti s (fun s ->
						let (s, slot_nr) = tonumber s in
						(s, int_of_float slot_nr)
					) in
					let s = pop s in
					(s, Player_slot (player_nrs, slot_nrs))
				| "player_hand" ->
					(* Get players for player hand *)
					let s = getfield s "players" in
					let player_nrs = fold_rawgeti s (fun s ->
						let (s, player_nr) = getnumber s "player_nr" in
						(s, int_of_float player_nr)
					) in
					let s = pop s in
					(s, Player_hand player_nrs)
				| slot_type ->
					(* Invalid slot type, abort *)
					error s (print "enable_draggable: Wrong slot type: %s" slot_type);
					raise ApiError
			in
			(s, slot_type)
		) in
		let s = pop s in	(* -1 => card list, -2 => players *)
		let card_list = get_card_list s in
		let s = pop s in	(* -1 => players *)
		(* Update player nrs *)
		draggable_player_nrs := fold_rawgeti s (fun s ->
			let (s, player_nr) = getint s "player_nr" in
			(s, player_nr)
		);
		let s = pop s in
		endstate s;
		(* TODO: Need mutex for this? In case of real-time function? *)
		draggable_cards := card_list;
		droppable_slots := slot_list;
		draggable_callback := callback;
		broadcast {
			command_type = Enable_draggable (!draggable_player_nrs, card_list, slot_list);
			username = "System";
		};
		0
	);

	let open Lua.LUA in

	(** Enable onclick
			Example: enable_onclick({card1, card2}, function(player, card) chat("Clicked card") end) *)
	pushcfunction2 s "enable_onclick" (fun s ->
		(* stack: -1 => callback, -2 => card list *)
		(* Store callback *)
		let (s, callback) = ref_ s Lua_api.Lua.registryindex in		(* stack: -1 => card_list *)
		onclick_callback := callback;
		let cards = get_card_list s in
		onclick_cards := cards;
		let s = pop s in	(* stack: empty *)
		endstate s;
		broadcast {
			command_type = Enable_onclick cards;
			username = "System";
		};
		0
	);

	pushcfunction1 s "set_realtime" (fun s ->
		(* stack: -1 => callback *)
		let (s, callback) = ref_ s Lua_api.Lua.registryindex in		(* stack: empty *)
		with_mutex realtime_mutex (fun () ->
			realtime_callback := callback;
		);
		endstate s;
		(* Stop current event, if any *)
		(match !realtime_event with 
			| None ->
				()
			| Some ev ->
				log "stopping realtime event";
				Lwt_engine.stop_event ev
		);
		log "new realtime event";
		realtime_event := Some (Lwt_engine.on_timer 0.1666666 true (fun event ->	(* 6 fps *)
			timestamp := !timestamp + 1;
			if (!timestamp > 999999999) then timestamp := 1;	(* reset timestamp to 1 *)
			with_mutex realtime_mutex (fun () ->
				if !realtime_callback = 0 then
					()	(* Do nothing *)
				else (
					(* Run callback *)
					(*(try Misc.get_opt !state with Not_found -> failwith "No state for realtime callback");*)
					(try
						let s = rawgeti_registryindex s !realtime_callback in		(* stack: -1 => callback fn *)
						let s = pcall_fn0_noresult s in	(* stack: empty *)
						endstate s;
					with
						ex ->
            	let msg = Printexc.to_string ex in
							broadcast_error msg
					);
				)
			);
		));
		0
	);

	(** Copy of function above, but with 60 FPS *)
	pushcfunction1 s "set_realtime60" (fun s ->
		(* stack: -1 => callback *)
		let (s, callback) = ref_ s Lua_api.Lua.registryindex in		(* stack: empty *)
		with_mutex realtime_mutex (fun () ->
			realtime_callback := callback;
		);
		endstate s;
		(* Stop current event, if any *)
		(match !realtime_event with 
			| None ->
				()
			| Some ev ->
				log "stopping realtime event";
				Lwt_engine.stop_event ev
		);
		log "new realtime event";
		realtime_event := Some (Lwt_engine.on_timer (1. /. 60.) true (fun event ->	(* test, 60 fps *)
			timestamp := !timestamp + 1;
			if (!timestamp > 999999999) then timestamp := 1;	(* reset timestamp to 1 *)
			with_mutex realtime_mutex (fun () ->
				if !realtime_callback = 0 then
					()	(* Do nothing *)
				else (
					(* Run callback *)
					(*(try Misc.get_opt !state with Not_found -> failwith "No state for realtime callback");*)
					(try
						let s = rawgeti_registryindex s !realtime_callback in		(* stack: -1 => callback fn *)
						let s = pcall_fn0_noresult s in	(* stack: empty *)
						endstate s;
					with
						ex ->
            	let msg = Printexc.to_string ex in
							broadcast_error msg
					);
				)
			);
		));
		0
	);
	
	
	(** Disable realtime function *)
	pushcfunction0 s "unset_realtime" (fun s ->
		(match !realtime_event with 
			| None ->
				()
			| Some ev ->
				log "stopping realtime event";
				Lwt_engine.stop_event ev
		);
		0
	);

	(** Bind function to keydown 
			Example: bind_key(65, callback) *)
	pushcfunction2 s "bind_key" (fun s ->
		(* stack: -1 => callback, -2 => char code *)
		let (s, callback) = ref_ s Lua_api.Lua.registryindex in	(* stack: -1 => char code *)
		let (s, char_code) = toint s in
		let s = pop s	in (* stack: empty *)

		(* Check so char code doesn't already exists *)
		if List.exists (function 
			| Key_binding (charc, callb) ->
			  charc = char_code
			)
			!keydown_bindings
		then
			error s (print "binding already exists for character code %d" char_code);

		(* Check so that char code is within 8-222 *)
		if char_code < 8 || char_code > 222 then
			error s "Character code must be between 8 and 222";

		keydown_bindings := Key_binding (char_code, callback) :: !keydown_bindings;
		endstate s;
		broadcast {
			command_type = Bind_key !keydown_bindings;
			username = "System";
		};
		0
	);

	(** Unbinds the key with character code 
			Example: unbind_key(68) *)
	pushcfunction1 s "unbind_key" (fun s ->
		let (s, char_code) = toint s in
		let s = pop s	in (* stack: empty *)
		endstate s;
		(* Check so char code exists *)
		if not (List.exists (function 
			| Key_binding (charc, callb) ->
			  charc = char_code
			)
			!keydown_bindings)
		then
			error s (print "Found no binding with character code %d" char_code);

		keydown_bindings := List.filter (function Key_binding (charc, callb) ->
			charc <> char_code
		) !keydown_bindings;

		broadcast {
			command_type = Bind_key !keydown_bindings;
			username = "System";
		};
		0
	);

	(** Enable use of canvas instead of div, table, etc
			Example: enable_canvas() *)
	pushcfunction0 s "enable_canvas" (fun s ->
		broadcast {
			command_type = Enable_canvas;
			username = "System";
		};
		0
	);

	(** Disable canvas and enables draggable/markable/etc again *)
	pushcfunction0 s "disable_canvas" (fun s ->
		broadcast {
			command_type = Disable_canvas;
			username = "System";
		};
		0
	);

	(** Movables commands *)
	pushcfunction1 s "set_movables" (fun s ->
		(* stack: -1 => movables list *)
		let movables = fold_rawgeti s (fun s ->
			let (s, obj_id) = getnumber s "obj_id" in
			let obj_id = int_of_float obj_id in
			let (s, x) = getnumber s "x" in
			let (s, y) = getnumber s "y" in
			let (s, x_vel) = getnumber s "x_vel" in
			let (s, y_vel) = getnumber s "y_vel" in
			let (s, x_acc) = getnumber s "x_acc" in
			let (s, y_acc) = getnumber s "y_acc" in
			let s = getfield s "card" in
			let (s, dir) = getstring s "dir" in
			let (s, img) = getstring s "img" in
			let card = {dir; img; card_nr = (-1); card_id = (-1)} in
			let s = pop s	in
			(s, {obj_id; card; x; y; x_vel; y_vel; x_acc; y_acc})
		) in
		broadcast {
			command_type = Set_movables (!timestamp, movables);	(* global variable timestamp, increases in set_realtime() *)
			username = "System";
		};
		0
	);

	(* End of API *)
()
;;

(** Start game session *)
let start client env = 
	(* Check that this is session creator *)
	if !state <> None then
		failwith "Lua state is not empty";

	if !game_state = Running then
		failwith "Game still running";
	
	if client.user.User.id <> env#user.User.id then
		failwith "Only session creator can start game";

	(try 
		(* Start Lua state and add players, decks etc *)
		state := Some (Lua.start env (List.map (fun client -> (client.player_id, client.user)) !clients));	(* This might raise exception *)
		(** Random seed *)
		state := (try Some (Lua.LUA.runstring (Misc.get_opt !state) "math.randomseed(os.time())" "randomseed") with
			_ -> 
				begin
					broadcast_error "Could not run math.randomseed";
					None
				end;
		);

														(* getn = table.getn *)
		state := (try Some (Lua.LUA.runstring (Misc.get_opt !state) "getn = table.getn" "getn") with
			_ -> 
				begin
					broadcast_error "Could not run math.randomseed";
					None
				end;
		);

		(* Get api Lua functions (shuffle, pick_card ...), and push them into Lua state *)
		let common_scripts = Lua.Api.get_apis env#db in
		List.iter (fun script ->
			state := (try 
				(*log(script.Lua.Api.script);*)
				Some (Lua.LUA.runstring (Misc.get_opt !state) script.Lua.Api.script ("adding api " ^ script.Lua.Api.name)) with
				_ ->
					begin
						broadcast_error ("Could not run api function " ^ script.Lua.Api.name);
						None
					end
			)
		) common_scripts;

		(* Sandbox. Remove os, io tables TODO: Add more to remove, like setmetatable, etc *)
		state := (try Some (Lua.LUA.runstring (Misc.get_opt !state) "
			io = nil; 
			os = nil;
			loadstring = nil;
			load = nil;
			loadfile = nil;
			package = nil;
			module = nil;
			require = nil;
			sprintf = string.format;
			dofile = nil;
			-- debug = nil;					-- debug.trace required for Lua stacktrace
			setfenv = nil;
			-- getmetatable = nil;	-- Required for dump function?
			-- setmetatable = nil;
			" "sandbox") with
			_ -> 
				begin
					broadcast_error "Could not sandbox Lua";
					None
				end;
		);

		(* Add API from db to Lua *)
		(try add_api (Misc.get_opt !state) env client;
		with ex ->
			let backtrace = Printexc.get_backtrace () in
			let msg = Printexc.to_string ex in
			let msg = msg ^ "\nBacktrace: " ^ backtrace in
			log ("Error: " ^ msg);
			failwith "Fail";
		);

		(* Send out info about hands and slots to build up html divs at clients. *)
		broadcast {command_type = Build_html (
				(* Reverse clients to get right order in javascript *)
				(let clients' = List.rev !clients in List.map (fun client -> client.user.User.username) clients'),
				env#game.Game.hands,
				env#game.Game.player_slots,
				env#game.Game.table_slots,
				env#game.Game.gadgets
			); 
			username = "System"
		};

		broadcast {command_type = Start; username = client.user.User.username};
		players_turn := (Random.int !players_online) + 1;
		set_players_turn !players_turn;
		broadcast {
			command_type = Players_turn !players_turn; 
			username = "System"
		};

		(* Set starttime for game session *)
		(* TODO: This won't work, because this version of env will deleted when out of scope *)
		Gamesession.start_game_session env#db env#get_game_session;
		(*Lwt_preemptive.detach (fun () -> Gamesession.start_game_session env#db env#get_game_session) ();*)

		(* Run game init script *)
		let init_script = env#game.Game.init_script in 
		state := (try Some (Lua.LUA.runstring (Misc.get_opt !state) init_script "init_script") with
			| Not_found ->
				broadcast {command_type = Error ("Could not run game init script:\n\n found no error message"); username = "System"};
				None
			| Lua.LuaException msg ->
				broadcast {command_type = Error ("Could not run init script:\n\n" ^ msg); username = "System"};
				None
		);

		(** 	Help function 
			@return state option *)
		let runstring str chunkname =
			try Some (Lua.LUA.runstring (Misc.get_opt !state) str chunkname) with
				ex ->
					begin
						let msg = Printexc.to_string ex in
						(*let msg = msg ^ "\nBacktrace: " ^ (Printexc.get_backtrace ()) in*)
						broadcast_error ("Could not run " ^ chunkname ^ ": " ^ msg);
						None
					end
		in

		(* Add onplay_all *)
		state := runstring env#game.Game.onplay_all "onplay_all"; 
		state := runstring env#game.Game.onpickup_all "onpickup_all"; 
		state := runstring env#game.Game.onbeginturn "onbeginturn";
		state := runstring env#game.Game.onendturn "onendturn";
		state := runstring "init();" "init()";

		game_state := Running;

		(* Run onbeginturn for beginning player *)
		onbeginturn ()
	with
		ex ->
			(* Get stack trace? *)
			let msg = Printexc.to_string ex in
			(*let msg = msg ^ "\nBacktrace: " ^ (Printexc.get_backtrace ()) in*)
			log ("Error: " ^ msg);
			broadcast {command_type = Error ("Could not start lua state: " ^ msg); username = "System"};
	)

(**
	Listen for new clients

	@param sock_listen	socket to listen on
	@param env		immediate object; env containing user_id, game_session etc
*)
let rec main sock_listen env =

	(** accept client, and get the websocket channel for this client *)
	Lwt_websocket.Channel.accept sock_listen >>= fun (channel, addr) ->

	(* Add channel if still room (max players limit not reached), else send error message *)
	if (List.length !clients < env#game.Game.max_players && !game_state = Lobby) then
		begin
			(* Wait for login *)
			ignore (channel#read_frame >>= function
				| Lwt_websocket.Frame.TextFrame text ->
					(* Parse command to Json *)
					let in_command = 
						(try 
							command_of_json (Json_io.json_of_string text) 
						with
							_ -> 
								ignore(Lwt_io.eprintl "json error"); 
								{command_type = Error ("Json parse error: " ^ text); 
								username = "System"}
						) in

					(match in_command.command_type with
						| Login (username, session_id, password) ->
							let login = LoginCookie.check_login_aux env#db username session_id in	(* session_id = user session id *)
							(* Check login cookie *)
							(match login with
								  | User.Logged_in user | User.Guest user -> 
								  	(* Check for game session password *)
									let session_password = (env#get_game_session).Gamesession.password in
									if session_password = "" || Db.digest password = session_password then
										begin
											let client = add_client channel user in
											players_online := !players_online + 1;
											broadcast_users();

											(*let game_session = env#get_game_session in*)
											(*let game_session_id = Misc.get_opt game_session.Gamesession.id in*)

											(* Start up a listening thread *)
											ignore (return (handle_client client env));
										end
									else
										begin
											send channel {command_type = Error "Wrong game session password"; username = "System"};
											ignore(channel#write_close_frame);
											exit_if_last env
										end
								| User.Not_logged_in -> 
									send channel {command_type = Error "User not logged in"; username = "System"};
									ignore(channel#write_close_frame);
									exit_if_last env
							)
						| Error _ ->
							(* Could not parse JSON *)
							send channel in_command;
							ignore(channel#write_close_frame);
							exit_if_last env
						| _ ->
							(* Error, must have login as first message *)
							send channel {command_type = Error "Must login as first message"; username = "System"};
							ignore(channel#write_close_frame);
							exit_if_last env
					);
					return ()
			  | Lwt_websocket.Frame.CloseFrame(status_code, body) ->
					ignore(channel#write_close_frame);
					exit_if_last env;
					return ()
				| _ ->
					exit_if_last env;
					return ()
			);
		end
	else
		begin
			send channel {command_type = Error "Already max players or game started"; username = "System"};
			ignore(channel#write_close_frame);
			()
		end;

      (* Listen for other users *)
      main sock_listen env

and handle_client client env =

	client.channel#read_frame >>= function

		(** ping -> pong *)
		| Lwt_websocket.Frame.PingFrame(msg) ->
			client.channel#write_pong_frame >>= fun () ->
			handle_client client env (** wait for close frame from client *)

		(** text frame -> echo back *)
		| Lwt_websocket.Frame.TextFrame text ->

			(* Reset timeout *)
			with_mutex active_mutex (fun () ->
						active_since_last_timeout := true;
			);
      
		(* Parse command to Json *)
		let in_command = (try command_of_json (Json_io.json_of_string text) with _ -> 
			log "json error"; 
			{
				command_type = Error ("Json parse error: " ^ text); 
				username = "System"
			}
		) in

	(try 	(* For your safety... *)
	(match in_command.command_type with
		| Chat msg ->
			broadcast {
				command_type = Chat (escape msg);
				username = client.user.User.username;
			}
		| Error msg ->
			broadcast in_command
		| Add_participate -> (
			(* This might fail if user click "back" and "forth" on browser*)
			try 
				let game_session_id = Misc.get_opt (env#get_game_session).Gamesession.id in
				ignore (Participates.add_participate env#db client.user.User.id game_session_id);
				()
				(*log (print "added part, user id = %d, session_id = %d" client.user.User.id game_session_id);*)
			with
				_ ->
					chat "Can't join session. Did you use the forword button on the browser instead of a button on the webpage?";
					(* Close down everything *)
					players_online := !players_online - 1;
					remove_client client.channel_id env;
					broadcast {command_type = Chat (client.user.User.username ^ " went offline"); username = "System"};
					broadcast_users(); 
					ignore(client.channel#write_close_frame);
			)
		| Websocket_connected ->
			let game_session = env#get_game_session in
			if not !websocket_connected then (
				(* Set game session as connected *)
				Gamesession.websocket_connected env#db game_session;
				websocket_connected := true;
			)
		| Login (username, session_id, password) ->
			(* Should not login here *)
			log("login request");
			send client.channel {command_type = Error "Should not login now"; username = "System"};
			()
		| Start ->
			start client env
		| Play_again ->
			(* Reset everything *)
			actions := ActionMap.empty;
			gadgets := [];
			state := None;
			draggable_callback := 0;
			draggable_cards := [];
			droppable_slots := [];
			draggable_player_nrs := [];
			onclick_callback := 0;
			onclick_cards := [];
			enable_marking := [];
			realtime_callback := 0;
			realtime_event := None;
			keydown_bindings := [];
			start client env
		| Dump_decks ->
			debug env client (fun s -> 
				let dump_info = Lua.dump s "decks" in
				send client.channel {command_type = Deck_dump dump_info; username= "System"};
      )
		| Dump_players ->
			debug env client (fun s -> 
				let dumped_players = Lua.dump s "players" in
				send client.channel {command_type = Player_dump dumped_players; username= "System"};
			)
		| Dump_table ->
			debug env client (fun s -> 
				let dump = Lua.dump s "table_slots" in
				send client.channel {command_type = Table_dump dump; username= "System"};
		)
		| Execute_lua script ->
				debug env client (fun s -> 
					Lua.LUA.endstate (Lua.LUA.runstring s script "execute lua")
				)
	(**
	 *    Actions sent from client
	 *)
	(* Pick a card from deck *)
	| Action (Pick_card_data deck_nr) ->
		(* Check if there is an action for this player *)
		if ActionMap.exists (fun k v -> match v with
			| Add_menu_to_deck (deck_nr, Pick_card mt, players) ->
					List.exists (fun p_nr -> p_nr = client.player_id) players
				| _ ->
					false
				)
				!actions
			then
				action client "pick_card" (fun s ->
					let s = Lua.LUA.getfn s "__pick_card" in
					let s = Lua.LUA.pushnumber2 s (float_of_int client.channel_id) in
					let s = Lua.LUA.pushnumber2 s (float_of_int deck_nr) in
					let s = Lua.LUA.pushnumber2 s 1.0 in
					let s = Lua.LUA.pcall_fn3 s in
					let (s, _) = Lua.LUA.fn_getbool s in

					(* Update hands *)
					update_hand s client;
					update_other_hands s;

					Lua.LUA.endstate s;
				)
			else
				broadcast {command_type = Error ("This action (pick card) is not available for this player"); username = "System"}
		(* Play a card from hand *)
		| Action (Play_card_data card_nr) ->
			(* Check if there is an action for this player *)
			if ActionMap.exists (fun k a -> match a with
				| Add_menu_to_hand (Play_card mt, player_nrs) ->
					List.exists (fun p_nr -> 
						p_nr = client.player_id) 
						player_nrs
				| _ ->
					false
				)
				!actions
			then
				action client "play_card" (fun s ->
					let player = "player" ^ (string_of_int client.player_id) in

					(* Check so that player really have card on hand *)
					let has_card' = has_card s player card_nr in

					(* Does player really have card? *)
					if has_card' then
						begin
							(* Call internal Lua function *)
							let s = Lua.LUA.getfn s "__play_card" in
							let s = Lua.LUA.pushnumber2 s (float_of_int client.player_id) in
							let s = Lua.LUA.pushnumber2 s (float_of_int card_nr) in
							let s = Lua.LUA.pcall_fn2 s in
							let (s, result) = Lua.LUA.fn_getbool s in
							Lua.LUA.endstate s;
							()
						end
					else
						(* Hacking attempt or bug? *)
						broadcast_error ("Player has no card with card_nr " ^ (string_of_int card_nr))
				)
			else
				broadcast {command_type = Error ("This action (play card) is not available for this player"); username = "System"}
		(* Play a card from player slot (can be deck, overlay, stack or card faced up/down) *)
		(* TODO: Expand this to play cards from table slots too? *)
		| Action (Play_slot_card_data slot_nr) ->
			(* Check that this action exists for this player and slot *)
			if ActionMap.exists (fun k a -> match a with
				| Add_menu_to_player_slot (Play_card mt, slot_nrs, player_nrs) ->
					(* Return true if player_id is in player_nrs and slot_nr is in slot_nrs *)
					(* TODO: Test this more *)
					List.mem client.player_id player_nrs && List.mem slot_nr slot_nrs
				| _ ->
					false
				)
				!actions
			then
				action client "play_card" (fun s ->
					(* First we need card_nr on top of slot *)
					let open Lua in
					let s = Misc.get_opt !state in
					let s = LUA.gettable s ("player" ^ string_of_int client.player_id) in
					let s = LUA.getfield s "slots" in
					let s = LUA.rawgeti s slot_nr in	(* stack: -1 => slot, -2 => slots, -3 => player *)
					let (s, __type) = LUA.getstring s "__type" in
					let s = (match __type with
						| "overlay" | "stack" ->
							(* Get card_nr *)
							let (s, length) = LUA.objlen s in
							let s = LUA.rawgeti s length in	(* stack: -1 => card, -2 => cards, -3 =>, slot, -4 => slots, ..*)
							let (s, card_nr) = LUA.getnumber s "card_nr" in
							let card_nr = int_of_float card_nr in
							let s = LUA.pop s in	(* Pop all! *)
							let s = LUA.pop s in
							let s = LUA.pop s in
							let s = LUA.pop s in

							(* Play card *)
							let s = Lua.LUA.getfn s "__play_card" in
							let s = Lua.LUA.pushnumber2 s (float_of_int client.player_id) in
							let s = Lua.LUA.pushnumber2 s (float_of_int card_nr) in
							let s = Lua.LUA.pcall_fn2 s in
							let (s, result) = Lua.LUA.fn_getbool s in
							s
						| "card" ->
							raise (WebsocketException "Not implemented: play slot card from card")
						| "deck" ->
							raise (WebsocketException "Not implemented: play slot card from deck")
						| _ ->
							raise (WebsocketException ("Play_slot_card_data: Unknown type in slot: " ^ __type))
					) in
					LUA.endstate s;
					()
				)
			else
				broadcast {command_type = Error ("This action (play card from player table) is not available for this player"); username = "System"}
		(** Action for table slots and player slots using callbacks *)
		| Action (Callback_data (action_id, slot_nr, "table_slot")) ->

			(* Get action *)
			let action_record = match ActionMap.find action_id !actions with
				| Add_callback_to_slot action_record -> action_record
				| _ -> failwith (print "Did not find callback action with action_id %d" action_id)
			in

			(* Check so that slot_nr is in callback *)
			if not (List.mem slot_nr action_record.target_ids) then
				failwith (print "Slot nr is not in action: %d" slot_nr);

			(* Check players turn *)
			if !players_turn <> client.player_id then
				failwith (print "Not this players turn: %d" client.player_id);

			if !game_state <> Running then
				failwith "Game not running";

			(* Run callback for this action *)
			let open Lua in
			let s = Misc.get_opt !state in
			let s = LUA.rawgeti_registryindex s action_record.a_callback in		(* stack: -1 => callback *)
			let s = LUA.getglobal s (print "player%d" client.player_id) in 	(* stack: -1 => player, -2 => callback *)
			let s = LUA.getglobal s "table_slots" in	(* stack: -1 => table_slots, -2 => player, -3 => callback *)
			let s = LUA.rawgeti s slot_nr in					(* stack: -1 => slot, -2 => table_slots, -3 => player, -4 => callback *)
			let s = LUA.remove_second s in			(* stack: -1 => slot, -2 => player, -3 => callback *)
			let s = LUA.pcall_fn2_noresult s in	(* stack: empty *)
			LUA.endstate s;
		(** Menus can only be added to ones ownes slots and hand *)
		| Action (Callback_data (action_id, slot_nr, "player_slot")) ->
			(* Get action *)
			let action_record = match ActionMap.find action_id !actions with
				| Add_callback_to_slot action_record -> action_record
				| _ -> failwith (print "Did not find callback action with action_id %d" action_id)
			in

			(* Check so that slot_nr is in callback *)
			if not (List.mem slot_nr action_record.target_ids) then
				failwith (print "Slot nr is not in action: %d" slot_nr);

			(* Check players turn *)
			if !players_turn <> client.player_id then
				failwith (print "Not this players turn: %d" client.player_id);

			if !game_state <> Running then
				failwith "Game not running";

			(* Run callback for this action *)
			let open Lua in
			let s = Misc.get_opt !state in
			let s = LUA.rawgeti_registryindex s action_record.a_callback in		(* stack: -1 => callback *)
			let s = LUA.getglobal s (print "player%d" client.player_id) in 	(* stack: -1 => player, -2 => callback *)
			let s = LUA.getfield s "slots" in		(* stack: -1 => slots, -2 => player, -3 => callback *)
			let s = LUA.rawgeti s slot_nr in					(* stack: -1 => slot, -2 => slots, -3 => player, -4 => callback *)
			let s = LUA.remove_second s in			(* stack: -1 => slot, -2 => player, -3 => callback *)
			let s = LUA.pcall_fn2_noresult s in	(* stack: empty *)
			LUA.endstate s;

		| Action (Callback_data (action_id, slot_nr, target)) ->
			failwith (print "Illegal target for Callback_data: %s" target)

		(**
		 *    Marking and unmarking
		 *)
		| Action (Mark marking_slot) -> (
				(* Check player turn *)
				if client.player_id = !players_turn then (
				match marking_slot with
					| Marking_player_slot (player_nr, slot_nr) -> (
							(* Check if this slot is markable *)
							let l = List.filter (fun slot ->
								match slot with
									| Player_slot (player_nrs, slot_nrs) ->
										(* Check so that player_nr and slot_nr is in lists *)
										List.mem player_nr player_nrs && List.mem slot_nr slot_nrs
									| _ ->
										false
								)
								!enable_marking
							in
							if List.length l > 0 then (
									let open Lua in
									let s = Misc.get_opt !state in
									let s = LUA.gettable s ("player" ^ string_of_int player_nr) in	(* stack: -1 => playerN *)
									let s = LUA.getfield s "slots" in		(* stack: -1 => slots, -2 => player *)
									let s = LUA.rawgeti s slot_nr in		(* stack: -1 => table/nil, -2 => slots, -3 => player *)
									if LUA.istable s then (
											let s = LUA.setboolean s ("marked", true) in
											let s = LUA.pop s in
											let s = LUA.pop s in
											let s = LUA.pop s in
											LUA.endstate s;
										)
									else (
										(* No table in slot, need to create one *)
										let s = LUA.pop s in				(* stack: -1 => slots, -2 => player *)
										(* if slot_nr > #player.slots + 1, then a gap is created in the table! *)
										let (s, slots) = LUA.objlen s in
										let diff = slot_nr - slots in
										if diff > 1 then (
												let rec fill_gaps i =
													if i < diff then (
															let s = LUA.newtable s in
															let s = LUA.setboolean s ("marked", false) in
															ignore (LUA.rawseti s (i + slots));
															fill_gaps (i + 1)
														)
													else
														()
												in
												fill_gaps 1
										);
										let s = LUA.newtable s in		(* stack: -1 => table, -2 => slots, -3 => player *)
										let s = LUA.setboolean s ("marked", true) in	(* stack: -1 => table, -2 => slots, -3 => player *)
										let s = LUA.rawseti s slot_nr in	(* stack: -1 => slots, -2 => player *)
										let s = LUA.pop s in
										let s = LUA.pop s in
										LUA.endstate s;
									);
								)
							else
								chat("Internal error: This slot is not enabled as markable.")
						)
					| Marking_table_slot slot_nr -> (
							(* Check if this slot is markable *)
							let l = List.filter (fun slot ->
								match slot with
									| Table_slot slot_nrs ->
										List.mem slot_nr slot_nrs
									| _ ->
										false
								)
								!enable_marking
							in
							if List.length l > 0 then (
									let open Lua in
									let s = Misc.get_opt !state in
									let s = LUA.gettable s "table_slots" in
									let (s, length) = LUA.objlen s in
									let s = LUA.rawgeti s slot_nr in	(* stack: -1 => slot, -2 => table_slots *)
									if LUA.istable s then (
											let s = LUA.setboolean s ("marked", true) in
											let s = LUA.pop s in
											let s = LUA.pop s in
											LUA.endstate s;
										)
									else (
										let s = LUA.pop s in				(* stack: -1 => table_slots *)
										(* if slot_nr > #table_slots + 1, then a gap is created in the table! *)
										let diff = slot_nr - length in
										if diff > 1 then (
												let rec fill_gaps i =
													if i < diff then (
															let s = LUA.newtable s in
															let s = LUA.setboolean s ("marked", false) in
															ignore (LUA.rawseti s (i + length));
															fill_gaps (i + 1)
														)
													else
														()
												in
												fill_gaps 1
										);
										let s = LUA.newtable s in	(* stack: -1 => new table, -2 => table_slots *)
										let s = LUA.setboolean s ("marked", true) in
										let s = LUA.rawseti s slot_nr in
										let s = LUA.pop s in
										LUA.endstate s
									)
								)
							else
								chat("Internal error: Marking_table_slot: This slot is not enabled as markable.")
						)

					| Marking_opponent_hand player_nr -> (
							chat "Marking_opponent_hand";
							let l = List.filter (fun slot ->
								match slot with
									| Player_hand player_nrs ->
										List.mem player_nr player_nrs
									| _ ->
										false
								)
								!enable_marking
							in
							if List.length l > 0 then (
								let open Lua in
								let s = Misc.get_opt !state in
								let s = LUA.gettable s ("player" ^ string_of_int player_nr) in	(* stack: -1 => playerN *)
								let s = LUA.getfield s "hand" in
								let s = LUA.setboolean s ("marked", true) in
								let s = LUA.pop s in
								let s = LUA.pop s in
								LUA.endstate s
							)
							else (
								chat("Internal error: Marking_opponent_hand: This hand is not enabled as markable.")
							)
						)
					| Marking_hand_slot hand_slot_nr -> (
							let l = List.filter (fun slot ->
								match slot with
									| Player_hand player_nrs ->
										(* Check if my hand is in Player_hand list *)
										List.mem client.player_id player_nrs
									| _ ->
										false
								)
								!enable_marking
							in
							if List.length l > 0 then (
								let open Lua in
								let s = Misc.get_opt !state in
								let s = LUA.gettable s ("player" ^ string_of_int client.player_id) in	(* stack: -1 => playerN *)
								let s = LUA.getfield s "hand" in		(* stack: -1 => hand, -2 => player *)
								let s = LUA.rawgeti s hand_slot_nr in	(* stack: -1 => card, -2 => hand, -3 => player *)
								if LUA.istable s then (
									let s = LUA.setboolean s ("marked", true) in
									let s = LUA.pop s in
									let s = LUA.pop s in
									let s = LUA.pop s in
									LUA.endstate s;
								)
								else (
									chat "Internal error: Marking_hand_slot: Trying to mark non-table/empty slot";
									let s = LUA.pop s in
									let s = LUA.pop s in
									let s = LUA.pop s in
									LUA.endstate s
								)
							)
							else
								chat "Internal error: Mark Marking_hand_slot: This slot is not enabled as markable"
						)
				)
				else (
					chat "Cannot mark slot: Not this players turn"
				)
			)
		| Action (Unmark marking_slot) -> (
				if client.player_id = !players_turn then (
				match marking_slot with
					| Marking_player_slot (player_nr, slot_nr) -> (
						let open Lua in
						let s = Misc.get_opt !state in
						let s = LUA.gettable s ("player" ^ string_of_int player_nr) in	(* stack: -1 => playerN *)
						let s = LUA.getfield s "slots" in		(* stack: -1 => slots, -2 => player *)
						let s = LUA.rawgeti s slot_nr in		(* stack: -1 => table/nil, -2 => slots, -3 => player *)
						let s = if LUA.istable s then (
									LUA.setboolean s ("marked", false)
						)
						else (
							chat "Internal error: Unmark Marking_player_slot: Did not find table";
							s
						) in
						let s = LUA.pop s in
						let s = LUA.pop s in
						let s = LUA.pop s in
						LUA.endstate s;
						)
					| Marking_hand_slot hand_slot_nr -> (
							let open Lua in
							let s = Misc.get_opt !state in
							let s = LUA.gettable s (print "player%d" client.player_id) in	(* stack: -1 => playerN *)
							let s = LUA.getfield s "hand" in		(* stack: -1 => slots, -2 => player *)
							let s = LUA.rawgeti s hand_slot_nr in		(* stack: -1 => table/nil, -2 => slots, -3 => player *)
							let s = if LUA.istable s then (
										LUA.setboolean s ("marked", false)
							)
							else (
								chat "Internal error: Unmark Marking_hand_slot: Did not find table";
								s
							) in
							let s = LUA.pop s in
							let s = LUA.pop s in
							let s = LUA.pop s in
							LUA.endstate s;
						)
					| Marking_opponent_hand player_nr -> (
						let open Lua in
						let s = Misc.get_opt !state in
						let s = LUA.gettable s (print "player%d" player_nr) in	(* stack: -1 => playerN *)
						let s = LUA.getfield s "hand" in		(* stack: -1 => slots, -2 => player *)
						let s = if LUA.istable s then (
									LUA.setboolean s ("marked", false)
						)
						else (
							chat "Internal error: Unmark Marking_opponent_hand: Did not find table";
							s
						) in
						let s = LUA.pop s in
						let s = LUA.pop s in
						LUA.endstate s
					)
					| Marking_table_slot slot_nr -> (
						let open Lua in
						let s = Misc.get_opt !state in
						let s = LUA.gettable s "table_slots" in	(* stack: -1 => table_slots *)
						let s = LUA.rawgeti s slot_nr in		(* stack: -1 => slot, -2 => table_slots *)
						let s = if LUA.istable s then (
									LUA.setboolean s ("marked", false)
						)
						else (
							chat "Internal error: Unmark Marking_table_slot: Did not find table";
							s
						) in
						let s = LUA.pop s in
						let s = LUA.pop s in
						LUA.endstate s
					)
				)
				else (
					chat "Cannot unmark slot: Not this players turn"
				)
			)
		(** Gadget actions from player *)
		
		(* Simple button pressed *)
		| Button_pressed gadget_id ->
			if !game_state = Running then (
				(* Get gadget *)
				let gadget = List.find (fun g -> g.gadget_id = gadget_id) !gadgets in
				(* Get callback *)
				let open Lua in
				let s = Misc.get_opt !state in
				let s = LUA.rawgeti_registryindex s gadget.callback in		(* stack: -1 => callback *)
				let s = LUA.getglobal s (print "player%d" client.player_id) in	(* stack: -1 => playerN, -2 => callback *)
				let s = LUA.pcall_fn1_noresult s in	(* stack: empty *)
				LUA.endstate s;
			)

		(* <select> or slider was changed *)
		| Select_changed (gadget_id, value) | Slider_changed (gadget_id, value) ->
			if !game_state = Running then (
				let gadget = List.find (fun g -> g.gadget_id = gadget_id) !gadgets in
				let open Lua in
				let s = Misc.get_opt !state in
				let s = LUA.rawgeti_registryindex s gadget.callback in		(* stack: -1 => callback *)
				let s = LUA.getglobal s (print "player%d" client.player_id) in	(* stack: -1 => playerN, -2 => callback *)
				let s = LUA.pushnumber s (float_of_int value) in	(* stack: -1 => value, -2 => playerN, -3 => callback *)
				let s = LUA.pcall_fn2_noresult s in
				LUA.endstate s;
			)

		(* Button belonging to input was pressed *)
		| Input_button_pressed (gadget_id, data) ->
			if !game_state = Running then (
				let gadget = List.find (fun g -> g.gadget_id = gadget_id) !gadgets in
				let open Lua in
				let s = Misc.get_opt !state in
				let s = LUA.rawgeti_registryindex s gadget.callback in		(* stack: -1 => callback *)
				let s = LUA.getglobal s (print "player%d" client.player_id) in	(* stack: -1 => playerN, -2 => callback *)
				let s = LUA.pushstring s data in	(* stack: -1 => data, -2 => playerN, -3 => callback *)
				let s = LUA.pcall_fn2_noresult s in
				LUA.endstate s;
			)

		| Confirm_pressed (gadget_id, answer) ->
			if !game_state = Running then (
				let gadget = List.find (fun g -> g.gadget_id = gadget_id) !gadgets in
				let open Lua in
				let s = Misc.get_opt !state in
				let s = LUA.rawgeti_registryindex s gadget.callback in		(* stack: -1 => callback *)
				let s = LUA.getglobal s (print "player%d" client.player_id) in	(* stack: -1 => playerN, -2 => callback *)
				let s = LUA.pushboolean s answer in	(* stack: -1 => data, -2 => playerN, -3 => callback *)
				let s = LUA.pcall_fn2_noresult s in
				LUA.endstate s;
			)

		(** Animation commands *)

		(* Animation done, run callback *)
		| Animate_callback id ->
      ignore (Lwt_mutex.lock animate_callback_mutex);
			if List.mem id !anim_callbacks then (
				let open Lua in
				let s = Misc.get_opt !state in
				let s' = LUA.to_lua in
				remove_anim_callback s' id;
				let s = LUA.rawgeti_registryindex s id in		(* stack: -1 => callback *)
				let s = LUA.pcall_fn0_noresult s in					(* stack: empty *)
				LUA.endstate s;
			)
			(* Silence fail, all clients signal callback (how to decide only one?) *)
			(*else 
				failwith (print "Animate_callback: No such callback id: %d" id)*)
			;
      ignore (Lwt_mutex.unlock animate_callback_mutex);
		| Card_dropped (card_nr, location) ->
			let open Lua.LUA in
			let s = Misc.get_opt !state in

			(** Check so that this player has draggable enabled *)
			if not (List.mem client.player_id !draggable_player_nrs) then
				(*error s "Draggable not enabled for this player"; TODO: This won't work, gives PANIC? *)
				raise (WebsocketException "Draggable not enabled for this player");

			(* Check for callback *)
			if !draggable_callback = 0 then
				raise (WebsocketException "Card dropped, but no callback function found");

			(* Check for draggable card *)
			if not (List.exists (fun c ->
					c.card_nr = card_nr
				) !draggable_cards) then
				raise (WebsocketException (print "Card %d is no droppable" card_nr));

			(* Check for droppable slot *)
			if not (List.exists (fun slot ->
				match location.slot_type, slot with
				| A_player_slot, Player_slot (player_nrs, slot_nrs) ->
					List.mem location.player_nr player_nrs && List.mem location.slot_nr slot_nrs
				| A_table_slot, Table_slot slot_nrs ->
					List.mem location.slot_nr slot_nrs
				| A_player_hand, Player_hand player_nrs ->
					List.mem location.player_nr player_nrs
				| _, _ ->
					false
			) !droppable_slots) then
				raise (WebsocketException (print "Slot is not droppable"))
			else (
				let string_of_slot_type = function
					| A_table_slot -> "table_slot"
					| A_player_slot -> "player_slot"
					| A_player_hand -> "player_hand"
				in
				(** Assumes location on top of stack. DOES NOT POP.
						OBS: location has 'player' field in Lua, but 'player_nr' in OCaml *)
				(*
				let get_location s =
					(* stack: -1 => location *)
					let (s, slot_type) = getstring s "slot_type" in
					(* Fetch different fields depending on slot type *)
					match slot_type with
						| "player_slot" -> 
							let s = getfield s "player" in
							let (s, player_nr) = getint s "player_nr" in
							let s = pop s in
							let (s, slot_nr) = getint s "slot_nr" in
							let s = getfield s "index" in
							(* Index nil? *)
							let isitnil = isnil s in				(* stack: -1 => slot, -2 => table_slots *)
							let s = pop s in
							let (s, index) = if isitnil then (s, (-1)) else getint s "index" in
							(s, {
								slot_type = A_player_slot;
								player_nr;
								slot_nr;
								index;
							})
						| "table_slot" -> 
							let (s, slot_nr) = getint s "slot_nr" in
							let s = getfield s "index" in
							(* Index nil? *)
							let isitnil = isnil s in				(* stack: -1 => slot, -2 => table_slots *)
							let s = pop s in
							let (s, index) = if isitnil then (s, (-1)) else getint s "index" in
							(s, {
								slot_type = A_table_slot;
								slot_nr;
								index;
								player_nr = (-1);
							})
						| "player_hand" -> 
							let s = getfield s "player" in
							let (s, player_nr) = getint s "player_nr" in
							let s = pop s in
							let s = getfield s "slot_nr" in	(* player_hand can be with or without slot_nr, depending on src or dest *)
							let isitnil = isnil s in				(* stack: -1 => slot, -2 => table_slots *)
							let s = pop s in
							let (s, slot_nr) = if isitnil then (s, (-1)) else getint s "slot_nr" in
							(s, {
								slot_type = A_player_hand;
								player_nr;
								slot_nr;
								index = (-1);
							})
						| s -> failwith (print "get_location: illegal slot type: %s" s)
				in
				*)
				(* Run callback as callback(player, card, src, dest) *)
				let s = rawgeti_registryindex s !draggable_callback in		(* stack: -1 => callback fn *)
				let s = getglobal s (print "player%d" client.player_id) in 	(* stack: -1 => player, -2 => callback fn *)
				(*let s = getglobal s (print "card%d" card_nr) in	*)
				(* Get src location *)
				let s = getglobal s "__locate_card"	in 
				let s = getglobal s (print "card%d" card_nr) in
				let s = pcall_fn1 s in (* stack: -1 => src location, -2 => player, -3 => callback fn *)
				(*
				let (s, src) = get_location s in
				let s = pop s in
				let s = match src.slot_type with
				 	| A_table_slot ->
						let s = getglobal s "table_slots" in
						let s = rawgeti s src.slot_nr in
						let s = remove_second s in
						s
					| _ -> failwith "Not implemented"
				in
				*)
				(* Get dest location *)
				let s = newtable s in
				let s = setstring s ("slot_type", string_of_slot_type location.slot_type) in
				let s = if location.slot_nr <> (-1) then setnumber s ("slot_nr", float_of_int location.slot_nr) else s in
				let s = if location.player_nr <> (-1) then (
					let s = getglobal s (print "player%d" location.player_nr) in	(* stack: -1 => playerN, -2 => dest, ... *)
					let s = setfield s "player" in
					s
				)
				else 
					s 
				in
				let s = if location.index <> (-1) then setnumber s ("index", float_of_int location.index) else s in
				(* stack: -1 => dest location, -2 => src location, -3 => player, -4 => callback fn *)
				let s = pcall_fn3_noresult s in
				endstate s;
				()
			);
			()
		| Card_onclick card_nr ->

			let open Lua.LUA in
			let s = Misc.get_opt !state in

			(*if client.player_id <> !players_turn then 
				raise (WebsocketException (print "Not this players turn"));*)

			(* Check for callback *)
			if !onclick_callback = 0 then
				raise (WebsocketException "Card dropped, but no callback function found");

			(* Check for clickable card *)
			if not (List.exists (fun c ->
					c.card_nr = card_nr
				) !onclick_cards) then
				raise (WebsocketException (print "Card %d is no clickable" card_nr));

			(* Run callback *)
			let s = rawgeti_registryindex s !onclick_callback in		(* stack: -1 => callback fn *)
			let s = getglobal s (print "player%d" client.player_id) in 	(* stack: -1 => player, -2 => callback fn *)
			let s = getglobal s (print "card%d" card_nr) in
			let s = pcall_fn2_noresult s in
			endstate s;
		| Keydown char_code ->
			(*log (print "keydown %d" char_code);*)

			(* Check so this char code is registred, and get callback *)
			let Key_binding (_, callback) = try 
				List.find (function 
					| Key_binding (charc, callb) ->
						charc = char_code)
					!keydown_bindings
				with
					| Not_found -> raise (WebsocketException (print "No bound character code to %d" char_code))
			in

			(* Run callback *)
			let open Lua.LUA in
			let s = Misc.get_opt !state in
			let s = rawgeti_registryindex s callback in		(* stack: -1 => callback fn *)
			let s = getglobal s (print "player%d" client.player_id) in 	(* stack: -1 => player, -2 => callback fn *)
			let s = pcall_fn1_noresult s in
			endstate s;
		| _ -> 
			log "Unkown command type from client"
	)
	with 
		ex ->
			let backtrace = Printexc.get_backtrace () in
			let msg = Printexc.to_string ex in
			let msg = msg ^ "\nBacktrace: " ^ backtrace in
			log ("Error: " ^ msg);
			broadcast_error msg
	);

			(* Loop *)
      handle_client client env

    | Lwt_websocket.Frame.BinaryFrame ->
      return ()

    | Lwt_websocket.Frame.PongFrame(msg) ->
      return ()

    (** close frame -> close frame *)
    | Lwt_websocket.Frame.CloseFrame(status_code, body) ->

      (** http://tools.ietf.org/html/rfc6455#section-5.5.1
				If an endpoint receives a Close frame and did not previously send a
				Close frame, the endpoint MUST send a Close frame in response. 
      *)

			(*Lwt_io.eprintl ("Removing channel from list, id = " ^ (string_of_int id));*)

			players_online := !players_online - 1;
			remove_client client.channel_id env;
			log (print "player%d logging out" client.channel_id);
			(* Remove player from Lua, or end game? *)
			(*
			let open Lua in
			let s = Misc.get_opt !state in
			let s = LUA.pushnil s in	(* stack: -1 => nil *)
			let s = LUA.setglobal s (print "player%d" client.player_id) in	(* stack: empty *)
			*)
			(*
			let s = LUA.gettable s "table" in	(* stack: -1 => table *)
			let s = LUA.getfield s "remove" in		(* stack: -1 => remove (fn), -2 => table *)
			let s = LUA.pushnumber s (float_of_int client.player_id) in	(* stack: -1 => id, -2 => remove, -3 => table *)
			let s = LUA.getglobal s "players" in	(* stack: -1 => players, -2 => id, -3 => remove, -4 => table *)
			let s = LUA.pcall_fn2 s in	(* stack: -1 => result, -2 => table *)
			let s = LUA.pop s in	(* Pop function result *)
			let s = LUA.pop s in	(* stack: empty *)
			LUA.endstate s;
			*)
			broadcast {command_type = Chat (client.user.User.username ^ " went offline"); username = "System"};
			broadcast_users(); 
			ignore(client.channel#write_close_frame);
			return () 

    | Lwt_websocket.Frame.UndefinedFrame(msg) ->
			log "undefined frame";
      return ()
;;

open Operation

(**
 *    Start a websocket listener on @port and @addr (host url)
 *
 *    @param port       int, socket port
 *    @param addr       string, like "www.tonesoftales.com"
 *    @return           unit? lwt?
 *)
let start_websocket env =
  log "start websocket";
	let addr_inet = Unix.ADDR_INET (Unix.inet_addr_of_string env#addr, env#port) in
	let sock_listen = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in

	(** setup listen socket *)
	Lwt_unix.setsockopt sock_listen Unix.SO_REUSEADDR true;
	Lwt_unix.bind sock_listen addr_inet;
	Lwt_unix.listen sock_listen 5;

	(**
	 *    End script if timeout
	 *)
	let rec timeout () =
		Lwt_engine.on_timer 180. true (fun event ->
			(* Set active = false *)
			with_mutex active_mutex (fun () ->
				let active = !active_since_last_timeout in
				if active then (
					active_since_last_timeout := false;
				)
				else (
					(* Timeout, broadcast close to all clients *)
					log "timeout";
					broadcast {command_type = Close; username = (User.get_username env#user)};
					(* Also remove session from db *)
					Gamesession.end_game_session env#db env#get_game_session;
					exit 0
				)
			);

			(* Stop this timer and start a new one (hack to prevent 1 sec loop) *)
			log "starting new timer";
			Lwt_engine.stop_event event;
			ignore(timeout());
			()
		) 
	in

	(* We want stacktrace *)
	Printexc.record_backtrace true;

  log "before timeout()";
	ignore(timeout());

	game_state := Lobby;

  log "before run main sock_listen env";
	Lwt_main.run (main sock_listen env)
;;

