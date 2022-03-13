-- Table for modules to determine their Database versions
CREATE TABLE IF NOT EXISTS `tbl_msyncdb_version` ( 
    `version` INT UNSIGNED NOT NULL, 
    `module_id` VARCHAR(25) NOT NULL,
    UNIQUE INDEX `module_UNIQUE` (`module_id`)
);

-- Table for Server grouping
CREATE TABLE IF NOT EXISTS `tbl_server_grp` (
    `p_group_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `group_name` VARCHAR(15) NOT NULL,
    UNIQUE INDEX `group_UNIQUE` (`group_name`)
);

-- Table for all servers
CREATE TABLE IF NOT EXISTS `tbl_msync_servers` (
    `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `server_name` VARCHAR(75) NOT NULL,
    `options` VARCHAR(100) NOT NULL DEFAULT '[]',
    `ip` VARCHAR(15) NOT NULL,
    `port` VARCHAR(5) NOT NULL,
    `server_group` INT UNSIGNED NOT NULL,
    FOREIGN KEY (server_group) REFERENCES tbl_server_grp(p_group_id),
    UNIQUE INDEX `server_UNIQUE` (`ip`, `port`)
);

-- Table for all users. Mudules should reference this table instead of saving the steamid
CREATE TABLE IF NOT EXISTS `tbl_users` (
    `p_user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `steamid` VARCHAR(20) NOT NULL,
    `steamid64` VARCHAR(17) NOT NULL,
    `nickname` VARCHAR(30) NOT NULL,
    `joined` DATETIME NOT NULL,
    UNIQUE INDEX `steamid_UNIQUE` (`steamid`),
    UNIQUE INDEX `steamid64_UNIQUE` (`steamid64`)
);

-- Insert default user for console queries. As the console doesnt run as user, we use STEAM_0:0:0 ( non existzing SteamID ) for the console user
INSERT INTO `tbl_users` (steamid, steamid64, nickname, joined)
SELECT * FROM (SELECT 'STEAM_0:0:0', '76561197960265728', '(CONSOLE)' AS newUser, '2004-12-24 12:00:00') AS dataQuery
ON DUPLICATE KEY UPDATE nickname=newUser;

-- Insert default group for all servers into the database. allservers is a context used to state a dataset should be synced no matter the server group
INSERT INTO `tbl_server_grp` (group_name)
SELECT * FROM (SELECT 'allservers' AS newGroup) AS dataQuery
ON DUPLICATE KEY UPDATE group_name=newGroup;
/*
######################################
THIS PART IS STILL WORK IN PROGRESS
WE ARE REPLACING INSERT QUERIES WITH INSERTS
TO PREVENT AUTO_INCREMENT GAPS AS GOOD AS POSSIBLE
######################################

-- Procedure to create a new user ( or update an existing one )
CREATE PROCEDURE msync_createUser(IN pro_steamid VARCHAR(20), IN pro_steamid64 VARCHAR(17), IN pro_nickname VARCHAR(30), IN pro_joined DATETIME)
BEGIN
    IF EXISTS(SELECT p_user_id FROM tbl_users WHERE steamid64=pro_steamid64 AND steamid=pro_steamid) THEN
        -- check nickname
        IF (SELECT nickname FROM tbl_users WHERE steamid64=pro_steamid64) != pro_nickname THEN
            UPDATE tbl_users SET nickname=pro_nickname WHERE steamid64=pro_steamid64;
        END IF;
    ELSE
        -- CREATE USER
        INSERT INTO tbl_users (steamid, steamid64, nickname, joined )
        VALUES (
            pro_steamid,
            pro_steamid64,
            pro_nickname,
            pro_joined
        );
    END IF;
END

-- Procedure to create a new server ( or update an existing one )
CREATE PROCEDURE msync_createServer(IN pro_serverName VARCHAR(75), IN pro_ip VARCHAR(15), IN pro_port VARCHAR(5),IN pro_serverGroup VARCHAR(15))
BEGIN
	IF pro_serverName IS NULL OR pro_ip IS NULL OR pro_port IS NULL OR pro_serverGroup IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NULL is not allowed.';
    END IF;
    
    IF EXISTS(SELECT p_id FROM tbl_msync_servers WHERE `ip`=pro_ip AND `port`=pro_port) THEN
        -- check server name
        IF (SELECT server_name FROM tbl_msync_servers WHERE `ip`=pro_ip AND `port`=pro_port) != pro_serverName THEN
            UPDATE tbl_msync_servers SET server_name=pro_serverName WHERE `ip`=pro_ip AND `port`=pro_port;
        END IF;
        
        -- Check server group
        IF EXISTS(SELECT p_group_id FROM tbl_server_grp WHERE group_name=pro_serverGroup) THEN
			IF (SELECT server_group FROM tbl_msync_servers WHERE `ip`=pro_ip AND `port`=pro_port) != (SELECT p_group_id FROM tbl_server_grp WHERE group_name=pro_serverGroup) THEN
				UPDATE tbl_msync_servers SET server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=pro_serverGroup) WHERE `ip`=pro_ip AND `port`=pro_port;
			END IF;
		END IF;
    ELSE
        -- Create Server
        INSERT INTO `tbl_msync_servers` (server_name, ip, `port`, server_group)
		SELECT * FROM (
			SELECT pro_serverName, pro_ip, pro_port, tbl_server_grp.p_group_id
			FROM tbl_server_grp
			WHERE
				tbl_server_grp.group_name=pro_serverGroup
		) AS dataQuery;
	END IF;
END

-- Procedure to increase a db version number by one
CREATE PROCEDURE msync_updateDB(IN pro_mod_id VARCHAR(25))
BEGIN
	IF EXISTS(SELECT `version` FROM tbl_msyncdb_version WHERE module_id=pro_mod_id) THEN
		UPDATE tbl_msyncdb_version SET `version` = `version` + 1 WHERE module_id=pro_mod_id;
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Module does not exist';
	END IF;
END
*/

/*
# This query inserts a new user into the database
INSERT INTO `tbl_users` (steamid, steamid64, nickname, joined)
SELECT * FROM (SELECT ? AS steamid, ? AS steamid64, ? AS newNick, ? AS joined) AS dataQuery
ON DUPLICATE KEY UPDATE nickname=newNick;

# This query inserts a new server group into the database
INSERT INTO `tbl_server_grp` (group_name) 
SELECT * FROM (SELECT ? AS newGroup) AS dataQuery
ON DUPLICATE KEY UPDATE group_name=newGroup;

# This query inserts a new server into the database
INSERT INTO `tbl_msync_servers` (server_name, ip, `port`, server_group)
SELECT * FROM (
    SELECT ? AS newServerName, ? AS ip, ? AS `port`, tbl_server_grp.p_group_id AS newGroup
    FROM tbl_server_grp
    WHERE
        tbl_server_grp.group_name=?
) AS dataQuery
ON DUPLICATE KEY UPDATE server_name=newServerName, server_group=newGroup;
*/