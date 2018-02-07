(**
 *    Sql generation using dyntype, for records
 *
 *    For this to work the record must be named as the table, except for the
 *    prefix ds_. All fields in the table should be present in the record.
 *
 *    The record should be defined with dyntype like:
 *    type record = { ... } with value, type_of;;
 *
 *    @since 2013-03-03
 *)

open Dyntype

(** Fetch field list from value_of_type *)
let field_list_value l = 
      List.map (fun t -> 
            match t with 
                  (s, _) -> s) 
      l;;

(** Fetch field list from type_of_type *)
let field_list_type l = 
      let open Type in
      List.map (fun dict ->
      match dict with
            (fieldname, _, _) -> fieldname
      ) l;;

(*
let field_list_type' l =
      let open Type in
      List.map (function dics -> (fieldname, _, t) ->) l
            *)

(**
 *    Take a string list and implode and put ',' between
 *
 *    @param l          string list
 *    @return           string
 *)
let field_list_to_string l =
      let field_list_string = List.fold_left (fun a b -> a ^ "," ^ b) "" l in
      String.sub field_list_string 1 (String.length field_list_string - 1);; (* Strip first ',' *)

(**
 *    args to WHERE, like ["hej", "asd"] => "hej=? AND asd=?"
 *
 *    @param args       string list
 *    @return           string
 *)
let args_to_where args =
      let where = List.fold_left (fun a b -> a ^ b ^ "=? AND ") "" args in
      if where <> "" then String.sub where 0 (String.length where - 4) else where;;  (* strip last AND *)

(**
 *    Create INSERT sql for value_of type
 *
 *    @param value_of_t       value_of_t {...}
 *    @param return           string; sql query like INSERT INTO ds_[recordname](...) VALUES(?, ... )
 *)
let insert value_of =
      let open Value in
      match value_of with
            Ext ((typename, _), Dict l) -> 
                  (* Fetch all field names from type *)
                  let field_list = field_list_value l in
                  let field_list_string = field_list_to_string field_list in
                  let question_marks = List.fold_left (fun a b -> a ^ "?,") "" field_list in
                  let question_marks = String.sub question_marks 0 (String.length question_marks - 1) in (* Strip last ',' *)
                  let query = "INSERT INTO ds_" ^ typename ^ "(" ^ field_list_string ^ ") VALUES (" ^ question_marks ^ ")" in
                  query
            | _ -> failwith "No Ext for value_of_type?";;

(**
 *    Create SELECT sql code
 *
 *    Example usage:
 *          select (type_of_foo) 
 *
 *    @param type_of    type_of_type
 *    @param args       list of args to put in WHERE clause
 *	@param extras	Stuff put at absolute end of query, like ORDER BY or SORT BY
 *    @return           string; sql query like SELECT [field_list] FROM ds_[recordname] [WHERE args]
 *)
let select ?(args=[]) ?(extras="") type_of =
      let open Type in
      match type_of with
            Ext (typename, Dict (`R, l)) ->
                  let field_list = field_list_type l in
                  let field_list_string = field_list_to_string field_list in
                  let where = args_to_where args in
                  let query = "SELECT " ^ field_list_string ^ " FROM ds_" ^ typename ^ " " in
                  let query = if (List.length args > 0) then query ^ "WHERE " ^ where else query in
                  query ^ " " ^ extras
            | Ext (typename, Dict (`O, l)) -> failwith "No support for objects"
            | _ -> failwith "No Ext for type_of_type?"

(**
 *    Create update sql code
 *
 *    Example usage:
 *          update value_of_game ["game_id"; "card_id"]
 *
 *    @param args       string list for where fields
 *    @param value_of   value_of_t {...}
 *    @return           string; sql UPDATE
 *)
let update args value_of =
      let open Value in
      match value_of with
            Ext ((typename, _), Dict l) -> 
                  (* Fetch all field names from type *)
                  let field_list = field_list_value l in
                  let field_list_string = List.fold_left (fun a b -> a ^ b ^ "=?,") "" field_list in
                  let field_list_string = String.sub field_list_string 0 (String.length field_list_string - 1) in (* Strip first ',' *)
                  let where = args_to_where args in
                  let query = "UPDATE ds_" ^ typename ^ " SET " ^ field_list_string in
                  let query = if (List.length args > 0) then query ^ " WHERE " ^ where else query in
                  query
            | _ -> failwith "No Ext for value_of_type?";;

(*

tests from toplevel:

let s = Value.to_string (value_of_t3 {q = 123; w = 23.2})
let t = Value.of_string s
t3_of_value t => {q = 123; w = 23.2}

            

let row_of_t 
            

 *)
