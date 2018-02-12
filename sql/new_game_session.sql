DROP PROCEDURE new_game_session;
DROP FUNCTION get_new_port;

DELIMITER //
CREATE FUNCTION get_new_port () RETURNS INT
BEGIN

	DECLARE _port INT DEFAULT 8080;

	## Get next port number
	SELECT 
		port INTO _port 
	FROM 
		ds_game_session 
	ORDER BY 
		created DESC 
	LIMIT 1;

	IF _port > 9999999 THEN
			SET _port = 8080;
	ELSE
			SET _port = _port + 1;
	END IF;

	RETURN _port;

END
//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE new_game_session
(IN user_id int, IN game_id int, IN password varchar(100),
IN public tinyint, IN `comment` varchar(500), IN debug tinyint, OUT id int, OUT out_port INT)
COMMENT 'insert a new game session'
BEGIN
    DECLARE _port INT DEFAULT 8080;

    start transaction;

    ## Get next port number
    SELECT 
			port INTO _port 
		FROM 
			ds_game_session 
		ORDER BY 
			created DESC 
		LIMIT 1;

    if _port > 9999999 then
        set _port = 8080;
    else
        set _port = _port + 1;
    end if;

    INSERT INTO ds_game_session(user_id, game_id, password, public, `comment`, port, debug, created, started, ended)
    VALUES(user_id, game_id, password, public, `comment`, _port, debug, now(), "1900-01-01 00:00:00", "1900-01-01 00:00:00");

    SET id = last_insert_id();
    SET out_port = _port;

    COMMIT;

END
//
DELIMITER ;

