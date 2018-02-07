-- Procedure to login as guest
-- Login with free guest account, or create new one if no free is found
DROP PROCEDURE get_guest_account;

DELIMITER //
CREATE PROCEDURE get_guest_account
(OUT user_id INT)
BEGIN

	START TRANSACTION;

	SELECT
		u.id INTO user_id
	FROM
		ds_user AS u
		LEFT JOIN ds_user_cookie AS cookie ON u.id = cookie.user_id
	WHERE
		u.guest_account = true AND
		-- Either old cookie or no cookie
		(cookie.datetime < DATE_SUB(NOW(), INTERVAL 1 DAY) OR ISNULL(cookie.datetime))
	ORDER BY
		u.id ASC
	LIMIT 1
	;

	IF ISNULL(user_id) THEN
		## No free guest account found, create a new
		SET user_id = (SELECT id FROM ds_user ORDER BY id DESC LIMIT 1) + 1;
		INSERT INTO ds_user(id, username, password, email, guest_account) VALUES (
			NULL, 
			CONCAT('guest', user_id),
			UUID(),	-- Random password
			CONCAT('guestmail', user_id),
				TRUE
			);
		-- Fetch user id (double check)
		SET user_id = LAST_INSERT_ID();
	END IF;

	COMMIT;

END;
//
DELIMITER ;
