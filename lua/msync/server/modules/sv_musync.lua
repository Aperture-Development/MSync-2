MSync = MSync or {}
MSync.modules = MSync.modules or {}
--[[
 * @file       sv_musync.lua
 * @package    MySQL UTime Synchronization
 * @author     Aperture Development
 * @license    root_dir/LICENCE
 * @version    0.0.0
]]

--[[
    Define name, description and module identifier
]]
local info = {
    Name = "MySQL UTime Synchronization",
    ModuleIdentifier = "MUSync",
    Description = "Synchronizes Playtime across your servers",
    Version = "0.0.0"
}

--[[
    Prepare Module
]]
MSync.modules[info.ModuleIdentifier] = MSync.modules[info.ModuleIdentifier] or {}
MSync.modules[info.ModuleIdentifier].info = info

--[[
    Define mysql table and additional functions that are later used
]]
MSync.modules[info.ModuleIdentifier].init = function( transaction )
    transaction:addQuery( MSync.DBServer:query([[
        CREATE TABLE IF NOT EXISTS musync_time (
            f_user_id INT UNSIGNED NOT NULL,
            f_servergrp_id INT UNSIGNED NOT NULL,
            playtime BIGINT NOT NULL,
            last_played BIGINT NOT NULL,
            UNIQUE KEY time_UNIQUE(f_user_id, f_servergrp_id),
            FOREIGN KEY (f_user_id) REFERENCES tbl_users(p_user_id),
            FOREIGN KEY (f_servergrp_id) REFERENCES tbl_server_grp(p_group_id)
        ); 
    ]] ))

    transaction:addQuery( MSync.DBServer:query([[
        INSERT INTO tbl_msyncdb_version (`version`, module_id)
        SELECT * FROM (
            SELECT 1 AS `version`, 'musync' AS mod_id
        ) AS dataQuery
        ON DUPLICATE KEY UPDATE module_id=mod_id;
    ]] ))

    --[[
        get a users current playtime
    ]]
    MSync.modules[info.ModuleIdentifier].GetUserPlaytime = function( ply )

        --[[
        if not args.ply then
            MSync.log(MSYNC_DBG_ERROR, "[MUSync] GetUserPlaytime: parameter \"ply\" is required")
            return
        end

        args = {
            ply = args.ply,
            callback = args.callback or nil,
            callback_data = args.callback_data or nil
        }

        local ply = args.ply
        ]]

        -- Check for users playtime
        -- if Playtime allservers >= current playtime, update current playtime ( we assume the server group was changed and we need to update our db entries )
        -- if user not found, run create user function
        -- if playtime in utime is bigger then db time, do not load, simply update playtime

        --[[
            SELECT playtime, last_played
            FROM musync_time
            WHERE
                f_user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?) AND
                f_servergrp_id=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
        ]]

        --[[
            SELECT playtime, last_played
            FROM musync_time
            WHERE
                f_user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?) AND
                f_servergrp_id=(SELECT p_group_id FROM tbl_server_grp WHERE group_name='allservers')
        ]]

        local loadUserTimeQ = MSync.DBServer:prepare( [[
            SELECT playtime, last_played
            FROM musync_time
            WHERE
                f_user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?) AND
                f_servergrp_id=(SELECT p_group_id FROM tbl_server_grp WHERE group_name=?)
        ]] )

        function loadUserTimeQ.onSuccess( q, data ) 
            if table.IsEmpty( data ) then
                local loadAllserverUserTimeQ = MSync.DBServer:prepare( [[
                    SELECT playtime, last_played
                    FROM musync_time
                    WHERE
                        f_user_id=(SELECT p_user_id FROM tbl_users WHERE steamid=? AND steamid64=?) AND
                        f_servergrp_id=(SELECT p_group_id FROM tbl_server_grp WHERE group_name='allserver')
                ]] )

                function loadAllserverUserTimeQ.onSuccess( loadAllserverTimeQ, loadAllserverTimeData ) 
                    if table.IsEmpty( loadAllserverTimeData ) then
                        MSync.modules[info.ModuleIdentifier].CheckUser( ply )
                    else
                        if ply:GetUTime() <= loadAllserverTimeData[1].playtime then
                            ply:SetUTime( loadAllserverTimeData[1].playtime )
                            ply:SetUTimeStart( CurTime() )
                        end

                        MSync.modules[info.ModuleIdentifier].UpdateUserPlaytime( ply )
                    end
                end

                function loadAllserverUserTimeQ.onError( loadAllserverTimeQ, err, sql ) 
                    MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MUSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {["err"] = err, ["sql"] = sql}))
                end

                loadAllserverUserTimeQ:start()
            else
                if data[1].playtime >= ply:GetUTime() then
                    ply:SetUTime(data[1].playtime)
                    ply:SetUTimeStart( CurTime() )
                end

                MSync.modules[info.ModuleIdentifier].UpdateUserPlaytime( ply )
            end
        end

        function loadUserTimeQ.onError( q, err, sql ) 
            MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MUSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {["err"] = err, ["sql"] = sql}))
        end

        loadUserTimeQ:start()
    end

    --[[
        Runs various validation on a user before saving to the database
    ]]
    MSync.modules[info.ModuleIdentifier].CheckUser = function( args )

        if not args.ply then
            MSync.log(MSYNC_DBG_ERROR, "[MUSync] CheckUser: parameter \"ply\" is required")
            return
        end

        args = {
            ply = args.ply,
            callback = args.callback or nil,
            callback_data = args.callback_data or nil
        }

        local ply = args.ply

        -- check if user has UTime variables
        -- if User has no utime variables, create new empty entry
        -- if user has utime > 0 create new entry with utime values

        if ply:GetUTime() > 0 then
            -- User already has playtime
            -- check if user exists in db
            -- is user playtime > local playtime then select entry
            -- if user playtime < local playtime then update db entry and no getting player
        else 
            -- user does not have playtime
            -- select user from db
        end

        --[[
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
        ]]
        return true
    end

    --[[
        Updates the playtime in our database
    ]]
    MSync.modules[info.ModuleIdentifier].UpdateUserPlaytime = function( args )

        if not args.ply then
            MSync.log(MSYNC_DBG_ERROR, "[MUSync] UpdateUSerPlaytime: parameter \"ply\" is required")
            return
        end

        args = {
            ply = args.ply,
            callback = args.callback or nil,
            callback_data = args.callback_data or nil
        }

        local ply = args.ply

        local userInformations = {
            ["totalPlaytime"] = 0,
            ["lastPlayed"] = CurTime(),
            ["steamid"] = ply:SteamID(),
            ["steamid64"] = ply:SteamID64(),
        }

        if tonumber(ply:GetUTime()) > 0 then
            userInformations["totalPlaytime"] = ply:GetUTime()
            userInformations["lastPlayed"] = ply:GetUTimeStart()
        end

        local updateUserPlaytimeQ = MSync.DBServer:prepare( [[
            INSERT INTO musync_time (f_user_id, f_servergrp_id, playtime, last_played)
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
        ]] )
        updateUserPlaytimeQ:setString( 1, userInformations["totalPlaytime"] )
        updateUserPlaytimeQ:setNumber( 2, userInformations["lastPlayed"] )
        updateUserPlaytimeQ:setString( 3, userInformations["steamid"] )
        updateUserPlaytimeQ:setString( 4, userInformations["steamid64"] )
        updateUserPlaytimeQ:setString( 5, MSync.settings.data.serverGroup )

        function updateUserPlaytimeQ.onSuccess( q, data )
            MSync.log(MSYNC_DBG_INFO, "[MUSync] Saved playtime of user with steamid \"" .. userInformations["steamid"] .. "\"")

            MSync.log(MSYNC_DBG_DEBUG, "[MUSync] Exec: MUSync.UpdateUserPlaytime Params: " .. userInformations["totalPlaytime"] .. " " .. userInformations["lastPlayed"])
            if args.callback then
                args.callback( callback_data )
            end
        end

        function updateUserPlaytimeQ.onError( q, err, sql ) 
            MSync.log(MSYNC_DBG_ERROR, MSync.formatString("\n------------------------------------\n[MUSync] SQL Error!\n------------------------------------\nPlease include this in a Bug report:\n\n$err\n\n------------------------------------\nDo not include this, this is for debugging only:\n\n$sql\n\n------------------------------------", {["err"] = err, ["sql"] = sql}))
        end

        updateUserPlaytimeQ:start()
    end

