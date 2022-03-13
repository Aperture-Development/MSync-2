-- Table to hold all user ranks
CREATE TABLE IF NOT EXISTS `tbl_mrsync` (
    `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `rank` VARCHAR(15) NOT NULL,
    `server_group` INT UNSIGNED NOT NULL,
    FOREIGN KEY (server_group) REFERENCES tbl_server_grp(p_group_id),
    FOREIGN KEY (user_id) REFERENCES tbl_users(p_user_id),
    UNIQUE INDEX `user_UNIQUE` (`user_id`, `server_group`)
);

-- Insert MSync db version
INSERT INTO tbl_msyncdb_version (`version`, module_id)
SELECT * FROM (
    SELECT 1 AS `version`, 'mrsync' AS mod_id
) AS dataQuery
ON DUPLICATE KEY UPDATE module_id=mod_id;

/*
# Query for adding a users rank to the database
INSERT INTO `tbl_mrsync` (user_id, `rank`, server_group) 
SELECT * FROM (
    SELECT tbl_users.p_user_id, ? AS newRank, tbl_server_grp.p_group_id
    FROM tbl_users, tbl_server_grp
    WHERE
        (
            tbl_users.steamid=? AND tbl_users.steamid64=?
        )
    AND
        tbl_server_grp.group_name=?
) AS dataQuery
ON DUPLICATE KEY UPDATE `rank`=newRank;

# Query to remove all 'allservers' groups from the user
DELETE FROM `tbl_mrsync` WHERE user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?) AND server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers');

# Query to remove all non 'allservers' groups from the user
DELETE FROM `tbl_mrsync` WHERE user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?) AND server_group<>(SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers');

# Query to get someones rank from the database
SELECT `rank` FROM `tbl_mrsync` 
WHERE user_id=(
    SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?
) AND (server_group=(
    SELECT p_group_id FROM tbl_server_grp WHERE group_name=?
) OR server_group=(
    SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers'
))
LIMIT 1;

# Query to delete a users rank from the database
DELETE FROM `tbl_mrsync` WHERE 
user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?) AND 
(
    server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers') OR
    server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
);
*/