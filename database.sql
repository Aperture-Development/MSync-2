/*
    Manual Database Setup File
*/
CREATE DATABASE IF NOT EXISTS 'msync';

CREATE TABLE IF NOT EXISTS 'tbl_msyncdb_version' ( 'version' float NOT NULL );

CREATE TABLE IF NOT EXISTS 'tbl_msync_servers' (
	'id' INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    'server_name' VARCHAR(15) NOT NULL,
    'options' VARCHAR(100) NOT NULL DEFAULT '[]',
    'server_group' VARCHAR(45)
);

CREATE TABLE IF NOT EXISTS 'tbl_users' (
    'user_id' INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    'steamid' VARCHAR(20) NOT NULL,
    'steamid64' VARCHAR(17) NOT NULL,
    'nickname' VARCHAR(30) NOT NULL,
    'joined' DATETIME NOT NULL,
);

CREATE TABLE IF NOT EXISTS 'tbl_mbsync' (
    'id' INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    'userid' INT UNSIGNED NOT NULL,
    'adminid' INT UNSIGNED NOT NULL,
    'reason' VARCHAR(45) NOT NULL,
    'date_unix' float NOT NULL,
    'lenght_unix' float NOT NULL
);

CREATE TABLE IF NOT EXISTS 'tbl_mrsync' (
    'id' INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    'user_id' INT UNSIGNED NOT NULL,
    'rank' VARCHAR(15) NOT NULL,
    'server_group' VARCHAR(45)
);

CREATE TABLE IF NOT EXISTS 'tbl_mws' (
    'id' INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    'userid' INT UNSIGNED NOT NULL,
    'adminid' INT UNSIGNED NOT NULL,
    'reason' VARCHAR(45) NOT NULL,
    'date_unix' float NOT NULL,
    'expire' float NOT NULL
);

CREATE TABLE IF NOT EXISTS 'tbl_mrs' (
    'id' INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    'userid' INT UNSIGNED NOT NULL,
    'adminid' INT UNSIGNED NOT NULL,
    'resolved' BOOLEAN DEFAULT FALSE,
    'message' VARCHAR(100) NOT NULL
);