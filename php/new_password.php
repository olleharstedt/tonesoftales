<?php

/**
	Change your password
*/


if (isset($_POST['op']) && $_POST['op'] == "new_password") {
	$begin_salt = "asdflkj4taertuioafga";
	$end_salt = "asdflkjh435948509809dfasdf09a8sdf";

	$username = $_POST['username'];
	$new_pwd = $_POST['new_password'];
	$retype_pwd = $_POST['retype_password'];
	$robot = $_POST['robot'];

	if (substr($robot, 0, 1) != substr($new_pwd, 0, 1) || substr($robot, -1) != substr($new_pwd, -1)) {
		echo "Robot question error";
		exit;
	}

	if ($new_pwd != $retype_pwd) {
		echo "Error: New password and retype are not the same";
		exit;
	}

	if (strlen($new_pwd) < 5) {
		echo "New password too short. Must be atleast 6 letters.";
		exit;
	}

	// Open db
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

	// Get new and old password
	$old_pwd = $begin_salt . $_POST['old_password'] . $end_salt;
	$old_pwd_md5 = md5($old_pwd);
	$new_pwd = $begin_salt . $new_pwd . $end_salt;
	$new_pwd_md5 = md5($new_pwd);

	$stmt = $pdo->prepare("SELECT username, id, password, email FROM ds_user WHERE username = ?");
	$stmt->execute(array($username));
	$result = $stmt->fetchAll(PDO::FETCH_ASSOC);

	// Abort if there is no user
	if (!$result) {
		echo "No such user: " . $username;
		exit;
	}

	$user_id = $result[0]['id'];

	if ($result[0]['password'] == $old_pwd_md5) {
		$stmt = $pdo->prepare("UPDATE ds_user SET password = ? WHERE id = ?");
		try {
			$stmt->execute(array($new_pwd_md5, $user_id));
		}
		catch (exception $e) {
			echo "Could not save new password: " . $e->getMessage();
			exit;
		}

		echo "New password saved";
		exit;
	}
	else {
		echo "Wrong password and/or username";
		exit;
	}

}

?>

<!DOCTYPE html>
<html>
	<head>
		<title>Tones of Tales - New password</title>
	</head>
	<body>
		<h2>Tones of Tales - New password</h2>
		<fieldset style='width: 500px;'>
			<legend><b>Login</b></legend>
			<form method=post action=/secure/new_password.php>
				<input type=hidden name=op value=new_password />
				<input type=hidden name=module value=user />
				<table>
					<tr>
						<td style='text-align: right;'>Username:</td>
						<td><input type=text name=username maxlength=100/></td>
					</tr>
					<tr>
						<td style='text-align: right;'>Current password:</td>
						<td><input type=password name=old_password maxlength=100/></td>
					</tr>
					<tr>
						<td style='text-align: right;'>New password:</td>
						<td><input type=password name=new_password maxlength=100/></td>
					</tr>
					<tr>
						<td style='text-align: right;'>Retype new password:</td>
						<td><input type=password name=retype_password maxlength=100/></td>
					</tr>
					<tr>
						<td style='text-align: right;'>Robot check:</td>
						<td><input type=password name=robot maxlength=100/></td>
						<td>Type the first and last letters in your NEW password</td>
					</tr>
					<tr>
						<td></td>
						<td><input type=submit value="Create new password"></td>
					</tr>
				</table>
			</form>
		</fieldset>
	</body>
</html>
