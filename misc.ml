(**
 *    Some misc functions needed
 *
 *    @since 2012-11-09
 *    @author Olle Härstedt
 *)

let get_opt op =
	match op with 
		Some v -> v
		| None -> 
			(
				Printexc.record_backtrace true;
				raise Not_found
			)

let implode_list l =
      List.fold_left (^) "" l

(** Return day of month as int *)
let get_day () =
	let open Unix in
	let time = time() in
	let gm = localtime time in
	gm.tm_mday

(**
 *    Get local datetime, like so: "2012-01-01 01:00:00"
 *
 *    @return     String
 *)
let get_datetime () =
      let zero_prefix i =
            if i < 10 then
                  "0" ^ string_of_int i
            else
                  string_of_int i
      in
      let open Unix in
      let time = time() in
      let gm = localtime time in
      let month = zero_prefix (gm.tm_mon + 1) in
      let year = zero_prefix (gm.tm_year + 1900) in
      let day = zero_prefix (gm.tm_mday) in
      let hour = zero_prefix (gm.tm_hour) in
      let minutes = zero_prefix (gm.tm_min) in
      let seconds = zero_prefix (gm.tm_sec) in
      year ^ "-" ^ month ^ "-" ^ day ^ " " ^ hour ^ ":" ^ minutes
      ^ ":" ^ seconds;;

(**
	Didn't work very well. Used TIMESTAMPDIFF in MySQL instead.

	Takes a date like "2012-02-03 23:10:00" and turn it into seconds. Approximative.

	@param t 	string;
	@return	int of seconds
*)
(*
let to_seconds t echo = 
	let sub_aux start length =
		int_of_string (String.sub t start length) in
	let year = sub_aux 0 4 in
	let month = sub_aux 5 2 in
	let day = sub_aux 8 2 in
	let hours = sub_aux 11 2 in
	let minutes = sub_aux 14 2 in
	let seconds = sub_aux 17 2 in
	echo (" " ^ (string_of_int month) ^ " ");
	year * 31556926 + month * 2629743 + day * 86400 + hours * 3600 + minutes * 60 + seconds;;
*)
