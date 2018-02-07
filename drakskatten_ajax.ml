(**
	Ajax interface to clients

	@since 2013-02-28
*)

open User;;

exception AjaxException of string;;

(* Create an HTML escaping function for the UTF-8 encoding. *)
let escape_html = Netencoding.Html.encode ~in_enc:`Enc_utf8 ()

open Operation;; 

(**
	Dispatch operations from op_list

	@param module_name	name of module where the op is
	@param function_name	name of function 
	@param cgi
	@param db
	@param echo		cgi#out
	@param login		login type, either logged in or not
*)
let dispatch_op module_name function_name op_args =
	let op = (try
			Operation.get_op_ajax module_name function_name
		with
			Not_found -> raise (AjaxException ("Could not find op " ^ function_name ^ " in module " ^ module_name ^ " for ajax op list")))
		in
	Operation.apply op op_args;;

(**
 *    Process a page request. 
 *    Actual "main" function.
 *
 *    @param cgi  cgi object passed from Netcgi.run
 *)
let process (cgi : Netcgi.cgi) =
	cgi#set_header
		~cache:`No_cache
		~content_type:"application/json; charset=\"utf-8\""
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

	(* echo function to output strings *)
	let echo = cgi#out_channel#output_string in

	(* Get op, and default to "startpage" *)
	let op_name = cgi#argument_value "op" in

	(* Get module name, if present *)
	let module_name = cgi#argument_value "module" in

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

      (* localhost or tonesoftales.com *)
      let addr = get_xmlinfo xml "addr" in

	let websocket_timeout = int_of_string (get_xmlinfo xml "websocket_timeout") in

	(* Open db *)
	let db = Db.open_db xml in

	(* Dispatch op *)
	(try 
		(* Check for login *)
		let login = LoginCookie.check_login cgi db in
		let open Operation in
		(* Environment for controller code *)
		let op_args = {
			cgi = cgi;
			db = db;
			echo = echo;
			login = login;
                  (*on_load = (fun s -> echo "");       (* This do nothing in ajax version *)*)
                  addr = addr;
			websocket_timeout = websocket_timeout;
                  log = (fun s  -> Printf.eprintf "%s" s);
		} in
		if (op_name <> "" && module_name <> "") then dispatch_op module_name op_name op_args;
	with
		  AjaxException msg -> echo msg
		| Mysql.Error msg -> echo msg
		| Db.DatabaseException msg -> echo msg
		| User.UserException msg -> echo msg
		| Card.CardException msg -> echo msg
		| Game.GameException msg -> echo msg
		| Failure msg -> echo msg
		| Not_found -> echo "Not found ajax");
		(*| _ -> echo "Could not dispatch op. Unknown exception.");*)

	(* Close connection with db *)
	Db.close db;

	(* Flush the output buffer. *)
	cgi#out_channel#commit_work();

	cgi#finalize();;

(* Initialize and run the Netcgi process. *)
let () =
	(*let port = 8765 in*)
	(*Printf.printf "%s (CGI) ajax, listening.\n%!" Sys.argv.(0);*)
	let config = Netcgi.default_config in
	let buffered _ ch = new Netchannels.buffered_trans_channel ch in
	Netcgi_cgi.run ~config:config ~output_type:(`Transactional buffered) process

