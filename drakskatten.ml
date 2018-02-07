(**
	Main cgi file for card website.
	Also testing ground.

	@since 2012-11-26

	TODO:
		- When session id gets to high (int64) there will be conversion problems from and to int32.
*)

open User;;

exception DrakException of string;;

(* Create an HTML escaping function for the UTF-8 encoding. *)
let escape_html = Netencoding.Html.encode ~in_enc:`Enc_utf8 ~unsafe_chars:Netencoding.Html.unsafe_chars_html4 ()

(**
 *    Head of HTML and some introductory text.
 *
 *    @param title      String, title of the web page.
 *)
let start_html title js =
	Printf.sprintf "\
		<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
		<html xmlns=\"http://www.w3.org/1999/xhtml\">
                  <head>
			<title>%s</title>

                  	<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />

			<!-- Codemirror editor -->
				<script type='text/javascript' src='/codemirror-3.1/lib/codemirror.js'></script>
				<script type='text/javascript' src='/codemirror-3.1/addon/dialog/dialog.js'></script>
				<script type='text/javascript' src='/codemirror-3.1/addon/search/searchcursor.js'></script>
				<script type='text/javascript' src='/codemirror-3.1/addon/search/search.js'></script>
				<script type='text/javascript' src='/codemirror-3.1/mode/lua/lua.js'></script>
                        <link href='/codemirror-3.1/lib/codemirror.css' rel='stylesheet' type='text/css'>
                        <link href='/codemirror-3.1/addon/dialog/dialog.css' rel='stylesheet' type='text/css'>

                        <link href='../css/style.css' rel='stylesheet' type='text/css'>
                        <link href='../css/jquery-ui.css' rel='stylesheet' type='text/css'>
                        <script type='text/javascript' src='/js/jquery-1.9.1.min.js'></script>
                        <script type='text/javascript' src='/js/jquery-ui.min.js'></script>
                        <script type='text/javascript' src='/js/tool.js'></script>
                        <script type='text/javascript' src='/js/drakskatten.js'></script>
                        <script type='text/javascript' src='/js/jstest.js'></script>

                        <script type='text/javascript'>%s </script>

                  </head>
                  <body>
		" 
                (escape_html title)
                js
;;

(**
	Dispatch operations from op_list
	The controller modules hook up their ops in this list at program start.

	@param module_name	name of module where the op is
	@param function_name	name of function 
	@param cgi
	@param db
	@param echo		cgi#out
	@param login		login type, either logged in or not
*)
let dispatch_op module_name function_name op_args =
	let op = (try
			Operation.get_op module_name function_name
		with
			Not_found -> raise (DrakException ("Could not find op " ^ function_name ^ " in module " ^ module_name ^ " for op list"))) in
	Operation.apply op op_args;;

(*
let () =
	let port = 1201 in
	Printf.printf "%s (FCGI) listening on port %i.\n%!" Sys.argv.(0) port;
	let buffered _ ch = new Netchannels.buffered_trans_channel ch in
	Netcgi_fcgi.run ~output_type:(`Transactional buffered) ~sockaddr:(Unix.ADDR_INET(Unix.inet_addr_any, port))
	(fun cgi -> Add.main(cgi :> cgi));;
*)

(**
 *    Process a page request. 
 *    Actual "main" function.
 *
 *    @param cgi  cgi object passed from Netcgi.run
 *)
