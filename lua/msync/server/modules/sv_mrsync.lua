MSync = MSync or {}
MSync.modules = MSync.modules or {}
MSync.modules.MRSync = MSync.modules.MRSync or {}
--[[
 * @file       sv_mrsync.lua
 * @package    MySQL Rank Sync
 * @author     Aperture Development
 * @license    root_dir/LICENCE
 * @version    2.1.2
]]

--[[
    Define name, description and module identifier
]]
MSync.modules.MRSync.info = {
    Name = "MySQL Rank Sync",
    ModuleIdentifier = "MRSync",
    Description = "Synchronise your ranks across your servers",
    Version = "2.1.2"
}

--[[
    Define mysql table and additional functions that are later used
]]
function MSync.modules.MRSync.init( transaction )
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
        Description: Function to save a players rank
        Returns: nothing
    ]]
    function MSync.modules.MRSync.saveRank(ply)

        if MSync.modules.MRSync.settings.nosync[ply:GetUserGroup()] then return end;

        local addUserRankQ = MSync.DBServer:prepare( [[
            INSERT INTO `tbl_mrsync` (user_id, rank, server_group)
            VALUES (
                (SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?), 
            ?, 
                (SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
            )
            ON DUPLICATE KEY UPDATE rank=VALUES(rank);
        ]] )
        addUserRankQ:setString(1, ply:SteamID())
        addUserRankQ:setString(2, ply:SteamID64())
        addUserRankQ:setString(3, ply:GetUserGroup())
        if not MSync.modules.MRSync.settings.syncall[ply:GetUserGroup()] then
            addUserRankQ:setString(4, MSync.settings.data.serverGroup)
        else
            addUserRankQ:setString(4, "allservers")
        end

        addUserRankQ:start()
    end

    --[[
        Description: Function to save a players rank using steamid and group name
        Returns: nothing
    ]]
    function MSync.modules.MRSync.saveRankByID(steamid, group)

        if MSync.modules.MRSync.settings.nosync[group] then return end;

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

        addUserRankQ:start()
    end

    --[[
        Description: Function to load a players rank
        Returns: nothing
    ]]
    function MSync.modules.MRSync.loadRank(ply)
        local loadUserQ = MSync.DBServer:prepare( [[
            SELECT rank FROM `tbl_mrsync` 
            WHERE user_id=(
                SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?
            ) AND (server_group=(
                SELECT p_group_id FROM tbl_server_grp WHERE group_name=?
            ) OR server_group=(
                SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers'
            ));
        ]] )
        loadUserQ:setString(1, ply:SteamID())
        loadUserQ:setString(2, ply:SteamID64())
        loadUserQ:setString(3, MSync.settings.data.serverGroup)

        function loadUserQ.onData( q, data )
            if not ULib.ucl.groups[data.rank] then
                print("[MRSync] Could not load rank "..data.rank.." for "..ply:Nick()..". Rank does not exist on this server")
                return
            end

            if data.rank == ply:GetUserGroup() then return end;

            ply:SetUserGroup(data.rank)
        end

        loadUserQ:start()
    end

    --[[
        Description: Function to load the MSync settings file
        Returns: true
    ]]
    function MSync.modules.MRSync.loadSettings()
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
        else
            MSync.modules.MRSync.settings = util.JSONToTable(file.Read("msync/mrsync.txt", "DATA"))
        end

        return true
    end

    --[[
        Description: Function to save the MSync settings to the settings file
        Returns: true if the settings file exists
    ]]
    function MSync.modules.MRSync.saveSettings()
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
        if not ply:query("msync.getSettings") then return end

        MSync.modules.MRSync.sendSettings(ply)
    end )

    --[[
        Description: Net Receiver - Gets called when the client requests the settings table
        Returns: nothing
    ]]
    util.AddNetworkString("msync.mrsync.sendSettings")
    net.Receive("msync.mrsync.sendSettings", function(len, ply)
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
        MSync.modules.MRSync.loadRank(ply)
    end)

    -- Save rank on disconnect
    hook.Add("PlayerDisconnected", "mrsync.H.saveRank", function(ply)
        MSync.modules.MRSync.saveRank(ply)
    end)

    -- Save rank on GroupChange
    hook.Add("ULibUserGroupChange", "mrsync.H.saveRankOnUpdate", function(sid, _, _, new_group, _)
        MSync.modules.MRSync.saveRankByID(sid, new_group)
    end)
end

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules.MRSync.info