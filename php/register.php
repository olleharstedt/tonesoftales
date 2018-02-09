<?php

/**
	@since 2013-06-28
*/

if (isset($_POST['op']) && $_POST['op'] == "create_user") {

	$username = htmlspecialchars($_POST['username']);
	$email = $_POST['email'];
	
	if(preg_match("/[^\w-.]/", $username)){
		    // invalid character
		echo "Username contains invalid characters. Only a-z, A-Z, 0-9 allowed";
		exit;
	}

	if(!filter_var($email, FILTER_VALIDATE_EMAIL)) {
		// either invalid email, or it contains in @yahoo.com
		echo "Invalid email";
		exit;
	}

	// Check username length
	if (strlen($username) < 4) {
		echo "Username too short. Must be at least 4 characters";
		exit;
	}

	// Check robot check
	if (substr($username, 0, 4) != $_POST['robot']) {
		// Abort
		echo "Robot question error. Check your username and that you really wrote the first four letters of it in the robot question field.";
		exit;
	}

	// Check password length
	if (strlen($_POST['password']) < 6) {
		echo "Password must be at least 6 characters";
		exit;
	}

	// Check email
	if (strlen($_POST['email']) < 4) {
		echo "No email found";
		exit;
	}

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

	$pwd = $begin_salt . $_POST['password'] . $end_salt;
	$pwd_md5 = md5($pwd);
	$email = $_POST['email'];

	// Check that username is not taken
	$stmt = $pdo->prepare("SELECT id FROM ds_user WHERE username = ?");
	$stmt->execute(array($username));
	$result = $stmt->fetchAll(PDO::FETCH_ASSOC);
	if ($result) {
		echo "Username is taken: " . $username;
		exit;
	}

	// Check that email is not taken
	$stmt = $pdo->prepare("SELECT email FROM ds_user WHERE email = ?");
	$stmt->execute(array($email));
	$result = $stmt->fetchAll(PDO::FETCH_ASSOC);
	if ($result) {
		echo "E-mail is taken. Please provide another e-mail address.";
		exit;
	}

	// Save user
	$stmt = $pdo->prepare("INSERT INTO ds_user(username, password, email, newsletter) VALUES(?, ?, ?, ?)");
	try {
		$stmt->execute(array($username, $pwd_md5, $email, (int) $_POST['newsletter'] == "on"));
		echo "Account registred. Please <a href='/cgi-bin/drakskatten?op=login_form&module=user'>login</a> to proceed.<br>";

	}
	catch (exception $e) {
		echo "Error: " . $e->getMessage();
	}

	exit;
}

?>


<html>
	<head>
		<title>Tones of Tales - Register</title>
		<link rel='stylesheet' href='css/style.css' type='text/css'>
		<style>
			.td {
				text-align: right;
			}
		</style>
	</head>
	<body>
		<h2>Tones of Tales - Register</h2>
		<p style='width: 700px;'>This will register a new account on Tones of Tales, which gives you opportunity to play cards and more games with other users, and even make your own games.</p>
		<fieldset style='width: 700px;'>
			<legend><b>Register</b></legend>
			<form method=post action=/register.php>
				<input type=hidden name=op value=create_user />
				<input type=hidden name=module value=user />
				<table>
					<tr>
						<th class='td'>Username</th>
						<td><input type=text name=username maxlength=100/></td>
					<tr>
					<tr>
						<th class='td'> Password</th>
						<td><input type=password name=password maxlength=100/></td>
					</tr>
					<tr>
						<th class='td'>Email</th>
						<td><input type=text name=email maxlength=100/></td>
					</tr>
					<tr>
						<th class='td'>Newsletter</th>
						<td><input type=checkbox name=newsletter /></td>
						<td class='note'>Check if you want to receive information about new games and features</td>
					</tr>
					<tr>
						<th class='td'>Robot check</th>
						<td><input type=text name=robot maxlength=4/></td>
						<td class='note'>Type the four first letters of your username</td>
					</tr>
					<tr>
						<td></td>
						<td><input class='button' type=submit value="Register account"></td>
					</tr>
				</table>
			</form>
		</fieldset>
	</body>
</html>
