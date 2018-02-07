(**
 *    Chat controller stuff
 *
 *    @since 2013-03-07
 *)

open Operation
open Game

type channel = { 
      id : int;
      channel : Lwt_websocket.Channel.t;
}

let _ =
      let add_op_ajax_login = add_op_ajax_login "chat" in

      add_op_ajax_login
            "start_chat"
            (fun args user ->
                  args.echo "chat";
            )
;;
