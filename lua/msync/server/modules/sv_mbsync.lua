MSync = MSync or {}
MSync.modules = MSync.modules or {}
--[[
 * @file       sv_mbsync.lua
 * @package    MySQL Ban Sync
 * @author     Aperture Development
 * @license    root_dir/LICENSE
 * @version    1.3.2
]]

--[[
    Define name, description and module identifier
]]
local info = {
    Name = "MySQL Ban Sync",
    ModuleIdentifier = "MBSync",
    Description = "Synchronise bans across your servers",
    Version = "1.3.2"
}

--[[
    Prepare Module
]]
MSync.modules[info.ModuleIdentifier] = MSync.modules[info.ModuleIdentifier] or {}
MSync.modules[info.ModuleIdentifier].info = info
MSync.modules[info.ModuleIdentifier].recentDisconnects = MSync.modules[info.ModuleIdentifier].recentDisconnects or {}
local userTransactions = userTransactions or {}

--[[
    Define mysql table and additional functions that are later used
]]
MSync.modules[info.ModuleIdentifier].init = function( transaction )
    MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.init")
    transaction:addQuery( MSync.DBServer:query([[
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
    ]] ))

    --[[
        Description: Function to update the database to the newest version, in case it isn't up to date
    ]]
    MSync.modules[info.ModuleIdentifier].updateDB = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.updateDB")

        local selectDbVersion = MSync.DBServer:prepare( [[
            SELECT version FROM `tbl_msyncdb_version` WHERE module_id=?;
        ]] )
        selectDbVersion:setString(1, info.ModuleIdentifier)

        selectDbVersion.onSuccess = function( q, data )
            -- Do nothing for now
            MSync.log(MSYNC_DBG_INFO, "[MBSync] Checking database version")
            if data[1] then
                if data[1].version < 1 then
                    MSync.log(MSYNC_DBG_INFO, "[MBSync] Database version of MBSync is too old, updating it to Version 1")
                    local updates = MSync.DBServer:createTransaction()
                    updates:addQuery( MSync.DBServer:query([[
                        ALTER TABLE tbl_mbsync
                        MODIFY `date_unix` INT UNSIGNED NOT NULL,
                        MODIFY `length_unix` INT UNSIGNED NOT NULL;
                    ]]))
                    updates:addQuery( MSync.DBServer:query([[
                        INSERT INTO tbl_msyncdb_version (version, module_id) VALUES (1, 'MBSync')
                        ON DUPLICATE KEY UPDATE version=VALUES(version);
                    ]]))
                    updates:start()
                else
                    MSync.log(MSYNC_DBG_INFO, "[MBSync] Database version is up-to-date. No update necessary")
                end
            else
                MSync.log(MSYNC_DBG_INFO, "[MBSync] No data was returned, updating MBSync table to current version")
                local updates = MSync.DBServer:createTransaction()
                updates:addQuery( MSync.DBServer:query([[
                    ALTER TABLE tbl_mbsync
                    MODIFY `date_unix` INT UNSIGNED NOT NULL,
                    MODIFY `length_unix` INT UNSIGNED NOT NULL;
                ]]))

                updates:addQuery( MSync.DBServer:query([[
                    INSERT INTO tbl_msyncdb_version (version, module_id) VALUES (1, 'MBSync')
                    ON DUPLICATE KEY UPDATE version=VALUES(version);
                ]]))
                updates:start()
            end
        end

        selectDbVersion.onError = function( q, err, sql )
            MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MBSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {['err'] = err, ['sql'] = sql}))
        end

        selectDbVersion:start()
    end

    MSync.modules[info.ModuleIdentifier].updateDB()

    --[[
        Description: Function to ban a player
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].banUser = function(ply, calling_ply, length, reason, allserver)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.banUser Param.: $ply $calling_ply $length \"$reason\" $allserver", {["ply"] = ply:Nick(),["calling_ply"] = tostring(calling_ply),["length"] = length,["reason"] = reason,["allserver"] = allserver}))

        if MSync.modules[info.ModuleIdentifier].banTable[ply:SteamID64()] then
            MSync.log(MSYNC_DBG_INFO, "[MBSync] User \"" .. ply:SteamID64() .. "\" is already banned, editing old ban instead")
            if not length == 0 then
                length = ((os.time() - MSync.modules[info.ModuleIdentifier].banTable[util.SteamIDTo64(userid)].timestamp)+(length*60))/60
            end
            MSync.modules[info.ModuleIdentifier].editBan( MSync.modules[info.ModuleIdentifier].banTable[ply:SteamID64()]['banId'], reason, length, calling_ply, allserver)
            return
        end

        local banUserQ = MSync.DBServer:prepare( [[
            INSERT INTO `tbl_mbsync` (user_id, admin_id, reason, date_unix, length_unix, server_group)
            VALUES (
                (SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?), 
                (SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?), 
            ?, ?, ?,
                (SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
            );
        ]] )
        local timestamp = os.time()
        banUserQ:setString(1, ply:SteamID())
        banUserQ:setString(2, ply:SteamID64())
        banUserQ:setString(3, calling_ply)
        banUserQ:setString(4, util.SteamIDTo64(calling_ply))
        banUserQ:setString(5, reason)
        banUserQ:setNumber(6, timestamp)
        banUserQ:setNumber(7, length*60)
        if not allserver then
            banUserQ:setString(8, MSync.settings.data.serverGroup)
        else
            banUserQ:setString(8, "allservers")
        end

        banUserQ.onSuccess = function( q, data )
            -- Notify the user about the ban and add it to ULib to prevent data loss on Addon Remove
            -- Also, kick the user from the server

            if calling_ply == "STEAM_0:0:0" then
                adminNick = "(CONSOLE)"
            else
                adminNick = player.GetBySteamID( calling_ply ):Nick()
            end

            local msgLength
            local msgReason
            local banData = {
                admin = adminNick,
                reason = reason,
                unban = timestamp+(length*60),
                time = timestamp
            }
            if length == 0 then
                banData["unban"] = length
                msgLength = "Permanent"
            else
                msgLength = ULib.secondsToStringTime(length*60)
            end

            if reason == "" then
                msgReason = "(None given)"
            end

            ply:Kick("\n"..ULib.getBanMessage( ply:SteamID(), banData))
            MSync.modules[info.ModuleIdentifier].getActiveBans()
            MSync.modules[info.ModuleIdentifier].msg(calling_ply, "Banned "..ply:Nick().." for "..msgLength.." with reason "..msgReason)
        end

        banUserQ.onError = function( q, err, sql )
            MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MBSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {['err'] = err, ['sql'] = sql}))
        end

        banUserQ:start()
    end

    --[[
        Description: Function to ban a userid
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].banUserID = function(userid, calling_ply, length, reason, allserver)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.banUserID Param.: $userid $calling_ply $length \"$reason\" $allserver", {["userid"] = userid,["calling_ply"] = tostring(calling_ply),["length"] = length,["reason"] = reason,["allserver"] = allserver}))

        if MSync.modules[info.ModuleIdentifier].banTable[util.SteamIDTo64(userid)] then
            MSync.log(MSYNC_DBG_INFO, "[MBSync] User \"" .. userid .. "\" is already banned, editing old ban instead")
            if not (length == 0) then
                length = ((os.time() - MSync.modules[info.ModuleIdentifier].banTable[util.SteamIDTo64(userid)].timestamp)+(length*60))/60
            end
            MSync.modules[info.ModuleIdentifier].editBan( MSync.modules[info.ModuleIdentifier].banTable[util.SteamIDTo64(userid)]['banId'], reason, length, calling_ply, allserver)
            return
        end

        local banUserIdQ = MSync.DBServer:prepare( [[
            INSERT INTO `tbl_mbsync` (user_id, admin_id, reason, date_unix, length_unix, server_group)
            VALUES (
                (SELECT p_user_id FROM tbl_users WHERE steamid=? OR steamid64=?), 
                (SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?), 
            ?, ?, ?,
                (SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
            );
        ]] )
        local timestamp = os.time()
        banUserIdQ:setString(1, userid)
        banUserIdQ:setString(2, userid)
        banUserIdQ:setString(3, calling_ply)
        banUserIdQ:setString(4, util.SteamIDTo64(calling_ply))
        banUserIdQ:setString(5, reason)
        banUserIdQ:setNumber(6, timestamp)
        banUserIdQ:setNumber(7, length*60)
        if not allserver then
            banUserIdQ:setString(8, MSync.settings.data.serverGroup)
        else
            banUserIdQ:setString(8, "allservers")
        end

        banUserIdQ.onSuccess = function( q, data )
            -- Notify the user about the ban and add it to ULib to prevent data loss on Addon Remove
            -- Also, kick the user from the server
            if calling_ply == "STEAM_0:0:0" then
                adminNick = "(CONSOLE)"
            else
                adminNick = player.GetBySteamID( calling_ply ):Nick()
            end

            local banData = {
                admin = adminNick,
                reason = reason,
                unban = timestamp+(length*60),
                time = timestamp
            }
            if length == 0 then
                banData["unban"] = length
                msgLength = "Permanent"
            else
                msgLength = ULib.secondsToStringTime(length*60)
            end

            if reason == "" then
                msgReason = "(None given)"
            else
                msgReason = reason
            end
            MSync.modules[info.ModuleIdentifier].getActiveBans()

            MSync.modules[info.ModuleIdentifier].msg(calling_ply, "Banned "..userid.." for "..msgLength.." with reason "..msgReason)

            if not player.GetBySteamID(userid) then return end

            player.GetBySteamID(userid):Kick("\n"..ULib.getBanMessage( userid, banData))
        end

        banUserIdQ.onError = function( q, err, sql )
            if string.match( err, "^Column 'user_id' cannot be null$" ) then
                MSync.log(MSYNC_DBG_INFO, "[MBSync] User does not exist! Creating user before retrying")
                MSync.mysql.addUserID(userid)
                MSync.modules[info.ModuleIdentifier].banUserID(userid, calling_ply, length, reason, allserver)
            else
                MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MBSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {['err'] = err, ['sql'] = sql}))
            end
        end

        banUserIdQ:start()
    end

    --[[
        Description: Function to edit a ban
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].editBan = function(banId, reason, length, calling_ply, allserver)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.editBan Param.: $banid \"$reason\" $length $calling_ply $allserver", {["banid"] = banId,["reason"] = reason,["length"] = length,["calling_ply"] = tostring(calling_ply),["allserver"] = allserver}))

        local editBanQ = MSync.DBServer:prepare( [[
            UPDATE `tbl_mbsync`
            SET 
                reason=?,
                length_unix=?,
                admin_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?),
                server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
            WHERE p_ID=?
        ]] )
        editBanQ:setString(1, reason)
        editBanQ:setNumber(2, length*60)
        editBanQ:setString(3, calling_ply)
        editBanQ:setString(4, util.SteamIDTo64(calling_ply))
        if not allserver then
            editBanQ:setString(5, MSync.settings.data.serverGroup)
        else
            editBanQ:setString(5, "allservers")
        end
        editBanQ:setString(6, tostring(banId))

        editBanQ.onSuccess = function( q, data )
            MSync.modules[info.ModuleIdentifier].getActiveBans()
            MSync.modules[info.ModuleIdentifier].msg(calling_ply, "Edited ban with id "..banId.." with data: \nLength: "..ULib.secondsToStringTime(length*60).."\nReason: "..reason)
        end

        editBanQ.onError = function( q, err, sql )
            MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MBSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {['err'] = err, ['sql'] = sql}))
        end

        editBanQ:start()
    end

    --[[
        Description: Function to unban a banId
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].unBanUserID = function(calling_ply, banId)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.unBanUserID Param: " .. tostring(calling_ply) .. " " .. banId)
        local unBanUserIdQ = MSync.DBServer:prepare( [[
            UPDATE `tbl_mbsync`
            SET ban_lifted=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?)
            WHERE p_ID=? 
        ]] )
        unBanUserIdQ:setString(1, calling_ply)
        unBanUserIdQ:setString(2, util.SteamIDTo64(calling_ply))
        unBanUserIdQ:setNumber(3, banId)

        unBanUserIdQ.onSuccess = function( q, data )
            MSync.modules[info.ModuleIdentifier].getActiveBans()

            MSync.modules[info.ModuleIdentifier].msg(calling_ply, "Removed ban with id "..banId)
        end

        unBanUserIdQ.onError = function( q, err, sql )
            MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MBSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {['err'] = err, ['sql'] = sql}))
        end

        unBanUserIdQ:start()
    end

    --[[
        Description: Function to unban a user
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].unBanUser = function(ply_steamid, calling_ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.unBanUser Param.: " .. ply_steamid .. " " .. tostring(calling_ply))
        local unBanUserQ = MSync.DBServer:prepare( [[
            UPDATE `tbl_mbsync`
            SET 
                ban_lifted=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?)
            WHERE 
                user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? OR steamid64=?) AND 
                server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?) AND
                ((date_unix + length_unix) >= ? OR length_unix = 0) AND
                ban_lifted IS NULL
        ]] )
        unBanUserQ:setString(1, calling_ply)
        unBanUserQ:setString(2, util.SteamIDTo64(calling_ply))
        unBanUserQ:setString(3, ply_steamid)
        unBanUserQ:setString(4, ply_steamid)
        unBanUserQ:setString(5, MSync.settings.data.serverGroup)
        unBanUserQ:setNumber(6, os.time())

        unBanUserQ.onSuccess = function( q, data )
            MSync.modules[info.ModuleIdentifier].getActiveBans()

            MSync.modules[info.ModuleIdentifier].msg(calling_ply, "Unbanned "..ply_steamid)
        end

        unBanUserQ.onError = function( q, err, sql )
            MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MBSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {['err'] = err, ['sql'] = sql}))
        end

        unBanUserQ:start()
    end

    --[[
        Description: Function to get all bans
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].getBans = function(ply, fullTable)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.getBans Param.: " .. ply:Nick() .. " " .. tostring(fullTable))
        local getBansQ = MSync.DBServer:prepare( [[
            SELECT 
                tbl_mbsync.p_id, 
                tbl_mbsync.reason, 
                tbl_mbsync.date_unix,
                tbl_mbsync.length_unix,
                banned.steamid AS 'banned.steamid',
                banned.steamid64 AS 'banned.steamid64',
                banned.nickname AS 'banned.nickname',
                admin.steamid AS 'admin.steamid',
                admin.steamid64 AS 'admin.steamid64',
                admin.nickname AS 'admin.nickname',
                unban_admin.steamid AS 'unban_admin.steamid',
                unban_admin.steamid64 AS 'unban_admin.steamid64',
                unban_admin.nickname AS 'unban_admin.nickname',
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
            ;
        ]] )

        getBansQ.onSuccess = function( q, data )

            local banTable = {}

            MSync.log(MSYNC_DBG_INFO, "[MBSync] Recieved ban data from Database")
            if fullTable then
                MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Generating full ban table to send to \"" .. ply:Nick() .. "\"")
                for k,v in pairs(data) do

                    banTable[v.p_id] = {
                        banId = v.p_id,
                        reason = v.reason,
                        timestamp = v.date_unix,
                        length = v.length_unix,
                        servergroup = v["group_name"],
                        banned = {
                            steamid = v['banned.steamid'],
                            steamid64 = v['banned.steamid64'],
                            nickname = v['banned.nickname']
                        },
                        banningAdmin = {
                            steamid = v['admin.steamid'],
                            steamid64 = v['admin.steamid64'],
                            nickname = v['admin.nickname']
                        },
                        unBanningAdmin = {
                            steamid = v['unban_admin.steamid'],
                            steamid64 = v['unban_admin.steamid64'],
                            nickname = v['unban_admin.nickname']
                        }
                    }

                end
            else
                MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Generating short ban table to send to \"" .. ply:Nick() .. "\"")
                for k,v in pairs(data) do
                    if not v['unban_admin.steamid'] and ((not((v.date_unix+v.length_unix) < os.time())) or (v.length_unix==0)) then
                        banTable[v["banned.steamid64"]] = {
                            banId = v.p_id,
                            reason = v.reason,
                            timestamp = v.date_unix,
                            length = v.length_unix,
                            servergroup = v["group_name"],
                            banned = {
                                steamid = v["banned.steamid"],
                                nickname = v["banned.nickname"],
                                steamid64 = v["banned.steamid64"]
                            },
                            adminNickname = v["admin.nickname"]
                        }
                    end
                end
            end

            --MSync.modules[info.ModuleIdentifier].sendSettings(ply, banTable)
            -- We need to add 0.4 to the calculated number to guarantee that we always round up to the next highest number 
            -- Luckily because we always calculate with whole numbers (there is no half ban) this should be enough to guarantee that we always send enough packages
            MSync.modules[info.ModuleIdentifier].sendCount(ply, math.Round((table.Count(banTable) / 10)+0.4))
            local tempTable = MSync.modules[info.ModuleIdentifier].splitTable(banTable)
            for k,v in pairs(tempTable) do
                MSync.modules[info.ModuleIdentifier].sendPart(ply, v)
            end

        end

        getBansQ.onError = function( q, err, sql )
            MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MBSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {['err'] = err, ['sql'] = sql}))
        end

        getBansQ:start()
    end

    --[[
        Description: Function to get all active bans
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].getActiveBans = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.getActiveBans")
        local getActiveBansQ = MSync.DBServer:prepare( [[
            SELECT 
                tbl_mbsync.*,
                banned.steamid,
                banned.steamid64,
                banned.nickname AS 'banned.nickname',
                admin.nickname AS 'admin.nickname'
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
                    server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers')
                )
        ]] )
        getActiveBansQ:setNumber(1, os.time())
        getActiveBansQ:setString(2, MSync.settings.data.serverGroup)

        getActiveBansQ.onSuccess = function( q, data )

            local banTable = {}
            for k,v in pairs(data) do
                banTable[v["steamid64"]] = {
                    banId = v.p_id,
                    reason = v.reason,
                    timestamp = v.date_unix,
                    length = v.length_unix,
                    banned = {
                        steamid = v.steamid,
                        nickname = v["banned.nickname"]
                    },
                    adminNickname = v["admin.nickname"]
                }
            end
            MSync.log(MSYNC_DBG_INFO, "[MBSync] Local ban table updated with new data")

            MSync.modules[info.ModuleIdentifier].banTable = banTable

            --[[
                Check if a banned player joined while the data wasn't synchronized
            ]]
            for k,v in pairs(player.GetAll()) do
                if banTable[v:SteamID64()] then
                    local ban = banTable[v:SteamID64()]
                    --[[
                        Translate ban data for ULib
                    ]]
                    local banData = {
                        admin = ban.adminNickname,
                        reason = ban.reason,
                        unban = ban.length+ban.timestamp,
                        time = ban.timestamp
                    }

                    local message = ULib.getBanMessage( ban.banned.steamid, banData)

                    MSync.log(MSYNC_DBG_WARNING, "[MBSync] User \"" .. ply:Nick() "\" was banned while data resynchronized, kicking from server")
                    v:Kick(message)
                else
                    -- Do nothing
                end
            end
        end

        getActiveBansQ.onError = function( q, err, sql )
            MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MBSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {['err'] = err, ['sql'] = sql}))
        end

        getActiveBansQ:start()
    end

    --[[
        Description: This function allows us to export our active bans into ULX
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].exportBansToULX = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.exportBansToULX")
        local exportActiveBans = MSync.DBServer:prepare( [[
            SELECT 
                tbl_mbsync.*,
                banned.steamid,
                banned.steamid64,
                banned.nickname AS 'banned.nickname',
                admin.nickname AS 'admin.nickname',
                admin.steamid AS 'admin.steamid'
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
                    server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers')
                )
        ]] )
        exportActiveBans:setNumber(1, os.time())
        exportActiveBans:setString(2, MSync.settings.data.serverGroup)

        exportActiveBans.onSuccess = function( q, data )

            print("[MBSync] Exporting all MBSync bans to ULX. Please wait...")
            for k,v in pairs(data) do
                local unban
                if v.length_unix == 0 then
                    unban = 0
                else
                    unban = v.date_unix + v.length_unix
                end

                local admin
                if v["admin.steamid"] == "STEAM_0:0:0" then
                    admin = v["admin.nickname"]
                else
                    admin = v["admin.nickname"].."("..v["admin.steamid"]..")"
                end

                ULib.bans[ v["steamid"] ] = {
                    admin = admin,
                    time = v.date_unix,
                    unban = unban,
                    reason = v.reason,
                    name = v["banned.nickname"]
                }
                userTransactions[v["steamid64"]] = true
                hook.Call( ULib.HOOK_USER_BANNED, _, v["steamid"], ULib.bans[ v["steamid"] ] )
            end
            ULib.fileWrite( ULib.BANS_FILE, ULib.makeKeyValues( ULib.bans ) )
            print("[MBSync] Export finished")

        end

        exportActiveBans.onError = function( q, err, sql )
            MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MBSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {['err'] = err, ['sql'] = sql}))
        end

        exportActiveBans:start()
    end
    concommand.Add("msync."..info.ModuleIdentifier..".export", function( ply, cmd, args )
        MSync.modules[info.ModuleIdentifier].exportBansToULX()
    end)

    --[[
        Description: Function to allow the import of all ULX bans to MBSync
        Arguments:
            - allservers [boolean] - Should all bans be imported as local bans or as allserver bans? ( true = allservers, false = server group)
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].importBansFromULX = function( allservers )
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.importBansFromULX Param.: " .. tostring(allservers))
        local transactions = {}
        local banTransaction = MSync.DBServer:createTransaction()

        print("[MBSync] Importing bans from ULX into MBSync, please wait...")
        for k,v in pairs(ULib.bans) do
            --[[
                - Create User
                - Create ban query
            ]]
            transactions[k] = MSync.DBServer:prepare( [[
                INSERT INTO `tbl_mbsync` (user_id, admin_id, reason, date_unix, length_unix, server_group)
                VALUES (
                    (SELECT p_user_id FROM tbl_users WHERE steamid=?), 
                    (SELECT p_user_id FROM tbl_users WHERE steamid=?), 
                ?, ?, ?,
                    (SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
                );
            ]] )
            local timestamp = os.time()
            transactions[k]:setString(1, k)

            if v['modified_admin'] then
                if v['modified_admin'] == "(Console)" then
                    transactions[k]:setString(2,"STEAM_0:0:0")
                else
                    transactions[k]:setString(2,string.match(v['modified_admin'], "STEAM_%d:%d:%d+"))
                end
            else
                if v['admin'] == "(Console)" then
                    transactions[k]:setString(2,"STEAM_0:0:0")
                else
                    transactions[k]:setString(2,string.match(v['admin'], "STEAM_%d:%d:%d+"))
                end
            end

            transactions[k]:setString(3, v['reason'] or "(None given)")
            transactions[k]:setNumber(4, tonumber(v['time']))

            if tonumber(v['unban']) == 0 then
                transactions[k]:setNumber(5, tonumber(v['unban']))
            else
                transactions[k]:setNumber(5, tonumber(v['unban']) - tonumber(v['time']))
            end

            if not allserver then
                transactions[k]:setString(6, MSync.settings.data.serverGroup)
            else
                transactions[k]:setString(6, "allservers")
            end

            banTransaction:addQuery(transactions[k])
            MSync.log(MSYNC_DBG_INFO, "[MBSync] Imported ban for SteamID: " .. k)
        end

        banTransaction.onSuccess = function()
            print("[MBSync] Ban import from ULX finished successfully")
        end

        banTransaction.onError = function(tr, err)
            MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MBSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {['err'] = err, ['sql'] = sql}))
        end

        banTransaction:start()
    end
    concommand.Add("msync."..info.ModuleIdentifier..".import", function( ply, cmd, args )
        local allservers = false

        if args[1] == "true" then
            allservers = true
        end

        MSync.modules[info.ModuleIdentifier].importBansFromULX( allservers )
    end)

    --[[
        Description: Function to load the MSync settings file
        Returns: true
    ]]
    MSync.modules[info.ModuleIdentifier].loadSettings = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec.: MBSync.loadSettings")
        if not file.Exists("msync/"..info.ModuleIdentifier..".txt", "DATA") then
            MSync.modules[info.ModuleIdentifier].settings = {
                syncDelay = 300
            }
            file.Write("msync/"..info.ModuleIdentifier..".txt", util.TableToJSON(MSync.modules[info.ModuleIdentifier].settings, true))
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] No configuration found, generated default one")
        else
            MSync.modules[info.ModuleIdentifier].settings = util.JSONToTable(file.Read("msync/mbsync.txt", "DATA"))
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Configuration found, loaded into MBSync")
        end

        return true
    end

    --[[
        Description: Function to save the MSync settings to the settings file
        Returns: true if the settings file exists
    ]]
    MSync.modules[info.ModuleIdentifier].saveSettings = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.saveSettings")
        file.Write("msync/"..info.ModuleIdentifier..".txt", util.TableToJSON(MSync.modules[info.ModuleIdentifier].settings, true))
        return file.Exists("msync/"..info.ModuleIdentifier..".txt", "DATA")
    end

    --[[
        Description: Function to split table into multible 10er parts
        Returns: table split in 10er part counts
    ]]
    MSync.modules[info.ModuleIdentifier].splitTable = function(tbl)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.splitTable Param.: " .. tostring(tbl))

        local i = 0
        local dataSet = 0
        local splitTableData = {}

        for k,v in pairs(tbl) do
            if not splitTableData[dataSet] then splitTableData[dataSet] = {} end
            if i == 10 then
                dataSet = dataSet + 1
                i = 0
            else
                splitTableData[dataSet][k] = v
                i = i + 1
            end
        end

        return splitTableData
    end

    --[[
        Load settings when module finished loading
    ]]
    MSync.modules[info.ModuleIdentifier].loadSettings()

    if not MSync.modules[info.ModuleIdentifier].banTable then
        MSync.log(MSYNC_DBG_WARNING, "[MBSync] Ban table not found yet, requesting now")
        MSync.modules[info.ModuleIdentifier].getActiveBans()
    end
