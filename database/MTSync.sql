CREATE TABLE IF NOT EXISTS mtsync_time (
    f_user_id INT UNSIGNED NOT NULL,
    f_servergrp_id INT UNSIGNED NOT NULL,
    playtime BIGINT NOT NULL,
    last_played BIGINT NOT NULL,
    UNIQUE KEY time_UNIQUE(f_user_id, f_servergrp_id),
    FOREIGN KEY (f_user_id) REFERENCES tbl_users(p_user_id),
    FOREIGN KEY (f_servergrp_id) REFERENCES tbl_server_grp(p_group_id)
); 

-- Insert MSync db version
INSERT INTO tbl_msyncdb_version (`version`, module_id)
SELECT * FROM (
    SELECT 1 AS `version`, 'mtsync' AS mod_id
) AS dataQuery
ON DUPLICATE KEY UPDATE module_id=mod_id;

/*
-- INSERT NEW PLAYTIME TO DATABASE
INSERT INTO mtsync_time (f_user_id, f_servergrp_id, playtime, last_played)
SELECT * FROM (
    SELECT tbl_users.p_user_id, tbl_server_grp.p_group_id, ? AS plyTime, ? AS lastPly
    FROM tbl_users, tbl_server_grp
    WHERE
        (
            tbl_users.steamid = ? AND
            tbl_users.steamid64 = ?
        ) AND (
            tbl_server_grp.group_name = ?
        )
) AS dataQuery
ON DUPLICATE KEY UPDATE playtime=plyTime AND last_played=lastPly

-- SELECT A USERS PLAYTIME
SELECT playtime, last_played 
FROM mtsync_time 
WHERE
    f_user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?) AND
    f_servergrp_id=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)

-- SELECT A USERS TOTAL PLAYTIME
SELECT SUM(playtime) AS playtime, MAX(last_played) AS last_played
FROM mtsync_time
WHERE
    f_user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?)
*/