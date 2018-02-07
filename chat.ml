(**
 		Global chat
		@since 2013-10-24
 *)

open Unix
open Lwt

type channel = {
	id : int;
	channel : Lwt_websocket.Channel.t;
	user : User.user;
}

type command_type =
	| Chat of string
	| Error of string
	| Login of string * int	* string	(* Login request: username, login session id, session password *)
	| Users_online of (string * int) list 	(* List of all users online and their channel ids *)
and command = {
	command_type : command_type;
	username : string;
} with json

let channels = ref ([] : channel list)
let channel_id = ref 0
let channels_mutex = Lwt_mutex.create()
let active_mutex = Lwt_mutex.create()
let active_since_last_timeout = ref true

(* Do stuff with mutex on channels *)
let with_mutex m fn = 
	ignore(Lwt_mutex.lock m);
	let result = fn() in
	ignore(Lwt_mutex.unlock m);
	result
;;

let log str = ignore (Lwt_io.eprintl str)

let broadcast command =
	with_mutex channels_mutex (fun () ->
		for i=0 to List.length !channels - 1 do
			let c = List.nth !channels i in 
			let command_json = json_of_command command in
			let command_string = Json_io.string_of_json command_json in
			ignore(c.channel#write_text_frame command_string)
		done
	)

let chat msg = 
	broadcast {
		command_type = Chat msg; 
		username = "System"
	}

(* Create timeout that checks for activity *)
      (*
let timeout = Lwt_timeout.create 10 (fun () ->
  with_mutex active_mutex (fun () ->
        let active = !active_since_last_timeout in
        if active then active_since_last_timeout := false else exit 0;
        Lwt_io.eprintl "timeout";
  );
) 
*)

(* Add a channel to a list *)
let add_channel channel user =
	with_mutex channels_mutex (fun () ->
		channel_id := !channel_id + 1;
		let channel' = {
			id = !channel_id; 
			channel;
			user;
		} in
		channels := channel' :: !channels;
		channel'
	)
;;

let remove_channel id =
	with_mutex channels_mutex (fun () ->
		channels := List.filter (fun c -> c.id <> id) !channels;
	)
;;

let send channel command =
	let command_json = json_of_command command in
	let command_string = Json_io.string_of_json command_json in
	channel#write_text_frame command_string;
	()

(** Update user list in chat *)
let broadcast_users () =
	let usernames = List.map (fun c -> 
		(c.user.User.username, c.id)
	) !channels in
	let command = {
		command_type = Users_online usernames;
		username = "System"
	} in
	broadcast command

(** Return command of string *)
let parse_command text = 
	(try 
		command_of_json (Json_io.json_of_string text) 
	with
		_ -> 
			ignore(Lwt_io.eprintl "json error"); 
			{command_type = Error ("Json parse error: " ^ text); 
			username = "System"}
	)

let rec main sock_listen env =

	(** accept client, and get the websocket channel for this client *)
	Lwt_websocket.Channel.accept sock_listen >>= fun (channel, addr) ->

	begin
		(* Wait for login *)
		ignore (channel#read_frame >>= function
			| Lwt_websocket.Frame.TextFrame text ->
				(* Parse command to Json *)
				let in_command = parse_command text in

				(match in_command.command_type with
					| Login (username, session_id, password) ->
						let login = LoginCookie.check_login_aux env#db username session_id in	(* session_id = user session id *)
						(* Check login cookie *)
						(match login with
							| User.Logged_in user | User.Guest user -> 

								let channel' = add_channel channel user in
								broadcast_users ();

								(* Start up a listening thread *)
								ignore (return (handle_client channel' env));
							| User.Not_logged_in -> 
								send channel {command_type = Error "User not logged in"; username = "System"};
								ignore(channel#write_close_frame);
						)
					| Error _ ->
						(* Could not parse JSON *)
						send channel in_command;
						ignore(channel#write_close_frame);
					| _ ->
						(* Error, must have login as first message *)
						send channel {command_type = Error "Must login as first message"; username = "System"};
						ignore(channel#write_close_frame);
				);
				return ()
			| Lwt_websocket.Frame.CloseFrame(status_code, body) ->
				ignore(channel#write_close_frame);
				return ()
			| _ ->
				return ()
		)
	end;

	(* Listen for other users *)
	main sock_listen env

and handle_client (channel : channel) env =
      channel.channel#read_frame >>= function

    (** ping -> pong *)
    | Lwt_websocket.Frame.PingFrame(msg) ->
      channel.channel#write_pong_frame >>= fun () ->
      handle_client channel env (** wait for close frame from client *)

    (** text frame -> echo back *)
    | Lwt_websocket.Frame.TextFrame text ->

			(* Parse command to Json *)
			let in_command = parse_command text in

      with_mutex active_mutex (fun () ->
      	active_since_last_timeout := true;
      );

			(*
      with_mutex channels_mutex (fun () ->
            for i=0 to List.length !channels - 1 do
                  let c = List.nth !channels i in
                  ignore(c.channel#write_text_frame text)
            done;
      );
			*)

			(try (match in_command.command_type with
				| Chat msg | Error msg ->
					broadcast in_command
				| Login (username, session_id, password) ->
					()
				| _ ->
					()
				)
			with
				_ ->
				()
			);

      handle_client channel env (** Loop *)

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
      remove_channel channel.id;
      ignore(channel.channel#write_close_frame);
			broadcast_users(); 
      return ()

    | Lwt_websocket.Frame.UndefinedFrame(msg) ->
      return ()
;;

(**
 *    Start a websocket listener on @port and @addr (host url)
 *
 *    @param port       int
 *    @param addr       string, like "www.tonesoftales.com"
 *    @return           unit? lwt?
 *)
let start_chat addr port env =
	let addr_inet = Unix.ADDR_INET (Unix.inet_addr_of_string addr, port) in
	let sock_listen = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in

	(** setup listen socket *)
	Lwt_unix.setsockopt sock_listen Unix.SO_REUSEADDR true;
	Lwt_unix.bind sock_listen addr_inet;
	Lwt_unix.listen sock_listen 5;

	let rec timeout2 () =
		Lwt_engine.on_timer 1800. true (fun event ->

			ignore(Lwt_io.eprintl "on_timer");
			(*Lwt_io.printl "Content-Type: text/html\\ntimerbla";*)

			(* Set active = false *)
			with_mutex active_mutex (fun () ->
				let active = !active_since_last_timeout in
				if active then active_since_last_timeout := false else (log "timeout"; exit 0);
			);

			(* Stop this timer and start a new one *)
			Lwt_engine.stop_event event;
			ignore(timeout2())
		) 
	in

	ignore(timeout2());

	Lwt_main.run (main sock_listen env)
;;
