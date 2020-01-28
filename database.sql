/*
    Manual Database Setup File
*/
CREATE DATABASE IF NOT EXISTS `msync`;

USE `msync`;

CREATE TABLE IF NOT EXISTS `tbl_msyncdb_version` ( `version` float NOT NULL );

CREATE TABLE IF NOT EXISTS `tbl_msync_servers` (
    `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `server_name` VARCHAR(55) NOT NULL,
    `options` VARCHAR(100) NOT NULL DEFAULT '[]',
    `ip` INT NOT NULL,
    `port` VARCHAR(5) NOT NULL,
    `server_group` INT NOT NULL,
    UNIQUE INDEX `server_UNIQUE` (`ip`, `port`)
);

CREATE TABLE IF NOT EXISTS `tbl_server_grp` (
    `p_group_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `group_name` VARCHAR(15) NOT NULL,
    UNIQUE INDEX `group_UNIQUE` (`group_name`)
);

CREATE TABLE IF NOT EXISTS `tbl_users` (
    `p_user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `steamid` VARCHAR(20) NOT NULL,
    `steamid64` VARCHAR(17) NOT NULL,
    `nickname` VARCHAR(30) NOT NULL,
    `joined` DATETIME NOT NULL,
    UNIQUE INDEX `steamid_UNIQUE` (`steamid`),
    UNIQUE INDEX `steamid64_UNIQUE` (`steamid64`)
);

CREATE TABLE IF NOT EXISTS `tbl_mbsync` (
    `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `userid` INT UNSIGNED NOT NULL,
    `adminid` INT UNSIGNED NOT NULL,
    `reason` VARCHAR(45) NOT NULL,
    `date_unix` float NOT NULL,
    `lenght_unix` float NOT NULL,
    `server_group` INT UNSIGNED NOT NULL,
    `ban_lifted` INT UNSIGNED,
    FOREIGN KEY (server_group) REFERENCES tbl_server_grp(p_group_id),
    FOREIGN KEY (userid) REFERENCES tbl_users(p_user_id),
    FOREIGN KEY (adminid) REFERENCES tbl_users(p_user_id)
);

CREATE TABLE IF NOT EXISTS `tbl_mrsync` (
    `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `rank` VARCHAR(15) NOT NULL,
    `server_group` INT UNSIGNED NOT NULL,
    FOREIGN KEY (server_group) REFERENCES tbl_server_grp(p_group_id),
    FOREIGN KEY (user_id) REFERENCES tbl_users(p_user_id),
	UNIQUE INDEX `user_UNIQUE` (`user_id`, `server_group`)
);

CREATE TABLE IF NOT EXISTS `tbl_mws` (
    `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `userid` INT UNSIGNED NOT NULL,
    `adminid` INT UNSIGNED NOT NULL,
    `reason` VARCHAR(45) NOT NULL,
    `date_unix` float NOT NULL,
    `expire` float NOT NULL,
    `server_group` INT UNSIGNED NOT NULL,
    FOREIGN KEY (server_group) REFERENCES tbl_server_grp(p_group_id),
    FOREIGN KEY (userid) REFERENCES tbl_users(p_user_id),
    FOREIGN KEY (adminid) REFERENCES tbl_users(p_user_id)
);

CREATE TABLE IF NOT EXISTS `tbl_mrs` (
    `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `userid` INT UNSIGNED NOT NULL,
    `adminid` INT UNSIGNED NOT NULL,
    `resolved` BOOLEAN DEFAULT FALSE,
    `message` VARCHAR(100) NOT NULL,
    `server_group` INT UNSIGNED NOT NULL,
    FOREIGN KEY (server_group) REFERENCES tbl_server_grp(p_group_id),
    FOREIGN KEY (userid) REFERENCES tbl_users(p_user_id),
    FOREIGN KEY (adminid) REFERENCES tbl_users(p_user_id)
);

CREATE TABLE IF NOT EXISTS `tbl_musync` (
    `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `userid` INT UNSIGNED NOT NULL,
    `time` INT UNSIGNED NOT NULL,
    `server_group` INT UNSIGNED NOT NULL,
    FOREIGN KEY (server_group) REFERENCES tbl_server_grp(p_group_id),
    FOREIGN KEY (userid) REFERENCES tbl_users(p_user_id)
);