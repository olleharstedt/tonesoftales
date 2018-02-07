(**
	Small module for login cookie

	@since 2012-12-01
	@author Olle Harstedt
*)


(* This is the cookie information stored in db *)
type cookie = {
	user_id : int;
	datetime : string;
	login_session_id : int
};;

(* Login too old, delete all session ids from database and return false *)
let delete_old_sessions db user_id =
	let query = "DELETE FROM ds_user_cookie WHERE user_id = ?" in
	let args = [|string_of_int user_id|] in
	let stmt = Db.create_stmt db query in
	(ignore (Db.execute_stmt stmt args));
	Db.close_stmt stmt;;

(** Sets username and session id cookies for login 
		Should work in Ajax calls, too *)
let set_cookies (cgi : < set_header : ?status:Nethttp.http_status ->
		?content_type:string ->
		?content_length:int ->
		?set_cookie:Nethttp.cookie list ->
		?set_cookies:Netcgi.Cookie.t list ->
		?cache:Netcgi.cache_control ->
		?filename:string ->
		?language:string ->
		?script_type:string ->
		?style_type:string -> ?fields:(string * string list) list -> unit -> unit; .. >)username session_id =
	(* Create new header with cookie info *)
	(* TODO: Fix new session id for each check, to prevent session hijacking *)
	let user_cookie = Netcgi_common.Cookie.make
		~path:"/"
		~max_age: (60 * 60 * 24) 	(* Last one day *)
		"username" username in
	let session_id_cookie = Netcgi_common.Cookie.make
		~path:"/"
		~max_age: (60 * 60 * 24)
		"session_id" (string_of_int session_id) in
	cgi#set_header
		~cache:`No_cache
		~content_type:"text/html; charset=\"iso-8859-1\""
		~set_cookies: [user_cookie; session_id_cookie]
		()
;;

(**
	Does two things: Create a new row in db with session information; and add the same information in browser cookie. This is later used as validation.
	Should user SSL?

	@param cgi		Cgi object
	@param db 		Db handler
	@param user		User record
	@return 		unit
	@raise		Could, if db fails.
*)
let create_new_login (cgi : < set_header : ?status:Nethttp.http_status ->
		?content_type:string ->
		?content_length:int ->
		?set_cookie:Nethttp.cookie list ->
		?set_cookies:Netcgi.Cookie.t list ->
		?cache:Netcgi.cache_control ->
		?filename:string ->
		?language:string ->
		?script_type:string ->
		?style_type:string -> ?fields:(string * string list) list -> unit -> unit; .. >) db user = 
	Random.self_init();
	let session_id = Random.bits() in
	let username = User.get_username user in
	let user_id = User.get_user_id user in
	let datetime = Misc.get_datetime () in

	(* Remove all old sessions *)
	delete_old_sessions db user_id;

	(* Save new session information in db *)
	let query = "INSERT INTO ds_user_cookie(user_id, datetime, login_session_id) VALUES(?, ?, ?)" in
	let args = [|(string_of_int user_id); datetime; (string_of_int session_id)|] in
	let stmt = Db.create_stmt db query in
	ignore (Db.execute_stmt stmt args);
	Db.close_stmt stmt;
	set_cookies cgi username session_id
;;


(**
	Help function for below

	@param db 		Db handler
	@param username	string
	@param session_id int
	@return 		bool * string option (login, username)
*)
let check_login_aux db username session_id =
	let open User in
	let query = "
		SELECT 
			u.username,
			TIMESTAMPDIFF(SECOND, c.datetime, NOW()) AS sec_diff,
			c.login_session_id,
			u.id
		FROM 
			ds_user_cookie AS c 
			JOIN ds_user AS u ON c.user_id = u.id
		WHERE 
			u.username = ? AND
			c.login_session_id = ?
		ORDER BY
			c.datetime DESC
	" in
	let args = [|username; string_of_int session_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let row = Db.fetch_row result in
	Db.close_stmt stmt;
	let return = (match row with
		(* Yey, there was a cookie row in db *)
		Some row -> 
			let username_db = (match row.(0) with Some u -> u | None -> "") in
			let sec_diff = (match row.(1) with Some d -> d | None -> "") in
			let login_session_id = int_of_string (match row.(2) with Some i -> i | None ->raise (UserException "No login session id?")) in
			let user_id = (match row.(3) with Some id -> int_of_string id | None -> raise (UserException "No user id???")) in
			if (int_of_string sec_diff) > 43200 (* Half a day *) then
				(* Cookie expired. DESTROY ALL! *)
				begin
					delete_old_sessions db user_id;
					Not_logged_in
				end
			else
				(* Everything ok, compare username and session id *)
				let login = (username = username_db) && login_session_id = session_id in
				if login then (
					let user = (match get_user db username_db with 
						  Some user -> 
							  (* Login OK, update timestamp *)
							  let query = "
								UPDATE
									ds_user_cookie
								SET
									datetime=?
								WHERE
									login_session_id=? AND 
									user_id=?
									" in
							  let args = [|
								  Misc.get_datetime();
								  string_of_int login_session_id;
								  string_of_int user_id; |] in
							  let stmt = Db.create_stmt db query in
							  ignore (Db.execute_stmt stmt args);
							  (* Return user *)
							  user
						| None -> raise (UserException "Found no user"))
					in
					if user.guest_account then Guest user else Logged_in user
				)
				else
					Not_logged_in
		(* Found cookie but nothing in db, strange. Return false anyway. *)
		| None -> Not_logged_in) in
	return

(**
	Check if user is logged in.
      Update timestamp for cookie in db if login ok.

	@todo		Check datetime if too old.
	@return 	bool * string option (login, username)
*)
let check_login (cgi : < environment : Netcgi.cgi_environment; set_header : ?status:Nethttp.http_status ->
		?content_type:string ->
		?content_length:int ->
		?set_cookie:Nethttp.cookie list ->
		?set_cookies:Netcgi.Cookie.t list ->
		?cache:Netcgi.cache_control ->
		?filename:string ->
		?language:string ->
		?script_type:string ->
		?style_type:string -> ?fields:(string * string list) list -> unit -> unit; .. >) db =
	(* Get values from cookies *)
	let username = (
		try 
			Netcgi_common.Cookie.value (cgi#environment#cookie "username") 
		with 
			Not_found -> "") in
	let session_id = (
		try 
			int_of_string (Netcgi_common.Cookie.value (cgi#environment#cookie "session_id")) 
		with 
			Not_found -> -1 
			| _ (* int_of_string might throw something *) -> -1) in

	(* Return false if username or session id was not found in cookie *)
	if username = "" || session_id = -1 then
		(*(false, None)*)
		User.Not_logged_in

	(* Compare data from cookie with db *)
	else (
		let user = check_login_aux db username session_id in
		let open User in
		(* Check if to update cookie *)
		(match user with
			| Logged_in user | Guest user -> 
				set_cookies cgi username session_id
			| _ -> ()
		);
		(* Return user *)
		user
	)
