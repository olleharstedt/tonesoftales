/**

	Misc Javascript functions to Drakskatten

	@since 2013-02-28

	Copyright etc

*/

// Disable for production, enable for debug
	//log = function (msg) {};
log = console && console.log ? function (msg) { console.log(msg)} : function (msg) {};

// Codemirror stuff below
function isFullScreen(cm) {
	return /\bCodeMirror-fullscreen\b/.test(cm.getWrapperElement().className);
}
function winHeight() {
	return window.innerHeight || (document.documentElement || document.body).clientHeight;
}
function winWidth() {
	return window.innerWidth || (document.documentElement || document.body).clientWidth;
}
function setFullScreen(cm, full) {
	var wrap = cm.getWrapperElement();
	if (full) {
		wrap.className += " CodeMirror-fullscreen";
		wrap.style.height = winHeight() + "px";
		wrap.style.width = winWidth() + "px";
		document.documentElement.style.overflow = "hidden";
	} else {
		wrap.className = wrap.className.replace(" CodeMirror-fullscreen", "");
		wrap.style.height = "500px";
		wrap.style.width = "700px";
		document.documentElement.style.overflow = "";
	}
	cm.refresh();
}
CodeMirror.on(window, "resize", function() {
	var showing = document.body.getElementsByClassName("CodeMirror-fullscreen")[0];
	if (!showing) return;
	showing.CodeMirror.getWrapperElement().style.height = winHeight() + "px";
	//showing.CodeMirror.getWrapperElement().style.width = winWidth() + "px";
});

codemirror = null;	// Code editor	// TODO: Array of editors
codemirror2 = null;	// Code editor
codemirror3 = null;	// Code editor
codemirror4 = null;	// Code editor
codemirror5 = null;	// Code editor

/* Some stuff to satisfy js_of_ocaml */
function unix_inet_addr_of_string (s) { return s }

ws = null;			// WebSocket. TODO: Collide with js_of_ocaml??
my_player_nr = 0;		// Player nr, not id (id is in database, but we don't know who will play, only who's first, second etc)
player_turn_nr = 0;

// Global game variable
game = {}

// Legend for turn arrow
_legend = false

/**
	When deck is added with Place_deck, a deck object will be pushed to this array.
	Place_deck is  deprecated; use Update_table instead.
*/
table_decks = [];

/**
	Not used
*/
tables = [];

/** Table style, keep track of change for each new frame, so we know if we have to rebuild the table */
old_table_width = 0;
old_table_height = 0;
old_table_rows = 0;
old_table_cols = 0;
old_table_legend = 0;

/**
	Cards on hand
	When pick_card, card is pushed onto the array
*/
hand_ = [];

/**
	Array of callback functions for updating hand menus
	Used after html is put in placed, after each update
*/
hand_menu_callbacks = [];

/** As above, for table menus (cards, decks) */
table_menu_callbacks = []

/** As above, for player slots */
player_slot_callbacks = []

/** List of all callback lists above */
all_callbacks = [hand_menu_callbacks, table_menu_callbacks, player_slot_callbacks];

/** Key callbacks. Each item is an array like ["Key_bind", char_code, callback_int] */
keydown_callbacks = [];
$(document).keydown(function(ev) {

	// If focus is in input field, do nothing
	if (ev.target.tagName.toLowerCase() == "input") {
		// Do nothing
	}
	else {
		for (var i = 0; i < keydown_callbacks.length; i++) {
			var bind = keydown_callbacks[i]
			if (ev.which == bind[1]) {
				log("pressed " + ev.which);
				var command = {
					command_type: ['Keydown', bind[1]],
					username: getCookie("username")
				}
				ws.send(JSON.stringify(command));
			}
		}
	}

});

/** Using canvas or not */
var using_canvas = false;

/** Movables enabled or not (triggers realtime loop) */
var movables_enabled = false;
var new_movables = []; // Movables just received from server
var old_movables = {}; // Movables received last update, as {card_nr: obj, ...} TODO: Better obj id than card_nr? Dynamically created?
var timestamp = 0;	// Increase each frame. Resets at 999999999 on server.

// this code from: http://www.paulirish.com/2011/requestanimationframe-for-smart-animating/
// shim layer with setTimeout fallback
window.requestAnimFrame = (function(){
  return  window.requestAnimationFrame       ||
          window.webkitRequestAnimationFrame ||
          window.mozRequestAnimationFrame    ||
          function( callback ){
            window.setTimeout(callback, 1000 / 60);
          };
})();
// usage:
// instead of setInterval(render, 16) ....
//(function animloop(){
// requestAnimFrame(animloop);
// render();
//})();
// place the rAF *before* the render() to assure as close to
// 60fps with the setTimeout fallback.


$(document).ready(function ()
{
	// Check if there is an editor textfield on the page. If so, replace it with CodeMirror
	try {
	codemirror = CodeMirror.fromTextArea(document.getElementById("editor"), {
		lineNumbers: true,
		theme: "default",
		extraKeys: {
			"F11": function(cm) {
				setFullScreen(cm, !isFullScreen(cm));
			},
			"Esc": function(cm) {
				if (isFullScreen(cm)) setFullScreen(cm, false);
			},
			"Ctrl-S": function (cm) {
				save_init_script();
			}
		}
	});
	codemirror2 = CodeMirror.fromTextArea(document.getElementById("editor2"), {
		lineNumbers: true,
		theme: "default",
		extraKeys: {
			"Ctrl-S": function (cm) {
				save_init_script();
			},
			"F11": function(cm) {
				setFullScreen(cm, !isFullScreen(cm));
			},
			"Esc": function(cm) {
				if (isFullScreen(cm)) setFullScreen(cm, false);
			}
		}
	});
	codemirror3 = CodeMirror.fromTextArea(document.getElementById("editor3"), {
		lineNumbers: true,
		theme: "default",
		extraKeys: {
			"F11": function(cm) {
				setFullScreen(cm, !isFullScreen(cm));
			},
			"Esc": function(cm) {
				if (isFullScreen(cm)) setFullScreen(cm, false);
			},
			"Ctrl-S": function (cm) {
				save_init_script();
			}
		}
	});
	codemirror4 = CodeMirror.fromTextArea(document.getElementById("editor4"), {
		lineNumbers: true,
		theme: "default",
		extraKeys: {
			"F11": function(cm) {
				setFullScreen(cm, !isFullScreen(cm));
			},
			"Esc": function(cm) {
				if (isFullScreen(cm)) setFullScreen(cm, false);
			},
			"Ctrl-S": function (cm) {
				save_init_script();
			}
		}
	});
	codemirror5 = CodeMirror.fromTextArea(document.getElementById("editor5"), {
		lineNumbers: true,
		theme: "default",
		extraKeys: {
			"F11": function(cm) {
				setFullScreen(cm, !isFullScreen(cm));
			},
			"Esc": function(cm) {
				if (isFullScreen(cm)) setFullScreen(cm, false);
			},
			"Ctrl-S": function (cm) {
				save_init_script();
			}
		}
	});
	}
	catch (ex) {
		//Nothing
	}

	// resizable clashes with fullscreen at F11
	//$('.CodeMirror').resizable({
		//resize: function() {
			//editor.setSize($(this).width(), $(this).height());
		//}
	//});

	// Connect web socket
	var port = $('#port').val();
	var addr = $('#addr').val();
	if (port) {
		//ws = new WebSocket();
	}

	var chat = document.getElementById('message');
	if (chat) {
		chat.addEventListener("keyup", function(e) {
			if (!e) { 
				var e = window.event; 
			}
			e.preventDefault(); // sometimes useful

			// Enter is pressed
			if (e.keyCode == 13) { 
				var msg = $('#message').val();
				if (msg != "") {
					say(msg);
				}
				$('#message').val("");
			}
		}, 
		false);
	}

});

// Add input and select data from page to @data
function add_data_from_form(data)
{
	var form = document.getElementsByTagName('form')[0];
	var inputs = Array.prototype.slice.call(form.getElementsByTagName('input'));
	//var textareas = Array.prototype.slice.call(document.getElementsByTagName('textarea'));
	//var inputs = inputs.concat(textareas);

	// Add data from form
	inputs.forEach( function (input) {
		if (input.tagName == "textarea")
			data[input.name] = input.innerHTML;
		else if (input.type != "button")
			data[input.name] = input.value;
	});

	selects = Array.prototype.slice.call(form.getElementsByTagName('select'));

	selects.forEach( function (select) {
		data[select.name] = select.options[select.selectedIndex].value;
	});
}

// Defined in jstest.js, from OCaml jstest.ml!
/**
	Populate cards for chosen game.
*/
/*
function choose_game()
{

	var game_id = $('#game_select').val();
	$.getJSON("drakskatten_ajax?op=list_of_cards_for_game&module=card&game_id=" + game_id, function (data) {
		console.log("here");
		console.log(data);

		// Clear card list
		$('#card_select').html("");
		$('#submit').hide();

		// Abort if no cards found
		if (data.length == 0)
		{
			alert("No cards found for this game. Add decks to game first.");
			return;
		}

		$('#submit').show();

		data.forEach( function (card) { 
			// Append option
			$('#card_select').append($('<option></option>', {value: card.id}).text(card.title));
			//var option = document.createElement('option');
			//option.value = card.id;
			//option.innerHTML = card.title;
			//select.add(option, null);
		});

	});
}
*/

/**
 * 	Save script for card
 */
function save_card_has_script()
{
	var data = {
		onpickup: codemirror.getValue(),
		onplay: codemirror2.getValue()
	};

	add_data_from_form(data);

	console.log(data);

	var ajax = $.ajax({
		type: "POST",
	    	url: "/cgi-bin/drakskatten_ajax", 
	    	data: data,
	    	success: function (data, textStatus, jqXHR) {
			alert("Script saved");
		},
	    	error: function (data, textStatus) {
			alert("Error: " + textStatus);
		}
	});
}

/**
 * 	Run when user chooses game in drop-down on game init script edit page.
 * 	Load script for game and put it into editor.
 */
function choose_init_script_game () {
	var game_id = $('#game_select').val();
	if (game_id != -1) {
		$.getJSON("drakskatten_ajax?op=get_init_script&module=game&game_id=" + game_id, function (data) {
			codemirror.setValue(data.init_script);
			codemirror2.setValue(data.onplay_all);
			codemirror3.setValue(data.onendturn);
			codemirror4.setValue(data.onbeginturn);
			codemirror5.setValue(data.onpickup_all);

			var game = data;

			if (data.init_script == "")
			{
				codemirror.setValue("function init()\nend");
			}

			$.getJSON("drakskatten_ajax?op=get_game_info&module=game&game_id=" + game_id, function (data) {
				log(data);
				var right_div = document.getElementById('right');
				right_div.innerHTML = "";
				var rows = data.map(function (el) { 
					return "<tr><td>" + el.deck_name + "</td><td>" + el.deck_nr + "</td></tr>";
				});
				var string_rows = rows.join();
				right_div.innerHTML += "<p>Decks in this game:</p><table><tr><td><b>Name</b></td><td><b>Nr</b></td></tr>" + string_rows + "</table><br>";
				right_div.innerHTML += "<p>Table slots in game:</p>" + game.table_slots;
			});
		});
	}
}

function choose_opensource() {
	var game_id = $('#game_select').val();
	if (game_id != -1) {
		$.getJSON("drakskatten_ajax?op=get_opensource&module=game&game_id=" + game_id, function (data) {
			codemirror.setValue(data.init_script);
			codemirror2.setValue(data.onplay_all);
			codemirror3.setValue(data.onendturn);
			codemirror4.setValue(data.onbeginturn);
			codemirror5.setValue(data.onpickup_all);

			var game = data;

			if (data.init_script == "")
			{
				codemirror.setValue("function init()\nend");
			}

			$.getJSON("drakskatten_ajax?op=get_game_info_opensource&module=game&game_id=" + game_id, function (data) {
				log(data);
				var right_div = document.getElementById('right');
				right_div.innerHTML = "";
				var rows = data.map(function (el) { 
					return "<tr><td>" + el.deck_name + "</td><td>" + el.deck_nr + "</td></tr>";
				});
				var string_rows = rows.join();
				right_div.innerHTML += "<p>Decks in this game:</p><table><tr><td><b>Name</b></td><td><b>Nr</b></td></tr>" + string_rows + "</table><br>";
				right_div.innerHTML += "<p>Table slots in game:</p>" + game.table_slots;
			});
		});
	}
}

// Save init script for game
function save_init_script()
{
	var game_id = $('#game_select').val();
	var data = {
		init_script: codemirror.getValue(),
		onplay_all: codemirror2.getValue(),
		onendturn: codemirror3.getValue(),
		onbeginturn: codemirror4.getValue(),
		onpickup_all: codemirror5.getValue()
	};

	add_data_from_form(data);

	var ajax = $.ajax({
		type: "POST",
	    	url: "/cgi-bin/drakskatten_ajax", 
	    	data: data,
	    	success: function (data, textStatus, jqXHR) {
			alert("Script saved");
		},
	    	error: function (data, textStatus) {
			alert("Error: " + textStatus);
		}
	});
}