end

--[[
    Define net receivers and util.AddNetworkString
]]
MSync.modules[info.ModuleIdentifier].net = function()

    --[[
        Description: Function to send a message to a player
        Arguments:
            player [player] - the player that wants to open the admin GUI
            text [string] - the text you want to send to the client
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".sendMessage")
    MSync.modules[info.ModuleIdentifier].msg = function(ply, content, msgType)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.msg Param.: $ply \"$content\" $msgType")
        if type(ply) == "string" and not (ply == "STEAM_0:0:0") then
            ply = player.GetBySteamID( ply )
        end

        if type(ply) == "Entity" or type(ply) == "Player" then
            if not IsValid(ply) then
                print("[MBSync] "..content)
            else
                MSync.log(MSYNC_DBG_INFO, "[MBSync] "..content)
                if not msgType then msgType = 0 end
                -- Basic message
                if msgType == 0 then
                    net.Start("msync."..info.ModuleIdentifier..".sendMessage")
                        net.WriteFloat(msgType)
                        net.WriteString(content)
                    net.Send(ply)
                end
            end
        elseif ply == "STEAM_0:0:0" then
            print("[MBSync] "..content)
        end
    end

    --[[
        Description: Function to send the ban list to a player
        Arguments:
            player [player] - the player that wants to open the admin GUI
            banTable [table] - the ban table
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".sendBanTable")
    MSync.modules[info.ModuleIdentifier].sendSettings = function(ply, banTable)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.sendSettings Param.: " .. tostring(ply) .. " " .. tostring(banTable))
        net.Start("msync."..info.ModuleIdentifier..".sendBanTable")
            net.WriteTable(banTable)
        net.Send(ply)
    end

    --[[
        Description: Function to open the ban table on the player
        Arguments:
            player [player] - the player that wants to open the admin GUI
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".openBanTable")
    MSync.modules[info.ModuleIdentifier].openBanTable = function(ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.openBanTable Param.: " .. tostring(ply))
        net.Start("msync."..info.ModuleIdentifier..".openBanTable")
        net.Send(ply)
    end

    --[[
        Description: Net Receiver - Gets called when the client banned a player with the ban gui
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".banid")
    net.Receive("msync."..info.ModuleIdentifier..".banid", function(len, ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Net: msync.MBSync.banid Player: " .. tostring(ply))
        if not ply:query("msync."..info.ModuleIdentifier..".banPlayer") then MSync.log(MSYNC_DBG_WARNING, "[MBSync] User \"" .. ply:Nick() .. "\" tried to ban a user without permission");return end

        local ban = net.ReadTable()

        --[[
            Error check and fill in of default data
        ]]

        if not ban.userid then return end;

        if not ban.reason then ban.reason = "No reason given" end
        if not ban.length then ban.length = 0 end

        if not ban.allserver then
            ban.allserver = true
        else
            if ban.allserver == "true" or ban.allserver == "1" then
                ban.allserver = true
            else
                ban.allserver = false
            end
        end

        --[[
            Run ban function to ban the userid
        ]]
        MSync.modules[info.ModuleIdentifier].banUserID(ban.userid, ply, ban.length, ban.reason, ban.allserver)
    end )

    --[[
        Description: Net Receiver - Gets called when the client edits a ban
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".editBan")
    net.Receive("msync."..info.ModuleIdentifier..".editBan", function(len, ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Net: msync.MBSync.editBan Player: " .. tostring(ply))
        if not ply:query("msync."..info.ModuleIdentifier..".banPlayer") then MSync.log(MSYNC_DBG_WARNING, "[MBSync] User \"" .. ply:Nick() .. "\" tried to ban a user without permission");return end

        local editedBan = net.ReadTable()

        --[[
            Error check and fill in of default data
        ]]

        if not editedBan.banid then return end;

        if not editedBan.reason then editedBan.reason = "No reason given" end
        if not editedBan.length then editedBan.length = 0 end

        if not editedBan.allserver then
            editedBan.allserver = true
        else
            if editedBan.allserver == "true" or editedBan.allserver == "1" then
                editedBan.allserver = true
            else
                editedBan.allserver = false
            end
        end

        --[[
            Run edit function to edit ban data
        ]]
        MSync.modules[info.ModuleIdentifier].editBan(editedBan.banid, editedBan.reason, editedBan.length, ply, editedBan.allserver)
    end )

    --[[
        Description: Net Receiver - Gets called when the client tries to unban someone
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".unban")
    net.Receive("msync."..info.ModuleIdentifier..".unban", function(len, ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Net: msync.MBSync.unban Player: " .. tostring(ply))
        if not ply:query("msync."..info.ModuleIdentifier..".unBanID") then MSync.log(MSYNC_DBG_WARNING, "[MBSync] User \"" .. ply:Nick() .. "\" tried to unban a user without permission");return end

        local banid = net.ReadFloat()

        --[[
            Error check and fill in of default data
        ]]

        if not banid then return end;

        --[[
            When unbanning someone using the banid, we need to still unban the user in ULX, so this is the best solution.

            We loop trough the active ban table, search for the banid ( it has to be there, otherwise the user can't know it ) and then unban the steamid
        ]]
        local steamid = ""
        for k,v in pairs(MSync.modules[info.ModuleIdentifier].banTable) do
            if v.banid == banid then
                steamid = v.banned['steamid']
            end
        end

        --[[
            Run unban function that takes the banid
        ]]
        MSync.modules[info.ModuleIdentifier].unBanUserID(ply, banid)

        --[[
            For ulx's sake, we unban the user in ulx for the case that a user has been banned using ulx ban and now gets unbanned using mbsync unbanid
        ]]
        userTransactions[util.SteamIDTo64(target_steamid)] = true
        ULib.unban(target_steamid, calling_ply)
    end )

    --[[
        Description: Function to send the mbsync settings to the client
        Arguments:
            player [player] - the player that wants to open the admin GUI
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".sendSettingsPly")
    MSync.modules[info.ModuleIdentifier].sendSettings = function(ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.sendSettings Param.: " .. tostring(ply))
        net.Start("msync."..info.ModuleIdentifier..".sendSettingsPly")
            net.WriteTable(MSync.modules[info.ModuleIdentifier].settings)
        net.Send(ply)
    end

    --[[
        Description: Net Receiver - Gets called when the client requests the settings table
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".getSettings")
    net.Receive("msync."..info.ModuleIdentifier..".getSettings", function(len, ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Net: msync.MBSync.getSettings Player: " .. tostring(ply))
        if not ply:query("msync.getSettings") then MSync.log(MSYNC_DBG_WARNING, "[MBSync] User \"" .. ply:Nick() .. "\" tried to get the settings without permission");return end

        MSync.modules[info.ModuleIdentifier].sendSettings(ply)
    end )

    --[[
        Description: Net Receiver - Gets called when the client wants to open the ban gui
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".sendSettings")
    net.Receive("msync."..info.ModuleIdentifier..".sendSettings", function(len, ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Net: msync.MBSync.sendSettings Player: " .. tostring(ply))
        if not ply:query("msync.sendSettings") then MSync.log(MSYNC_DBG_WARNING, "[MBSync] User \"" .. ply:Nick() .. "\" tried to send settings to the server without permission");return end

        MSync.modules[info.ModuleIdentifier].settings = net.ReadTable()
        MSync.modules[info.ModuleIdentifier].saveSettings()
    end )

    --[[
        Description: Function to send the 10 last disconnects to a player
        Arguments:
            player [player] - the player that requests the data
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".openBanGUI")
    MSync.modules[info.ModuleIdentifier].openBanGUI = function(ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.openBanGUI Param.: " .. tostring(ply))
        local tableLength = table.Count(MSync.modules[info.ModuleIdentifier].recentDisconnects)
        local disconnectTable = {}

        if tableLength > 0 then
            local runs = 0
            for k,v in pairs(MSync.modules[info.ModuleIdentifier].recentDisconnects) do
                if runs > (tableLength - 10) then
                    disconnectTable[k] = v
                end
                runs = runs + 1
            end
        else
            disconnectTable = {}
        end
        net.Start("msync."..info.ModuleIdentifier..".openBanGUI")
            net.WriteTable(disconnectTable)
        net.Send(ply)
    end

    --[[
        Description: Function to send the data part count to the client
        Arguments:
            player [player] - the player that requests the data
            number [interger] - the count of data parts to be sent to the player
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".recieveDataCount")
    MSync.modules[info.ModuleIdentifier].sendCount = function(ply, number)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.sendCount Param.: " .. tostring(ply) .. " " .. number)
        net.Start("msync."..info.ModuleIdentifier..".recieveDataCount")
            net.WriteFloat(number)
        net.Send(ply)
    end

    --[[
        Description: Function to send a table part to a player
        Arguments:
            player [player] - the player that requests the data
            part [table] - the table part that gets sent to the player
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".recieveData")
    MSync.modules[info.ModuleIdentifier].sendPart = function(ply, part)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.sendPart Param.: " .. tostring(ply) .. " " .. tostring(part))
        net.Start("msync."..info.ModuleIdentifier..".recieveData")
            net.WriteTable(part)
        net.Send(ply)
    end

    --[[
        Description: Net Receiver - Gets called when the client requests the ban data
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".getBanTable")
    net.Receive("msync."..info.ModuleIdentifier..".getBanTable", function(len, ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Net: msync.MBSync.getBanTable Player: " .. tostring(ply))
        local fullTable = net.ReadBool()
        if fullTable then
            if not ply:query("msync.openAdminGUI") then MSync.log(MSYNC_DBG_WARNING, "[MBSync] User \"" .. ply:Nick() .. "\" tried to get the full ban table without permission");return end
            MSync.modules[info.ModuleIdentifier].getBans(ply, fullTable)
        else
            if not ply:query("msync."..info.ModuleIdentifier..".openBanTable") then MSync.log(MSYNC_DBG_WARNING, "[MBSync] User \"" .. ply:Nick() .. "\" tried to get the short ban table without permission");return end
            MSync.modules[info.ModuleIdentifier].getBans(ply, false)
        end
    end )

end

--[[
    Define ulx Commands and overwrite common ulx functions (module does not get loaded until ulx has fully been loaded)
]]
MSync.modules[info.ModuleIdentifier].ulx = function()
    MSync.modules[info.ModuleIdentifier].Chat = MSync.modules[info.ModuleIdentifier].Chat or {}

    --[[
        Without any argument, open ban GUI
        With arguments, run ban command

        Arguments:
            target [player] - the player target
            length [number] - the ban length - OPTIONAL - Default: 0/Permanent
            allserver [bool] - if its on all servers - OPTIONAL - Default: 0/false
            reason [string] - the ban reason - OPTIONAL - Default: "banned by staff"
    ]]
    MSync.modules[info.ModuleIdentifier].Chat.banPlayer = function(calling_ply, target_ply, length, allserver, reason)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.Chat.banPlayer Param.: $calling_ply $target_player $length $allserver \"$reason\"", {["calling_ply"] = calling_ply,["target_player"] = target_ply,["length"] = length,["allserver"] = allserver,["reason"] = reason}))
        local calling_steamid = ""

        if not IsValid(calling_ply) then
            calling_steamid = "STEAM_0:0:0"
        else
            if not calling_ply:query("msync."..info.ModuleIdentifier..".banPlayer") then return end;
            if calling_ply == target_ply then
                MSync.modules[info.ModuleIdentifier].openBanGUI(calling_ply)
                return
            else
                calling_steamid = calling_ply:SteamID()
            end
        end
        if not IsValid(target_ply) then return end

        --[[
            Set default values if empty and translate allserver string to bool
        ]]
        if not length then length = 0 end

        if not allserver then
            allserver = true
        else
            if allserver == "true" or allserver == "1" then
                allserver = true
            else
                allserver = false
            end
        end

        if not reason then reason = "No reason given" end

        --[[
            Run ban function with given variables
        ]]
        MSync.modules[info.ModuleIdentifier].banUser(target_ply, calling_steamid, length, reason, allserver)
    end
    local BanPlayer = ulx.command( "MSync", "msync."..info.ModuleIdentifier..".banPlayer", MSync.modules[info.ModuleIdentifier].Chat.banPlayer, "!mban" )
    BanPlayer:addParam{ type=ULib.cmds.PlayerArg, hint="player", ULib.cmds.optional}
    BanPlayer:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="true/false, if the player should be banned on all servers", ULib.cmds.optional }
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
    BanPlayer:defaultAccess( ULib.ACCESS_SUPERADMIN )
    BanPlayer:help( "Opens the MBSync GUI ( without parameters ) or bans a player" )

    --[[
        ban the targeted steamid

        Arguments:
            target_steamid [string] - the target steamid
            length [number] - the ban length - OPTIONAL - Default: 0/Permanent
            allserver [bool] - if its on all servers - OPTIONAL - Default: 0/false
            reason [string] - the ban reason - OPTIONAL - Default: "banned by staff"
    ]]
    MSync.modules[info.ModuleIdentifier].Chat.banSteamID = function(calling_ply, target_steamid, length, allserver, reason)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.Chat.banSteamID Param.: $calling_ply $target_steamid $length $allserver \"$reason\"", {["calling_ply"] = calling_ply,["target_steamid"] = target_steamid,["length"] = length,["allserver"] = allserver,["reason"] = reason}))
        local calling_steamid = ""

        if not IsValid(calling_ply) then
            calling_steamid = "STEAM_0:0:0"
        else
            if not calling_ply:query("msync."..info.ModuleIdentifier..".banSteamID") then return end;
            calling_steamid = calling_ply:SteamID()
        end

        --[[
            Check for empty or invalid steamid
        ]]

        if not target_steamid or not ULib.isValidSteamID(target_steamid) then return end

        --[[
            Set default values if empty and translate allserver string to bool
        ]]
        if not length then length = 0 end

        if not allserver then
            allserver = true
        else
            if allserver == "true" or allserver == "1" then
                allserver = true
            else
                allserver = false
            end
        end

        reason = reason or "(None given)"

        --[[
            Run ban function with given functions
        ]]
        MSync.modules[info.ModuleIdentifier].banUserID(target_steamid, calling_steamid, length, reason, allserver)

    end
    local BanPlayer = ulx.command( "MSync", "msync."..info.ModuleIdentifier..".banSteamID", MSync.modules[info.ModuleIdentifier].Chat.banSteamID, "!mbanid" )
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="steamid"}
    BanPlayer:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="true/false, if the player should be banned on all servers", ULib.cmds.optional }
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
    BanPlayer:defaultAccess( ULib.ACCESS_SUPERADMIN )
    BanPlayer:help( "Bans the given SteamID." )

    --[[
        unban a user with the given steamid

        Arguments:
            target_steamid [string] - the target steamid
    ]]
    MSync.modules[info.ModuleIdentifier].Chat.unBanID = function(calling_ply, target_steamid)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.Chat.unBanID Param.: $calling_ply $target_steamid", {["calling_ply"] = calling_ply,["target_steamid"] = target_steamid}))
        local calling_steamid = ""

        if not IsValid(calling_ply) then
            calling_steamid = "STEAM_0:0:0"
        else
            if not calling_ply:query("msync."..info.ModuleIdentifier..".unBanID") then return end;
            calling_steamid = calling_ply:SteamID()
        end

        --[[
            Check for empty or invalid steamid
        ]]
        if not target_steamid or not ULib.isValidSteamID(target_steamid) then return end

        --[[
            Unban user with given steamid
        ]]
        MSync.modules[info.ModuleIdentifier].unBanUser(target_steamid, calling_steamid)

        --[[
            For ulx's sake, we unban the user in ulx for the case that a user has been banned using ulx ban and now gets unbanned using mbsync unbanid
        ]]
        userTransactions[util.SteamIDTo64(target_steamid)] = true
        ULib.unban(target_steamid, calling_ply)
    end
    local BanPlayer = ulx.command( "MSync", "msync."..info.ModuleIdentifier..".unBanID", MSync.modules[info.ModuleIdentifier].Chat.unBanID, "!munban" )
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="steamid"}
    BanPlayer:defaultAccess( ULib.ACCESS_SUPERADMIN )
    BanPlayer:help( "Unbans the given SteamID." )

    --[[
        check if a player is banned

        Arguments:
            target_steamid [string] - the target steamid
    ]]
    MSync.modules[info.ModuleIdentifier].Chat.checkBan = function(calling_ply, target_steamid)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.Chat.checkBan Param.: $calling_ply $target_player", {["calling_ply"] = calling_ply,["target_steamid"] = target_steamid}))
        if not IsValid(calling_ply) then
            -- Do nothing
        else
            if not calling_ply:query("msync."..info.ModuleIdentifier..".checkBan") then return end;
        end

        if not target_steamid or not ULib.isValidSteamID(target_steamid) then return end

        if MSync.modules[info.ModuleIdentifier].banTable[util.SteamIDTo64(target_steamid)] then

            --[[
                Load the ban date from the activa ben table to a local variable
            ]]
            local banData = table.Copy(MSync.modules[info.ModuleIdentifier].banTable[util.SteamIDTo64(target_steamid)])

            --[[
                Translate ban length and Date into readable values
            ]]

            if banData.length == 0 then
                banData.length = "permanent"
            else
                banData.length = os.date( "%H:%M:%S - %d/%m/%Y", banData.timestamp + banData.length)
            end

            banData.timestamp = os.date( "%H:%M:%S - %d/%m/%Y", banData.timestamp)

            if string.len(banData.reason) <= 0 then
                banData.reason = "None Given"
            end

            --[[
                Message the ban informations to the asking player
            ]]
            MSync.modules[info.ModuleIdentifier].msg(calling_ply,"Player banned!\nBanID: "..banData.banId.."\nReason: "..banData.reason.."\nBanned by: "..banData.adminNickname.."\nBan Date: "..banData.timestamp.."\nBan lasting till: "..banData.length)
        else
            -- Respond that the player is not banned
            MSync.modules[info.ModuleIdentifier].msg(calling_ply,"The target player is not banned from this server.")
        end
    end
    local BanPlayer = ulx.command( "MSync", "msync."..info.ModuleIdentifier..".checkBan", MSync.modules[info.ModuleIdentifier].Chat.checkBan, "!mcheck" )
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="steamid"}
    BanPlayer:defaultAccess( ULib.ACCESS_SUPERADMIN )
    BanPlayer:help( "Checks if there is currently a active ban for given SteamID." )

    --[[
        opens the ban table

        Arguments:
            none
    ]]
    MSync.modules[info.ModuleIdentifier].Chat.openBanTable = function(calling_ply)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.Chat.openBanTable Param.: $calling_ply", {["calling_ply"] = calling_ply}))
        if not IsValid(calling_ply) then MSync.log(MSYNC_DBG_ERROR, "[MBSync] This command can only be executed in-game"); return; end
        if not calling_ply:query("msync."..info.ModuleIdentifier..".openBanTable") then return end;
        -- Open Ban Table
        MSync.modules[info.ModuleIdentifier].openBanTable(calling_ply)
    end
    local BanPlayer = ulx.command( "MSync", "msync."..info.ModuleIdentifier..".openBanTable", MSync.modules[info.ModuleIdentifier].Chat.openBanTable, "!mbsync" )
    BanPlayer:defaultAccess( ULib.ACCESS_SUPERADMIN )
    BanPlayer:help( "Opens the MBSync ban table, this table only shows active bans." )

    --[[
        Edits the ban with the given banID

        Arguments:
            banID [number] - the ban id
            length [number] - the ban length - OPTIONAL - Default: 0/Permanent
            allserver [bool] - if its on all servers - OPTIONAL - Default: 0/false
            reason [string] - the ban reason - OPTIONAL - Default: "banned by staff"
    ]]
    MSync.modules[info.ModuleIdentifier].Chat.editBan = function(calling_ply, ban_id, length, allserver, reason)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.Chat.banPlayer Param.: $calling_ply $ban_id $length $allserver \"$reason\"", {["calling_ply"] = calling_ply,["ban_id"] = ban_id,["length"] = length,["allserver"] = allserver,["reason"] = reason}))
        local calling_steamid = ""

        if not IsValid(calling_ply) then
            calling_steamid = "STEAM_0:0:0"
        else
            if not calling_ply:query("msync."..info.ModuleIdentifier..".editBan") then return end;
            calling_steamid = calling_ply:SteamID()
        end

        --[[
            Set default values if empty and translate allserver string to bool
        ]]
        if not length then length = 0 end

        if not allserver then
            allserver = true
        else
            if allserver == "true" or allserver == "1" then
                allserver = true
            else
                allserver = false
            end
        end

        if not reason then reason = "No reason given" end

        --[[
            Run ban function with given variables
        ]]
        MSync.modules[info.ModuleIdentifier].editBan(tostring(ban_id), tostring(reason), tostring(length), calling_steamid, allserver)
    end
    local EditBan = ulx.command( "MSync", "msync."..info.ModuleIdentifier..".editBan", MSync.modules[info.ModuleIdentifier].Chat.editBan, "!medit" )
    EditBan:addParam{ type=ULib.cmds.NumArg, hint="BanID"}
    EditBan:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
    EditBan:addParam{ type=ULib.cmds.StringArg, hint="true/false, all servers?", ULib.cmds.optional }
    EditBan:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
    EditBan:defaultAccess( ULib.ACCESS_SUPERADMIN )
    EditBan:help( "Edits the given ban id with new ban data" )

end

--[[
    Define hooks your module is listening on e.g. PlayerDisconnect
]]
MSync.modules[info.ModuleIdentifier].hooks = function()
    --[[
        This hook starts the timers for the asynchronous ban data loading and the check if one of the online players has been banned
    ]]
    timer.Create("msync."..info.ModuleIdentifier..".getActiveBans", MSync.modules[info.ModuleIdentifier].settings.syncDelay, 0, function()
        MSync.modules[info.ModuleIdentifier].getActiveBans()
    end)
    MSync.modules[info.ModuleIdentifier].getActiveBans()

    hook.Add("CheckPassword", "msync."..info.ModuleIdentifier..".banCheck", function( steamid64 )
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Checking ban status for \"" .. steamid64 .. "\"")
        if MSync.modules[info.ModuleIdentifier].banTable[steamid64] then
            local ban = MSync.modules[info.ModuleIdentifier].banTable[steamid64]
            local unbanDate
            if ban.length == 0 then
                unbanDate = "Never"
            else
                unbanDate = os.date( "%c", ban.timestamp+ban.length)
            end
            --[[
                Print to console that a banned user tries to join
            ]]
            MSync.log(MSYNC_DBG_WARNING, MSync.formatString("\n---== [MBSync] ==---\nA banned player tried to join the server.\n-- Informations --\nNickname: $nickname\nSteamID: $steamid\nBan Date: $date\nUnban Date: $unbanDate\nBanned by: $admin\n---== [END] ==---", {
                ["nickname"] = ban.banned.nickname,
                ["steamid"] = ban.banned.steamid,
                ["date"] = os.date( "%c", ban.timestamp),
                ["unbanDate"] = unbanDate,
                ["admin"] = ban.adminNickname
            }))

            --[[
                Translate ban data for ULib
            ]]
            local banData = {
                admin = ban.adminNickname,
                reason = ban.reason,
                unban = ban.timestamp+ban.length,
                time = ban.timestamp
            }

            if ban.length == 0 then
                banData["unban"] = ban.length
            end

            local message = ULib.getBanMessage( ban.banned.steamid, banData)
            return false, message
        else
            --[[
            This function has been disabled in favor of security and to not cause previously ulx banned players to be unbanned.
            It has been commented out because of possible usage in the future

            if ULib.bans[util.SteamIDFrom64(steamid64)] then
                userTransactions[steamid64] = true
                ULib.unban(target_steamid, calling_ply)
                -- Disabled because it could cause security issues with whitelisted servers
                --return true
            end
            ]]
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] User with steamid \"" .. steamid64 .. "\" has passed the ban check")
            return
        end
    end)

    hook.Add("PlayerDisconnected", "msync."..info.ModuleIdentifier..".saveDisconnects", function( ply )
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Disconnect: Adding player \"" .. tostring(ply) .. "\" to list of recent disconnects")
        if ply:IsBot() then return end
        local tableLength = table.Count(MSync.modules[info.ModuleIdentifier].recentDisconnects)
        local data = {
            name = ply:Name(),
            steamid = ply:SteamID(),
            steamid64 = ply:SteamID64()
        }

        MSync.modules[info.ModuleIdentifier].recentDisconnects[tableLength] = data
    end)

    hook.Add("ULibPlayerBanned", "msync.mbsync.ulxban", function(steamid, banData)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] ULX ban detected for user \"" .. steamid .. "\"")

        local ban = {}

        if userTransactions[util.SteamIDTo64(steamid)] then
            userTransactions[util.SteamIDTo64(steamid)] = nil
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] User has already been banned in MBSync, aborting ban")
            return
        end

        if banData.unban == 0 then
            ban.length = 0
        else
            ban.length = (banData.unban-os.time())/60
        end

        if not banData.reason then
            banData.reason = "(None given)"
        end

        if banData.modified_admin then
            if banData.modified_admin == "(Console)" then
                ban.admin = "STEAM_0:0:0"
            else
                ban.admin = string.match(banData.modified_admin, "STEAM_%d:%d:%d+")
            end
        else
            if banData.admin == "(Console)" then
                ban.admin = "STEAM_0:0:0"
            else
                ban.admin = string.match(banData.admin, "STEAM_%d:%d:%d+")
            end
        end

        MSync.modules[info.ModuleIdentifier].banUserID(steamid, ban.admin, ban.length, banData.reason, false)
    end)

    hook.Add("ULibPlayerUnBanned", "msync.mbsync.ulxunban", function(steamid, admin)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] ULX Unban detected for user \"" .. steamid .. "\"")

        if userTransactions[util.SteamIDTo64(steamid)] then
            userTransactions[util.SteamIDTo64(steamid)] = nil
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] User already has been unbanned from MBSync, aborting unban")
            return
        end

        local admin_id = ""
        if not IsValid(admin) then
            admin_id = "STEAM_0:0:0"
        else
            admin_id = admin:SteamID()
        end
        MSync.modules[info.ModuleIdentifier].unBanUser(steamid, admin_id)
    end)
end

--[[
    Define a function to run on the server when the module gets disabled
]]
MSync.modules[info.ModuleIdentifier].disable = function()
    hook.Remove("CheckPassword", "msync."..info.ModuleIdentifier..".banCheck")
    hook.Remove("PlayerDisconnected", "msync."..info.ModuleIdentifier..".saveDisconnects")
    hook.Remove("ULibPlayerBanned", "msync.mbsync.ulxban")
    hook.Remove("ULibPlayerUnBanned", "msync.mbsync.ulxunban")
    timer.Remove("msync."..info.ModuleIdentifier..".getActiveBans")
end

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules[info.ModuleIdentifier].info