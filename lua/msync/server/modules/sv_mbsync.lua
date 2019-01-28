MSync = MSync or {}
MSync.modules = MSync.modules or {}
MSync.modules.MBSync = MSync.modules.MBSync or {}
--[[
 * @file       sv_samplemodule.lua
 * @package    Sample Module
 * @author     Aperture Development
 * @license    root_dir/LICENCE
 * @version    1.0.0
]]

--[[
    Define name, description and module identifier
]]
MSync.modules.MBSync.info = {
    Name = "MySQL Ban Sync",
    ModuleIdentifier = "MBSync",
    Description = "Synchronise band across your servers",
    Version = "0.0.1"
}

--[[
    Define mysql table and additional functions that are later used
]]
function MSync.modules.MBSync.init( transaction ) 
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
            FOREIGN KEY (userid) REFERENCES tbl_users(p_user_id),
            FOREIGN KEY (adminid) REFERENCES tbl_users(p_user_id)
        );
    ]] ))
    
    --[[
        Description: Function to ban a player
        Returns: nothing
    ]]
    function MSync.modules.MBSync.banUser(ply, calling_ply, length, reason, allserver)
        local banUserQ = MSync.DBServer:prepare( [[
            INSERT INTO `tbl_mbsync` (user_id, admin_id, reason, date_unix, lenght_unix, server_group)
            VALUES (
                (SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?), 
                (SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?), 
            ?, ?, ?,
                (SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
            )
            ON DUPLICATE KEY UPDATE reason=VALUES(reason) AND lenght_unix=VALUES(lenght_unix) AND server_group=VALUES(server_group);
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
        Description: Function to unban a banId
        Returns: nothing
    ]]
    function MSync.modules.MBSync.unBanUserID(calling_ply, banId)
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
    function MSync.modules.MBSync.unBanUser(ply, calling_ply)
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
        if not allserver then
            banUserQ:setString(5, MSync.settings.data.serverGroup)
        else
            banUserQ:setString(5, "allservers")
        end
            
        unBanUserQ:start()
    end

    --[[
        Description: Function to get all bans
        Returns: nothing
    ]]
    function MSync.modules.MBSync.getBans(ply)
        local getBansQ = MSync.DBServer:prepare( [[
            SELECT * FROM `tbl_mbsync`;
        ]] )
        getBansQ:setString(1, ply:SteamID())
        unBanUserQ:setString(2, ply:SteamID64())
        unBanUserQ:setString(3, calling_ply:SteamID())
        unBanUserQ:setString(4, calling_ply:SteamID64())
        unBanUserQ:setString(5, reason)
        unBanUserQ:setNumber(6, os.time())
        unBanUserQ:setNumber(7, lenght)
        if not allserver then
            unBanUserQ:setString(8, MSync.settings.data.serverGroup)
        else
            unBanUserQ:setString(8, "allservers")
        end
            
        banunBanUserQUserQ:start()
    end

end

--[[
    Define net receivers and util.AddNetworkString
]]
function MSync.modules.MBSync.net() 
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
function MSync.modules.MBSync.ulx() 
    
end

--[[
    Define hooks your module is listening on e.g. PlayerDisconnect
]]
function MSync.modules.MBSync.hooks() 
    hook.Add("initialize", "msync_sampleModule_init", function()
        
    end)
end

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules.MBSync.info