// Test
function send_chat_message(msg)
{
}

// Used??
function start_chat() {
	var data = {
		module: "startpage",
		op: "start_chat",
	};
	$.ajax({
		type: "POST",
		url: "/cgi-bin/drakskatten_ajax", 
		data: data,
		success: function (){},
		error: function (data, textStatus) {
			console.log(textStatus);
		}
	});
}

/**
	Commands the server to startup a websocket listener CGI.
	If success, make a websocket that connects to it.

	DEFINED IN OCAML, jstest.ml, SINCE 2013-08-08

	@param addr		string; Address of server
	@param port		int
	@param game_session_id	int
	@param pwd		boolean; true if password is used for this session
*/
/*
function open_new_lobby(addr, port, game_session_id, pwd) {
	var data = {
		module: "gamesession",
		op: "open_new_lobby",
		game_session_id: game_session_id
	};
	$.ajax({
		type: "POST",
		url: "/cgi-bin/drakskatten_ajax", 
		data: data,
		success: function (){
				new_websocket(addr, port, pwd);
			},
		error: function (data, textStatus) {
			console.log("Could not start gamesession");
			console.log(textStatus);
		}
	});
}
*/

/**
 * 	Show deck menus for players turn, hide for others
 * 	Depend on global variables:
 * 		player_turn_nr
 * 		my_player_nr
 *		decks
 *	
 *	DONE IN OCAML SINCE 2013-08-08, jstest.ml
 */
function show_menus() {
	if (player_turn_nr == my_player_nr) {

		// Show menus for decks
		// TODO: Replace this with table_slots below
		var length = table_decks.length;
		for (i = 0; i < length; i++) {
			(function fn() {			// Need local scope for ul
				deck_nr = table_decks[i].deck_nr;
				var ul = document.getElementById('deck_' + deck_nr + '_menu');
				if (ul) {
					ul.style.display = 'none';
					deck_div = document.getElementById('deck_' + deck_nr);
					deck_div.onmouseover = function () {
						ul.style.display = 'block';
					};
					deck_div.onmouseout = function () {
						ul.style.display = 'none';
					};
					// Also check if the mouse aint moving
					if ($('#deck_' + deck_nr).ismouseover()) {
						ul.style.display = 'block';
					}
				}
			})();
		}

		// Show menus for table_slots
		var length = table_decks.length;
		var i = 1;
		//for (i = 0; i < length; i++) {
		do {
			var ul = document.getElementById('table_slot' + i + '_menu');
			(function fn() {			// Need local scope for ul
				var ul = document.getElementById('table_slot' + i + '_menu');
				var slot = document.getElementById('table_slot' + i);
				if (ul && slot) {
					ul.style.display = 'none';
					slot.onmouseover = function () {
						ul.style.display = 'block';
					};
					slot.onmouseout = function () {
						ul.style.display = 'none';
					};
					// Also check if the mouse aint moving
					if ($('#table_slot' + i).ismouseover()) {
						ul.style.display = 'block';
					}
				}
			})();
			i++;
		} while (ul != undefined);

		// Show menus for cards in hand
		var l = hand_.length;
		for (i = 1; i <= l; i++) {
			(function fn() {			// Need local scope for ul
				card_slot = document.getElementById('hand1_slot' + i);
				var ul = document.getElementById('hand1_slot' + i + '_menu');
				// TODO: show_menus() called before each card is added to hand, but hand_ contains all cards.
				if (ul) {
					ul.style.display = 'none';
					card_slot.onmouseover = function () {
						ul.style.display = 'block';
					};
					card_slot.onmouseout = function () {
						ul.style.display = 'none';
					};
					// Also check if the mouse aint moving
					if ($('#hand1_slot' + i).ismouseover()) {
						ul.style.display = 'block';
					}
				}
			})();
		}

		// Show menus for player slots
		var i = 1;
		do {
			var slot = document.getElementById('player' + my_player_nr + '_slot' + i);	// Scope stuff for while-loop
			(function fn() {			// Need local scope for ul
				var slot = document.getElementById('player' + my_player_nr + '_slot' + i);
				var ul = document.getElementById('player' + my_player_nr + '_slot' + i + '_menu');
				if (ul && slot) {
					ul.style.display = 'none';
					slot.onmouseover = function () {
						ul.style.display = 'block';
					};
					slot.onmouseout = function () {
						ul.style.display = 'none';
					};
					// Also check if the mouse aint moving
					if ($('#player' + my_player_nr + '_slot' + i).ismouseover()) {
						ul.style.display = 'block';
					}
				}
			})();
			i++;
		} while (slot != undefined);
	}
	else {
		// Not my turn, hide menus etc

		// Hide deck menus
		var length = table_decks.length;
		for (i = 0; i < length; i++) {
			deck_nr = table_decks[i].deck_nr;
			deck_div = document.getElementById('deck_' + deck_nr);
			if (deck_div) {
				deck_div.onmouseover = function () {};
				deck_div.onmouseout = function () {};
			}
			var ul = document.getElementById('deck_' + deck_nr + '_menu');
			if (ul) {
				ul.style.display = 'none';
			}
		}

		// Hide table slot menus
		i = 1;
		do {
			slot = document.getElementById('table_slot' + i);
			if (slot != undefined) {		// This can happen if race-condition? Many incoming websocket messages.
				slot.onmouseover = function () {};
				slot.onmouseout = function () {};
				var ul = document.getElementById('table_slot' + i + '_menu');
				if (ul != undefined) {
					ul.style.display = 'none';
				}
			}
			i++;
		} while (slot != undefined);

		// Hide hand menus
		var l = hand_.length;
		for (i = 1; i <= l; i++) {
			card_slot = document.getElementById('hand1_slot' + i);
			if (card_slot != undefined) {		// This can happen if race-condition? Many incoming websocket messages.
				card_slot.onmouseover = function () {};
				card_slot.onmouseout = function () {};
				var ul = document.getElementById('hand1_slot' + i + '_menu');
				ul.style.display = 'none';
			}
		}

		// Hide player slot menus
		i = 1;
		do {
			slot = document.getElementById('player' + my_player_nr + '_slot' + i);
			if (slot != undefined) {		// This can happen if race-condition? Many incoming websocket messages.
				slot.onmouseover = function () {};
				slot.onmouseout = function () {};
				var ul = document.getElementById('player' + my_player_nr + '_slot' + i + '_menu');
				if (ul != undefined) {
					ul.style.display = 'none';
				}
			}
			i++;
		} while (slot != undefined);
		
	}
}

/** Global variables for marking */
var marked_slots = [];		// List of marked slots (html elements)
var enable_marking = []; 	// List of markable slots
var slots = {}		// img -> slot

/** Global variables for draggable and droppable */
var draggable_cards = [];
var droppable_slots = [];
var draggable_player_nrs = []; // Drag-n-drop enabled for these players

/** Global variable for onclick */
var onclick_cards = [];

/** Update all draggable and droppable cards and slots */
function update_draggable() {

	// Abort if not enabled for me
	var nrs = draggable_player_nrs.filter(function (nr) { return nr == my_player_nr } );
	if (nrs.length == 0) {
		// Disable draggables
		$(".ui-draggable").draggable("destroy");
		log("draggable not enabled for me");
		return;
	}

	//chat("draggable_cards.length = " + draggable_cards.length);
	//console.trace();
	var length = draggable_cards.length;
	for (var i = 0; i < length; i++) {
		var card = draggable_cards[i];
		//var c_ = document.getElementById("card{0}".format(card.card_nr));
		//if (c_ == undefined) {
			//chat("No card found: " + card.card_nr);
		//}
		$("#card{0}".format(card.card_nr)).draggable({
			revert: "invalid",
			start: function () {
				$(this).addClass("noclick");	// Avoid collision with onclick and draggable
			}
			//stop: function () {
				//$(this).removeClass("noclick");
			//}
		}).css("z-index", "100");
	}
	// Turn off default drag behaviour
	$(document).on("dragstart", function(event, ui) {
		if (ui && ui.draggable) {
			return true;
		}
		else if (event.target.className.indexOf("ui-draggable") == -1) {
			return false;
		}
		//return false;
	});


	var length = droppable_slots.length;
	for (var i = 0; i < length; i++) {
		var slot = droppable_slots[i];
		switch (slot[0]) {
			case "Player_slot":
				var player_nrs = slot[1];
				var slot_nrs = slot[2];
				for (var k = 0; k < player_nrs.length; k++) {
					for (var j = 0; j < slot_nrs.length; j++) {
						(function () {
							var slot_nr = slot_nrs[j];
							var player_nr = player_nrs[k];
							$("#player{0}_slot{1}".format(player_nr, slot_nr)).droppable({
								hoverClass: 'droppable-hover',
								drop: function (event, ui) {
									var card_nr = ui.draggable[0].card_nr;
									var command = {
										command_type: [
											"Card_dropped",
											card_nr,
											// Dest location
											{
												slot_type: "A_player_slot",
												slot_nr: slot_nr,
												player_nr: player_nr,
												index: -1 	// No index for destination
											}
										],
										username: getCookie("username")
									}
									ws.send(JSON.stringify(command));
								}
							});
						})()
					}
				}

				break;
			case "Table_slot":
				var slot_nrs = slot[1];
				for (var j = 0; j < slot_nrs.length; j++) {
					(function () { 
						var slot_nr = slot_nrs[j];
						$("#table_slot{0}".format(slot_nrs[j])).droppable({
							hoverClass: 'droppable-hover',
							drop: function (event, ui) {
								log(ui.draggable[0].index);
								var card_nr = ui.draggable[0].card_nr;
								var command = {
									command_type: [
										'Card_dropped', 
										card_nr,
										// Dest location
										{slot_type: "A_table_slot", 
										 slot_nr: slot_nr, 
										 player_nr: -1, 
										 index: -1 	// No index for destination
										}
									],
									username: getCookie("username")
								};
								ws.send(JSON.stringify(command));
							}
						});
					})();
				}
				break;
			case "Player_hand":
				var player_nrs = slot[1];
				for (var j = 0; j < player_nrs.length; j++) {
					(function () {
						var player_nr = player_nrs[j];
						$("#player{0}_hand1 .hand_icon img".format(player_nr)).droppable({
							hoverClass: 'droppable-hover',
							drop: function (event, ui) {
								var card_nr = ui.draggable[0].card_nr;
								chat(card_nr);
								var command = {
									command_type: [
									"Card_dropped",
									card_nr,
									// Dest
									{
										slot_type: "A_player_hand",
										slot_nr: -1,
										player_nr: player_nr,
										index: -1
									}
									],
									username: getCookie("username")
								};
								ws.send(JSON.stringify(command));
							}
						});
					})();
				}
				break;
			default:
				chat("Error: Unknown slot type: " + slot[0]);
		}
	}
}

/** 
 * 	Run to update what happens when you click on a mark_slot slot (yellow border)
 */
function update_marking() {
	$('.mark_slot').off("click.mark");
	$('.mark_slot').on("click.mark", function(el) {
		mark(el);
	});
}

function mark(el) {

	var target = el.target;
	if (target.children != undefined && target.children.length > 0) {
		// problem?
	}

	// Only mark during your turn
	if (my_player_nr != player_turn_nr) {
		log("only mark during your turn");
		return;
	}

	if (marked_slots.indexOf(target) > -1) {
		// Already marked? Unmark.
		var index = marked_slots.indexOf(target);
		marked_slots.splice(index, 1);
		target.style.border = "";
		target.style.borderRadius = "";
		target.style.padding = "0px";
		$(".mark_background", target.parentNode).fadeOut(125, function () { 
			$(this).remove(); 
			//target.style.padding = "0px";
		});
		var command = {
			command_type: [
				'Action', 
				['Unmark', target.slot]
			],
			username: getCookie("username")
		};
		ws.send(JSON.stringify(command));
	}
	else {
		if (target.slot == undefined || target.slot == null) {
			chat("Internal error: target.slot == null or undefined");
			return;
		}
		// Loop through markable slots and check if target.slot is in them
		var slot_is_markable = false;
		var length = enable_marking.length;
		for (var i = 0; i < length; i++) {
			var s = enable_marking[i];
			switch (target.slot[0]) {
				case "Marking_player_slot":
					var player_nr = target.slot[1];
					var slot_nr = target.slot[2];
					if (s[0] == "Player_slot") {
						// s[1] = player_nrs, s[2] = slot_nrs
						if (s[1].indexOf(player_nr) > -1 && s[2].indexOf(slot_nr) > -1) {
							slot_is_markable = true;
						}
					}
					break;
				case "Marking_table_slot":
					var slot_nr = target.slot[1];
					if (s[0] == "Table_slot") {
						if (s[1].indexOf(slot_nr) > -1) {
							slot_is_markable = true;
						}
					}
					break;
				case "Marking_opponent_hand":
					var player_nr = target.slot[1];
					if (s[0] == "Player_hand") {
						if (s[1].indexOf(player_nr) > -1) {
							slot_is_markable = true;
						}
					}
					break;
				case "Marking_hand_slot":	// My hand
					var hand_slot_nr = target.slot[1];
					if (s[0] == "Player_hand") {
						if (s[1].indexOf(my_player_nr) > -1) {		// All my hand slots enabled?
							slot_is_markable = true;
						}
					}
					break;
				default:
					chat("Internal error: Unknown target slot: " + target.slot[0]);
					return;
					break;
			}
		}
		if (!slot_is_markable) {
			// Did not find markable slot in enable_marking, abort
			return;
		}

		marked_slots.push(target);
		target.style.border = "3px solid yellow";
		target.style.borderRadius = "11px";
		target.style.zIndex = "50";
		// TODO Show special mark img or not?
		var img = document.createElement('img');
		img.src = '/img/mark_background.jpg';
		img.style.position = 'absolute';
		img.style.top = "-10px";
		img.style.left = "-10px";
		img.style.zIndex = '-1';
		img.className = "mark_background";
		target.parentNode.style.position = 'relative';
		target.parentNode.style.zIndex = "10";
		//$(img).hide().appendTo(target.parentNode).fadeIn(100);
		//target.parentNode.appendChild(img);
		target.style.padding = "2px";
		//target.slot.forEach( function (el) {
			//chat(el + ' ');
		//});
		//log("target.slot = ");
		//log(target.slot);
		var command = {
			command_type: [
				'Action', 
				['Mark', target.slot]
			],
			username: getCookie("username")
		};
		ws.send(JSON.stringify(command));
	}
}

