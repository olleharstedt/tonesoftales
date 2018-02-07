<?php

/**
	Secure SSL login procedure
	Copy of that in OCaml
	Replaces that in OCaml

	Same page for both form and POST

	TODO: Limit tries to ten

	@since 2013-06-28
*/


if (isset($_POST['op']) && $_POST['op'] == "login") {
	$begin_salt = "asdflkj4taertuioafga";
	$end_salt = "asdflkjh435948509809dfasdf09a8sdf";

	$config_xml = simplexml_load_file("/home/d37433/config.xml");
	$db_user = $config_xml->database->user;
	$db_host = $config_xml->database->host;
	$db_database = $config_xml->database->database;
	$db_pwd = $config_xml->database->password;

	$homepage_addr = $config_xml->homepage->hostname;

	$pdo = new PDO(
		"mysql:host=$db_host;dbname=$db_database",
		$db_user,
		$db_pwd
	);
	$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

	// Get password
	$username = $_POST['username'];
	$pwd = $begin_salt . $_POST['password'] . $end_salt;
	$pwd_md5 = md5($pwd);

	$stmt = $pdo->prepare("SELECT username, id, password, email FROM ds_user WHERE username = ?");
	$stmt->execute(array($username));
	$result = $stmt->fetchAll(PDO::FETCH_ASSOC);

	// Abort if there is no user
	if (!$result) {
		echo "No such user: " . $username;
		exit;
	}

	// Check password
	if ($result[0]['password'] == $pwd_md5) {
		// Login ok

		// First, delete all old cookies in db
		$user_id = $result[0]['id'];
		$stmt = $pdo->prepare("DELETE FROM ds_user_cookie WHERE user_id = ?");

		try {
			$stmt->execute(array($user_id));
		}
		catch (exception $e) {
			echo "Could not delete old session: " . $e->getMessage();
			exit;
		}

		// Create new session cookie indb
		$session_id = mt_rand(0, 999999999);
		$stmt = $pdo->prepare("INSERT INTO ds_user_cookie(user_id, datetime, login_session_id) VALUES(?, ?, ?)");

		try {
			$stmt->execute(array($user_id, date("Y-m-d H:i:s"), $session_id));
		}
		catch (exception $e) {
			echo "Login failed: " . $e->getMessage();
			exit;
		}

		// Set cookies in browser
		setcookie("username", $username, time() + (60 * 60 * 24), "/");
		setcookie("session_id", $session_id, time() + (60 * 60 * 24), "/");

		echo "Login ok. Redirecting... (or press <a href='http://$homepage_addr/cgi-bin/drakskatten?op=startpage&module=startpage'>here</a>).<br />";

		// Redirect

		header("Location: http://$homepage_addr/cgi-bin/drakskatten?op=startpage&module=startpage");
		/*
		echo "<script>
			window.location.href = \"http://$homepage_addr/cgi-bin/drakskatten?op=startpage&module=startpage\"
		</script>";
		*/

		exit;
	}
	else {
		echo "Wrong password and/or username";
		exit;
	}


	exit;
}

?>

<html>
	<head>
		<title>Tones of Tales - Login</title>
		<link rel='stylesheet' href='css/style.css' type='text/css'>
		<script type='text/javascript' src='/js/jquery-1.9.1.min.js'></script>
		<script type='text/javascript' src='/js/tool.js'></script>
		<script type='text/javascript' src='/js/drakskatten.js'></script>
	</head>
	<body>
		<div id=menu><a href='drakskatten?op=home&module=startpage'><img src='/img/home.jpg' /> Home</a>
		<a href='drakskatten?op=doc&module=startpage'><img src='/img/doc.jpg' /> Documentation</a>
		<a href='drakskatten?op=contact&module=startpage'><img src='/img/talk.jpg' /> Contact</a>
		<a href='http://%s/login.php'><img src='/img/login.png' /> Login</a>
		<a href='http://%s/register.php'><img src='/img/checkbox.png' /> Register account</a>
		</div>
		<h2>Tones of Tales - Login</h2>
		<fieldset style='width: 700px;'>
			<legend><b>Login</b></legend>
			<form method=post action=/login.php>
				<input type=hidden name=op value=login />
				<input type=hidden name=module value=user />
				<table>
					<tr>
						<th style='text-align: right;'>Username</th>
						<td><input type=text name=username maxlength=100/></td>
					</tr>
					<tr>
						<th style='text-align: right;'>Password</th>
						<td><input type=password name=password maxlength=100/></td>
					</tr>
					<tr>
						<td></td>
						<td><input class='button' type=submit value=Login></td>
					</tr>
					<tr>
						<td></td>
						<td class=note><span href='' class=anchor onclick='window.location.href="/cgi-bin/drakskatten?op=register_form&module=user";'>Register</span> an account, or login as <span class=anchor onclick='guest_login(); return false;'>guest</span>.</td>
					</tr>
				</table>
			</form>
		</fieldset>
	</body>
</html>
