(**

	A user in the Drakskatten database.
	Email, password etc etc.

	@since 2012-11-25
	@todo	User stronger hash function (bcrypt) and more advanced salt (random and new for each password).
*)

exception UserException of string;;

let escape = Netencoding.Html.encode ~in_enc:`Enc_utf8 ()

let begin_salt = "asdflkj4taertuioafga";;
let end_salt = "asdflkjh435948509809dfasdf09a8sdf";;

type user = {
	id : int;
	username : string;
	password : string;	(* Digest.t = string *)
	email : string;
	guest_account : bool;
};;

(* Login type, representing state of login *)
type login = Logged_in of user | Guest of user | Not_logged_in;;

(* Some getters *)
let get_user_id user = user.id;;
let get_username user = escape user.username;;

(**
	Creates a user dir in the /upload directory.
*)
let create_dir user =
	Unix.chdir "/home/d37433/public_html/drakskatten/upload";
	let fileperm = 0o777 in
	Unix.mkdir (escape user.username) fileperm;;

(**
	Makes a user out of a html form.
	Used when creating a new user.

	@param cgi	Cgi object
*)
let user_of_cgi (cgi : < argument_value : string -> string >) =
	let username = escape (cgi#argument_value "username") in
	if String.length username < 4 then raise (UserException "Username too short");
	let password = cgi#argument_value "password" in

	(* Abort if password is empty *)
	if (password = "") then raise (UserException "Empty password");

	(* Add salt *)
	let password = begin_salt ^ password ^ end_salt in
	let hashed_password = Digest.to_hex (Digest.string password) in 	(* TODO: User other encryption than MD5 *)

	let email = cgi#argument_value "email" in

	(* Abort if no email found *)
	if (email = "") then raise (UserException "No email");

	{
		id = -1;
		username = username;
		password = hashed_password;
		email = email;
		guest_account = false;	(* Only SQL PROCEDURE makes guest accounts *)
	};;


(**
	Add a user to the db
	Password should be hashed and salted.

	@param db	Database handler
	@param user	User record
	@return		(result, nr affected)
	@raise		UserExists if user already exists
*)
let create_user db user =
	let query = "INSERT INTO ds_user VALUES (NULL, ?, ?, ?)" in
	let args = [|user.username; user.password; user.email|] in
	ignore (Db.run_query db query args);

	(* If still here, db went well, so create a dir *)
	create_dir user;;

(**
	Creates a user record of a db row.

	@param row	string option array
	@raise		UserException with msg if id or username is not found.
*)
let user_of_row row =
	{
		id = int_of_string (match row.(0) with Some id -> id | None -> raise (UserException "Found no id of user"));
		username = (match row.(1) with Some un -> un | None -> raise (UserException "Found no username of user"));
		email = Db.fetch_field row 2 "No email";
		password = (match row.(3) with Some p -> p | None -> raise (UserException "Found no password"));
		guest_account = (match row.(4) with Some guest -> guest = "1" | None -> raise (UserException "Found no guest_account field"));
	};;

(**
	Get user from database.

	@param db	Database handler
	@param username	String; username
	@return		Option, Some user if user found, otherwise None.
*)
let get_user db username =
	let query = "SELECT id, username, email, password, guest_account FROM ds_user WHERE username=?" in
	let args = [|username|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let row = Db.fetch_row result in
	let return = (match row with
		  Some row -> Some (user_of_row row)
		| None -> None)
		in
	Db.close_stmt stmt;
	return;;

(**
	Get user from database.

	@param db	Database handler
	@param username	int
	@return		user
*)
let get_user_by_id db user_id  =
	let query = "SELECT id, username, email, password, guest_account FROM ds_user WHERE id=?" in
	let args = [|string_of_int user_id|] in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt args in
	let row = Db.fetch_row result in
	let return = (match row with
		  Some row -> Some (user_of_row row)
		| None -> raise Not_found)
		in
	Db.close_stmt stmt;
	return;;

(**
	Get the html string of user create form

	@return		String of form
*)
(*
let print_add_form () = 
	Printf.sprintf "
	<fieldset>
		<legend>Create new user</legend>
		<form method=post action=drakskatten>
			<input type=hidden name=op value=create_user />
			<input type=hidden name=module value=user />
			Username:<input type=text name=username maxlength=100/><br>
			Password:<input type=password name=password maxlength=100/><br>
			Email:<input type=text name=email maxlength=100/><br>
			Robot check: Type the four first letters of your username:<input type=text name=robot maxlength=4/><br>
			<input type=submit value=Create>
		</form>
	</fieldset>
	";;
*)

(**
	Check if password is correct for this user.

	@param db 	The db returned by open_db
	@param username	String
	@param password Plain text password written by user
	@raise		UserException if no user is found with this username
	@return		login type from LoginCookie
*)
(*
let login db username password = 
	let password = begin_salt ^ password ^ end_salt in
	let hashed_password = Digest.to_hex (Digest.string password) in
	(* Get user for this user name *)
	let user = get_user db username in
	match user with 
		Some user -> 
			if (user.password = hashed_password) then
				Logged_in user
			else
				Not_logged_in
		| None -> raise (UserException ("No such user: " ^ username));;
*)

(**
	Logout a user.
	User must be logged in to perform this.
	Deletes all session ids in database for this user.

	@param db 	The database handler returned by open_db
	@param login 	login type
*)
let logout db login =
	match login with
		| Not_logged_in -> raise (UserException "User must be logged in to log out");
		| Logged_in user | Guest user ->
			begin
				let query = "DELETE FROM ds_user_cookie WHERE user_id = ?" in
				let args = [|(string_of_int user.id)|] in
				let stmt = Db.create_stmt db query in
				ignore (Db.run_query db query args);
				Db.close_stmt stmt;
			end;;

(**
	Return html of login form

	@return		String; html
*)
let login_form () =
	Printf.sprintf "
	<fieldset>
		<legend>Login</legend>
		<form method=post action=drakskatten>
			<input type=hidden name=op value=login />
			<input type=hidden name=module value=user />
			Username:<input type=text name=username maxlength=100/><br>
			Password:<input type=password name=password maxlength=100/><br>
			<input type=submit value=Login>
		</form>
	</fieldset>
	";;

(**
	Return a free guest account
	Creates a new account if no free is found

	@param db 	The database handler returned by open_db
*)
let get_guest_account db log =
	let query = "CALL get_guest_account(@id)" in
	let stmt = Db.create_stmt db query in
	ignore (Db.execute_stmt stmt [||]);
	Db.close_stmt stmt;
	let user_id = int_of_string (Db.get_stored_out db "id") in (* Get results from stored procedure *)
	let user = get_user_by_id db user_id in
	user
;;
(*
	let id_of_row row = 
		match row.(0) with Some id -> int_of_string id | None -> raise (UserException "Found no id for guest account")
	in
	let query = "
		SELECT
			user.id
		FROM
			ds_user AS user
			LEFT JOIN ds_user_cookie AS cookie ON user.id = cookie.user_id
		WHERE
			user.guest_account = true AND
			-- Either old cookie or no cookie
			(cookie.datetime < DATE_SUB(NOW(), INTERVAL 1 DAY) OR ISNULL(cookie.datetime))
	" in
	let stmt = Db.create_stmt db query in
	let result = Db.execute_stmt stmt [||] in
	let row = Db.fetch_row result in
	let user = match row with
		| Some row -> 
			(* Found a guest account, return it *)
			let user_id = id_of_row row in
			Db.close_stmt stmt;
			get_user_by_id db user_id
		| None -> 
			(* Close old stmt *)
			Db.close_stmt stmt;
			(* Found no guest account, create a new *)
			(* First, get new guest number by looking at newest guest account *)
			let query = "
				START TRANSACTION;
				SET @id = (SELECT id FROM ds_user ORDER BY id DESC LIMIT 1) + 1;
				INSERT INTO ds_user(id, username, password, email, guest_account) VALUES (
					NULL, 
					CONCAT('guest', @id),
					UUID(),	-- Random password
					CONCAT('guestmail', @id),
						TRUE
					);
				COMMIT;
			" in
			let stmt2 = Db.create_stmt db query in
			let result = Db.execute_stmt stmt2 [||] in
			Db.close_stmt stmt2;
			(* No just recurse and the function should find the newly created account *)
			get_free_guest_account db
	in
	user
;;
*)