/**
 * 	Turn off mark click handler and removes mark class
 * 	Also unmarks border
 */
function unmark_onclick(el) {
	$(el).off("click.mark");
	$(el).removeClass("mark_slot");

	if (marked_slots.indexOf(el) > -1) {
		var index = marked_slots.indexOf(el);
		marked_slots.splice(index, 1);
		el.style.border = "";
	}

}

/**
 * 	Removes all borders/marks
 * 	Used when turn ends
 */
function unmark_all() {
	//chat("unmark_all");
	$('.mark_slot').css("border", "0px");
	$('.mark_slot').off("click.mark");
	$(".mark_background").fadeOut(125, function () { 
		$(this).remove(); 
	});
	marked_slots = [];
}

/**
 * 	Clean my hand and updates it with new cards picked up (or attained otherwise)
 *	Also updates menu.
 * 	Not run for opponents hands.
 *
 * 	@param hand			json hand from server
 */
function update_hand(hand) {
	hand_ = hand;	// Update global hand
	var hand_div = document.getElementById('player' + my_player_nr + '_hand1');
	//hand_div.style.clear = "both";
	hand_div.style.position = "relative";
	hand_div.innerHTML = '';
	var length = hand.length;
	//if (length > 0) {

	var img_div = document.createElement('div');
	var img = document.createElement('img');
	img.src = '/img/hand.jpg';
	img_div.style.cssFloat = "left";
	img.style.position = "absolute";
	img.style.top = "26px";
	//img.width = "50px";
	img_div.appendChild(img);
	img_div.className = "hand_icon";
	img_div.width = "50px";
	hand_div.appendChild(img_div);

	//}
	// TODO: Number of rows (max 5 cells in each row)
	var rows = length % 5;
	var _table = document.createElement('table');
	_table.style.cssFloat = "left";
	hand_div.appendChild(_table);

	// Add dummy row to fix height (for hand icon to show correct)
	if (length == 0) {
		log("update_hand, length 0");
		//_table.style.height = "100px";
		var row = document.createElement('tr');
		_table.appendChild(row);
		var td = document.createElement('td');
		td.innerHTML = "<div style='padding: 4px;'><img src='/img/card_back.png' /></div>";
		td.style.visibility = "hidden";
		row.appendChild(td);
	}

	for (var i = 0; i < length; i++) {

		if (i % 5 == 0) {
			var row = document.createElement('tr');
			_table.appendChild(row);
		}
		var td = document.createElement('td');
		var card = hand[i];
		var i__ = i + 1;	// Start from 1, not 0
		var img_div = document.createElement('div');	// Div to surround img, needed by menu
		img_div.style.position = 'relative';
		img_div.style.display = 'table-cell';
		img_div.style.padding = "4px";
		// No menu, make a new
		var menu_ul = document.createElement('ul');
		menu_ul.className = 'menu';
		menu_ul.id = "hand1_slot" + i__ + "_menu";
		//deck_div.appendChild(menu_ul);
		var img = document.createElement('img');
		img.src = '/drakskatten/upload/' + card.dir + '/' + card.img;
		img.id = "card{0}".format(card.card_nr);
		img.card_nr = card.card_nr;
		img.className = "mark_slot";
		img.slot = ["Marking_hand_slot", i + 1];
		img_div.appendChild(img);
		img_div.card_id = card.card_id;
		var p = document.createElement('p');
		img_div.appendChild(p);
		img_div.id = 'hand1_slot' + i__;
		img_div.appendChild(menu_ul);
		//hand_div.appendChild(img_div);
		td.appendChild(img_div);
		row.appendChild(td);
		// Add menus
		hand_menu_callbacks.forEach(function (fn) {
			fn(menu_ul, i__, card.card_nr);
		})
	}

	update_marking();
	update_draggable();

}

/**
	Clean table slots and updates them
*/
function update_table(table_slots) {
}

