-- Table for punishment types
CREATE TABLE IF NOT EXISTS mws_punishment_types (
    p_type_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(10) NOT NULL,
    UNIQUE KEY type_UNIQUE(type_name)
);

-- Table to hold all punishments
CREATE TABLE IF NOT EXISTS mws_punishments (
    p_punishment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    f_type_id BIGINT UNSIGNED NOT NULL,
    `data` TEXT,
    `warn_count` INT UNSIGNED NOT NULL,
    FOREIGN KEY (f_type_id) REFERENCES mws_punishment_types(p_type_id) ON DELETE CASCADE,
);

-- Table to hold all warns ( backlog 
-- Warns are only to be set to inactive if a certain period of time passed since the last warn
CREATE TABLE IF NOT EXISTS mws_warns (
    p_warn_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    f_user_id INT UNSIGNED NOT NULL,
    f_admin_id INT UNSIGNED NOT NULL,
    f_servergrp_id INT UNSIGNED NOT NULL,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    warn_description TEXT NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (f_user_id) REFERENCES tbl_users(p_user_id) ON DELETE CASCADE,
    FOREIGN KEY (f_admin_id) REFERENCES tbl_users(p_user_id) ON DELETE CASCADE,
    FOREIGN KEY (f_servergrp_id) REFERENCES tbl_server_grp(p_group_id) ON DELETE CASCADE
);

-- Table to hold which Punishments have been executed for what warn
CREATE TABLE IF NOT EXISTS mws_user_punished (
    f_punishment_id BIGINT UNSIGNED,
    f_warn_id BIGINT UNSIGNED,
    UNIQUE KEY infraction_UNIQUE(f_punishment_id, f_warn_id),
    FOREIGN KEY (f_punishment_id) REFERENCES mws_punishments(p_punishment_id) ON DELETE CASCADE,
    FOREIGN KEY (f_warn_id) REFERENCES mws_warns(p_warn_id) ON DELETE CASCADE
);

-- Insert Punishment types
INSERT INTO mws_punishment_types (type_name) 
SELECT * FROM (
    SELECT 'kick' AS punishment UNION
    SELECT 'ban' AS punishment UNION
    SELECT 'broadcast' AS punishment UNION
    SELECT 'rank' AS punishment
) AS dataQuery
ON DUPLICATE KEY UPDATE type_name=punishment;

-- Insert MSync db version
INSERT INTO tbl_msyncdb_version (`version`, module_id)
SELECT * FROM (
    SELECT 1 AS `version`, 'mws' AS mod_id UNION
    SELECT 0 AS `version`, 'mws_data' AS mod_id
) AS dataQuery
ON DUPLICATE KEY UPDATE module_id=mod_id;

/*
######################################
AUTOMATIC TRIGGERS
######################################
*/

-- Create trigger to update data versions
CREATE TRIGGER insert_mws_data_version
    AFTER INSERT
    ON mws_warns FOR EACH ROW
BEGIN
    CALL msync_updateDB('mws_data')
END

-- Create trigger to update data versions
CREATE TRIGGER update_mws_data_version
    AFTER UPDATE
    ON mws_warns FOR EACH ROW
BEGIN
    CALL msync_updateDB('mws_data')
END

-- Create trigger to update data versions
CREATE TRIGGER delete_mws_data_version
    AFTER DELETE
    ON mws_warns FOR EACH ROW
BEGIN
    CALL msync_updateDB('mws_data')
END

-- Create trigger to update data versions
CREATE TRIGGER insert_mws_data_version
    AFTER DELETE
    ON mws_warns FOR EACH ROW
BEGIN
    CALL msync_updateDB('mws_data')
END

/*
INSERT INTO mws_warns (f_user_id, f_admin_id, f_servergrp_id, timestamp, warn_description)
SELECT 
    user_tbl.p_user_id AS userId,
    admin_tbl.p_user_id AS adminId,
    tbl_server_grp.p_group_id AS serverGrpId
    ? AS timestamp,
    ? AS description
FROM 
    tbl_users AS user_tbl,
    tbl_users AS admin_tbl,
    tbl_server_grp
WHERE
    (
        user_tbl.steamid = ? AND
        user_tbl.steamid64 = ?
    ) AND (
        admin_tbl.steamid = ? AND
        admin_tbl.steamid64 = ?
    ) AND (
        tbl_server_grp.group_name = ?
    )

INSERT INTO mws_user_punished (f_punishment_id, f_warn_id)
SELECT 
