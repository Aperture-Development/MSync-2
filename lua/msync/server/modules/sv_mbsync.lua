MSync = MSync or {}
MSync.modules = MSync.modules or {}
--[[
 * @file       sv_mbsync.lua
 * @package    MySQL Ban Sync
 * @author     Aperture Development
 * @license    root_dir/LICENCE
 * @version    0.0.3
]]

--[[
    Define name, description and module identifier
]]
local info = {
    Name = "MySQL Ban Sync",
    ModuleIdentifier = "MBSync",
    Description = "Synchronise bans across your servers",
    Version = "0.0.3"
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
            `lenght_unix` float NOT NULL,
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
            INSERT INTO `tbl_mbsync` (user_id, admin_id, reason, date_unix, lenght_unix, server_group)
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
        banUserQ:setNumber(7, lenght)
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
            INSERT INTO `tbl_mbsync` (user_id, admin_id, reason, date_unix, lenght_unix, server_group)
            VALUES (
                (SELECT p_user_id FROM tbl_users WHERE steamid=? OR steamid64=? OR p_user_id=?), 
                (SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?), 
            ?, ?, ?,
                (SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
            );
        ]] )
        banUserIdQ:setString(1, userid)
        banUserIdQ:setString(2, userid)
        banUserIdQ:setString(3, userid)
        banUserIdQ:setString(4, calling_ply:SteamID())
        banUserIdQ:setString(5, calling_ply:SteamID64())
        banUserIdQ:setString(6, reason)
        banUserIdQ:setNumber(7, os.time())
        banUserIdQ:setNumber(8, lenght)
        if not allserver then
            banUserIdQ:setString(9, MSync.settings.data.serverGroup)
        else
            banUserIdQ:setString(9, "allservers")
        end
            
        banUserIdQ:start()
    end

    --[[
        Description: Function to edit a ban
        Returns: nothing
    ]]
    function MSync.modules.[info.ModuleIdentifier].editBan(banId, reason, lenght, calling_ply, allserver)
        local editBanQ = MSync.DBServer:prepare( [[
            UPDATE `tbl_mbsync`
            SET 
                reason=?,
                lenght_unix=?,
                adminid=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?),
                server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
            WHERE p_ID=?
        ]] )
        editBanQ:setString(1, reason)
        editBanQ:setString(2, lenght)
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
                tbl_mbsync.lenght_unix,
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
        --[[
            Ban Table Lua structure:
            bans = {
                [tbl_mbsync.p_id] = {
                    reason =  tbl_mbsync.reason
                    banDate = tbl_mbsync.date_unix
                    banLenght = tbl_mbsync.lenght_unix
                    bannedUser = {
                        steamid = banned.steamid
                        steamid64 = banned.steamid64
                        nickname = banned.nickname
                    }
                    banningAdmin = {
                        steamid = admin.steamid
                        steamid64 = admin.steamid64
                        nickname = admin.nickname
                    }
                    unBanningAdmin = {
                        steamid = unban_admin.steamid
                        steamid64 = unban_admin.steamid64
                        nickname = unban_admin.nickname
                    }
                }
            }
        ]]
        banunBanUserQUserQ:start()
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
                banned.nickname,
                admin.nickname
            FROM `tbl_mbsync`
            LEFT JOIN tbl_users AS banned
                ON tbl_mbsync.userid = banned.p_group_id
            LEFT JOIN tbl_users AS admin
                ON tbl_mbsync.adminid = admin.p_group_id
            WHERE
                ban_lifted IS NULL AND
                (
                    (date_unix+lenght_unix)>? OR
                     lenght_unix=0
                ) AND
                (
                    server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?) OR
                    server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers')
                )
        ]] )
        getActiveBansQ:setNumber(1, os.time())
        getActiveBansQ:setString(8, MSync.settings.data.serverGroup)
        --[[
            Ban Table Lua structure:
            activeBans = {
                [banned.steamid64] = {
                    banId = tbl_mbsync.p_id
                    reason = tbl_mbsync.reason
                    timestamp = tbl_mbsync.date_unix
                    length = tbl_mbsync.lenght_unix
                    banned = {
                        steamid = banned.steamid
                        Nickname = banned.nickname
                    }
                    adminNickname = admin.nickname
                }
            }
        ]]
        function getActiveBansQ.onData( q, data )
            if data.rank == ply:GetUserGroup() then return end;

            ply:SetUserGroup(data[1].rank)
        end

        getActiveBansQ:start()
    end

end

--[[
    Define net receivers and util.AddNetworkString
]]
function MSync.modules.[info.ModuleIdentifier].net() 
    net.Receive( "my_message", function( len, pl )
        if ( IsValid( pl ) and pl:IsPlayer() ) then
            print( "Message from " .. pl:Nick() .. " received. Its length is " .. len .. "." )
        else
            print( "Message from server received. Its length is " .. len .. "." )
        end
    end )
end

--[[
    Define ulx Commands and overwrite common ulx functions (module does not get loaded until ulx has fully been loaded)
]]
function MSync.modules.[info.ModuleIdentifier].ulx() 
    
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