// BEGIN
function websocket_onmessage (msg) {
	var command = JSON.parse(msg.data);
	var command_type = command.command_type;
	log(command);
	log(command_type);

	/**	Make a card img tag, face up/down with position/rotation
		Return img tag */
	var make_card_img = function (card) {
		if (card == undefined) {
			console.trace();
			throw "No card defined";
		}

		var img = document.createElement('img');
		img.style.position = "absolute";
		if (card[0] == "Card_facing_down") {
			img.src = '/img/card_back.png';
			var position = card[1];
			img.style.top = position.top + "px";
			img.style.left = position.left + "px"
			img.style.transform = img.style['-ms-transform'] = img.style['-webkit-transform'] = "rotate(" + position.rotate + "deg)";
		}
		else {	// Card facing up
			var card_id = card[1];
			var card_nr = card[2];
			var dir = card[3];
			var img_ = card[4];
			var position = card[5]
			img.src = '/drakskatten/upload/' + dir + '/' + img_;
			img.style.top = position.top + "px";
			img.style.left = position.left + "px"
			img.style.transform = img.style['-ms-transform'] = img.style['-webkit-transform'] = "rotate(" + position.rotate + "deg)";
			img.id = "card{0}".format(card_nr);
			img.card_nr = card_nr;

			// Check if card is clickable
			for (var i = 0; i < onclick_cards.length; i++) {
				var card2 = onclick_cards[i];
				if (card2.card_nr == card_nr) {
					log("clickable, card nr = " + card_nr);
					img.onclick = (function () {

						var card_nr2 = card_nr;
						var img2 = img;

						return function () {
							if ($(img2).hasClass("noclick")) { // Don't clash with draggable
								$(img2).removeClass("noclick");
							}
							else {
								var command = {
									command_type: ["Card_onclick", card_nr2],
									username: getCookie("username")
								};
								ws.send(JSON.stringify(command));
							}
						}
					})();
				}
			}

			//div.card_nr = card_nr;
			//div.card_id = card_id;
		}
		return img
	}

	/** Creates a div with card, img faced down, appended to @slot, id = @slot_name + @i
			Return menu ul created, to be used by menu callbacks */
	var create_card_faced_down = function (i, slot, slot_name, card) {
		var div = document.createElement('div');	// Div to surround img, needed by menu
		div.style.position = 'relative';
		// No menu, make a new
		var menu_ul = document.createElement('ul');
		menu_ul.className = 'menu';
		menu_ul.style.zIndex = 100;
		menu_ul.id = slot_name + i + "_menu";
		var img = make_card_img(card);
		img.index = -1;
		div.appendChild(img);
		div.appendChild(menu_ul);
		slot.appendChild(div);

		return {"menu_ul": menu_ul, "img": img};
	};

	/** Creates a div with card and menu from @card, img faced up, append to @slot, id = @slot_name + @i 
			Return menu ul created, to be used by menu callbacks */
	var create_card_faced_up = function (card, i, slot, slot_name) {
		var card_id = card[1];
		var card_nr = card[2];
		var dir = card[3];
		var img_ = card[4]

		var div = document.createElement('div');	// Div to surround img, needed by menu
		div.style.position = 'relative';
		// No menu, make a new
		var menu_ul = document.createElement('ul');
		menu_ul.className = 'menu';
		menu_ul.style.zIndex = 100;
		menu_ul.id = slot_name + i + "_menu";
		var img = make_card_img(card)
		img.index = -1;
		div.appendChild(img);
		div.card_id = card_id;
		div.card_nr = card_nr;
		//div.id = 'table_slot' + (i + 1);
		div.appendChild(menu_ul);
		slot.appendChild(div);

		return {"menu_ul": menu_ul, "img": img};
	}

	/** Makes a new menu ul. Append menu li:s to this */
	var make_menu_ul = function (id) {
		var menu_ul = document.createElement('ul');
		menu_ul.id = id;
		menu_ul.className = 'menu';
		menu_ul.style.zIndex = 100;
		return menu_ul;
	}

	switch (typeof command_type == "string" ? command_type : command_type[0]) {
		case "Chat":
			chat(command_type[1], command.username);
			break;
		case "Close":
			//alert("Timeout, server closing");
			chat("Timout, server closing", "Client");
			movables_enabled = false;
			break;
		case "Error":
			//alert("Error: " + command_type[1]);
			chat("Error: " + command_type[1]);
			break;
		case "Users_online":
			var span = $('#users_online');
			span.html("");
			var html = "";
			var my_username = getCookie("username");
			for (var username in command_type[1]) {
				//span.append(username + ", ");
				html = html + username + ", ";
				if (username = my_username) {
					my_player_nr = command_type[1][username];
				}
			}
			// Strip last ,
			html = html.substring(0, html.length - 2);
			span.html(html);
			/*
			command_type[1].forEach(function (el, index) {
				textarea.append(el + "\n");
				if (el = my_username) {
					my_player_nr = index + 1
				}
			});
			*/
			if (my_player_nr == 0 || my_player_nr == undefined) {
				// Serious error, did not found my username among list
				chat("Error: Users_online: Did not find your username among users online. Closing websocket.", "Client");
				ws.close();
			}
			break;
		case "Start":
			//alert("Starting game");

			$('#game_area').show();
			chat("Starting game", "System");
			var start = document.getElementById('start');
			if (start) {	// Only found for session creator
				start.value = "Play again";
				start.disabled = true;
				start.onclick = play_again;
			}
			break;
		case "End_game":
			var start = document.getElementById('start');
			if (start) {	// Only found for session creator
				start.disabled = false;
			}
			var arrow = document.getElementById('arrow');	// Arrow for players turn
			if (arrow) {
				arrow.innerHTML = '';
			}
			player_turn_nr = 9999;
			keydown_callbacks = [];
			onclick_cards = [];
			draggable_player_nrs = [];
			draggable_cards = [];
			droppable_slots = [];
			movables_enabled = false;
			old_table_width = -old_table_width;	// Force rebuild html next game
			show_menus();
			break;
		// Debug info received after sending Dump_decks
		case "Deck_dump":
			//console.log("Deck dump:");
			//console.log(command_type[1]);
			debug_chat("Deck dump:\n");
			debug_chat(command_type[1]);
			break;
		case "Player_dump":
			debug_chat("Player dump:\n");
			debug_chat(command_type[1]);
			break;
		case "Table_dump":
			debug_chat("Table dump:\n");
			debug_chat(command_type[1]);
			break;
		case "Log":
			debug_chat(command_type[1]);
			break;
		case "Players_turn":

			unmark_all();

			// Delete arrow from former players legend
			if (_legend) {
				_legend.innerHTML = _old_html;
			}
			
			player_turn_nr = command_type[1];

			// Add arrow to legend
			var area = document.getElementById('player' + player_turn_nr + '_area');
			var legends = area.getElementsByTagName('legend');
			_legend = legend = legends[0];
			_old_html = legend.innerHTML;
			//html = '<span style="color: green;">&#x25B6;</span> ' + legend.innerHTML;
			html = '<span id=arrow>&#x25B6;</span> ' + legend.innerHTML;
			legend.innerHTML = html;
			var arrow = document.getElementById('arrow');

			// Flash arrow if it's my turn
			if (player_turn_nr == my_player_nr) {
				setTimeout(function() { arrow.style.color = 'white' }, 200);
				setTimeout(function() { arrow.style.color = 'inherit' }, 400);
				setTimeout(function() { arrow.style.color = 'white' }, 600);
				setTimeout(function() { arrow.style.color = 'inherit' }, 800);
				setTimeout(function() { arrow.style.color = 'white' }, 1000);
				setTimeout(function() { arrow.style.color = 'inherit' }, 1200);
			}

			show_menus();

			if (player_turn_nr == my_player_nr) {
				update_marking();
				update_draggable();
			}

			break;
		// Build up slots and hands
		case "Build_html":
			// Must have player id here
			if (my_player_nr == undefined || my_player_nr == 0) {
				chat("Error: Build_html: Did not find your player id. Closing websocket.", "Client");
				ws.close();
			}

			// Reset everything
			$('#others').html("");
			$('#table').html("");
			$('#me').html("");
			player_turn_nr = 0;
			table_decks = [];
			hand_ = {};
			hand_menu_callbacks = [];
			table_menu_callbacks = []
			player_slot_callbacks = []

			var players_online = command_type[1];
			var hands = command_type[2];
			var player_slots = command_type[3];
			var table_slots = command_type[4];
			var gadgets = command_type[5];
			game.table_slots = table_slots;		// Store for later use?
			var game_area = document.getElementById('game_area');
			var table = document.getElementById('table');
			var table_fs = document.createElement('fieldset');
			var table_l = document.createElement('legend');
			table_l.innerHTML = 'Table';
			table_l.id = "table_l";
			table_fs.appendChild(table_l);
			table_fs.id = "table_fs";
			table.appendChild(table_fs);
			table = table_fs;
			var me_div = document.getElementById('me');		// My game area
			var others = document.getElementById('others');		// Other players area

			me_div.style.cssFloat = 'left';
			me_div.style.clear = 'both';

			table.style.cssFloat = 'left';
			table.style.clear = 'both';

			

			// Add player divs with hands and slots
			var built = 0;	// Nr of player areas built
			var length = command_type[1].length;
			for (i = my_player_nr - 1; // Start with me
					 built < length;) {
				username = command_type[1][i];
				var id = player_nr = i + 1
				built++
				i++;
				if (i >= length) { i = 0 } // Wrap around

				log("build html player " + id);
				var player_area = document.createElement('fieldset');
				//player_area.style.width = '100%';
				//player_area.style.height = '100%';
				player_area.style.cssFloat = 'left';
				player_area.style.position = 'relative';
				//player_area.style.width = '100%';
				var legend = document.createElement('legend');
				if (id == my_player_nr) {
					legend.innerHTML = username + " (you, {0})".format(my_player_nr);
				}
				else {
					legend.innerHTML = username + " ({0})".format(id);
				}
				player_area.appendChild(legend);
				player_area.id = 'player' + id + '_area';
				player_area.className = 'player_area';

				// Build player slots
				var player_table = document.createElement('div');
				player_table.id = 'player' + id + '_table';
				player_table.style.position = 'relative';
				player_table.style.clear = "left";
				var img_div = document.createElement('div');
				img_div.id = 'player' + id + '_table_icon_div';
				img_div.style.position = 'relative';
				player_table.appendChild(img_div);
				// Put player slots in a <table>
				var table_ = document.createElement('table');
				player_table.appendChild(table_);
				for (j = 0; j < player_slots; j++) {

					// Create new row each 5th slot
					if (j % 5 == 0) {
						var row = document.createElement('tr');
						table_.appendChild(row);
					}

					var td = document.createElement('td');
					var slot = document.createElement('div');
					td.appendChild(slot);
					slot.id = 'player' + id + '_slot' + (j + 1);
					slot.className = 'player_slot mark_slot';

					// Marking stuff
					slot.slot = ["Marking_player_slot", player_nr, j + 1];

					//player_table.appendChild(slot);
					row.appendChild(td);
					/* 
					(function f(slot) { 
						var toggle = 0
						slot.onclick = function (e) {
							var imgs = slot.getElementsByTagName('img');
							if (toggle) {
								imgs[imgs.length - 1].style.border = "solid 2px #ff8";	// Last img in case of overlay/stack
							}
							else {
								imgs[0].style.border = "";
							}
							toggle = 1 - toggle;
						}
					})(slot);
					*/
				}
				
				for (j = 0; j < hands; j++) {
					var hand = document.createElement('div');
					hand.id = 'player' + id + '_hand' + (j + 1);
					// Add mark class if hand is not mine
					if (id != my_player_nr) {
						hand.className = 'hand mark_slot';
					}
					else {
						hand.className = 'hand';
					}
				}

				update_marking();
				update_draggable();

				// Seperate my player area from others
				if (id == my_player_nr) {
					player_area.appendChild(player_table);
					player_area.appendChild(hand);

					// Add gadgets div to my area
					if (gadgets > 0) {
						var gadgets = document.createElement('div');
						gadgets.id = 'player' + id + '_gadgets';
						gadgets.className = "gadgets";
						//gadgets.style.position = 'relative';
						var img_div = document.createElement('div');
						var img = document.createElement('img');
						img.src = '/img/keyboard.png';
						img_div.style.cssFloat = "left";
						img.style.marginLeft = "8px";
						//img.style.display = 'none';
						img.style.visibility = "hidden";
						img_div.appendChild(img);
						img_div.className = "table_icon";
						img_div.style.width = "56px";
						img_div.style.height = "50px";
						img_div.style.position = 'relative';
						//gadgets.appendChild(img_div);

						var gadget_slot = document.createElement('div');
						gadget_slot.className = 'gadget_slot';
						gadget_slot.id = "gadget_slot";	// TODO: Only one slot?
						gadgets.appendChild(gadget_slot);

						player_area.appendChild(gadgets);
					}

					me_div.appendChild(player_area);
				}
				else {
					player_area.appendChild(hand);
					player_area.appendChild(player_table);
					others.appendChild(player_area);
				}
			}

			// Add table slots to table div
			for (i = 0; i < table_slots; i++) {
				var slot = document.createElement('div');
				slot.id = 'table_slot' + (i + 1);
				slot.className = 'table_slot mark_slot';
				slot.style.cssFloat = 'left';
				//slot.style.border = 'solid #999 1px';

				// Marking stuff
				slot.slot = ["Marking_table_slot", i + 1];

				table.appendChild(slot);
			}

			update_marking();
			update_draggable();

			break;
		case "Place_deck":
			// use update_table instead
			/*
			log(command_type);
			debug_chat("Place deck: " + command_type[1] + ", " + command_type[2]);
			var deck_id = command_type[1];	// Id from DB, not nr!
			var table_slot_id = command_type[2];
			var table_slot = document.getElementById('table_slot' + table_slot_id);
			var deck_div = document.getElementById('deck_' + deck_id);

			// Check if this deck already is placed somewhere. If so, move it.
			if (deck_div != undefined) {
				table_slot.appendChild(deck_div);
			}
			// No deck div, create a new and place it.
			else {
				var div = document.createElement('div');
				div.id = 'deck_' + deck_id;
				div.style.position = 'relative'; 			// Need this for absolute positioned menu
				div.style.width = '100px';
				var img = document.createElement('img');
				img.src = '/img/deck_back.jpg'
				div.appendChild(img);
				table_slot.appendChild(div);

				decks.push({deck_id : deck_id});

				// jQuery UI menu
				//var menu = document.createElement('ul');
				//div.innerHTML += "<ul id=deck_" + deck_id + "_menu class=menu><li><a href='#'>Test 1</a></li><li><a href='#'>Bla</a></li></ul>";
				//$('#deck_' + deck_id + '_menu').menu();
			}
			
			break;
			*/

		/**
		*/
		case "Place_card_on_table_up":
			break;

		/**
			Get no card info, only table slot
		*/
		case "Place_card_on_table_down":
			break;

		/**
		 * 	Player with hand, etc
		 */
		case "Update_hand":
			// Remove all anim stuff
			$(".anim_img").remove();

			var hand = command_type[1];
			update_hand(hand);

			break;

		case "Show_hand_icon":

			// Show all hand icons
			var i = 1;
			do {
				var hand_div = document.getElementById('player' + i + '_hand1');
				//if (hand_div) {
					//log("show hand icon for player " + i);
					//log(hand_div.innerHTML);
				//}
				if (hand_div && hand_div.innerHTML == "") {
					hand_div.style.position = "relative";
					var img_div = document.createElement('div');
					var img = document.createElement('img');
					img.src = '/img/hand.jpg';
					img_div.style.cssFloat = "left";
					img.style.position = "absolute";
					img.style.top = "26px";
					//img.width = "50px";
					img_div.appendChild(img);
					img_div.className = "hand_icon";
					img_div.width = "50px";
					hand_div.appendChild(img_div);
					var _table = document.createElement('table');
					_table.style.height = "100px";
					_table.style.cssFloat = "left";
					var row = document.createElement('tr');
					_table.appendChild(row);
					var td = document.createElement('td');
					td.innerHTML = "&nbsp";
					row.appendChild(td);
					hand_div.appendChild(_table);
				}
				i++;
			} while(hand_div != undefined)

			update_draggable();

			break;

		/**
		 * 	Update card backs of other players hands
		 */
		case "Update_all_hands":
			// Remove all anim stuff
			$(".anim_img").remove();

			var hand_list = command_type[1];
			for (var n in hand_list) {
				var player_nr = hand_list[n][0];
				var cards = hand_list[n][1];
				var img = null;

				// Not my hand
				if (player_nr != my_player_nr) {
					var div = document.getElementById('player' + player_nr + '_hand1');
					div.style.clear = "both";
					div.style.position = 'relative';
					div.display = 'table-row';
					div.innerHTML = '';
					if (cards > 0) {
						var img_div = document.createElement('div');
						var img = document.createElement('img');
						img.src = '/img/hand.jpg';
						img_div.style.cssFloat = "left";
						img.style.position = "absolute";
						img.style.top = "26px";
						//img.width = "50px";
						img_div.appendChild(img);
						img_div.className = "hand_icon";
						img_div.width = "50px";
						div.appendChild(img_div);
					}
					j = -cards;
					factor =  cards < 10 ? (25 / cards) : (50 / cards);	// Smaller factor if you have less than 10 cards
					if (cards == 1) {		// Special case
						img = document.createElement('img');
						var img_div = document.createElement('div');
						img.src = '/img/card_back.png';
						img_div.style.width = "5px";
						img_div.style.height = '100px';
						img_div.appendChild(img);
						div.appendChild(img_div);
					}
					else {
						for (i = 0; i < cards; i++) {
							img = document.createElement('img');
							var img_div = document.createElement('div');
							img.src = '/img/card_back.png';
							img.style.transform = img.style['-ms-transform'] = img.style['-webkit-transform'] = "rotate(" + (j * factor) + "deg)";
							img_div.style.width = "5px";
							img_div.style.height = '100px';
							//img_div.style.left = (j * 5) + "px";
							img_div.appendChild(img);
							div.appendChild(img_div);
							j = j + 2
						}
					}
				}
				if (img != null) {
					unmark_onclick(div);
					$(img).addClass("mark_slot");
					//slots[img] = ["Table_slot", i + 1];
					img.slot = ["Marking_opponent_hand", player_nr];
					update_marking();
					update_draggable();
				}
			}
			break;

		/**
			Update table with deck and cards, and add their menus
		*/
		case "Update_table":
			// Remove all anim stuff
			$(".anim_img").remove();
			unmark_all();

			var elems = command_type[1];	// Can be Deck, Card_facing_up, Card_facing_down, Stack, Overlay
			var table_style = command_type[2];	// table style with width, height, rows, cols and table_legend
			var length = elems.length;

			if (using_canvas) {
				// Using <canvas> for graphics

				var canvas = document.getElementById("table_canvas");
				var ctx = canvas.getContext("2d");

				if (table_style.width > 0 &&
						table_style.height > 0 &&
						table_style.rows > 0 &&
						table_style.cols > 0 &&
						table_style.table_legend != "") {

					// Check if style has changed since last update
					if (old_table_width != table_style.width ||
							old_table_height != table_style.height ||
							old_table_rows != table_style.rows ||
							old_table_cols != table_style.cols ||
							old_table_legend 	!= table_style.table_legend) {

						// Update values
						old_table_width 	= table_style.width;
						old_table_height 	= table_style.height;
						old_table_rows 		= table_style.rows;
						old_table_cols 		= table_style.cols;
						old_table_legend 	= table_style.table_legend;

						canvas.width = table_style.width * table_style.cols;
						canvas.height = table_style.height * table_style.rows;

						var table_l = document.createElement("legend");
						var table_fs = document.getElementById('table_fs');
						table_l.innerHTML = table_style.table_legend;
						table_fs.appendChild(table_l);
					}

					// Clear canvas
					ctx.clearRect(0, 0, table_style.width * table_style.cols, table_style.height * table_style.rows);

					// Paint cards etc

					// Loop through table slots sent from server
					for (var i = 0; i < length; i++) {
						var slot_nr = i + 1;
						var elem = elems[i];
						
						// Elem can be array of string (Card_facing_down)
						if (typeof elem == "string") {
							var type = elem;
						}
						else {
							// Assuming array
							var type = elem[0];
						}

						var x = ((slot_nr - 1) % table_style.rows) * table_style.width;
						var y = (Math.floor((slot_nr - 1) / table_style.cols)) * table_style.height;

						switch (type) {
							case "Card_facing_down":
								break;
							case "Card_facing_up":
								var card_id = elem[1];
								var card_nr = elem[2];
								var dir = elem[3];
								var img_ = elem[4]
								var img_id = "preload_{0}_{1}".format(dir, img_);

								ctx.drawImage(document.getElementById(img_id), x, y);

							break;
							case "Stack":
								var stack = elem[1];
								var length2 = stack.length;

								var img = null;
								for (var j = 0; j < length2; j++) {
									var card = stack[j];
									var dir = card[3];
									var img_ = card[4];
									var img_id = "preload_{0}_{1}".format(dir, img_);
									ctx.drawImage(document.getElementById(img_id), x, y);
								}

								break;
							case "Overlay":
								break;
							default:
								chat("Internal error: Slot type not supported for canvas: " + type);
								break;
						}
					}

				}
				else {
					chat("Error: table_slots[].widht|height|cols|rows required to work with canvas");
					return;
				}

			}
			else {

				// No canvas, using HTML tags as usual

				var table = document.getElementById('table');
				var table_fs = document.getElementById('table_fs');
				var table_l = document.getElementById('table_l');
				if (!table_l) {
					table_l = document.createElement("legend");
				}

				// Check if table style is defined
				if (table_style.width > 0 &&
						table_style.height > 0 &&
						table_style.rows > 0 &&
						table_style.cols > 0 &&
						table_style.table_legend != "") {

					// Check if style has changed since last update
					if (old_table_width != table_style.width ||
							old_table_height != table_style.height ||
							old_table_rows != table_style.rows ||
							old_table_cols != table_style.cols) {

						// Update values
						old_table_width 	= table_style.width;
						old_table_height 	= table_style.height;
						old_table_rows 		= table_style.rows;
						old_table_cols 		= table_style.cols;
						old_table_legend 	= table_style.table_legend;

						// Rebuild table
						var html = "<table>";
						for (i = 0; i < table_style.rows; i++) {
							html += "<tr>";
							for (j = 0; j < table_style.cols; j++) {
								var slot_nr = (j + 1) + ((table_style.cols) * i);
								html += "<td><div id='table_slot{0}' style='width: {1}px; height: {2}px;'></div></td>".format(
									slot_nr,
									table_style.width,
									table_style.height
								);
							}
							html += "</tr>";
						}
						table_fs.innerHTML = html;

						$(table_l).text(table_style.table_legend).html();
						table_fs.appendChild(table_l);
					}

				}

				// First clear all table slots
				for (var i = 1; i <= game.table_slots; i++) {
					var table_slot = document.getElementById('table_slot' + i);
					if (table_slot != undefined) {
						table_slot.innerHTML = '';
					}
				}

				// Loop through table slots sent from server
				for (var i = 0; i < length; i++) {
					var slot_nr = i + 1;
					var elem = elems[i];
					if (typeof elem == "string") {
						var type = elem;
					}
					else {
						// Assuming array
						var type = elem[0];
					}
					var table_slot = document.getElementById('table_slot' + (i + 1));
					if (table_slot == undefined) {
						chat("Error: No more table slots left (" + i + ")");
						return;
						//table_slot = document.createElement('div');
						//table_slot.id = 'table_slot' + (i + 1);
						//table.appendChild(table_slot);
					}
					table_slot.innerHTML = '';	// Clear table slot
					table_slot.style.position = 'relative';

					// Check if we have a menu
					var ul = document.getElementById('table_slot' + slot_nr + '_menu');
					if (ul == undefined) {
						// No menu, make a new
						var menu = document.createElement('ul');
						menu.className = 'menu';
						menu.id = "table_slot" + slot_nr + "_menu";
						menu.style.zIndex = 100;
						table_slot.appendChild(menu);
						ul = menu;
					}
					// Add menus
					table_menu_callbacks.forEach(function (fn) {
						fn(ul, -1, slot_nr);
					});

					switch (type) {
						case "Deck":
							var deck_id = elem[1];
							var deck_nr = elem[2];
							var div = document.createElement('div');
							div.id = 'deck_' + deck_nr;
							div.style.position = 'relative'; 			// Need this for absolute positioned menu
							div.style.width = '100px';
							var img = document.createElement('img');
							img.src = '/img/deck_back.jpg'
							div.appendChild(img);
							table_slot.appendChild(div);

							// Check if we have a menu
							var ul = document.getElementById('deck_' + deck_nr + '_menu');
							if (ul == undefined) {
								// No menu, make a new
								var menu = document.createElement('ul');
								menu.className = 'menu';
								menu.id = "deck_" + deck_nr + "_menu";
								menu.style.zIndex = 100;
								div.appendChild(menu);
								ul = menu;
							}

							table_decks.push({"deck_id": deck_id, "deck_nr": deck_nr});

							// Add menus
							table_menu_callbacks.forEach(function (fn) {
								fn(ul, deck_nr, slot_nr);
							});

							unmark_onclick(table_slot);
							$(img).addClass("mark_slot");
							//slots[img] = ["Table_slot", i + 1];
							img.slot = ["Marking_table_slot", i + 1];
							update_marking();
							update_draggable();

							break;

						case "Card_facing_up":
							var card = elem;
							var ret = create_card_faced_up(card, i + 1, table_slot, "table_slot");

							// Update marking
							unmark_onclick(table_slot);
							$(ret.img).addClass("mark_slot");
							ret.img.slot = ["Marking_table_slot", i + 1];
							update_marking();
							update_draggable();

							break;
						case "Card_facing_down":

							var card = elem;
							var ret = create_card_faced_down(i + 1, table_slot, "table_slot", elem);

							unmark_onclick(table_slot);
							$(ret.img).addClass("mark_slot");
							//slots[ret.img] = ["Table_slot", i + 1];
							ret.img.slot = ["Marking_table_slot", i + 1];
							update_marking();
							update_draggable();

							break;

						case "Stack":
							var stack = elem[1];
							var length2 = stack.length;
							var div = document.createElement('div');	// Div to surround img, needed by menu
							div.style.position = 'relative';

							if (length2 > 0) {
								// For now, just pick the top card in the stack
								//var card = stack[length2 - 1];

								//if (card == "Card_facing_down") {
									//var menu_ul = create_card_faced_down(i + 1, table_slot, "table_slot");
								//}
								//else {
									//var menu_ul = create_card_faced_up(card, i + 1, table_slot, "table_slot");
								//}
								div.appendChild(make_menu_ul("table_slot" + (i + 1) + "_menu"));
							}

							var img = null;
							for (var j = 0; j < length2; j++) {
								var card = stack[j];
								img = make_card_img(card);
								img.index = j + 1;
								div.appendChild(img)
							}
							table_slot.appendChild(div);

							if (img == null) {
								// Problem?
							}
							else {
								unmark_onclick(table_slot);
								$(img).addClass("mark_slot");
								//slots[img] = ["Table_slot", i + 1];
								img.slot = ["Marking_table_slot", i + 1];
								update_marking();
								update_draggable();
							}

							break;
						case "Overlay":
							var overlay = elem[1];
							var length2 = overlay.length;
							var div = document.createElement('div');	// Div to surround img, needed by menu
							div.style.position = 'relative';
							for (var j = 0; j < length2; j++) {
								var card = overlay[j];
								var img = make_card_img(card);
								img.index = j + 1;
								//var img = document.createElement('img');
								/*
								if (card[0] == "Card_facing_down") {
									img.src = '/img/card_back.png';
								}
								else {	// Card facing up
									var card_id = card[1];
									var card_nr = card[2];
									var dir = card[3];
									var img_ = card[4];
									img.src = '/drakskatten/upload/' + dir + '/' + img_;
									div.card_nr = card_nr;
									div.card_id = card_id;
								}
								*/
								img.style.top = (j * 28) + "px";
								var menu_ul = document.createElement('ul');
								menu_ul.className = 'menu';
								menu_ul.style.zIndex = 100;
								menu_ul.id = "table_slot" + (j + 1) + "_menu";	// TODO: one menu for each img???
								div.appendChild(img);
								div.appendChild(menu_ul);
								table_slot.appendChild(div);
							}

							// Fix marking
							unmark_onclick(table_slot);
							$(img).addClass("mark_slot");		// Last img will be markable
							//slots[img] = ["Table_slot", i + 1];
							img.slot = ["Marking_table_slot", i + 1];
							update_marking();
							update_draggable();

							break;
						case "Dice":
							var value = elem[1];
							var dice_img = "dice{0}c.jpg".format(value);

							var div = document.createElement('div');	// Div to surround img, needed by menu
							var img = document.createElement('img');
							var menu_ul = document.createElement('ul');
							menu_ul.className = 'menu';
							menu_ul.style.zIndex = 100;
							menu_ul.id = "table_slot" + (i + 1) + "_menu";	// TODO: one menu for each img???
							img.src = '/img/' + dice_img;
							//img.style.marginTop = "40px";
							//img.style.marginLeft = "10px";
							div.appendChild(img);
							div.appendChild(menu_ul);
							table_slot.appendChild(div);

							// Fix marking
							unmark_onclick(table_slot);
							img.slot = ["Marking_table_slot", i + 1];
							$(img).addClass("mark_slot");
							update_marking();
							update_draggable();

							break;
						default:
							log("update_table: Unknown table_type: " + type)
							break;
					}

				}
			}

			break;

		/**
			Like Update_table, but instead the slots infront of the player
		*/
		case "Update_player_slots":
			
			// Remove all anim stuff
			$(".anim_img").remove();
			unmark_all();

			var player_nr = command_type[1];
			var elems = command_type[2];		// Can be Deck, Card_facing_up, Card_facing_down, Stack, Overlay
			var length = elems.length;
			var player = "player" + player_nr;
			var player_table = document.getElementById(player + '_table');

			// First clear all slots
			var i = 1;
			var slot = document.getElementById(player + "_slot" + i);
			while (slot != undefined) {
				slot.innerHTML = '';
				$('#' + player + '_slot' + i).addClass("mark_slot");
				i++;
				var slot = document.getElementById(player + "_slot" + i);
			}

			if (length > 0) {
				var img_div = document.getElementById('player' + player_nr + '_table_icon_div');
				var img = document.createElement('img');
				img.src = '/img/table.jpg';
				img_div.style.cssFloat = "left";
				img.style.position = "absolute";
				img.style.top = "50px";
				img.style.marginLeft = "6px";
				img_div.appendChild(img);
				img_div.className = "table_icon";
				img_div.style.width = "56px";
				img_div.style.height = "50px";
				img_div.style.position = 'relative';
			}

			// Loop through player slots sent from server
			for (var i = 0; i < length; i++) {
				var elem = elems[i];
				if (typeof elem == "string") {
					var type = elem;
				}
				else {
					// Assuming array
					var type = elem[0];
				}
				var player_slot = document.getElementById(player + "_slot" + (i + 1));

				if (player_slot == undefined) {
					chat("Error: No more player slots left (" + i + ")");
					return;
				}
				player_slot.innerHTML = '';	// Clear player slot
				player_slot.style.marginLeft = "6px";
				$(player_slot).addClass("mark_slot");

				switch (type) {
					case "Deck":
						var deck_id = elem[1];
						var deck_nr = elem[2];
						var div = document.createElement('div');
						div.id = 'deck_' + deck_nr;
						div.style.position = 'relative'; 			// Need this for absolute positioned menu
						//div.style.width = '100px';
						div.style.padding = "4px";
						var img = document.createElement('img');
						img.src = '/img/deck_back.jpg'
						div.appendChild(img);
						player_slot.appendChild(div);

						// Update mark
						unmark_onclick(player_slot);
						$(img).addClass('mark_slot');
						img.slot = ["Marking_player_slot", player_nr, i + 1];
						update_marking();
						update_draggable();

						// Check if we have a menu
						var ul = document.getElementById('deck_' + deck_nr + '_menu');
						if (ul == undefined) {
							// No menu, make a new
							ul = document.createElement('ul');
							ul.className = 'menu';
							ul.id = "deck_" + deck_nr + "_menu";
							ul.style.zIndex = 100;
							div.appendChild(ul);
						}

						//table_decks.push({"deck_id": deck_id, "deck_nr": deck_nr});

						// Add menus
						player_slot_callbacks.forEach(function (fn) {
							fn(ul, i + 1, player_nr);
						});

						break;

					case "Card_facing_up":
						var ret = create_card_faced_up(elem, i + 1, player_slot, player + "_slot");
						var menu_ul = ret.menu_ul;

						// Update marking
						unmark_onclick(player_slot);
						$(ret.img).addClass("mark_slot");
						ret.img.slot = ["Marking_player_slot", player_nr, i + 1];
						update_marking();
						update_draggable();

						// Add menus
						player_slot_callbacks.forEach(function (fn) {
							fn(menu_ul, i + 1, player_nr);
						});

						break;
					case "Card_facing_down":
					/*
						var div = document.createElement('div');	// Div to surround img, needed by menu
						div.style.position = 'relative';
						// No menu, make a new
						var menu_ul = document.createElement('ul');
						menu_ul.className = 'menu';
						menu_ul.style.zIndex = 100;
						menu_ul.id = player + "_slot" + (i + 1) + "_menu";
						var img = document.createElement('img');
						img.src = '/img/card_back.png';
						div.appendChild(img);
						div.appendChild(menu_ul);
						player_slot.appendChild(div);
					*/

						var ret = create_card_faced_down(i + 1, player_slot, player + "_slot", elem);
						var menu_ul = ret.menu_ul;

						// Update mark
						unmark_onclick(player_slot);
						$(ret.img).addClass("mark_slot");
						ret.img.slot = ["Marking_player_slot", player_nr, i + 1];
						update_marking();
						update_draggable();

						// Add menus
						player_slot_callbacks.forEach(function (fn) {
							fn(menu_ul, i + 1, player_nr);
						});

						break;
					case "Stack":
						var stack = elem[1];
						var length2 = stack.length;
						if (length2 > 0) {
							var div = document.createElement('div');	// Div to surround img, needed by menu
							div.style.position = 'relative';

							// For now, just pick the top card in the stack
							//var card = stack[length2 - 1];

							//if (card == "Card_facing_down") {
								//var menu_ul = create_card_faced_down(i + 1, table_slot, "table_slot");
								// Add menus
								//player_slot_callbacks.forEach(function (fn) {
									//fn(menu_ul, i + 1, player_nr);
								//});
							//}
							//else {
								//var menu_ul = create_card_faced_up(card, i + 1, table_slot, "table_slot");
								// Add menus
								//player_slot_callbacks.forEach(function (fn) {
									//fn(menu_ul, i + 1, player_nr);
								//});
							//}

							var img = null;
							for (var j = 0; j < length2; j++) {
								var card = stack[j];
								img = make_card_img(card);
								img.index = j + 1;
								div.appendChild(img);
							}

							var menu_ul = make_menu_ul(player + "_slot" + (i + 1) + "_menu");
							div.appendChild(menu_ul)

							player_slot.appendChild(div);

							// Add menus
							player_slot_callbacks.forEach(function (fn) {
								fn(menu_ul, i + 1, player_nr);
							});

							if (img == null) {
								// Problem?
							}
							else {
								unmark_onclick(player_slot);
								$(img).addClass('mark_slot');
								img.slot = ["Marking_player_slot", player_nr, i + 1];
								update_marking();
								update_draggable();
							}
						}

						break;
					case "Overlay":
						var overlay = elem[1];
						var length2 = overlay.length;
						if (length2 > 0) {
							var div = document.createElement('div');	// Div to surround img, needed by menu
							div.style.position = 'relative';
							div.style.cssFloat = 'left';
							player_slot.appendChild(div);
							var p = document.createElement('p');	// TODO: Extremely weird. player_slot must contain one element that is not positioned 'absolute' to work properly.
							player_slot.appendChild(p);
								
							// Loop through overlay cards
							for (var j = 0; j < length2; j++) {
								var card = overlay[j];
								var img = make_card_img(card);
								img.index = j + 1;
								/*
								var img = document.createElement('img');
								if (card[0] == "Card_facing_down") {
									img.src = '/img/card_back.png';
								}
								else {
									var card_id = card[1];
									var card_nr = card[2];
									var dir = card[3];
									var img_ = card[4];
									img.src = '/drakskatten/upload/' + dir + '/' + img_;
									div.card_nr = card_nr;
									div.card_id = card_id;
								}
								//else {
									// Internal error
									//log("update_player_slots: overlay: unknown card type")
								//}
								*/
								img.style.top = (j * 28) + "px";
								img.style.zIndex = 50;
								div.appendChild(img);
							}
							player_slot.style.height = 100 + (length2 * 28) + "px";

							// Add a menu to the div
							var menu_ul = document.createElement('ul');
							menu_ul.className = 'menu';
							menu_ul.style.zIndex = 100;
							menu_ul.id = player + "_slot" + (i + 1) + "_menu";
							div.appendChild(menu_ul);

							// Add menus
							player_slot_callbacks.forEach(function (fn) {
								fn(menu_ul, i + 1, player_nr);
							});

							unmark_onclick(player_slot);
							$(img).addClass('mark_slot');
							img.slot = ["Marking_player_slot", player_nr, i + 1];
							update_marking();
							update_draggable();
						}
						else {
						}

						break;

					case "Dice":
						var value = elem[1];
						var dice_img = "dice{0}c.jpg".format(value);

						var div = document.createElement('div');	// Div to surround img, needed by menu
						div.style.position = 'relative';
						var img = document.createElement('img');
						var menu_ul = document.createElement('ul');
						menu_ul.className = 'menu';
						menu_ul.style.zIndex = 100;
						menu_ul.id = "player{0}_slot{1}_menu".format(player_nr, i + 1);	// TODO: one menu for each img???
						img.src = '/img/' + dice_img;
						//img.style.marginTop = "40px";
						//img.style.marginLeft = "10px";
						div.appendChild(img);
						div.appendChild(menu_ul);
						player_slot.appendChild(div);

						// Add menus
						player_slot_callbacks.forEach(function (fn) {
							fn(menu_ul, i + 1, player_nr);
						});

						// Fix marking
						unmark_onclick(player_slot);
						img.slot = ["Marking_player_slot", player_nr, i + 1];
						$(img).addClass("mark_slot");
						update_marking();
						update_draggable();

						break;
					default:
						log("update_player_slots: Unknown table_type: " + type)
						break;
				}

			}

			break;

		// Not needed. Use Update_hand or Update_all_hands instead.
		case "Remove_card_from_hand":
			chat("Not implemented");
			break;

		/**
		 * 	Add action to deck, or other target
		 */
		case "Add_action":

			var action_id = command_type[1];
			if (action_id == undefined) {
				chat("Error: Add_action: action_id is undefined");
				return;
			}

			var action = command_type[2];

			var create_menu = function (html) {
			};

			switch (action[0]) {
				case "Add_menu_to_deck":

					// Check if we have a deck
					var deck_div = document.getElementById('deck_' + action[1]);
					if (deck_div == undefined) {
						// Abort!
						chat("Error: Add_action: Found no deck div for deck_nr " + action[1], "Client");
						return;
					}

					// Now we now action[1] is a real deck id
					var deck_nr = action[1];

					// Check if we have a menu
					var ul = document.getElementById('deck_' + deck_nr + '_menu');
					if (ul == undefined) {
						// No menu, make a new
						var menu = document.createElement('ul');
						menu.className = 'menu';
						menu.id = "deck_" + deck_nr + "_menu";
						deck_div.appendChild(menu);
						ul = menu;
					}

					var player_nrs = action[3];	// List of players for whom this action is available for

					var menu_text = action[2][1];

					// Add a list item to existing menu
					switch (action[2][0]) {	// Action name
						case "Pick_card":
							table_menu_callbacks[action_id] = function (ul, deck_nr, slot_nr) {
								// Check if this action is available for this player
								if (!player_nrs.some(function (el) { return el == my_player_nr })) {
									return;
								}

								if (deck_nr == -1) {
									return;
								}

								var li = document.createElement('li');
								var a = document.createElement('a');
								a.href ='';
								a.className = 'ui-corner-all';
								a.role = 'menuitem';
								a.tabindex = '-1';
								a.onclick = function (ev) {
									ev.preventDefault();

									var command = {command_type: [
										'Action', 
										['Pick_card_data', deck_nr]
										],
										username: getCookie("username")
									};
									ws.send(JSON.stringify(command));

									//unmark_all();

									return false;
								};
								//a.innerHTML = menu_text;
								$(a).text(menu_text).html();
								li.appendChild(a);
								li.className = 'ui-menu-item';
								li.role = 'presentation';
								ul.appendChild(li);
								$('#deck_' + deck_nr + '_menu').menu();	// Do this many times??
								show_menus();
							};
							break;
						default:
							chat("Error: Add_action: No such action" + action[2], "Client");
					}

					break;
				case "Add_menu_to_hand":
					var player_nrs = action[2];	// List of players for whom this action is available for
					var menu_text = action[1][1];
					switch (action[1][0]) {	// Action name
						case "Play_card":
							// Callback is called at update_hand (at card pickup)
							hand_menu_callbacks[action_id] = function (ul, i, card_nr) {
								// Check if this action is available for this player
								if (!player_nrs.some(function (el) { return el == my_player_nr })) {
									return;
								}
								var li = document.createElement('li');
								var a = document.createElement('a');
								a.href = '';
								a.className = 'ui-corner-all';
								a.role = 'menuitem';
								a.tabindex = '-1';
								//a.innerHTML = menu_text;
								$(a).text(menu_text).html();
								a.onclick = function (ev) {
									ev.preventDefault();

									var command = {command_type: [
										'Action',
										['Play_card_data', card_nr]
										],
										username : getCookie("username")
									};
									ws.send(JSON.stringify(command));

									//unmark_all();

									return false;
								}
								li.appendChild(a);
								li.className = 'ui-menu-item';
								li.role = 'presentation';
								ul.appendChild(li);
								ul.style.zIndex = 100;
								$('#hand1_slot' + i + '_menu').menu();	// Do this many times??
								show_menus();
							};
							break;
						default:
							chat("Error: Add_action: No such action: " + action[1], "Client");
					}
					break;
				case "Add_menu_to_player_slot":
					var slot_nrs = action[2];
					var player_nrs = action[3];
					var menu_text = action[1][1];
					switch (action[1][0]) {	// Action name
						case "Play_card":
							player_slot_callbacks[action_id] = function (ul, slot_nr, player_nr) {
								// Check if this action is available for this player
								if (!player_nrs.some(function (el) { return el == my_player_nr })) {
									return;
								}
								// Check if this action is for this slot
								if (!slot_nrs.some(function (el) { return el == slot_nr })) {
									return;
								}
								// Only add menu for me
								if (player_nr != my_player_nr) {
									return;
								}
								var li = document.createElement('li');
								var a = document.createElement('a');
								a.href = '';
								a.className = 'ui-corner-all';
								a.role = 'menuitem';
								a.tabindex = '-1';
								//a.innerHTML = menu_text;
								$(a).text(menu_text).html();
								a.onclick = function (ev) {
									ev.preventDefault();
									ev.stopPropagation();

									var command = {command_type: [
										'Action',
										['Play_slot_card_data', slot_nr]
										],
										username : getCookie("username")
									};
									ws.send(JSON.stringify(command));

									//unmark_all();

									return false;
								}
								li.appendChild(a);
								li.className = 'ui-menu-item';
								li.role = 'presentation';
								ul.appendChild(li);
								ul.style.zIndex = 100;
								$('#player' + my_player_nr + '_slot' + slot_nr + '_menu').menu();
								show_menus();
							};
							break;
						default:
							chat("Error: Add_menu_to_player_slot: No such action: " + action[1], "Client");
							break;
					}
					break;
				// Action with callback. TODO: Should work for all slots.
				case "Add_callback_to_slot":
					var action_record = action[1];

					player_nrs = action_record.player_nrs;
					
					switch (action_record.target) {
						case "table_slot":
							table_menu_callbacks[action_id] = function (ul, deck_nr, slot_nr) {

								// Check if this action is available for this player
								if (!action_record.a_player_nrs.some(function (el) { return el == my_player_nr })) {
									return;
								}

								// Check if this action is available for this slot
								if (!action_record.target_ids.some(function (el) { return el == slot_nr})) {
									return;
								}

								// Don't interfere with deck action "pick_card"
								if (deck_nr != -1) {
									return;
								}

								var li = document.createElement('li');
								var a = document.createElement('a');
								a.href ='';
								a.className = 'ui-corner-all';
								a.role = 'menuitem';
								a.tabindex = '-1';
								a.onclick = function (ev) {
									ev.preventDefault();

									var command = {command_type: [
										'Action', 
										['Callback_data', action_id, slot_nr, "table_slot"]
										],
										username: getCookie("username")
									};
									ws.send(JSON.stringify(command));

									//unmark_all();

									return false;
								};
								//a.innerHTML = action_record.menu_text;
								$(a).text(action_record.menu_text).html();
								li.appendChild(a);
								li.className = 'ui-menu-item';
								li.role = 'presentation';
								ul.appendChild(li);
								$('#table_slot' + slot_nr + '_menu').menu();	// Do this many times??
								show_menus();
							};
							
							break;
						case "player_slot":
							log("action record");
							log(action_record);
							player_slot_callbacks[action_id] = function (ul, slot_nr, player_nr) {
								// Check if this action is available for this player
								if (!action_record.a_player_nrs.some(function (el) { return el == my_player_nr })) {
									return;
								}

								// Check if this action is available for this slot
								if (!action_record.target_ids.some(function (el) { return el == slot_nr})) {
									return;
								}

								// Only add menu for me
								if (player_nr != my_player_nr) {
									return;
								}

								var li = document.createElement('li');
								var a = document.createElement('a');
								a.href = '';
								a.className = 'ui-corner-all';
								a.role = 'menuitem';
								a.tabindex = '-1';
								//a.innerHTML = action_record.menu_text;
								$(a).text(action_record.menu_text).html();
								a.onclick = function (ev) {
									ev.preventDefault();

									var command = {command_type: [
										'Action', 
										['Callback_data', action_id, slot_nr, "player_slot"]
										],
										username: getCookie("username")
									};
									ws.send(JSON.stringify(command));

									//unmark_all();

									return false;
								};
								li.appendChild(a);
								li.className = 'ui-menu-item';
								li.role = 'presentation';
								ul.appendChild(li);
								ul.style.zIndex = 100;
								$('#player' + my_player_nr + '_slot' + slot_nr + '_menu').menu();
								show_menus();

							};
							break;
						default:
							chat("Internal error: Only target 'table_slot' and 'player_slot' is supported by callback action.");
							break;
					}
					break;
				default:
					chat("Error: Add_action: No such action: " + action[0], "Client");
					break;
			}

			break;
		/** Removes action from any list it was in */
		case "Remove_action":
			//log("Remove_action");
			var action_id = command_type[1];
			//log("action_id = " + action_id);
			//log(hand_menu_callbacks);
			//log(table_menu_callbacks);
			//log(player_slot_callbacks);
			if (hand_menu_callbacks[action_id] != undefined) {
				delete hand_menu_callbacks[action_id];	// Unset callback function 
			}
			if (table_menu_callbacks[action_id] != undefined) {
				delete table_menu_callbacks[action_id];	// Unset callback function 
			}
			if (player_slot_callbacks[action_id] != undefined) {
				delete player_slot_callbacks[action_id];	// Unset callback function 
			}

			//for(var i = 0; i < all_callbacks.length; i++) {
				//var callback_list = all_callbacks[i];
				//log(callback_list);
			//}
			//all_callbacks.forEach(function(callback_list, index) {
			//});
			show_menus();
			break;
		case "Enable_marking":
			var slot_list = command_type[1];
			enable_marking = slot_list;	// Set global variable
			/*
			slot_list.forEach(function(slot, i) {
				switch (slot[0]) {
					case "player_slot":
						var player_nrs = slot[1];
						var slot_nrs = slot[2];
						break;
					case "table_slot":
						var slot_nrs = slot[1];
						break;
					case "player_hand":
						var player_nrs = slot[1];
						break;
				}
			});
			*/
			break;

		/** Gadget commands */
		case "Add_gadget":
			var gadget = command_type[1];
			//var gadgets = document.getElementById('player' + my_player_nr + '_gadgets');
			var gadgets = document.getElementById("gadget_slot");

			// Abort if my nr is not in player nrs
			if (!gadget.player_nrs.some(function (el) { return el == my_player_nr })) {
				return;
			}

			switch (gadget.type_) {
				case "button":
					var button = document.createElement('button');
					//button.innerHTML = gadget.text;
					$(button).text(gadget.text).html();
					button.className = 'button';
					//button.style.cssFloat = "left";
					button.id = "player" + my_player_nr + "_gadget" + gadget.gadget_id;
					button.onclick = function () { 
						var command = {
							command_type: [
								'Button_pressed', 
								gadget.gadget_id
							],
							username: getCookie("username")
						};
						ws.send(JSON.stringify(command));
					};
					gadgets.appendChild(button);
					break;
				case "select":
					var select = document.createElement('select');
					var options = gadget.spec[1];
					for (var i = 0; i < options.length; i++) {
						if (options[i] != "") {
							var option = document.createElement('option');
							option.innerHTML = options[i];
							//$(button).text(options[i]).html();
							option.value = i
							select.appendChild(option);
						}
					}
					select.id = "player{0}_gadget{1}".format(my_player_nr, gadget.gadget_id);
					select.onchange = function () {
						var command = {
							command_type: [
								'Select_changed',
								gadget.gadget_id,
								parseInt(select.options[select.selectedIndex].value) + 1
							],
							username: getCookie("username")
						};
						ws.send(JSON.stringify(command));
					};
					gadgets.appendChild(select);
					break;

				case "input":
					var div = document.createElement('div');
					div.id = "player{0}_gadget{1}".format(my_player_nr, gadget.gadget_id);
					var input = document.createElement('input');
					var button = document.createElement('button');
					//button.innerHTML = gadget.text;
					$(button).text(gadget.text).html();
					button.className = 'button';
					button.onclick = function () { 
						if (input.value != "") {
							var command = {
								command_type: [
									"Input_button_pressed",
									gadget.gadget_id,
									input.value
									],
									username: getCookie("username")
							};
							ws.send(JSON.stringify(command));
							input.value = '';
						}
					};
					input.className = 'input';
					input.addEventListener("keyup", function(e) {
						if (!e) { 
							var e = window.event; 
						}
						e.preventDefault(); // sometimes useful

						// Enter is pressed
						if (e.keyCode == 13) { 
							var command = {
								command_type: [
									"Input_button_pressed",
									gadget.gadget_id,
									input.value
									],
									username: getCookie("username")
							};
							ws.send(JSON.stringify(command));
							input.value = '';
						}
					}, 
					false);

					div.appendChild(input);
					div.appendChild(button);
					gadgets.appendChild(div);
					break;
				case "slider":
					var bottom = gadget.spec[1];
					var top_ = gadget.spec[2];
					var step = gadget.spec[3];
					var value = gadget.spec[4];
					var div = document.createElement('div');
					div.id = "player{0}_gadget{1}".format(my_player_nr, gadget.gadget_id);
					div.style.clear = "both";
					div.style.cssFloat = 'left';
					//div.style.padding = "10px";
					var input = document.createElement('input');
					input.style.width = "40px";
					input.style.cssFloat = "left";
					input.readOnly = true;
					var slider = document.createElement('div');
					//slider.id = "player{0}_gadget{1}".format(my_player_nr, gadget.gadget_id);
					slider.style.width = "300px";
					slider.style.cssFloat = "left";
					slider.style.marginTop = "15px";
					slider.style.marginBottom = "5px";
					slider.style.marginLeft = "10px";

					div.appendChild(slider);
					gadgets.appendChild(div);
					$(slider).slider({
						min: bottom,
						max: top_,
						range: "min",
						step: step,
						slide: function (event, ui) {
							input.value = ui.value
						},
						change: function (event, ui) {
							input.value = ui.value;
							var command = {
								command_type: [
									"Slider_changed",
									gadget.gadget_id,
									//$(slider).slider("value")
									ui.value
									],
									username: getCookie("username")
							};
							ws.send(JSON.stringify(command));
						}
					});
					//slider.onmouseup = function () { 
					//};

					div.appendChild(input);
					input.value = value;

					break;

				case "confirm":
					var title = gadget.spec[1];
					var div = document.createElement('div');
					var p = document.createElement('p');
					//p.innerHTML = gadget.text;
					$(p).text(gadget.text).html();
					div.title = title ? title : "Confirm";
					div.style.display = "none";
					div.appendChild(p);
					gadgets.appendChild(div);
					$(div).dialog({
						resizable: true,
						height: 240,
						modal: false,
						closeOnEscape: false,
						modal: true,
						open: function () {
							// Hack to remove focus on either button
							$(this).parent().find('.ui-dialog-buttonpane button').removeClass();
							$(this).parent().find('.ui-dialog-buttonpane button').addClass("button");
							$(this).parent().find('.ui-dialog-buttonpane button:eq(1)').focus();
							$(this).parent().find('.ui-dialog-buttonpane button:eq(1)').blur();
						},
						buttons: {
							Cancel: function () {
								$(this).dialog("close");
								var command = {
									command_type: [
										"Confirm_pressed",
										gadget.gadget_id,
										false
										],
										username: getCookie("username")
								};
								ws.send(JSON.stringify(command));
							},
							"OK": function () {
								$(this).dialog("close");
								var command = {
									command_type: [
										"Confirm_pressed",
										gadget.gadget_id,
										true
										],
										username: getCookie("username")
								};
								ws.send(JSON.stringify(command));
							}
						}
					});

					break;

				default:
					chat("Internal error: gadget type not supported: " + gadget.type_);
					break;
			}

			break;

		case "Update_gadget":
			var gadget = command_type[1];
			//var gadgets = document.getElementById('player' + my_player_nr + '_gadgets');
			var gadgets = document.getElementById("gadget_slot");

			// Abort if my nr is not in player nrs
			if (!gadget.player_nrs.some(function (el) { return el == my_player_nr })) {
				return;
			}

			var old_gadget = document.getElementById("player{0}_gadget{1}".format(my_player_nr, gadget.gadget_id));

			switch (gadget.type_) {
				case "button":
					//old_gadget.innerHTML = gadget.text;
					$(old_gadget).text(gadget.text).html();
					break;
				case "select":
					var options = gadget.spec[1];
					$(old_gadget).find("option").remove();
					for (var i = 0; i < options.length; i++) {
						if (options[i] != "") {
							var option = document.createElement('option');
							//option.innerHTML = options[i];
							$(option).text(options[i]).html();
							option.value = i
							old_gadget.appendChild(option);
						}
					}
					break;
				case "slider":
					var bottom = gadget.spec[1];
					var top_ = gadget.spec[2];
					var step = gadget.spec[3];
					var value = gadget.spec[4];
					var slider = $(".ui-slider", old_gadget);
					var options = {
						min: bottom,
						max: top_,
						range: "min",
						step: step,
						value: value
					};
					slider.slider("option", options);

					break;
				default:
					chat("Error: Can't update {0}".format(gadget.type_));
					break;
			}
			break;
		case "Remove_gadget":
			var gadget_id = command_type[1];
			//var gadgets = document.getElementById('player' + my_player_nr + '_gadgets');
			var gadget = document.getElementById('player' + my_player_nr + '_gadget' + gadget_id);
			/*
			if (!gadget) {
				chat("Error: No gadget found with id {0} for player with id {1}".format(gadget_id, my_player_nr));
			}
			else {
				$(gadget).remove();
			}
			*/

			if (gadget) {
				$(gadget).remove();
			}

			break;

		case "Update_points_table":
			var rows = command_type[1];

			var points_area = document.getElementById('points_area');
			var points_table = document.getElementById('points_table');
			points_table.innerHTML = "";

			// Find row with highest length
			var highest = 0;
			for (var i = 0; i < rows.length; i++) {
				if (rows[i].length > highest) {
					highest = rows[i].length;
				}
			}

			for (var i = 0; i < rows.length; i++) {
				var tr = document.createElement('tr');
				for (var j = 0; j < highest; j++) {
					if (i == 0) {
						td = document.createElement('th');
					}
					else {
						td = document.createElement('td');
					}
					//if (j == 0 && i != 0) {
						//td.style.borderRight = "1px solid rgb(153, 153, 153)";
					//}
					//td.innerHTML = rows[i][j] ? rows[i][j] : "";
					$(td).text(rows[i][j] ? rows[i][j] : "").html();
					tr.appendChild(td)
				}
				points_table.appendChild(tr);
			}

			points_area.style.display = "block";
			
			break;

		/** Animation commands */
		case "Animate":
			var anim = command_type[1];
			var src = anim.src;
			var dest = anim.dest;
			var callback_id = anim.anim_callback;

			log(src);

			/** Return <img> of @location
					Only used for src, which is known to have an img
					Location:
					{
						slot_type: "table_slot",
						slot_nr: 0,
						player_nr: 1,
						index: 2
					}
			*/
			var get_img_of_source = function(loc) {
				switch (loc.slot_type) {
					case "A_player_hand":
						// Is this my hand?
						if (my_player_nr == loc.player_nr) {
							var search_string = '#player{0}_hand1 #hand1_slot{1} > img'.format(loc.player_nr, loc.slot_nr);
							var imgs = $(search_string);

							if (!imgs || imgs.length != 1) {
								chat("Error: Did not find exactly one img");
								return;
							}

							return imgs[0];
						}
						// Not my hand
						else {
							var search_string = '#player{0}_hand1 img'.format(loc.player_nr, loc.slot_nr);
							var imgs = $(search_string);

							if (!imgs || imgs.length < 1) {
								chat("Error: Did not find opponents hand imgs");
							}
							else {
								return imgs[imgs.length - loc.slot_nr];
							}
						}

						break;
					case "A_player_slot":

						var search_string = '#player{0}_slot{1} img'.format(loc.player_nr, loc.slot_nr)
						log(search_string);
						var imgs = $(search_string);

						if (imgs && loc.index != -1) {
							// This is a stack/overlay
							return imgs[loc.index - 1];
						}
						else if (imgs) {
							// This is a single card or deck
							return imgs[0];
						}
						else {
							chat("Error: found no player slot imgs with search string {0}".format(search_string));
						}

						break;
					case "A_table_slot":
						var search_string = '#table_slot{0} img'.format(loc.slot_nr);
						log(search_string);

						var imgs = $(search_string);

						if (imgs && loc.index != -1) {
							// This is a stack/overlay
							return imgs[loc.index - 1];
						}
						else if (imgs) {
							// This is a single card or deck
							return imgs[0];
						}
						else {
							chat("Error: found no table slot imgs with search string {0}".format(search_string));
						}

						break;
					default:
						chat("Internal error: unknown slot type for source: {0}".format(loc.slot_type));
						break;
				}
			};

			/**	Get offset object of destination
			*/
			var get_offset_of_destination = function(loc) {
				switch (loc.slot_type) {
					case "A_player_hand":
						// Move card to hand icon
						var search_string = '#player{0}_hand1 .hand_icon img'.format(loc.player_nr);
						var div = $(search_string);

						if (div) {
							return div.offset();
						}
						else {
							chat("Error: Dit not find hand icon of player {0}".format(loc.player_nr));
							return;
						}
						break;
					case "A_player_slot":
						var search_string = "#player{0}_slot{1}".format(loc.player_nr, loc.slot_nr);
						log(search_string);
						var div = $(search_string);
						if (div) {
							return div.offset();
						}
						else {
							chat("Error: Did not find player_slot of destination");
							return;
						}
						break;
					case "A_table_slot":
						var search_string = "#table_slot{0}".format(loc.slot_nr);
						var div = $(search_string);
						if (div) {
							return div.offset();
						}
						else {
							chat("Error: did not find table_slot of destination");
							return;
						}
						break;
					default:
						chat("Internal error: unknown slot type for destination: {0}".format(loc.slot_type));
						break;
				}
			};

			// Find img of src
			var src_img = get_img_of_source(src);
			var src_offset = $(src_img).offset();
			log(src_img);
			log(src_offset);
			var dest_offset = get_offset_of_destination(dest);
			log(dest_offset);
			var src_is_deck = src_img.src.indexOf("deck_back") != -1;

			// Hide src img
			if (src_is_deck) {
				// Don't hide deck
			}
			else {
				src_img.style.visibility = "hidden";
			}

			// Create a copy img and place it in <body> on absolute position
			var new_img = document.createElement('img');
			// TODO: Hardcode deck img...
			new_img.src = src_is_deck ? '/img/card_back.png' : src_img.src;
			new_img.className = "anim_img";
			new_img.style.position = "absolute";
			new_img.style.top = src_offset.top + "px";
			new_img.style.left = src_offset.left + "px";
			document.body.appendChild(new_img);

			// Find slot/coord? of dest
			$(new_img).animate({left: dest_offset.left + "px", top: dest_offset.top + "px"}, 500, function () {
				// Tell server to run callback, if any
				if (callback_id != -1) {
					command = {
						command_type: ['Animate_callback', callback_id],
						username: getCookie("username")
					};
					ws.send(JSON.stringify(command));
				}
			});

			break;

		// Draggable and droppable commands
		case "Enable_draggable":
			// Set global variables
			draggable_player_nrs = command_type[1];
			draggable_cards = command_type[2];
			droppable_slots = command_type[3];

			update_draggable();

			break;

		case "Enable_onclick":
			// Set global variables
			onclick_cards = command_type[1];

			for (var j = 0; j < onclick_cards.length; j++) {
				var card = onclick_cards[j];
				log(card);
				var img = document.getElementById("card{0}".format(card.card_nr));
				if (img) {

						img.onclick = (function () {

							var card_nr2 = card.card_nr;
							var img2 = img;

							return function () {
								if ($(img2).hasClass("noclick")) { // Don't clash with draggable
									$(img2).removeClass("noclick");
								}
								else {
									var command = {
										command_type: ["Card_onclick", card_nr2],
										username: getCookie("username")
									};
									ws.send(JSON.stringify(command));
								}
							}
						}
					)();
				}
			}

			break;

		/** All the key bindings */
		case "Bind_key":
			keydown_callbacks = command_type[1];

			break;

		/** Commands for canvas */
		case "Enable_canvas":
			using_canvas = true;
			var table_fs = document.getElementById('table_fs');
			table_fs.innerHTML = "";
			var canvas = document.createElement("canvas");
			canvas.id = "table_canvas";
			table_fs.appendChild(canvas);
			old_table_width	= 0;	// Hack to rebuild table next frame
			break;

		case "Disable_canvas":
			using_canvas = false;
			$("#table_canvas").remove();
			old_table_width	= 0;	// Hack to rebuild table next frame
			break;

		/** Commands for movables */
		case "Set_movables":

			// Canvas required
			if (!using_canvas) {
				chat("Error: Must use canvas to use movable objects");
				return;
			}

			// Update movables
			var server_timestamp = command_type[1];
			new_movables = command_type[2];

			// Update velocity and accelleration of old objects
			for (var i = 0; i < new_movables.length; i++) {
				var old_obj = old_movables[new_movables[i].obj_id];
				var new_obj = new_movables[i];
				if (old_obj == null) {
					//chat("Internal error: Found no movable object with id {0}".format(new_movables[i].obj_id));
					// Add obj
					old_movables[new_movables[i].obj_id] = new_movables[i];
				}
				else {
					old_obj.x_acc = new_obj.x_acc;
					old_obj.y_acc = new_obj.y_acc;
					old_obj.x_vel = new_obj.x_vel;
					old_obj.y_vel = new_obj.y_vel;

					// Slightly adjust velocity times x difference
					if (old_obj.x > new_obj.x) {
						old_obj.x_acc -= 0.1 * (Math.abs(old_obj.x - new_obj.x));
					}
					if (old_obj.x < new_obj.x) {
						old_obj.x_acc += 0.1 * (Math.abs(old_obj.x - new_obj.x));
					}
					if (old_obj.y > new_obj.y) {
						old_obj.y_acc -= 0.1 * (Math.abs(old_obj.y - new_obj.y));
					}
					if (old_obj.y < new_obj.y) {
						old_obj.y_acc += 0.1 * (Math.abs(old_obj.y - new_obj.y));

					}

					// Teleport x and y if the diff is too high
					if (Math.abs(old_obj.x - new_obj.x) > 20) {
						old_obj.x = new_obj.x;
					}
					if (Math.abs(old_obj.y - new_obj.y) > 20) {
						old_obj.y = new_obj.y;
					}
				}
			}

			// Only set realtime loop once
			if (!movables_enabled) {

				movables_enabled = true;

				(function animloop(){

					if (!movables_enabled) {
						return;
					}

					requestAnimFrame(animloop);

					// Increase each frame. Resets at 999999999 on server
					timestamp++;
					if (timestamp > 999999999) { timestamp = 1; }

					// Get canvas context
					var canvas = document.getElementById("table_canvas");
					var ctx = canvas.getContext("2d");

					// Clear canvas
					ctx.clearRect(0, 0, canvas.width, canvas.height);

					// Loop old movables
					for (var obj_id in old_movables) {
						var obj = old_movables[obj_id];
						var img_id = "preload_{0}_{1}".format(obj.card.dir, obj.card.img);

						// Calculate new position
						obj.x_vel += obj.x_acc
						obj.y_vel += obj.y_acc
						obj.x += obj.x_vel
						obj.y += obj.y_vel
					
						ctx.drawImage(document.getElementById(img_id), obj.x, obj.y);
					}

				})();
			}

			break;

		default: 
			log(command_type);
			chat("Internal error: Command not supported: " + command_type[0]);
			break;
		// END of commands
	}
}

