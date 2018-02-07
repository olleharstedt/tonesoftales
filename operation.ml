(**
 *    Operation (op) module
 *    For operation called by from web site, e.g. add_card or add_card_form
 *
 *    @since 2013-02-23
 *    @author Olle Härstedt
 *)

exception OperationException of string;;

open User

(**
 *    Arguments to op function
 *    Pretty much an environment for controller code/op.
 *)
type op_args = {
      cgi : < argument_value : ?default:string -> string -> string;
      	argument_value_noescape : ?default:string -> string -> string;
		argument : string -> Netcgi.cgi_argument;
		out_channel : Netchannels.trans_out_obj_channel;
		environment : Netcgi.cgi_environment;
		finalize : unit -> unit;
	set_header : ?status:Nethttp.http_status ->
			?content_type:string ->
			?content_length:int ->
			?set_cookie:Nethttp.cookie list ->
			?set_cookies:Netcgi.Cookie.t list ->
			?cache:Netcgi.cache_control ->
			?filename:string ->
			?language:string ->
			?script_type:string ->
			?style_type:string -> ?fields:(string * string list) list -> unit -> unit;
	>;
      db : Db.db;
      echo : (string -> unit);
      login : (login);
      (*on_load : string -> unit;   (* onload javascript *)*)
      addr : string;                (* Address of server, e.g. localhost or tonesoftales.com *)
	websocket_timeout : int;	(* Seconds of non-activity before closing websocket server *)
      log : string -> unit;        	(* Error log *)
};;

(**
 *    Operation type.
 *)
type operation = {
      module_name : string;
      function_name : string;
      (* Operation function useing netcgi, db, echo and login *)
      func : op_args -> unit;
};;

(* List reference, to be updated by modules at init *)
let op_list = ref ([] : operation list);;

(* As above, but ajax operations *)
let ajax_list = ref ([] : operation list);;

(**
 *    Creates a new operation
 *
 *    @param module_name string
 *    @param function_name string
 *    @param func       function, see type definition above
 *)
let new_operation module_name function_name func =
      {
            module_name = module_name;
            function_name = function_name;
            func = func
      };;

(**
 *    Adds operation to operation list
 *
 *    @param operation operation
 *)
let add_op operation l =
      (* Check for duplicates *)
      let duplicates = List.filter (fun op -> op.module_name =
            operation.module_name && op.function_name = operation.function_name)
            !l in
      (match duplicates with
            (* Empty list is ok *)
            [] -> l := operation :: !l
            (* Non-empty list, abort *)
            | _ -> raise (OperationException ("Operation duplicate with op " ^ operation.module_name ^ ", " ^ operation.function_name)));;


(**
 *    Cheating function, both new_operation and add_operation in one
 *
 *    @param module_name      string
 *    @param op_name          string
 *    @param func             Netcgi.cgi -> Db.db -> (string -> unit) -> login -> unit;
 *)
let add_op' module_name op_name func =
      let op = {
            module_name = module_name;
            function_name = op_name;
            func = func
      } in
      add_op op op_list;;

(**
	Add operation with login implied

	@param module_name	name of module where the op is
	@param op_name		string, name of op from post
	@param func			op_args -> user -> unit
	@return 			unit
*)
let add_op_login ?allow_guests:(allow=true) module_name op_name func =
	let op = {
		module_name = module_name;
		function_name = op_name;
		func = (fun args ->
			match args.login, allow with
				| Logged_in user, _
				| Guest user, true ->
					func args user
				| Guest user, false ->
					failwith "Not available for guests"
				| Not_logged_in, _ -> 
					args.echo "Please login");
	} in
	add_op op op_list;;


(**
	Add op in ajax operation list

	@param module_name	name of module where the op is
	@param op_name		string, name of op from post
	@param func			op_args -> user -> unit
	@return			unit
*)
let add_op_ajax module_name op_name func =
	let op = {
		module_name = module_name;
		function_name = op_name;
		func = func
	} in
	add_op op ajax_list;;

let add_op_ajax_login ?allow_guests:(allow=true) module_name op_name func =
	let op = {
		module_name = module_name;
		function_name = op_name;
		func = (fun args ->
			match args.login, allow with
				| Logged_in user, _ 
				| Guest user, true ->
					func args user
				| Guest user, false ->
					failwith "Not available for guests"
				| Not_logged_in, _ -> args.echo "Please login");
	} in
	add_op op ajax_list;;
	
(**
 *    Get operation from a module_name and function_name
 *
 *    @param module_name      string
 *    @param function_name    string
 *    @return func            see type def above
 *)
let get_op module_name function_name =
      List.find (fun op -> op.module_name = module_name && op.function_name =
            function_name) !op_list;;

(* As above but for ajax op list *)
let get_op_ajax module_name function_name =
      List.find (fun op -> op.module_name = module_name && op.function_name =
            function_name) !ajax_list;;
(**
 *    Run func in op
 *)
let apply op op_args =
      op.func op_args;;
