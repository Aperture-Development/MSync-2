MSync = MSync or {}
MSync.modules = MSync.modules or {}
--[[
 * @file       sv_mbsync.lua
 * @package    MySQL Ban Sync
 * @author     Aperture Development
 * @license    root_dir/LICENSE
 * @version    0.0.4
]]

--[[
    Define name, description and module identifier
]]
local info = {
    Name = "MySQL Ban Sync",
    ModuleIdentifier = "MBSync",
    Description = "Synchronise bans across your servers",
    Version = "0.0.4"
}

--[[
    Prepare Module
]]
MSync.modules.[info.ModuleIdentifier] = MSync.modules.[info.ModuleIdentifier] or {}
MSync.modules.[info.ModuleIdentifier].info = info

--[[
    Define mysql table and additional functions that are later used
]]
function MSync.modules.[info.ModuleIdentifier].init( transaction ) 
    transaction:addQuery( MSync.DBServer:query([[
        CREATE TABLE IF NOT EXISTS `tbl_mbsync` (
            `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `user_id` INT UNSIGNED NOT NULL,
            `admin_id` INT UNSIGNED NOT NULL,
            `reason` VARCHAR(45) NOT NULL,
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
    function MSync.modules.[info.ModuleIdentifier].banUser(ply, calling_ply, length, reason, allserver)
        local banUserQ = MSync.DBServer:prepare( [[
            INSERT INTO `tbl_mbsync` (user_id, admin_id, reason, date_unix, length_unix, server_group)
            VALUES (
                (SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?), 
                (SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?), 
            ?, ?, ?,
                (SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
            );
        ]] )
        banUserQ:setString(1, ply:SteamID())
        banUserQ:setString(2, ply:SteamID64())
        banUserQ:setString(3, calling_ply:SteamID())
        banUserQ:setString(4, calling_ply:SteamID64())
        banUserQ:setString(5, reason)
        banUserQ:setNumber(6, os.time())
        banUserQ:setNumber(7, length)
        if not allserver then
            banUserQ:setString(8, MSync.settings.data.serverGroup)
        else
            banUserQ:setString(8, "allservers")
        end
            
        banUserQ:start()
    end

    --[[
        Description: Function to ban a userid
        Returns: nothing
    ]]
    function MSync.modules.[info.ModuleIdentifier].banUserID(userid, calling_ply, length, reason, allserver)
        local banUserIdQ = MSync.DBServer:prepare( [[
            INSERT INTO `tbl_mbsync` (user_id, admin_id, reason, date_unix, length_unix, server_group)
            VALUES (
                (SELECT p_user_id FROM tbl_users WHERE steamid=? OR steamid64=?), 
                (SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?), 
            ?, ?, ?,
                (SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
            );
        ]] )
        banUserIdQ:setString(1, userid)
        banUserIdQ:setString(2, userid)
        banUserIdQ:setString(3, calling_ply:SteamID())
        banUserIdQ:setString(4, calling_ply:SteamID64())
        banUserIdQ:setString(5, reason)
        banUserIdQ:setNumber(6, os.time())
        banUserIdQ:setNumber(7, length)
        if not allserver then
            banUserIdQ:setString(8, MSync.settings.data.serverGroup)
        else
            banUserIdQ:setString(8, "allservers")
        end
            
        banUserIdQ:start()
    end

    --[[
        Description: Function to edit a ban
        Returns: nothing
    ]]
    function MSync.modules.[info.ModuleIdentifier].editBan(banId, reason, length, calling_ply, allserver)
        local editBanQ = MSync.DBServer:prepare( [[
            UPDATE `tbl_mbsync`
            SET 
                reason=?,
                length_unix=?,
                adminid=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?),
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
            
        editBanQ:start()
    end

    --[[
        Description: Function to unban a banId
        Returns: nothing
    ]]
    function MSync.modules.[info.ModuleIdentifier].unBanUserID(calling_ply, banId)
        local unBanUserIdQ = MSync.DBServer:prepare( [[
            UPDATE `tbl_mbsync`
            SET ban_lifted=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?)
            WHERE p_ID=? 
        ]] )
        unBanUserIdQ:setString(1, calling_ply:SteamID())
        unBanUserIdQ:setString(2, calling_ply:SteamID64())
        unBanUserIdQ:setString(3, banId)
            
        unBanUserIdQ:start()
    end

    --[[
        Description: Function to unban a user
        Returns: nothing
    ]]
    function MSync.modules.[info.ModuleIdentifier].unBanUser(ply, calling_ply)
        local unBanUserQ = MSync.DBServer:prepare( [[
            UPDATE `tbl_mbsync`
            SET 
                ban_lifted=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?)
            WHERE 
                user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?) AND 
                server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
        ]] )
        unBanUserQ:setString(1, calling_ply:SteamID())
        unBanUserQ:setString(2, calling_ply:SteamID64())
        unBanUserQ:setString(3, ply:SteamID())
        unBanUserQ:setString(4, ply:SteamID64())
        unBanUserQ:setString(5, MSync.settings.data.serverGroup)
            
        unBanUserQ:start()
    end

    --[[
        Description: Function to get all bans
        Returns: nothing
    ]]
    function MSync.modules.[info.ModuleIdentifier].getBans(ply)
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
                ON tbl_mbsync.userid = banned.p_user_id
            LEFT JOIN tbl_users AS admin 
                ON tbl_mbsync.adminid = admin.p_user_id
            LEFT JOIN tbl_users AS unban_admin 
                ON tbl_mbsync.ban_lifted = unban_admin.p_user_id
            ;
        ]] )
        end
        

        function getBansQ.onData( q, data, ply )
            
            local banTable = {}

            print("[MBSync] Recieved all ban data")

            for k,v in pairs(data) do

                banTable[v.p_id] = {
                    reason = v.reason
                    banDate = os.date( "%H:%M:%S - %d/%m/%Y" , v.date_unix )
                    banlength = v.length_unix
                    bannedUser = {
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

            MSync.modules.[info.ModuleIdentifier].sendSettings(ply, banTable)

        end

        getBansQ:start()
    end

    --[[
        Description: Function to get all active bans
        Returns: nothing
    ]]
    function MSync.modules.[info.ModuleIdentifier].getActiveBans()
        local getActiveBansQ = MSync.DBServer:prepare( [[
            SELECT 
                tbl_mbsync.*,
                banned.steamid,
                banned.steamid64,
                banned.nickname AS 'banned.nickname',
                admin.nickname AS 'admin.nickname'
            FROM `tbl_mbsync`
            LEFT JOIN tbl_users AS banned
                ON tbl_mbsync.userid = banned.p_group_id
            LEFT JOIN tbl_users AS admin
                ON tbl_mbsync.adminid = admin.p_group_id
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
        
        function getActiveBansQ.onData( q, data )
            
            local banTable = {}

            print("[MBSync] Recieved ban data")

            for k,v in pairs(data) do

                banTable[v.steamid64] = {
                    banId = v.p_id,
                    reason = v.reason,
                    timestamp = v.date_unix,
                    length = v.length_unix,
                    banned = {
                        steamid = v.steamid
                        Nickname = v["banned.nickname"]
                    },
                    adminNickname = v["admin.nickname"]
                }

            end

            MSync.modules.[info.ModuleIdentifier].banTable = banTable

        end

        getActiveBansQ:start()
    end

end

--[[
    Define net receivers and util.AddNetworkString
]]
function MSync.modules.[info.ModuleIdentifier].net() 

    --[[
        Description: Function to send a message to a player
        Arguments:
            player [player] - the player that wants to open the admin GUI
            text [string] - the text you want to send to the client
        Returns: nothing
    ]]  
    util.AddNetworkString("msync."..[info.ModuleIdentifier]..".sendMessage")
    function MSync.modules.[info.ModuleIdentifier].sendSettings(ply, text)
        net.Start("msync."..[info.ModuleIdentifier]..".sendMessage")
            net.WriteString(text)
        net.Send(ply)
    end

    --[[
        Description: Function to send the ban list to a player
        Arguments:
            player [player] - the player that wants to open the admin GUI
            banTable [table] - the ban table
        Returns: nothing
    ]]  
    util.AddNetworkString("msync."..[info.ModuleIdentifier]..".sendBanTable")
    function MSync.modules.[info.ModuleIdentifier].sendSettings(ply, banTable)
        net.Start("msync."..[info.ModuleIdentifier]..".sendBanTable")
            net.WriteTable(banTable)
        net.Send(ply)
    end

    --[[
        TODO: 
        - Edit Ban
        - unban
        - ban
        - banid
        - checkban
    ]]
end

--[[
    Define ulx Commands and overwrite common ulx functions (module does not get loaded until ulx has fully been loaded)
]]
function MSync.modules.[info.ModuleIdentifier].ulx() 
    MSync.modules.[info.ModuleIdentifier].Chat = MSync.modules.[info.ModuleIdentifier].Chat or {}

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
    function MSync.modules.[info.ModuleIdentifier].Chat.banPlayer(calling_ply, target_ply, length, allserver, reason)
        if not calling_ply:query("msync."..(info.ModuleIdentifier)..".banPlayer") then return end;
        if not IsValid(calling_ply) then return end;

        MSync.modules.[info.ModuleIdentifier].banUser(target_ply, calling_ply, length, reason, allserver)

        
    end
    local BanPlayer = ulx.command( "MSync", "msync."..(info.ModuleIdentifier)..".banPlayer", MSync.modules.[info.ModuleIdentifier].Chat.banPlayer, "!mban" )
    BanPlayer:addParam{ type=ULib.cmds.PlayerArg, hint="player", ULib.cmds.optional}
	BanPlayer:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
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
    function MSync.modules.[info.ModuleIdentifier].Chat.banSteamID(calling_ply, target_steamid, length, allserver, reason)
        if not calling_ply:query("msync."..(info.ModuleIdentifier)..".banSteamID") then return end;

    end
    local BanPlayer = ulx.command( "MSync", "msync."..(info.ModuleIdentifier)..".banSteamID", MSync.modules.[info.ModuleIdentifier].Chat.banSteamID, "!mbanid" )
    BanPlayer:addParam{ type=ULib.cmds.StringArg, hint="steamid"}
	BanPlayer:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
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
    function MSync.modules.[info.ModuleIdentifier].Chat.unBanID(calling_ply, target_steamid)
        if not calling_ply:query("msync."..(info.ModuleIdentifier)..".unBanID") then return end;

    end
    local BanPlayer = ulx.command( "MSync", "msync."..(info.ModuleIdentifier)..".unBanID", MSync.modules.[info.ModuleIdentifier].Chat.unBanID, "!munban" )
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
    function MSync.modules.[info.ModuleIdentifier].Chat.checkBan(calling_ply, target_steamid)
        if not calling_ply:query("msync."..(info.ModuleIdentifier)..".checkBan") then return end;

    end
    local BanPlayer = ulx.command( "MSync", "msync."..(info.ModuleIdentifier)..".checkBan", MSync.modules.[info.ModuleIdentifier].Chat.checkBan, "!mcheck" )
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
    function MSync.modules.[info.ModuleIdentifier].Chat.openBanTable(calling_ply)
        if not calling_ply:query("msync."..(info.ModuleIdentifier)..".openBanTable") then return end;

    end
    local BanPlayer = ulx.command( "MSync", "msync."..(info.ModuleIdentifier)..".openBanTable", MSync.modules.[info.ModuleIdentifier].openBanGUI, "!mbsync" )
    BanPlayer:defaultAccess( ULib.ACCESS_SUPERADMIN )
    BanPlayer:help( "Opens MSync Settings." )


end

--[[
    Define hooks your module is listening on e.g. PlayerDisconnect
]]
function MSync.modules.[info.ModuleIdentifier].hooks() 
    hook.Add("initialize", "msync_sampleModule_init", function()
        
    end)
end

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules.[info.ModuleIdentifier].info