/**
	new_websocket(addr, port, password)
	
	@param addr		address to server
	@param port		port of websocket server
	@param pwd		bool; if pwd is on or not
*/
function new_websocket(addr, port, pwd) {

	ws = new WebSocket("ws://" + addr + ":" + port);

	ws.onmessage = websocket_onmessage;

	ws.onclose = function () {
		chat("Connection closed");
	};

	ws.onerror = function (evt) {
		chat("Websocket error (probably can't connect)");
		console.log(evt);
	}

	// Immediatly at open, send login request
	ws.onopen = function () {
		chat("Connected");
		// First login
		var command = {
			command_type: [
				'Login', 
				getCookie("username"), 
				parseInt(getCookie("session_id")), 
				pwd ? (tmp = prompt("Enter game session password:"), tmp ? tmp: "") : "" 
			],
			username: getCookie("username")
		};
		ws.send(JSON.stringify(command));

		// Second, mark session websocket as connected
		command = {
			command_type: 'Websocket_connected',
			username: getCookie("username")
		};
		ws.send(JSON.stringify(command));

		// Third, participate
		command = {
			command_type: 'Add_participate',
			username: getCookie("username")
		};
		ws.send(JSON.stringify(command));

	};
}

/*
 * 	Send action to server
 * 	Assumes it is this players turn (otherwise error message)
 *
 * 	@param action	action; see ml file for definitions
 */
