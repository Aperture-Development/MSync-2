-- Table to hold all ban data
CREATE TABLE IF NOT EXISTS `tbl_mbsync` (
    `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `admin_id` INT UNSIGNED NOT NULL,
    `reason` VARCHAR(100) NOT NULL,
    `date_unix` INT UNSIGNED NOT NULL,
    `length_unix` INT UNSIGNED NOT NULL,
    `server_group` INT UNSIGNED NOT NULL,
    `ban_lifted` INT UNSIGNED,
    FOREIGN KEY (server_group) REFERENCES tbl_server_grp(p_group_id),
    FOREIGN KEY (user_id) REFERENCES tbl_users(p_user_id),
    FOREIGN KEY (admin_id) REFERENCES tbl_users(p_user_id)
);

-- Insert MSync db version
INSERT INTO tbl_msyncdb_version (`version`, module_id)
SELECT * FROM (
    SELECT 1 AS `version`, 'mbsync' AS mod_id UNION
    SELECT 0 AS `version`, 'mbsync_data' AS mod_id
) AS dataQuery
ON DUPLICATE KEY UPDATE module_id=mod_id;

/*
######################################
AUTOMATIC TRIGGERS
######################################
*/
-- Create trigger to update data versions
CREATE TRIGGER insert_mbsync_data_version
    AFTER INSERT
    ON tbl_mbsync FOR EACH ROW
BEGIN
    CALL msync_updateDB('mbsync_data')
END

-- Create trigger to update data versions
CREATE TRIGGER update_mbsync_data_version
    AFTER UPDATE
    ON tbl_mbsync FOR EACH ROW
BEGIN
    CALL msync_updateDB('mbsync_data')
END

-- Create trigger to update data versions
CREATE TRIGGER delete_mbsync_data_version
    AFTER DELETE
    ON tbl_mbsync FOR EACH ROW
BEGIN
    CALL msync_updateDB('mbsync_data')
END

/*
# Adds a new ban to the database
INSERT INTO `tbl_mbsync` (user_id, admin_id, reason, date_unix, length_unix, server_group)
SELECT UserTbl.p_user_id, AdminTbl.p_user_id, ?, ?, ?, tbl_server_grp.p_group_id
FROM tbl_users AS UserTbl, tbl_users AS AdminTbl, tbl_server_grp
WHERE
    (
        UserTbl.steamid=? AND
        UserTbl.steamid64=?
    )
AND
    (
        AdminTbl.steamid=? AND
        AdminTbl.steamid64=?
    )
AND
    tbl_server_grp.group_name=?;

# Updates an existing ban with new data
UPDATE `tbl_mbsync`
SET 
    reason=?,
    length_unix=(UNIX_TIMESTAMP() - date_unix) + ?,
    admin_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?),
    server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
WHERE p_ID=?

# Unbans a user
UPDATE `tbl_mbsync`
SET ban_lifted=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?)
WHERE p_ID=?

# Unbans a user based on other factors
UPDATE `tbl_mbsync`
SET 
    ban_lifted=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?)
WHERE 
    user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? OR steamid64=?) AND 
    server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?) AND
    ((date_unix + length_unix) >= ? OR length_unix = 0) AND
    ban_lifted IS NULL

# Query to get all bans as table
SELECT 
    tbl_mbsync.p_id, 
    tbl_mbsync.reason, 
    tbl_mbsync.date_unix,
    tbl_mbsync.length_unix,
    banned.steamid AS "banned.steamid",
    banned.steamid64 AS "banned.steamid64",
    banned.nickname AS "banned.nickname",
    admin.steamid AS "admin.steamid",
    admin.steamid64 AS "admin.steamid64",
    admin.nickname AS "admin.nickname",
    unban_admin.steamid AS "unban_admin.steamid",
    unban_admin.steamid64 AS "unban_admin.steamid64",
    unban_admin.nickname AS "unban_admin.nickname",
    tbl_server_grp.group_name
FROM `tbl_mbsync`
LEFT JOIN tbl_server_grp 
    ON tbl_mbsync.server_group = tbl_server_grp.p_group_id
LEFT JOIN tbl_users AS banned 
    ON tbl_mbsync.user_id = banned.p_user_id
LEFT JOIN tbl_users AS admin 
    ON tbl_mbsync.admin_id = admin.p_user_id
LEFT JOIN tbl_users AS unban_admin 
    ON tbl_mbsync.ban_lifted = unban_admin.p_user_id

# Query to get all active bans
SELECT 
    tbl_mbsync.*,
    banned.steamid,
    banned.steamid64,
    banned.nickname AS "banned.nickname",
    admin.nickname AS "admin.nickname"
FROM `tbl_mbsync`
LEFT JOIN tbl_users AS banned
    ON tbl_mbsync.user_id = banned.p_user_id
LEFT JOIN tbl_users AS admin
    ON tbl_mbsync.admin_id = admin.p_user_id
WHERE
    ban_lifted IS NULL AND
    (
        (date_unix+length_unix)>? OR
            length_unix=0
    ) AND
    (
        server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?) OR
        server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name="allservers")
    )
*/