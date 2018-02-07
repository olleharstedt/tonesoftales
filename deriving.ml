(**
	Module for deriving json types, for types safe conversion in Javascript.

	@since 2013-07-28
*)

module Test = struct
	type t = {
		a : int
	}
	and t_list = t list deriving (Json)

	let l = [
		{a = 1};
		{a = 2};
	]

	let to_string v = Json.to_string<t_list> v
end

module Card = struct
	type card = {
		id : int;
		text : string;
		title : string;
		img : string;
		dir : string;
	} and 
	card_list = card list deriving (Json)

	let to_string v = Json.to_string<card_list> v
	let from_string v = Json.from_string<card_list> v
end
