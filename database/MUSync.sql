CREATE TABLE IF NOT EXISTS musync_time (
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
    SELECT 1 AS `version`, 'musync' AS mod_id
) AS dataQuery
ON DUPLICATE KEY UPDATE module_id=mod_id;