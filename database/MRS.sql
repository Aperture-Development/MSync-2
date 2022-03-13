-- Create resolve state table
CREATE TABLE IF NOT EXISTS mrs_resolve_states (
    p_resolve_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `data` TEXT,
    title VARCHAR(25),
    `description` VARCHAR(200),
    UNIQUE KEY title_UNIQUE(title)
);

-- Create report table
CREATE TABLE IF NOT EXISTS mrs_reports (
    p_report_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    f_user_id INT UNSIGNED NOT NULL,
    f_reported_id INT UNSIGNED,
    f_server_id INT UNSIGNED NOT NULL,
    f_server_group_id INT UNSIGNED NOT NULL,
    f_admin_id INT UNSIGNED NOT NULL,
    f_resolve_state_id INT UNSIGNED,
    `timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `message` VARCHAR(512) NOT NULL,
    proof VARCHAR(128),
    FOREIGN KEY (f_user_id) REFERENCES tbl_users(p_user_id) ON DELETE CASCADE,
    FOREIGN KEY (f_admin_id) REFERENCES tbl_users(p_user_id) ON DELETE CASCADE,
    FOREIGN KEY (f_reported_id) REFERENCES tbl_users(p_user_id) ON DELETE CASCADE,
    FOREIGN KEY (f_server_id) REFERENCES tbl_msync_servers(p_id) ON DELETE CASCADE,
    FOREIGN KEY (f_server_group_id) REFERENCES tbl_server_grp(p_group_id) ON DELETE CASCADE,
    FOREIGN KEY (f_resolve_state_id) REFERENCES mrs_resolve_states(p_resolve_id) ON DELETE CASCADE
);

-- Create Conversation table
CREATE TABLE IF NOT EXISTS mrs_conversation (
    p_reply_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    f_report_id INT UNSIGNED NOT NULL,
    f_state_change_id INT UNSIGNED,
    f_user_id INT UNSIGNED NOT NULL,
    `timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reply VARCHAR(256) NOT NULL,
    FOREIGN KEY (f_report_id) REFERENCES mrs_reports(p_report_id) ON DELETE CASCADE,
    FOREIGN KEY (f_state_change_id) REFERENCES mrs_resolve_states(p_resolve_id) ON DELETE CASCADE,
    FOREIGN KEY (f_user_id) REFERENCES tbl_users(p_user_id) ON DELETE CASCADE
);

-- Insert Punishment types
INSERT INTO mrs_resolve_states (title, `description`, `data`) 
SELECT * FROM (
    SELECT 'invalid' AS res_title, 'Set the report as invalid' AS res_desc, '[]' AS res_data UNION
    SELECT 'kick' AS res_title, 'Kick the reported user' AS res_desc, '[]' AS res_data UNION
    SELECT 'ban' AS res_title, 'Ban the reported user' AS res_desc, '[]' AS res_data
) AS dataQuery
ON DUPLICATE KEY UPDATE title=res_title AND `description`=res_desc AND `data`=res_data;

-- Insert MRS db versions
INSERT INTO tbl_msyncdb_version (`version`, module_id)
SELECT * FROM (
    SELECT 1 AS `version`, 'mrs' AS mod_id UNION
    SELECT 0 AS `version`, 'mrs_data' AS mod_id
) AS dataQuery
ON DUPLICATE KEY UPDATE module_id=mod_id;

/*
######################################
AUTOMATIC TRIGGERS
######################################
*/

-- Create trigger to update data versions
CREATE TRIGGER mrs_report_data_version
    AFTER INSERT
    ON mrs_reports FOR EACH ROW
BEGIN
    CALL msync_updateDB('mrs_data')
END

-- Create trigger to update data versions
CREATE TRIGGER mrs_resolve_data_version
    AFTER INSERT
    ON mrs_resolve_states FOR EACH ROW
BEGIN
    CALL msync_updateDB('mrs_data')
END

-- Create trigger to update data versions
CREATE TRIGGER mrs_conversation_data_version
    AFTER INSERT
    ON mrs_conversation FOR EACH ROW
BEGIN
    CALL msync_updateDB('mrs_data')
END