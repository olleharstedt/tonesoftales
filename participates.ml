(**
	Wrapper module for ds_participates table

	@since 2013-03-18
*)

type participates = {
	user_id : int;
	game_session_id : int
} with value, type_of

(**
	List of user_id that participates in game session

	@param db 		The db returned by open_db()
	@param session_id	int; game session id
	@return		int list; list of user ids
*)
let get_participations db session_id =
	let participations = Db.select_list
		db
		type_of_participates
		participates_of_value
		[("game_session_id", string_of_int session_id)]
	in
	List.map (fun p -> p.user_id) participations
		
(**
	Add a participation to db
	Used when a player joins lobby 

	@param db 		The db returned by open_db()
	@param user_id	int
	@param game_session_id	int
	@return 		unit
*)
let add_participate db user_id game_session_id =
	Db.insert
		db
		(value_of_participates {
			user_id; 
			game_session_id}
		)
