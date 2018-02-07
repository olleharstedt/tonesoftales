<?php

	$config_xml = simplexml_load_file("/home/d37433/config.xml");
	/*
	$db_user = $config_xml->database->user;
	$db_host = $config_xml->database->host;
	$db_database = $config_xml->database->database;
	$db_pwd = $config_xml->database->password;
	*/

	$homepage_addr = $config_xml->homepage->hostname;

?>

<html>
	<head>
		<!--Tradedoubler site verification 2337181 -->
		<title>Tones of Tales</title>
		<meta charset='utf-8'>
		<meta name='description' content="Tones of Tales is a web page dedicated to online card gaming and online card game creation. Login as guest or register an account, it's free!" />
		<link rel='stylesheet' href='css/style.css' type='text/css'>
		<link rel='stylesheet' href='css/jquery.galleryview-3.0-dev.css' type='text/css'>
		<script type='text/javascript' src='/js/jquery-1.9.1.min.js'></script>
		<script type='text/javascript' src='/js/jquery.timers-1.2.js'></script>
		<script type='text/javascript' src='/js/jquery.galleryview-3.0-dev.js'></script>
		<script type='text/javascript' src='/js/tool.js'></script>
		<script type='text/javascript' src='/js/drakskatten.js'></script>
		<style type="text/css">
			a {
				text-decoration: underline;
			}
			fieldset {
				width: 700px;
			}
		</style>
		<script>
			$(document).ready(function() {
				$('#slideshow').galleryView({
					panel_width: 500,
					panel_height: 500,
					show_captions: true,
					enable_overlays: true,
					panel_scale: 'fit'
				});
			});
		</script>
	</head>
	<body>
		<!-- Some facebook stuff -->
		<div id="fb-root"></div>
		<script>(function(d, s, id) {
			var js, fjs = d.getElementsByTagName(s)[0];
			if (d.getElementById(id)) return;
			js = d.createElement(s); js.id = id;
			js.src = "//connect.facebook.net/en_US/all.js#xfbml=1";
			fjs.parentNode.insertBefore(js, fjs);
		}(document, 'script', 'facebook-jssdk'));</script>
		<h1>Tones of Tales</h1>
		<fieldset>
			<legend>Introduction</legend>
			<p>Welcome to Tones of Tales! A site dedicated to card games and game making. All games are multiplayer, <a href='/cgi-bin/drakskatten?op=sourcecode&module=startpage'>open source</a> and uses HTML5.</p>
		</fieldset>
		<br />
		<ul id='slideshow'>
			<li><img src='/img/backgammon2.jpg' title='Backgammon' data-description='A classic boardgame if there ever was one.' /></li>
			<li><img src='/img/snakes.png' title='Snakes' data-description='A game we all learned to love from the early Nokia telephones. Now with multiplayer!' /></li>
			<li><img src='/img/holdem.jpg' title='Texas holdem' data-description='The most popular poker game online right now. This is the "no-limit" version.'/></li>
			<li><img src='/img/yatzy.jpg' title='Yatzy' data-description='The scandinavian version of Yahtzee. Go for five of a kind!' /></li>
			<li><img src='/img/palace.jpg' title='Palace' data-description='Also known as "shithead", a known party game.' /></li>
			<li><img src='/img/kasino.jpg' title='Casino' data-description='Pick as few cards as possible. Watch out for ten of diamonds and two of spades!' /></li>
			<li><img src='/img/31b.jpg' title='31' data-description='The classic game 31. Knock when you have high points in the same suit.' /></li>
			<li><img src='/img/simplepoker.jpg' title='Simple poker' data-description='A simple demonstration.' /></li>
		</ul>
		<br />
		<?php include('/home/d37433/templates/login.tmpl'); ?>
		<p><div class="fb-like" data-href="http://tonesoftales.com" data-colorscheme="light" data-layout="standard" data-action="like" data-show-faces="true" data-send="false"></div></p>
		<fieldset>
			<legend>Compatibility</legend>
		<p>This site make use of HTML5 features, so please make sure you have an updated browser (preferably Firefox, Chrome or Opera).</p>
		</fieldset>
		<p>Play the classic cardgame 31 with three friends:</p>
		<iframe width="640" height="360" src="//www.youtube.com/embed/7zlXZXsY5SA?list=PL5dwSu68V04g3yHiKB3CL0b5b_6OkEp-J" frameborder="0" allowfullscreen></iframe>
		<br />
		<br />
		<fieldset>
			<legend>Developing a card game</legend>
			<p>This homepage features an open API, meaning that you yourself can create games like the ones already present. This is done using the well-known scripting language <a href='http://www.lua.org/about.html'>Lua</a>. See the <a href='/cgi-bin/drakskatten?op=doc_tutorials&module=startpage'>tutorials</a> for more information on how to get started.</p>
			<p>All card games created by the site developer are available as open source. Check it out <a href='/cgi-bin/drakskatten?op=sourcecode&module=startpage'>here</a>.</p>
		</fieldset>
	</body>
</html>
