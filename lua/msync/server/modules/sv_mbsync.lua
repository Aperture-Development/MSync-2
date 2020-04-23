MSync = MSync or {}
MSync.modules = MSync.modules or {}
--[[
 * @file       sv_mbsync.lua
 * @package    MySQL Ban Sync
 * @author     Aperture Development
 * @license    root_dir/LICENSE
 * @version    0.0.6
]]

--[[
    Define name, description and module identifier
]]
local info = {
    Name = "MySQL Ban Sync",
    ModuleIdentifier = "MBSync",
    Description = "Synchronise bans across your servers",
    Version = "0.0.6"
}

--[[
    Prepare Module
]]
MSync.modules[info.ModuleIdentifier] = MSync.modules[info.ModuleIdentifier] or {}
MSync.modules[info.ModuleIdentifier].info = info
MSync.modules[info.ModuleIdentifier].recentDisconnects = MSync.modules[info.ModuleIdentifier].recentDisconnects or {}

--[[
    Define mysql table and additional functions that are later used
]]
MSync.modules[info.ModuleIdentifier].init = function( transaction )
    transaction:addQuery( MSync.DBServer:query([[
        CREATE TABLE IF NOT EXISTS `tbl_mbsync` (
            `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `user_id` INT UNSIGNED NOT NULL,
            `admin_id` INT UNSIGNED NOT NULL,
            `reason` VARCHAR(100) NOT NULL,
            `date_unix` float NOT NULL,
            `length_unix` float NOT NULL,
            `server_group` INT UNSIGNED NOT NULL,
            `ban_lifted` INT UNSIGNED,
            FOREIGN KEY (server_group) REFERENCES tbl_server_grp(p_group_id),
            FOREIGN KEY (user_id) REFERENCES tbl_users(p_user_id),
            FOREIGN KEY (admin_id) REFERENCES tbl_users(p_user_id)
        );
    ]] ))

    --[[
        Description: Function to ban a player
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].banUser = function(ply, calling_ply, length, reason, allserver)
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
        banUserQ:setString(3, calling_ply:SteamID())
        banUserQ:setString(4, calling_ply:SteamID64())
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
            local msgLength
            local msgReason
            local banData = {
                admin = calling_ply:Nick(),
                reason = reason,
                unban = timestamp+(length*60),
                time = timestamp
            }
            if length == 0 then
                banData["unban"] = length
                msgLength = "Permanent"
            else
                msgLength = ULib.secondsToStringTime(length)
            end

            if reason == "" then
                msgReason = "(None given)"
            end

            ply:Kick("\n"..ULib.getBanMessage( ply:SteamID(), banData))
            MSync.modules[info.ModuleIdentifier].getActiveBans()
            MSync.modules[info.ModuleIdentifier].msg(calling_ply, "Banned "..ply:Nick().." for "..msgLength.." with reason "..msgReason)
        end

        banUserQ.onError = function( q, err, sql )
            print("------------------------------------")
            print("[MBSync] SQL Error!")
            print("------------------------------------")
            print("Please include this in a Bug report:\n")
            print(err.."\n")
            print("------------------------------------")
            print("Do not include this, this is for debugging only:\n")
            print(sql.."\n")
            print("------------------------------------")
        end

        banUserQ:start()
    end

    --[[
        Description: Function to ban a userid
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].banUserID = function(userid, calling_ply, length, reason, allserver)
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
        banUserIdQ:setString(3, calling_ply:SteamID())
        banUserIdQ:setString(4, calling_ply:SteamID64())
        banUserIdQ:setString(5, reason)
        banUserIdQ:setNumber(6, timestamp)
        banUserIdQ:setNumber(7, length)
        if not allserver then
            banUserIdQ:setString(8, MSync.settings.data.serverGroup)
        else
            banUserIdQ:setString(8, "allservers")
        end

        banUserIdQ.onSuccess = function( q, data )
            -- Notify the user about the ban and add it to ULib to prevent data loss on Addon Remove
            -- Also, kick the user from the server
            local banData = {
                admin = calling_ply:Nick(),
                reason = reason,
                unban = timestamp+(length*60),
                time = timestamp
            }
            if length == 0 then
                banData["unban"] = length
                msgLength = "Permanent"
            else
                msgLength = ULib.secondsToStringTime(length)
            end

            if reason == "" then
                msgReason = "(None given)"
            else
                msgReason = reason
            end

            MSync.modules[info.ModuleIdentifier].msg(calling_ply, "Banned "..userid.." for "..msgLength.." with reason "..msgReason)

            if not player.GetBySteamID(userid) then return end

            player.GetBySteamID(userid):Kick("\n"..ULib.getBanMessage( userid, banData))
            MSync.modules[info.ModuleIdentifier].getActiveBans()
        end

        banUserIdQ.onError = function( q, err, sql )
            print("------------------------------------")
            print("[MBSync] SQL Error!")
            print("------------------------------------")
            print("Please include this in a Bug report:\n")
            print(err.."\n")
            print("------------------------------------")
            print("Do not include this, this is for debugging only:\n")
            print(sql.."\n")
            print("------------------------------------")
        end

        banUserIdQ:start()
    end

    --[[
        Description: Function to edit a ban
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].editBan = function(banId, reason, length, calling_ply, allserver)
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
        editBanQ:setString(2, length)
        editBanQ:setString(3, calling_ply:SteamID())
        editBanQ:setString(4, calling_ply:SteamID64())
        if not allserver then
            editBanQ:setString(5, MSync.settings.data.serverGroup)
        else
            editBanQ:setString(5, "allservers")
        end
        editBanQ:setString(6, banId)

        editBanQ.onSuccess = function( q, data )
            MSync.modules[info.ModuleIdentifier].getActiveBans()
            MSync.modules[info.ModuleIdentifier].msg(calling_ply, "Edited ban with id "..banId.." with length "..length.." with reason "..reason)
        end

        editBanQ.onError = function( q, err, sql )
            print("------------------------------------")
            print("[MBSync] SQL Error!")
            print("------------------------------------")
            print("Please include this in a Bug report:\n")
            print(err.."\n")
            print("------------------------------------")
            print("Do not include this, this is for debugging only:\n")
            print(sql.."\n")
            print("------------------------------------")
        end

        editBanQ:start()
    end

    --[[
        Description: Function to unban a banId
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].unBanUserID = function(calling_ply, banId)
        local unBanUserIdQ = MSync.DBServer:prepare( [[
            UPDATE `tbl_mbsync`
            SET ban_lifted=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?)
            WHERE p_ID=? 
        ]] )
        unBanUserIdQ:setString(1, calling_ply:SteamID())
        unBanUserIdQ:setString(2, calling_ply:SteamID64())
        unBanUserIdQ:setNumber(3, banId)

        unBanUserIdQ.onSuccess = function( q, data )
            MSync.modules[info.ModuleIdentifier].getActiveBans()
            MSync.modules[info.ModuleIdentifier].msg(calling_ply, "Removed ban with id "..banId)
        end

        unBanUserIdQ.onError = function( q, err, sql )
            print("------------------------------------")
            print("[MBSync] SQL Error!")
            print("------------------------------------")
            print("Please include this in a Bug report:\n")
            print(err.."\n")
            print("------------------------------------")
            print("Do not include this, this is for debugging only:\n")
            print(sql.."\n")
            print("------------------------------------")
        end

        unBanUserIdQ:start()
    end

    --[[
        Description: Function to unban a user
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].unBanUser = function(ply_steamid, calling_ply)
        local unBanUserQ = MSync.DBServer:prepare( [[
            UPDATE `tbl_mbsync`
            SET 
                ban_lifted=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?)
            WHERE 
                user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? OR steamid64=?) AND 
                server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
        ]] )
        unBanUserQ:setString(1, calling_ply:SteamID())
        unBanUserQ:setString(2, calling_ply:SteamID64())
        unBanUserQ:setString(3, ply_steamid)
        unBanUserQ:setString(4, ply_steamid)
        unBanUserQ:setString(5, MSync.settings.data.serverGroup)

        unBanUserQ.onSuccess = function( q, data )
            MSync.modules[info.ModuleIdentifier].getActiveBans()
            MSync.modules[info.ModuleIdentifier].msg(calling_ply, "Unbanned "..ply_steamid)
        end

        unBanUserQ.onError = function( q, err, sql )
            print("------------------------------------")
            print("[MBSync] SQL Error!")
            print("------------------------------------")
            print("Please include this in a Bug report:\n")
            print(err.."\n")
            print("------------------------------------")
            print("Do not include this, this is for debugging only:\n")
            print(sql.."\n")
            print("------------------------------------")
        end

        unBanUserQ:start()
    end

    --[[
        Description: Function to get all bans
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].getBans = function(ply, fullTable)
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

            print("[MBSync] Recieved all ban data")
            if fullTable then
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
            print("------------------------------------")
            print("[MBSync] SQL Error!")
            print("------------------------------------")
            print("Please include this in a Bug report:\n")
            print(err.."\n")
            print("------------------------------------")
            print("Do not include this, this is for debugging only:\n")
            print(sql.."\n")
            print("------------------------------------")
        end

        getBansQ:start()
    end

    --[[
        Description: Function to get all active bans
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].getActiveBans = function()
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
        getActiveBansQ:setString(8, MSync.settings.data.serverGroup)

        getActiveBansQ.onSuccess = function( q, data )

            local banTable = {}

            print("[MBSync] Recieved ban data")
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

                    v:Kick(message)
                else
                    -- Do nothing
                end
            end

            --[[
                TODO: After recieving data, we need to write the current ban data into ULib
            ]]

        end

        getActiveBansQ.onError = function( q, err, sql )
            print("------------------------------------")
            print("[MBSync] SQL Error!")
            print("------------------------------------")
            print("Please include this in a Bug report:\n")
            print(err.."\n")
            print("------------------------------------")
            print("Do not include this, this is for debugging only:\n")
            print(sql.."\n")
            print("------------------------------------")
        end

        getActiveBansQ:start()
    end

    --[[
        Description: Function to get all active bans
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].exportBansToULX = function()
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
        exportActiveBans:setString(8, MSync.settings.data.serverGroup)

        exportActiveBans.onSuccess = function( q, data )

            local function escapeString( str )
                if not str then
                    return "NULL"
                else
                    return sql.SQLStr(str)
                end
            end

            print("[MBSync] Exporting Bans to ULX")
            for k,v in pairs(data) do
                local unban
                if v.length_unix == 0 then
                    unban = 0
                else
                    unban = v.date_unix + v.length_unix
                end

                ULib.bans[ v["steamid"] ] = {
                    admin = v["admin.nickname"],
                    time = v.date_unix,
                    unban = unban,
                    reason = v.reason,
                    name = v["banned.nickname"]
                }
                hook.Call( ULib.HOOK_USER_BANNED, _, v["steamid"], ULib.bans[ v["steamid"] ] )
            end
            ULib.fileWrite( ULib.BANS_FILE, ULib.makeKeyValues( ULib.bans ) )
            print("[MBSync] Export finished")

        end

        exportActiveBans.onError = function( q, err, sql )
            print("------------------------------------")
            print("[MBSync] SQL Error!")
            print("------------------------------------")
            print("Please include this in a Bug report:\n")
            print(err.."\n")
            print("------------------------------------")
            print("Do not include this, this is for debugging only:\n")
            print(sql.."\n")
            print("------------------------------------")
        end

        exportActiveBans:start()
    end

    --[[
        Description: Function to load the MSync settings file
        Returns: true
    ]]
    MSync.modules[info.ModuleIdentifier].loadSettings = function()
        if not file.Exists("msync/"..info.ModuleIdentifier..".txt", "DATA") then
            MSync.modules[info.ModuleIdentifier].settings = {
                syncDelay = 300
            }
            file.Write("msync/"..info.ModuleIdentifier..".txt", util.TableToJSON(MSync.modules[info.ModuleIdentifier].settings, true))
        else
            MSync.modules[info.ModuleIdentifier].settings = util.JSONToTable(file.Read("msync/mbsync.txt", "DATA"))
        end

        return true
    end

    --[[
        Description: Function to save the MSync settings to the settings file
        Returns: true if the settings file exists
    ]]
    MSync.modules[info.ModuleIdentifier].saveSettings = function()
        file.Write("msync/"..info.ModuleIdentifier..".txt", util.TableToJSON(MSync.modules[info.ModuleIdentifier].settings, true))
        return file.Exists("msync/"..info.ModuleIdentifier..".txt", "DATA")
    end

    --[[
        Description: Function to split table into multible 10er parts
        Returns: table split in 10er part counts
    ]]
    MSync.modules[info.ModuleIdentifier].splitTable = function(tbl)
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
    MSync.modules[info.ModuleIdentifier].msg = function(ply, content, type)
        if not type then type = 0 end
        -- Basic message
        if type == 0 then
            net.Start("msync."..info.ModuleIdentifier..".sendMessage")
                net.WriteFloat(type)
                net.WriteString(content)
            net.Send(ply)
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
        net.Start("msync."..info.ModuleIdentifier..".openBanTable")
        net.Send(ply)
    end

    --[[
        Description: Net Receiver - Gets called when the client banned a player with the ban gui
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".banid")
    net.Receive("msync."..info.ModuleIdentifier..".banid", function(len, ply)
        if not ply:query("msync."..info.ModuleIdentifier..".banPlayer") then return end

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
        if not ply:query("msync."..info.ModuleIdentifier..".banPlayer") then return end

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
        if not ply:query("msync."..info.ModuleIdentifier..".unBanID") then return end

        local banid = net.ReadFloat()

        --[[
            Error check and fill in of default data
        ]]

        if not banid then return end;

        --[[
            Run edit function to edit ban data
        ]]
        MSync.modules[info.ModuleIdentifier].unBanUserID(ply, banid)
    end )

    --[[
        Description: Function to send the mbsync settings to the client
        Arguments:
            player [player] - the player that wants to open the admin GUI
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".sendSettingsPly")
    MSync.modules[info.ModuleIdentifier].sendSettings = function(ply)
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
        if not ply:query("msync.getSettings") then return end

        MSync.modules[info.ModuleIdentifier].sendSettings(ply)
    end )

    --[[
        Description: Net Receiver - Gets called when the client wants to open the ban gui
        Returns: nothing
    ]]
    util.AddNetworkString("msync."..info.ModuleIdentifier..".sendSettings")
    net.Receive("msync."..info.ModuleIdentifier..".sendSettings", function(len, ply)
        if not ply:query("msync.sendSettings") then return end

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
        print(number)
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
        local fullTable = net.ReadBool()
        if fullTable then
            if not ply:query("msync.openAdminGUI") then return end
            MSync.modules[info.ModuleIdentifier].getBans(ply, fullTable)
        else
            if not ply:query("msync."..info.ModuleIdentifier..".openBanTable") then return end
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
        TODO: The whole Command
        Expected behaviour:
        Without any argument, open ban GUI
        With arguments, run ban command

        Arguments:
            target [player] - the player target
            length [number] - the ban length - OPTIONAL - Default: 0/Permanent
            allserver [bool] - if its on all servers - OPTIONAL - Default: 0/false
            reason [string] - the ban reason - OPTIONAL - Default: "banned by staff"
    ]]
    MSync.modules[info.ModuleIdentifier].Chat.banPlayer = function(calling_ply, target_ply, length, allserver, reason)
        if not calling_ply:query("msync."..info.ModuleIdentifier..".banPlayer") then return end;
        if not IsValid(calling_ply) then return end;

        if calling_ply == target_ply then
            MSync.modules[info.ModuleIdentifier].openBanGUI(calling_ply)
        else
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
            MSync.modules[info.ModuleIdentifier].banUser(target_ply, calling_ply, length, reason, allserver)
        end
    end
    local BanPlayer = ulx.command( "MSync", "msync."..info.ModuleIdentifier..".banPlayer", MSync.modules[info.ModuleIdentifier].Chat.banPlayer, "!mban" )
    BanPlayer:addParam{ type=ULib.cmds.PlayerArg, hint="player", ULib.cmds.optional}
    BanPlayer:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="true/false, if the player should be banned on all servers", ULib.cmds.optional }
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
    BanPlayer:defaultAccess( ULib.ACCESS_SUPERADMIN )
    BanPlayer:help( "Opens the MBSync GUI ( without parameters ) or bans a player" )

    --[[
        TODO: The whole Command
        Expected behaviour:
        ban the targeted steamid

        Arguments:
            target_steamid [string] - the target steamid
            length [number] - the ban length - OPTIONAL - Default: 0/Permanent
            allserver [bool] - if its on all servers - OPTIONAL - Default: 0/false
            reason [string] - the ban reason - OPTIONAL - Default: "banned by staff"
    ]]
    MSync.modules[info.ModuleIdentifier].Chat.banSteamID = function(calling_ply, target_steamid, length, allserver, reason)
        if not calling_ply:query("msync."..info.ModuleIdentifier..".banSteamID") then return end;

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

        if not reason then reason = "No reason given" end

        --[[
            Run ban function with given functions
        ]]

        MSync.modules[info.ModuleIdentifier].banUserID(target_steamid, calling_ply, length, reason, allserver)

    end
    local BanPlayer = ulx.command( "MSync", "msync."..info.ModuleIdentifier..".banSteamID", MSync.modules[info.ModuleIdentifier].Chat.banSteamID, "!mbanid" )
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="steamid"}
    BanPlayer:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="true/false, if the player should be banned on all servers", ULib.cmds.optional }
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
    BanPlayer:defaultAccess( ULib.ACCESS_SUPERADMIN )
    BanPlayer:help( "Opens MSync Settings." )

    --[[
        TODO: The whole Command
        Expected behaviour:
        unban a user with the given steamid

        Arguments:
            target_steamid [string] - the target steamid
    ]]
    MSync.modules[info.ModuleIdentifier].Chat.unBanID = function(calling_ply, target_steamid)
        if not calling_ply:query("msync."..info.ModuleIdentifier..".unBanID") then return end;

        --[[
            Check for empty or invalid steamid
        ]]
        if not target_steamid or not ULib.isValidSteamID(target_steamid) then return end

        --[[
            Unban user with given steamid
        ]]
        MSync.modules[info.ModuleIdentifier].unBanUser(target_steamid, calling_ply)
    end
    local BanPlayer = ulx.command( "MSync", "msync."..info.ModuleIdentifier..".unBanID", MSync.modules[info.ModuleIdentifier].Chat.unBanID, "!munban" )
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="steamid"}
    BanPlayer:defaultAccess( ULib.ACCESS_SUPERADMIN )
    BanPlayer:help( "Opens MSync Settings." )

    --[[
        TODO: The whole Command
        Expected behaviour:
        check if a player is banned

        Arguments:
            target_steamid [string] - the target steamid
    ]]
    MSync.modules[info.ModuleIdentifier].Chat.checkBan = function(calling_ply, target_steamid)
        if not calling_ply:query("msync."..info.ModuleIdentifier..".checkBan") then return end;

        if not target_steamid or not ULib.isValidSteamID(target_steamid) then return end

        if MSync.modules[info.ModuleIdentifier].banTable[util.SteamIDTo64(target_steamid)] then

            --[[
                Load the ban date from the activa ben table to a local variable
            ]]
            local banData = MSync.modules[info.ModuleIdentifier].banTable[util.SteamIDTo64(target_steamid)]

            --[[
                Translate ban length and Date into readable values
            ]]

            if banData.length == 0 then
                banData.length = "permanent"
            else
                banData.length = os.date( "%H:%M:%S - %d/%m/%Y", banData.timestamp + banData.length)
            end

            banData.timestamp = os.date( "%H:%M:%S - %d/%m/%Y", banData.timestamp)

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
    BanPlayer:help( "Opens MSync Settings." )

    --[[
        TODO: The whole Command
        Expected behaviour:
        opens the ban table

        Arguments:
            none
    ]]
    MSync.modules[info.ModuleIdentifier].Chat.openBanTable = function(calling_ply)
        if not calling_ply:query("msync."..info.ModuleIdentifier..".openBanTable") then return end;
        -- Open Ban Table
        MSync.modules[info.ModuleIdentifier].openBanTable(calling_ply)
    end
    local BanPlayer = ulx.command( "MSync", "msync."..info.ModuleIdentifier..".openBanTable", MSync.modules[info.ModuleIdentifier].Chat.openBanTable, "!mbsync" )
    BanPlayer:defaultAccess( ULib.ACCESS_SUPERADMIN )
    BanPlayer:help( "Opens MSync Settings." )

    --[[
        TODO: The whole Command
        Expected behaviour:
        Edits the ban with the given banID

        Arguments:
            banID [number] - the ban id
            length [number] - the ban length - OPTIONAL - Default: 0/Permanent
            allserver [bool] - if its on all servers - OPTIONAL - Default: 0/false
            reason [string] - the ban reason - OPTIONAL - Default: "banned by staff"
    ]]
    MSync.modules[info.ModuleIdentifier].Chat.editBan = function(calling_ply, ban_id, length, allserver, reason)
        if not calling_ply:query("msync."..info.ModuleIdentifier..".editBan") then return end;
        if not IsValid(calling_ply) then return end;

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
        MSync.modules[info.ModuleIdentifier].editBan(tostring(ban_id), tostring(reason), tostring(length), calling_ply, allserver)
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
        TODO: Improove hook

        This hook starts the timers for the asynchronous ban data loading and the check if one of the online players has been banned
    ]]
    timer.Create("msync."..info.ModuleIdentifier..".getActiveBans", MSync.modules[info.ModuleIdentifier].settings.syncDelay, 0, function()
        MSync.modules[info.ModuleIdentifier].getActiveBans()
    end)
    MSync.modules[info.ModuleIdentifier].getActiveBans()

    hook.Add("CheckPassword", "msync."..info.ModuleIdentifier..".banCheck", function( steamid64 )
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
            print("---== [MBSync] ==---")
            print("A banned player tried to join the server.")
            print("-- Informations --")
            print("Nickname: "..ban.banned.nickname)
            print("SteamID: "..ban.banned.steamid)
            print("Ban Date: "..os.date( "%c", ban.timestamp))
            print("Unban Date: "..unbanDate)
            print("Banned by: "..ban.adminNickname)
            print("---== [END] ==---")

            --[[
                Translate ban data for ULib
            ]]
            local banData = {
                admin = ban.adminNickname,
                reason = ban.reason,
                unban = ban.timestamp+ban.length,
                time = ban.timestamp
            }

            local message = ULib.getBanMessage( ban.banned.steamid, banData)
            return false, message
        else
            return
        end
    end)

    hook.Add("PlayerDisconnected", "msync."..info.ModuleIdentifier..".saveDisconnects", function( ply )
        if ply:IsBot() then return end
        local tableLength = table.Count(MSync.modules[info.ModuleIdentifier].recentDisconnects)
        local data = {
            name = ply:Name(),
            steamid = ply:SteamID(),
            steamid64 = ply:SteamID64()
        }

        MSync.modules[info.ModuleIdentifier].recentDisconnects[tableLength] = data
    end)
end

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules[info.ModuleIdentifier].info