function action(action) {
}

/**
	Broadcast a chat message
*/
function say(msg, ws_) {
	// Compose JSON command
	var command = {
		command_type : ['Chat', msg],
		username : getCookie("username")
	};

	// Eventually want to use a different ws object
	var ws_ = ws_ || ws;

	ws_.send(JSON.stringify(command));
}

/**
	Append msg in chat
*/
function chat(msg, name, color) {
	//if (name) 
		//$('#chat').append(name + ": " + msg + '\n');
	//else
		//$('#chat').append(msg + '\n');
	var span = document.createElement('span');
	var msg_span = document.createElement('span');
	var name_span = document.createElement('span');
	msg_span.innerHTML = msg + '<br />';
	//$(msg_span).text(msg + "<br />").html();
	//name_span.innerHTML = name + ': ';
	$(name_span).text(name + ": ").html();

	if (name != undefined) {
		span.appendChild(name_span);
		span.appendChild(msg_span);
	}
	else {
		span.appendChild(msg_span);
	}

	// Hide "System" name
	if (name == "System") {
		//name_span.style.color = '#f00';
		name_span.innerHTML = '';
		//msg_span.style.color = "#999";
	}

	var chat = document.getElementById('chat');
	chat.appendChild(span);

	chat.scrollTop = chat.scrollHeight;

}

