(**
	Database module

	A wrapper around the Mysql library, creating names like the old PHP ones.

      Also using dyntype to fetch type information from records and from it
      construct sql code. Possibly.

	If a column can be NULL, the corresponding record field MUST be option.

	@since 2012-05-03
	@author Olle Harstedt <olle.harstedt@yahoo.com>
*)

type db = Mysql.dbd;;
type result = Mysql.Prepared.stmt_result;;

exception DatabaseException of string;;

(**
	Open db
	Open up db and return a handler. This handler is used in all
	succeeding database calls.
*
*     @return     Db handle
*)
let open_db xml = 
	(**
		Helper function to get database information from XML config file.

		@param xml		XML object returned by Xml.parse_file
		@param tagname	String, name of tag, e.g. "host"
		@throws 		Not_found if any tag was not found
	*)
	let get_databaseinfo xml tagname =
		(* Get all node children of XMl file *)
		let children = Xml.children xml in
		(* Find child with tag "database" *)
		let database_tag = List.find (fun x -> Xml.tag x = "database") children in
		(* Get children of that node *)
		let database_children = Xml.children database_tag in
		(* Find chil with tag @tagname *)
		let tag_info = List.find (fun x -> Xml.tag x = tagname) database_children in
		(* Return text data of that node *)
		Xml.pcdata (List.hd (Xml.children tag_info)) in

	(* Open db *)
	let db = Mysql.quick_connect
		~options: ([Mysql.SET_CHARSET_NAME "utf8"])
		~user: (get_databaseinfo xml "user")
		~password: (get_databaseinfo xml "password")
		~database: (get_databaseinfo xml "database")
		~host: (get_databaseinfo xml "host")
		~port: 3306 (); in
	(*
	let query = "set names utf8" in	(* This is necessary to get proper encoding *)
	ignore (Mysql.exec db query); 	(* Should have type unit, but if 'result = Mysql...' you get 'result unused *)
	*)
	db;;				(* Return the db handler *)

(* Escape html to utf8 *)
let escape = Netencoding.Html.encode ~in_enc:`Enc_utf8 ();;
let decode = Netencoding.Html.decode_to_latin1;;

(**
	Hash string
*)
let digest str = 
	Digest.to_hex (Digest.string str)

(**
	recordSearchFree
	Like the PHP equivalent

	@param db 		The db returned by open_db
	@param query	Query string
	@param args		Array of arguments to place holders in query
      @return           Tuple of (result, affected_rows, insert_id)
*)
let run_query db query args =
	let stmt = Mysql.Prepared.create db query in
	let result = Mysql.Prepared.execute stmt args in
	(result, Mysql.Prepared.affected stmt, Mysql.Prepared.insert_id stmt);;

(**
	Execute query
	Not prepared statement
*)
let exec db query =
	Mysql.exec db query

(**
 *    stmt_result -> string option array option
 *)
let fetch_row = Mysql.Prepared.fetch;;

(**
	Get rows from @result (from stmt execution)

	@param result	result from stmt execution
	@return		row list
*)
let get_rows result = 
	let rec aux r = 
		match fetch_row r with
			| None -> []
			| Some row -> row :: aux result
	in
	aux result

(**
	To fetch a variable from a stored procedures OUT, like:
		CALL foo(10, @bar)
	then
	let bar = get_stored_out db "bar" ...

	@param result	result from a query
	@param var		string; variable name, without @
	@return		string
*)
let get_stored_out db var =
	let result = exec db ("SELECT @" ^ var) in
	Misc.get_opt (Misc.get_opt (Mysql.fetch result)).(0)

(**
	Close a connection with db.
*)
let close db = 
	Mysql.disconnect db;;

(**
	Close a query after use
*)
let close_stmt stmt = 
	Mysql.Prepared.close stmt;;

(**
	Creates a prepared query to be used with execute_query.
*)
let create_stmt db query_string =
	Mysql.Prepared.create db query_string;;

(**
	Executes a query created with create_query and returns result as a string option array option.
*)
let execute_stmt stmt args =
	(*let args = Array.map (fun s -> escape s) args in *)
	Mysql.Prepared.execute stmt args;;

(**
 *    Help function for fetching result
 *
 *    @param row        Row value the gets fed to function when iter a result
 *    @param index      Column index
 *    @param default    Default value to return if column field was empty (None)
*)
let fetch_field row (index : int) (default : string) = 
      match row.(index) with
              None -> default
            | Some value -> value;;

(**
 *    Return int64 number of affected rows of last query.
 *)
let affected = Mysql.Prepared.affected;;

(**
	Fetch all rows from a result set, return as a list (applied with function).

	@param result	Result from a run_query
	@param f 		Transform function, e.g. deck_of_row. Could also be (fun x -> x).
	@return		Rows fetched as a list
*)
let list_of_result result f = 
	let rec fetch_rows_aux row result = match row with
		Some row -> [f row] @ (fetch_rows_aux (fetch_row result) result)
		| None -> [] in
	fetch_rows_aux (fetch_row result) result;; 

(* Get id of last inserted/affected row *)
let insert_id stmt =  Mysql.Prepared.insert_id stmt;;

(**
	Starts a transaction
	Must be followed by commit or rollback
*)
let start_transaction db =
	ignore(Mysql.exec db "START TRANSACTION")
	(*
	let query = "START TRANSACTION" in
	let stmt = create_stmt db query in
	execute_stmt stmt [||]
	*)

(**
	Commits a transaction
*)
let commit db = 
	ignore(Mysql.exec db "COMMIT")

(**
	Rollbacks a transaction
*)
let rollback db = 
	ignore(Mysql.exec db "ROLLBACK")

(**
	Execute stuff in fn within transaction, and returns whatever fn returns.
	Commit if everythings fine.
	If @fn raises exception, a rollback will be run and the exception run again.

	@param db 		The db returned by open_db()
	@param fn		unit -> 'a
	@return		unit
	@raise		raise exception in @fn
*)
let with_transaction db fn =
	start_transaction db;
	let result = (try fn () with e -> rollback db; raise e) in
	commit db;
	result

(**
 *    Insert record in db using dyntype
 *
 *    @param db         db from Db.open()
 *    @param value_of   value_of_type
 *    @return           id of inserted row; side-effect = saves value in db
 *)
let insert db value_of =
      let open Dyntype in
      let open Value in
      match value_of with
            Ext ((typename, _), Dict l) -> 
                  (* Fetch all values from type *)
                  let value_list = List.map (fun t -> 
                        match t with 
                              (_, Value (Int i)) -> Int64.to_string i 
                              | (_, Int i) -> Int64.to_string i 
                              | (_, Value (String s)) -> s 
                              | (_, String s) -> s 
                              | (_, Value (Float fl)) -> string_of_float fl
                              | (_, Float fl) -> string_of_float fl
                              | (_, Value (Bool b)) -> if b then "1" else "0"
                              | (_, Bool b) -> if b then "1" else "0"
                              | (_, Null) -> "null"
                              | (_, _) -> failwith "Not supported type"
                  ) l in
                  let query = Sql.insert value_of in
                  let stmt = create_stmt db query in
                  let args = Array.of_list value_list in
                  ignore(execute_stmt stmt args);
			let id = Mysql.Prepared.insert_id stmt in
                  close_stmt stmt;
			id
            | _ -> failwith "No Ext for value_of_type?";;

(**
 *    Update table row
 *    Make sure args uniquely defines a row!
 *
 *    @param db         db from Db.open()
 *    @param value_of   value_of_type
 *    @param args       associative list put in WHERE; this MUST be the key of the row
 *    @return           unit
 *)
let update db value_of args =
	let open Dyntype in
	let open Value in
	assert (List.length args > 0);
	let args_keys = List.map ( function (key, _) -> key) args in
	let args_values = List.map ( function (_, value) -> value) args in
	match value_of with
		Ext ((typename, _), Dict l) -> 
			(* Fetch all values from type *)
			let value_list = List.map (fun t -> 
				match t with 
					(_, Value (Int i)) -> Int64.to_string i 
					| (_, Int i) -> Int64.to_string i 
					| (_, Value (String s)) -> s 
					| (_, String s) -> s 
					| (_, Value (Float fl)) -> string_of_float fl
					| (_, Float fl) -> string_of_float fl
					| (_, Value (Bool b)) -> if b then "1" else "0"
					| (_, Bool b) -> if b then "1" else "0"
					| (_, Null) -> "null"
					| (_, _) -> failwith "Not supported type"
			) l in
			let query = Sql.update args_keys value_of in
			let stmt = create_stmt db query in
			let args' = Array.of_list (value_list @ args_values) in
			ignore(execute_stmt stmt args');
			close_stmt stmt;
		| _ -> failwith "No Ext for value_of_type?";;

(**
	Iterate fields in row

	@param l	list of fields from dyntype Dict
	@param row	string option array, from db result
	@param n	length of list/row
*)
let rec iter_fields l row n = match n with
	-1 -> []
	| n -> (match row.(n) with
		Some field -> ((List.nth l n), field) :: (iter_fields l row (n - 1))
		(*| None -> raise (DatabaseException "Found no field in Db.select_list."))*)
		| None -> ((List.nth l n), "") :: (iter_fields l row (n - 1)))	(* TODO: Fix this, should be None *)

(**
 *    Select type_of, return record
 *    Return first result, not a list. That is, key/args should be unique.
 *
 *    @param db         db from Db.open()
 *    @param type_of    type_of_type
 *    @param record_of_value  e.g. game_of_value
 *    @param args       associative list put in WHERE, pressumably table key(s)
 *	@param extras	string; ORDER BY or SORT BY etc, concatenated to end of query string
 *    @return           record of type type_of
 *)
let select ?(extras="") db type_of record_of_value args =
      let open Dyntype in
      let module V = Value in
      let module T = Type in
      match type_of with
            T.Ext (typename, T.Dict (_, l)) ->
                  (* Run query *)
                  let args_keys = List.map (function (key, value) -> key) args in
                  let args_values = List.map ( function (key, value) -> value) args in
                  let query = Sql.select type_of ~args:args_keys ~extras:extras in
                  let stmt = create_stmt db query in
                  let args = Array.of_list args_values in
                  let result = execute_stmt stmt args in
                  let row = (match fetch_row result with Some r -> r | None -> raise Not_found ) in
                  let length = Array.length row in

                  (* Get key/value pair of fields from type_of and values from rows *)
                  assert(List.length l = length);
                  let fields = iter_fields l row (length-1) in
                  let fields = List.rev fields in

                  (* Build up Value out of type info and values from db *)
                  let dict = V.Dict (List.map ( fun t ->
                        match t with
                              | ((key, _, T.String), value) -> (key, V.String value)
                              | ((key, _, T.Option (T.String)), value) -> (key, V.Value (V.String value))
                              | ((key, _, T.Int i), value) -> (key, V.Int (Int64.of_string value))
                              | ((key, _, T.Option (T.Int (Some i))), value) -> (key, V.Value (V.Int (Int64.of_string value)))
                              | ((key, _, T.Option (T.Int (None))), v) -> failwith ("Db.select: No value for " ^ key)
                              | ((key, _, T.Float), value) -> (key, V.Float (float_of_string value))
                              | ((key, _, T.Bool), value) -> (key, V.Bool (value = "1"))
                              | ((key, _, _), value) -> failwith ("Db.select: Not supported type for field " ^ key)
                  ) fields)
                  in

                  let ext = V.Ext ((typename, 2L), dict) in

                  close_stmt stmt;
                  record_of_value ext 
            | _ -> failwith "No Ext for type_of_type?";;

(**
 *    Select type_of, return record
 *    Return list of records. That is, key/args should NOT be unique (if they
 *    are, list will have length 1).
 *
 *    @param db         db from Db.open()
 *    @param type_of    type_of_type
 *    @param record_of_value  e.g. game_of_value
 *    @param args       associative list put in WHERE, pressumably search criterias
 *    @return           (record of type type_of) list
 *)
let select_list db type_of record_of_value args =
      let open Dyntype in
      let module V = Value in
      let module T = Type in
      match type_of with
            T.Ext (typename, T.Dict (_, l)) ->
                  (* Run query *)
                  let args_keys = List.map (function (key, value) -> key) args in
                  let args_values = List.map ( function (key, value) -> value) args in
                  let query = Sql.select type_of ~args:args_keys in
                  let stmt = create_stmt db query in
                  let args = Array.of_list args_values in
                  let result = execute_stmt stmt args in

                  let rec make_list result = match fetch_row result with
                        None -> []
                        | Some row ->
                              let length = Array.length row in
                              (* Get key/value pair of fields from type_of and values from rows *)
                              assert(List.length l = length);
                              let fields = iter_fields l row (length-1) in
                              let fields = List.rev fields in

                              (* Build up Value out of type info and values from db *)
                              let dict = V.Dict (List.map ( fun t ->
                                    match t with
                                          | ((key, _, T.String), value) -> (key, V.String value)
                                          | ((key, _, T.Option (T.String)), value) -> (key, V.Value (V.String value))
                                          | ((key, _, T.Int i), value) -> (key, V.Int (Int64.of_string value))
                                          | ((key, _, T.Option (T.Int (Some i))), value) -> (key, V.Value (V.Int (Int64.of_string value)))
                                          | ((key, _, T.Option (T.Int (None))), v) -> failwith ("Db.select: No value for " ^ key)
                                          | ((key, _, T.Float), value) -> (key, V.Float (float_of_string value)) (* TODO: Not working? *)
                                          | ((key, _, T.Bool), value) -> (key, V.Bool (value = "1"))
                                          | ((key, _, _), value) -> failwith ("Db.select_list: Not supported type for field " ^ key)
                              ) fields)
                              in
                              let ext = V.Ext ((typename, 2L), dict) in
                              (record_of_value ext) :: make_list result
                  in
                  make_list result;
            | _ -> failwith "No Ext for type_of_type?";;