end

--[[
    Define net receivers and util.AddNetworkString
]]
MSync.modules[info.ModuleIdentifier].net = function()
    -- we don't need netting for this
end

--[[
    Define ulx Commands and overwrite common ulx functions (module does not get loaded until ulx has fully been loaded)
]]
MSync.modules[info.ModuleIdentifier].ulx = function()
    -- we don't need commands for this
end

--[[
    Define hooks your module is listening on e.g. PlayerDisconnect
]]
MSync.modules[info.ModuleIdentifier].hooks = function()
    -- check if utime is actually installed, if not prevent hook addition and throw error

    hook.Add("PlayerInitialSpawn", "msync_musync_getplaytime", function( ply )
        -- load playtime from database
        --MSync.modules[info.ModuleIdentifier].GetUserPlaytime( ply )
    end)

    hook.Add("PlayerDisconnected", "msync_musync_updateplaytime", function( ply )
        -- save playtime to database
        MSync.modules[info.ModuleIdentifier].UpdateUserPlaytime{ ply = ply }
    end)
end

--[[
    Define a function to run on the server when the module gets disabled
]]
MSync.modules[info.ModuleIdentifier].disable = function()
    hook.Remove("PlayerInitialSpawn", "msync_musync_getplaytime")
    hook.Remove("PlayerDisconnected", "msync_musync_updateplaytime")
end

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules[info.ModuleIdentifier].info