/**
	Write @msg in debug textarea, if div #debug_text is defined
*/
function debug_chat(msg) {
	var d = $('#debug_text');
	if (d != undefined) {
		d.append(msg + '\n');
	}
}

/**
	Send start command to server
	Start game session
*/
function start_game() {
	var command = {
		command_type: "Start",
		username: getCookie("username")
	};
	ws.send(JSON.stringify(command));
}

// Play again after game over
function play_again() {
	
	var command = {
		command_type: "Play_again",
		username: getCookie("username")
	};
	ws.send(JSON.stringify(command));
}

// Get cookie value (from w3schools)
function getCookie(c_name)
{
	var i,x,y,ARRcookies=document.cookie.split(";");
	for (i=0;i<ARRcookies.length;i++)
	{
		x=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
		y=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
		x=x.replace(/^\s+|\s+$/g,"");
		if (x==c_name)
		{
			return unescape(y);
		}
	}
}

// Debugging stuff

/**
	Dump decks from lua state in debugging textarea
*/
function dump_decks() {
	var command = {
		command_type: 'Dump_decks' ,
		username: getCookie("username")
	}
	ws.send(JSON.stringify(command));
}

/**
	Dump players from lua state in debugging textarea
*/
function dump_players() {
	var command = {
		command_type: 'Dump_players' ,
		username: getCookie("username")
	}
	ws.send(JSON.stringify(command));
}

