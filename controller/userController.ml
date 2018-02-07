(**
	Controller code for user

	Lot of code commented, because migration to SSL/PHP in secure/ dir.

	@since 2013-02-25
*)

open Operation
open User

let print = Printf.sprintf;;

let escape = Netencoding.Html.encode ~in_enc:`Enc_utf8 ()

let _ =
	(* Short hand *)
	let add_op = add_op' "user" in
	let add_op_ajax = add_op_ajax "user" in

	(** Login as guest *)
	add_op_ajax "guest_login" (fun args ->

		(* Check if already logged in *)
		let login = LoginCookie.check_login args.cgi args.db in 

		(match login with
			| Logged_in user | Guest user -> 
				args.echo (print "Already logged in as %s." (escape user.username))
			| Not_logged_in ->
				(* Get available guest account *)
				let user = match get_guest_account args.db args.log with
					| Some u -> u
					| None -> failwith "Found no free guest account"
				in
				(* Add cookies and stuff *)
				LoginCookie.create_new_login args.cgi args.db user;
		)
	);

	(* User form *)
	add_op "register_form" (fun args ->
		let open Jg_types in
		let template_string = Jg_template.from_file 
			"/home/d37433/templates/register.tmpl" 
		in
		args.echo template_string;
	);

	(* Save user in db *)
	(*
	add_op "create_user"
		(fun args ->
			let user = user_of_cgi args.cgi in

			(* Check for robot (robot question = four first letters of username) *)
			let robot = args.cgi#argument_value "robot" in
			let first4 = String.sub user.username 0 4 in
			if first4 <> robot then raise (UserException "Robot question error");

			(* All ok, create user *)
			create_user args.db user;

			(* Display nice message *)
			args.echo "Username created<br>";
			args.echo "<a href='?op=login_form&module=user'>Login here</a><br>";
		);
	*)
	
	(* Login form *)
	add_op "login_form" (fun args -> 
		let open Jg_types in
		let template_string = Jg_template.from_file 
			"/home/d37433/templates/login.tmpl" 
		in
		args.echo template_string;
	);

	(*
	add_op "login" (fun args ->
		let username = args.cgi#argument_value "username" in
		let password = args.cgi#argument_value "password" in
		let login = login args.db username password in
		(match login with
			  Not_logged_in -> args.echo "Wrong password"
			| Logged_in user -> 
				begin
					LoginCookie.create_new_login args.cgi args.db user;
					args.echo "Login ok<br>";
					args.echo "<a href='?op=startpage&module=startpage'>To startpage</a><br>";
				end)
		);
	*)

	add_op "logout" (fun args ->
		logout args.db args.login;
		args.echo "Logged out"
		);;

