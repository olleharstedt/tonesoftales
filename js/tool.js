/**
	Tool stuff that should be loaded before anything else

	@since 2013-08-08
*/

// Some array functions
if (!Array.prototype.some)
{
	Array.prototype.some = function(fun /*, thisp */)
	{
		"use strict";

		if (this == null)
			throw new TypeError();

		var t = Object(this);
		var len = t.length >>> 0;
		if (typeof fun != "function")
			throw new TypeError();

		var thisp = arguments[1];
		for (var i = 0; i < len; i++)
		{
			if (i in t && fun.call(thisp, t[i], i, t))
				return true;
		}

		return false;
	};
}

if (!Array.prototype.filter) {
	Array.prototype.filter = function(fun /*, thisp*/) {
		'use strict';

		if (!this) {
			throw new TypeError();
		}

		var objects = Object(this);
		var len = objects.length >>> 0;
		if (typeof fun !== 'function') {
			throw new TypeError();
		}

		var res = [];
		var thisp = arguments[1];
		for (var i in objects) {
			if (objects.hasOwnProperty(i)) {
				if (fun.call(thisp, objects[i], i, objects)) {
					res.push(objects[i]);
				}
			}
		}

		return res;
	};
}


if (!Array.prototype.forEach) {
	Array.prototype.forEach = function(fn, scope) {
		for(var i = 0, len = this.length; i < len; ++i) {
			if (i in this) {
				fn.call(scope, this[i], i, this);
			}
		}
	};
}

// First, checks if it isn't implemented yet.
if (!String.prototype.format) {
	String.prototype.format = function() {
		var args = arguments;
		return this.replace(/{(\d+)}/g, function(match, number) { 
			return typeof args[number] != 'undefined'
			? args[number]
			: match
			;
		});
	};
}

//jQuery ismouseover  method
(function($){ 
	 $.mlp = {x:0,y:0}; // Mouse Last Position
	 function documentHandler(){
		 var $current = this === document ? $(this) : $(this).contents();
		 $current.mousemove(function(e){
			 jQuery.mlp = {
				 x: e.pageX,
				 y: e.pageY
			 }
		 });
		 $current.find("iframe").load(documentHandler);
	 }
	 $(documentHandler);
	 $.fn.ismouseover = function(overThis) {  
		 var result = false;
		 this.eq(0).each(function() {  
				 var $current = $(this).is("iframe") ? $(this).contents().find("body") : $(this);
				 var offset = $current.offset();             
				 result =    offset.left<=$.mlp.x && offset.left + $current.outerWidth() > $.mlp.x &&
				 offset.top<=$.mlp.y && offset.top + $current.outerHeight() > $.mlp.y;
		 });  
		 return result;
	 };  
 })(jQuery);

function ismouseover(str) {
	return $(str).ismouseover();
}