let process (cgi : Netcgi.cgi) =
	(* We want stacktrace *)
	Printexc.record_backtrace true;

	cgi#set_header
		~cache:`No_cache
		~content_type:"text/html; charset=\"utf-8\"\r\n\r\n"
		();

	(* Cook up our own cgi object *)
	let cgi = object
		method argument_value ?default:(d="") name = 
			escape_html (cgi#argument_value name)
		method argument_value_noescape ?default:(d="") name =
			cgi#argument_value name
		method argument = cgi#argument
		method out_channel = cgi#out_channel
		method environment = cgi#environment
		method finalize = cgi#finalize
		method set_header = cgi#set_header
	end in

	(* Get op, and default to "startpage" *)
	let op_name = cgi#argument_value "op" in
	let op_name = if (op_name = "") then "startpage" else op_name in

	(* Get module name, if present *)
	let module_name = cgi#argument_value "module" in
	let module_name = if (module_name = "") then "startpage" else module_name in

	(* echo function to output strings *)
	let echo = cgi#out_channel#output_string in

	(*cgi#argument_value = (fun ?default:string s -> 
		let s = escape_html s in
		cgi#argument_value s
	);*)

        let log = Printf.eprintf "%s\n" in

        (* This is needed for template/Jingoo to find right dir *)
        Sys.chdir "/";

        (*
	let l = [1;1;2;2;3;3] in
	let l2 = ExtLib.List.unique l in
        *)

        (* Start with some html *)
        echo (start_html "Tones of tales - Play card games" "");

        let open Netchannels in
        (* Html buffer *)
        (*let buffer = Buffer.create 1000 in*)
        (*let ch = new output_buffer buffer in*)
        (*let echo_buffer = ch#output_string in*)

	(* Open XML config file *)
	let xml = Xml.parse_file "/home/d37433/config.xml" in

	let get_xmlinfo xml tagname =
		(* Get all node children of XMl file *)
		let children = Xml.children xml in
		(* Find child with tag "database" *)
		let database_tag = List.find (fun x -> Xml.tag x = "homepage") children in
		(* Get children of that node *)
		let database_children = Xml.children database_tag in
		(* Find chil with tag @tagname *)
		let tag_info = List.find (fun x -> Xml.tag x = tagname) database_children in
		(* Return text data of that node *)
		Xml.pcdata (List.hd (Xml.children tag_info)) in

        (* Get address of page, to use with websocket *)
        let addr = get_xmlinfo xml "addr" in
	let hostname = get_xmlinfo xml "hostname" in

	let websocket_timeout = int_of_string (get_xmlinfo xml "websocket_timeout") in

	(* Open db *)
	let db = Db.open_db xml in

	(* Dispatch op *)
	(try 

		(* Check for login *)
		let login = LoginCookie.check_login cgi db in
		(match login with
			| User.Logged_in user | User.Guest user -> 
				echo "<div id=menu><a href='drakskatten?op=startpage&module=startpage'><img src='/img/home.jpg' /> Home</a>";
				echo " <a href='drakskatten?op=doc&module=startpage'><img src='/img/doc.jpg' /> Documentation</a>";
				echo " <a href='drakskatten?op=contact&module=startpage'><img src='/img/talk.jpg' /> Contact</a>";
				echo " <a href='drakskatten?op=logout&module=user'><img src='/img/logout.jpg' /> Logout</a>";
			  	echo (" <span id=name>Logged in as " ^ escape (User.get_username user) ^ "</span>");
				echo "</div><br />";
			| User.Not_logged_in -> 
				(*echo ("Not logged in");*)
				echo (Printf.sprintf "
					<div id=menu><a href='drakskatten?op=home&module=startpage'><img src='/img/home.jpg' /> Home</a>
					<a href='drakskatten?op=doc&module=startpage'><img src='/img/doc.jpg' /> Documentation</a>
					<a href='drakskatten?op=contact&module=startpage'><img src='/img/talk.jpg' /> Contact</a>
					<a href='drakskatten?op=login_form&module=user'><img src='/img/login.png' /> Login</a>
					<a href='http://%s/register.php'><img src='/img/checkbox.png' /> Register account</a>
					</div><br />
					"
					hostname
					));
            (* This is the environment for the controller ops *)
		let open Operation in
                (*let on_load = ref "" in*)
		let op_args = {
			cgi = cgi;
			db = db;
			echo = echo;
			login = login;
                        addr = addr;
			websocket_timeout = websocket_timeout;
                        log = (fun s  -> log s);
		} in
		(*
		let op_args = object
			method cgi = cgi
			method db = db
			method echo = echo
			method login = login
			method addr = addr
			method websocket_timeout = websocket_timeout
			method log = (fun s -> log s)
		end in
		*)
                log ("dispatching op " ^ op_name);

		if (op_name <> "" && module_name <> "") then dispatch_op module_name op_name op_args;

                (*echo (Buffer.contents buffer);*)

	with
		| DrakException msg -> echo msg
		| Mysql.Error msg -> 
			echo msg;
			let backtrace = Printexc.get_backtrace () in
			log ("Backtrace: " ^ backtrace);
		| Db.DatabaseException msg -> echo msg
		| User.UserException msg -> echo msg
		| Card.CardException msg -> echo msg
		| Game.GameException msg -> echo msg
		| Failure msg -> echo msg
		| Not_found -> echo "Not found cgi"
		| Invalid_argument msg ->
			echo msg;
			log (Printexc.get_backtrace ())
	);

		(*| _ -> echo "Could not dispatch op. Unknown exception.");*)

      (* A way to get IP of client
      let ip = Sys.getenv "REMOTE_ADDR" in
      echo ip;
      *)

	(* Close connection with db *)
	Db.close db;

	(* Flush the output buffer. *)
	cgi#out_channel#commit_work();

	cgi#finalize();
;;

(* Initialize and run the Netcgi process. *)
let () =
	(*let port = 8765 in*)
	(*Printf.eprintf "%s (FCGI) listening.\n%!" Sys.argv.(0);*)
	let config = Netcgi.default_config in
	let buffered _ ch = new Netchannels.buffered_trans_channel ch in
	Netcgi_cgi.run ~config:config ~output_type:(`Transactional buffered) process

