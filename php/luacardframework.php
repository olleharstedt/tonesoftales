<? php

/**
 * 	Info about TonesOfTales as a Lua card game framework
 */

?>

<!doctype html>
<html>
	<head>
		<title>Lua card game framework</title>
		<meta charset='utf-8'>
		<meta nam='description' content='Spela vändtia och andra spel online' />
		<link rel='stylesheet' href='css/style.css' type='text/css'>
		<script type='text/javascript' src='js/jquery-1.9.1.min.js' charset='UTF-8'></script>
		<script type='text/javascript' src='js/drakskatten.js' charset='UTF-8'></script>
		<script>
		$(function() {
			var pre = document.getElementsByTagName('pre'),
			    pl = pre.length;
			for (var i = 0; i < pl; i++) {
				pre[i].innerHTML = '<span class="line-number"></span>' + pre[i].innerHTML + '<span class="cl"></span>';
				var num = pre[i].innerHTML.split(/\n/).length;
				for (var j = 0; j < num; j++) {
					var line_num = pre[i].getElementsByTagName('span')[0];
					line_num.innerHTML += '<span>' + (j + 1) + '</span>';
				}
			}
		})();
		</script>

		<style type="text/css">
			a {
				text-decoration: underline;
			}
			img {
				border: solid 1px #888;
			}
		</style>
	</head>
	<body>
		<h1>Lua card game framework</h1>
		<fieldset style='width: 700px;'>
			<legend>Info</legend>
			<p>For some time now, I've been working on a webpage for card game creation called <a href='http://tonesoftales.com'>TonesOfTales</a>. There's a lot of progress going on, and for showcase I've made two games: Casino (Swedish version) and <a href='https://www.youtube.com/watch?v=pTqyUQlCGr8'>Palace</a> (also known as "shithead"). 
			<p> On TonesOfTales, every user can upload cards and decks, and then control the rules of the game using scripting language <a href='http://www.lua.org'>Lua</a>. In other words, there's an open API.</p>
			<p>Here's a small code-snippet on how it might look like:</p>
			<div class='tutorial'><pre class='lua' style='background-color: white;'>
shuffle(deck1)
set_values(deck1)

<span class='lua-comment'>-- Deal for players</span>
<span class='lua-keyword'>for</span> _, p <span class='lua-keyword'>in</span> <span class='lua-builtin'>ipairs</span>(players) <span class='lua-keyword'>do</span>
	deal_player(p)
	p.picked_cards = {}
	p.points = <span class='lua-number'>0</span>
<span class='lua-keyword'>end</span>

<span class='lua-comment'>-- Place deck on table</span>
table_slots[<span class='lua-number'>1</span>] = deck1

<span class='lua-comment'>-- Deal on table</span>
<span class='lua-keyword'>for</span> i = <span class='lua-number'>1</span>, <span class='lua-number'>4</span> <span class='lua-keyword'>do</span>
	<span class='lua-keyword'>local</span> card = draw_card()
	card.facing = <span class='lua-string'>"up"</span>
	<span class='lua-builtin'>table.insert</span>(table_slots, card)
<span class='lua-keyword'>end</span>

update_table()
			</pre></div>
			<p>And here's what it looks like in action:</p>
			<img src='/img/luacardgame_example.png' />
			<p>If you want to know more, you can read the <a href='http://tonesoftales.com/cgi-bin/drakskatten?op=doc_tutorials&module=startpage'>tutorials</a> (there's even a couple of videos there).</p>
			<p>It's free to <a href='/register.php'>register</a>.</p>
			<p>If you need any help, you can find my contact information under "Contact" in the menu (visible at <a href='/login.php'>login</a>).</p>
		</fieldset>
	</body>
</html>
