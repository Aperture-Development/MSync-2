MSync = MSync or {}
MSync.modules = MSync.modules or {}
MSync.modules.MRSync = MSync.modules.MRSync or {}
local userTransaction = userTransaction or {}
--[[
 * @file       sv_mrsync.lua
 * @package    MySQL Rank Sync
 * @author     Aperture Development
 * @license    root_dir/LICENCE
 * @version    2.2.2
]]

--[[
    Define name, description and module identifier
]]
MSync.modules.MRSync.info = {
    Name = "MySQL Rank Sync",
    ModuleIdentifier = "MRSync",
    Description = "Synchronise your ranks across your servers",
    Version = "2.2.2"
}

--[[
    Define mysql table and additional functions that are later used
]]
function MSync.modules.MRSync.init( transaction )
    MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Exec: MRSync.init")
    transaction:addQuery( MSync.DBServer:query([[
        CREATE TABLE IF NOT EXISTS `tbl_mrsync` (
            `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `user_id` INT UNSIGNED NOT NULL,
            `rank` VARCHAR(15) NOT NULL,
            `server_group` INT UNSIGNED NOT NULL,
            FOREIGN KEY (server_group) REFERENCES tbl_server_grp(p_group_id),
            FOREIGN KEY (user_id) REFERENCES tbl_users(p_user_id),
            UNIQUE INDEX `user_UNIQUE` (`user_id`, `server_group`)
        );
    ]] ))

    --[[
        Description: Function to save a players rank using steamid and group name
        Arguments:
            - steamid [string] : The steamid of the user to be saved
            - group [string] : the group to be saved in combination with the steamid
        Returns: nothing
    ]]
    function MSync.modules.MRSync.saveRankByID(steamid, group)

        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Exec: MRSync.saveRankByID Params: " .. steamid .. " " .. group)

        if MSync.modules.MRSync.settings.nosync[group] then MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Group \"" .. group .. "\" is set to No-Sync. Not sending data to the database"); return end;

        local addUserRankQ = MSync.DBServer:prepare( [[
            INSERT INTO `tbl_mrsync` (user_id, rank, server_group)
            VALUES (
                (SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?), 
            ?, 
                (SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
            )
            ON DUPLICATE KEY UPDATE rank=VALUES(rank);
        ]] )
        addUserRankQ:setString(1, steamid)
        addUserRankQ:setString(2, util.SteamIDTo64( steamid ))
        addUserRankQ:setString(3, group)
        if not MSync.modules.MRSync.settings.syncall[group] then
            addUserRankQ:setString(4, MSync.settings.data.serverGroup)
        else
            addUserRankQ:setString(4, "allservers")
        end

        addUserRankQ.onError = function( q, err, sql )
            if string.match( err, "^Column 'user_id' cannot be null$" ) then
                MSync.log(MSYNC_DBG_DEBUG, "[MRSync] User does not exist, creating user \"" .. steamid .. "\" and repeating");
                MSync.mysql.addUserID(steamid)
                MSync.modules.MRSync.saveRankByID(steamid, group)
            else
                MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MRSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {['err'] = err, ['sql'] = sql}))
            end
        end

        addUserRankQ:start()
    end

    --[[
        Description: Function to validate user rank in DB is correct
        Arguments:
            - steamid [STRING] - the steamid of the user to validate
            - group [STRING] - the group of the user to validate
    ]]
    function MSync.modules.MRSync.validateData( steamid, group )

        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Exec: MRSync.validateData Param.: " .. steamid .. " " .. group);

        if MSync.modules.MRSync.settings.nosync[group] then MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Group \"" .. group .. "\" is set to No-Sync. Not sending data to the database"); return end;

        local removeOldRanksQ

        if not MSync.modules.MRSync.settings.syncall[group] then

            MSync.log(MSYNC_DBG_INFO, "[MRSync] Non-Syncall group, removing all \"allservers\" ranks from user");

            removeOldRanksQ = MSync.DBServer:prepare( [[
                DELETE FROM `tbl_mrsync` WHERE user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?) AND server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers');
            ]] )
            removeOldRanksQ:setString(1, steamid)
            removeOldRanksQ:setString(2, util.SteamIDTo64(steamid))

            removeOldRanksQ.onSuccess = function( q, data )
                MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Data validation completed successfully, saving user");
                MSync.modules.MRSync.saveRankByID(steamid, group)
            end
        else

            MSync.log(MSYNC_DBG_INFO, "[MRSync] Syncall group, removing all groups from user \"" .. steamid .. "\" that are not \"allservers\"");

            removeOldRanksQ = MSync.DBServer:prepare( [[
                DELETE FROM `tbl_mrsync` WHERE user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?) AND server_group<>(SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers');
            ]] )
            removeOldRanksQ:setString(1, steamid)
            removeOldRanksQ:setString(2, util.SteamIDTo64(steamid))

            removeOldRanksQ.onSuccess = function( q, data )
                MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Data validation completed successfully, saving user");
                MSync.modules.MRSync.saveRankByID(steamid, group)
            end
        end

        removeOldRanksQ.onError = function( q, err, sql )
            if string.match( err, "^Column 'user_id' cannot be null$" ) then
                MSync.log(MSYNC_DBG_DEBUG, "[MRSync] User not found, creating user before trying again");
                MSync.mysql.addUserID(steamid)
                MSync.modules.MRSync.saveRankByID(steamid, group)
            else
                MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MRSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {['err'] = err, ['sql'] = sql}))
            end
        end

        removeOldRanksQ:start()
    end

    --[[
        Description: Function to load a players rank
        Arguments:
            - ply [playerEntity] : The player to be loaded
        Returns: nothing
    ]]
    function MSync.modules.MRSync.loadRank(ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Exec: MRSync.loadRank Param.:" .. ply:Nick());
        local loadUserQ = MSync.DBServer:prepare( [[
            SELECT `rank` FROM `tbl_mrsync` 
            WHERE user_id=(
                SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?
            ) AND (server_group=(
                SELECT p_group_id FROM tbl_server_grp WHERE group_name=?
            ) OR server_group=(
                SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers'
            ))
            LIMIT 1;
        ]] )
        loadUserQ:setString(1, ply:SteamID())
        loadUserQ:setString(2, ply:SteamID64())
        loadUserQ:setString(3, MSync.settings.data.serverGroup)

        function loadUserQ.onData( q, data )
            MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Got data for user \"" .. ply:Nick() .. "\". Rank: " .. data.rank);
            if not ULib.ucl.groups[data.rank] then
                MSync.log(MSYNC_DBG_ERROR, "[MRSync] Could not load rank "..data.rank.." for "..ply:Nick()..". Rank does not exist on this server")
                return
            end

            if data.rank == ply:GetUserGroup() then return end;

            MSync.log(MSYNC_DBG_INFO, "[MRSync] Data for user \"" .. ply:Nick() .. "\" valid and user does not have the right group, changing to " .. data.rank);
            ply:SetUserGroup(data.rank)
        end

        function loadUserQ.onSuccess( q, data )
            MSync.log(MSYNC_DBG_DEBUG, "[MRSync] loadUser query executed successfully");
            if not data[1] then
                if ply:GetUserGroup() == "user" or MSync.modules.MRSync.settings.nosync[ply:GetUserGroup()] then return end

                MSync.log(MSYNC_DBG_INFO, "[MRSync] Assuming user \"" .. ply:Nick() .. "\" has been removed from rank, setting them to default")

                userTransaction[ply:SteamID64()] = true
                ULib.ucl.removeUser(ply:SteamID())
            end
        end

        loadUserQ:start()
    end

    --[[
        Description: Function to remove a user entirely from MRSync
        Arguments:
            - steamid [string] : The steamid of the user to be removed
        Returns: nothing
    ]]
    function MSync.modules.MRSync.removeRank(steamid)

        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Exec: MRSync.removeRank Param.: " .. steamid);

        local removeUserRankQ = MSync.DBServer:prepare( [[
            DELETE FROM `tbl_mrsync` WHERE 
                user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?) AND 
                (
                    server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers') OR
                    server_group=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
                );
        ]] )
        removeUserRankQ:setString(1, steamid)
        removeUserRankQ:setString(2, util.SteamIDTo64( steamid ))
        removeUserRankQ:setString(3, MSync.settings.data.serverGroup)

        removeUserRankQ:start()
    end

    --[[
        Description: Function to load the MSync settings file
        Returns: true
    ]]
    function MSync.modules.MRSync.loadSettings()

        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Exec: MRSync.loadSettings");

        if not file.Exists("msync/mrsync.txt", "DATA") then
            MSync.modules.MRSync.settings = {
                nosync = {
                    ["member"] = true
                },
                syncall = {
                    ["superadmin"] = true
                }
            }
            file.Write("msync/mrsync.txt", util.TableToJSON(MSync.modules.MRSync.settings, true))
            MSync.log(MSYNC_DBG_DEBUG, "[MRSync] No config file, creating one now");
        else
            MSync.modules.MRSync.settings = util.JSONToTable(file.Read("msync/mrsync.txt", "DATA"))
            MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Found config file, loading it now");
        end

        return true
    end

    --[[
        Description: Function to save the MSync settings to the settings file
        Returns: true if the settings file exists
    ]]
    function MSync.modules.MRSync.saveSettings()
        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Exec: MRSync.saveSettings");
        file.Write("msync/mrsync.txt", util.TableToJSON(MSync.modules.MRSync.settings, true))
        return file.Exists("msync/mrsync.txt", "DATA")
    end

    --[[
        Load settings when module finished loading
    ]]
    MSync.modules.MRSync.loadSettings()
end

--[[
    Define net receivers and util.AddNetworkString
]]
function MSync.modules.MRSync.net()

    --[[
        Description: Function to send the mrsync settings to the client
        Arguments:
            player [player] - the player that wants to open the admin GUI
        Returns: nothing
    ]]
    util.AddNetworkString("msync.mrsync.sendSettingsPly")
    function MSync.modules.MRSync.sendSettings(ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Exec: MRSync.sendSettings Param.: " .. ply:Nick());
        net.Start("msync.mrsync.sendSettingsPly")
            net.WriteTable(MSync.modules.MRSync.settings)
        net.Send(ply)
    end

    --[[
        Description: Net Receiver - Gets called when the client requests the settings table
        Returns: nothing
    ]]
    util.AddNetworkString("msync.mrsync.getSettings")
    net.Receive("msync.mrsync.getSettings", function(len, ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Net: msync.mrsync.getSettings Ply.: " .. ply:Nick());
        if not ply:query("msync.getSettings") then return end

        MSync.modules.MRSync.sendSettings(ply)
    end )

    --[[
        Description: Net Receiver - Gets called when the client requests the settings table
        Returns: nothing
    ]]
    util.AddNetworkString("msync.mrsync.sendSettings")
    net.Receive("msync.mrsync.sendSettings", function(len, ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Net: msync.mrsync.sendSettings Ply.: " .. ply:Nick());
        if not ply:query("msync.sendSettings") then return end

        MSync.modules.MRSync.settings = net.ReadTable()
        MSync.modules.MRSync.saveSettings()
    end )


end

--[[
    Define ulx Commands and overwrite common ulx functions (module does not get loaded until ulx has fully been loaded)
]]
function MSync.modules.MRSync.ulx()

end

--[[
    Define hooks your module is listening on e.g. PlayerDisconnect
]]
function MSync.modules.MRSync.hooks()

    -- Load rank on spawn
    hook.Add("PlayerInitialSpawn", "mrsync.H.loadRank", function(ply)
        MSync.log(MSYNC_DBG_INFO, "[MRSync] Loading user rank for \"" .. ply:Nick() .. "\"");
        MSync.modules.MRSync.loadRank(ply)
    end)

    -- Save rank on disconnect
    hook.Add("PlayerDisconnected", "mrsync.H.saveRank", function(ply)
        MSync.log(MSYNC_DBG_INFO, "[MRSync] Saving user rank for \"" .. ply:Nick() .. "\"");
        --MSync.modules.MRSync.saveRank(ply)
        MSync.modules.MRSync.validateData(ply:SteamID(), ply:GetUserGroup())
    end)

    -- Save rank on GroupChange
    hook.Add("ULibUserGroupChange", "mrsync.H.saveRankOnUpdate", function(sid, _, _, new_group, _)
        MSync.log(MSYNC_DBG_INFO, "[MRSync] Rank changed for user \"" .. sid .. "\" updating it now");
        --MSync.modules.MRSync.saveRankByID(sid, new_group)
        MSync.modules.MRSync.validateData(sid, new_group)
    end)

    -- Remove Rank on ULX Remove
    hook.Add("ULibUserRemoved", "mrsync.H.saveRankOnUpdate", function(sid)
        MSync.log(MSYNC_DBG_INFO, "[MRSync] User deletion detected for \"" .. sid .. "\"");
        if userTransaction[util.SteamIDTo64(sid)] then
            userTransaction[util.SteamIDTo64(sid)] = nil
            MSync.log(MSYNC_DBG_INFO, "[MRSync] User has already been removed from MRSync, aborting removal");
            return
        end

        MSync.log(MSYNC_DBG_INFO, "[MRSync] User \"" .. ply:Nick() .. "\" was removed from ULX, removing from MRSync");
        MSync.modules.MRSync.removeRank(sid)
    end)
end

--[[
    Define a function to run on the server when the module gets disabled
]]
MSync.modules.MRSync.disable = function()
    hook.Remove("PlayerInitialSpawn", "mrsync.H.loadRank")
    hook.Remove("PlayerDisconnected", "mrsync.H.saveRank")
    hook.Remove("ULibUserGroupChange", "mrsync.H.saveRankOnUpdate")
    hook.Remove("ULibUserRemoved", "mrsync.H.saveRankOnUpdate")
end

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules.MRSync.info