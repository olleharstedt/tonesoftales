(**
	Module for ads, especially Tradedouble

	@since 2013-10-20
*)

(* Type for table ds_ads *)
type ads = {
	uri : string;
	company : string;
} with value, type_of

let get db = 
	Db.select_list
		db
		type_of_ads
		ads_of_value
		[]

(* Get all ads for a position *)
let get_position db pos =
	Db.select_list
		db
		type_of_ads
		ads_of_value
		[("position", string_of_int pos)]
