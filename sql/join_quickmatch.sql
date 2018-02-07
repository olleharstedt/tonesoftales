-- Procedure to join and/or create a game session through the quickmatch system
DROP PROCEDURE join_quickmatch;

DELIMITER //
CREATE PROCEDURE join_quickmatch
(IN _user_id INT, IN _game_id INT, OUT _port INT, OUT _game_session_id INT, OUT _creator BOOL)
-- Comment below too big for MySQL at server.
-- COMMENT 'Try to join a quickmatch game session for game @_game_id and user @_user_id. Return port of joined/created session.'
BEGIN

	START TRANSACTION;

	SET _creator = FALSE;

	## Get first session available
	SELECT
		gs.id, gs.port INTO _game_session_id, _port
	FROM
		ds_game_session AS gs
		JOIN ds_game AS g ON g.id = gs.game_id
	WHERE
		gs.game_id = _game_id AND
		gs.quickmatch = TRUE AND
		gs.created != 0 AND		-- Consistency check
		gs.created > DATE_SUB(NOW(), INTERVAL 10 MINUTE) AND	-- Disregard old sessions
		gs.started = 0 AND		-- Session must NOT been started
		gs.ended = 0 AND			-- Session must NOT have ended
		gs.websocket_connected = true AND			-- Websocket connection must be online
		(SELECT
			COUNT(*)
		FROM
			ds_participates
		WHERE
			game_session_id = gs.id) < g.max_players
	LIMIT 1;

	## No game session found, create a new one
	IF ISNULL(_game_session_id) THEN

		SET _port = get_new_port();
		SET _creator = TRUE;

		## No free game session present, create a new one and return the id
		INSERT INTO ds_game_session(
			user_id,
			game_id,
			port,
			quickmatch,
			created)
		VALUES (
			_user_id,
			_game_id,
			_port,
			TRUE,
			NOW()
		);

		SET _game_session_id = last_insert_id();

	END IF;

	## Session ready to join! Return port so we can connect to it

	COMMIT;

END;
//
DELIMITER ;