/**
 * 	Dump table in debugging textarea
 */
function dump_table() {
	var command = {
		command_type: 'Dump_table',
		username: getCookie("username")
	}
	ws.send(JSON.stringify(command));
}

/**
 * 	Execute arbitrary Lua code
 */
function execute_lua() {
	var lua_code = prompt("Write Lua code:");
	var command = {
		command_type: ['Execute_lua', lua_code],
		username: getCookie("username")
	}
	ws.send(JSON.stringify(command));
}

/** Join an existant not-started quickmatch */
function join_quickmatch() {
	var data = {
		module: "gamesession",
		op: "join_quickmatch",
		game_id: 28
	};
	var ajax = $.ajax({
		type: "POST",
	   	url: "/cgi-bin/drakskatten_ajax", 
	   	data: data,
	   	success: function (data, textStatus, jqXHR) {
				alert("success");
			},
			error: function (data, textStatus) {
				log("error");
				log(data);
				log(textStatus);
			}
	});
}

/** Creates a new quickmatch lobby */
function new_quickmatch(game_id) {
	window.location.href = "/cgi-bin/drakskatten?module=gamesession&op=join_quickmatch&game_id=" + game_id + "";
}

/** Get users waiting in a quickmatch lobby */
function get_waiting_users() {
	var select = document.getElementById("quickmatch_select");
	var game_id = select.options[select.selectedIndex].value;
	var info = document.getElementById("waiting_info");

	if (game_id == 0) {
		info.innerHTML = '';
		return;
	}

	var data = {
		module: "gamesession",
		op: "get_waiting_users",
		game_id: game_id
	};
	var ajax = $.ajax({
		type: "POST",
	   	url: "/cgi-bin/drakskatten_ajax", 
	   	data: data,
	   	success: function (data, textStatus, jqXHR) {
				var data = JSON.parse(data);
				var play = document.getElementById("play");

				play.onclick = function () {
					new_quickmatch(game_id);
				};

				if (data.length == 0) {
					info.innerHTML = "No one waiting for this game. Press \"Play\" to create a new session!";
				}
				else {
					info.innerHTML = data.length + " people waiting in lobby. Press \"Play\" to join them!"
				}

			},
			error: function (data, textStatus) {
				log("error");
				log(data);
				log(textStatus);
			}
	});
}

// onclick for guest login link
function guest_login() {

	
	var ajax = $.ajax({
		type: "GET",
			url: "/cgi-bin/drakskatten_ajax?op=guest_login&module=user", 
			success: function (data, textStatus, jqXHR) {
				// Login ok, redirect
				window.location.href = "/cgi-bin/drakskatten?module=startpage&op=startpage";
			},
			error: function (data, textStatus) {
				alert("Error: Could not login. Already logged in? Logout and try again. " + data);
				log(data);
				log(textStatus);
			}
	});

	return false;
}
