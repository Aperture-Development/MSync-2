MSync           = MSync     or {}
MSync.net       = MSync.net or {}
MSync.mysql     = MSync.mysql or {}
MSync.settings  = MSync.settings or {}
MSync.func  = MSync.func or {}

--[[
    Description: initializes the MySQL part
    Returns: nothing
]]
function MSync.mysql.initialize()
    if (file.Exists( "bin/gmsv_mysqloo_linux.dll", "LUA" ) or file.Exists( "bin/gmsv_mysqloo_win32.dll", "LUA" ) or file.Exists( "bin/gmsv_mysqloo_linux64.dll", "LUA" ) or file.Exists( "bin/gmsv_mysqloo_win64.dll", "LUA" )) and MSync.settings.data.mysql then
        require("mysqloo")

        MSync.log(MSYNC_DBG_INFO, "Initializing database")

        MSync.DBServer = mysqloo.connect(
            MSync.settings.data.mysql.host,
            MSync.settings.data.mysql.username,
            MSync.settings.data.mysql.password,
            MSync.settings.data.mysql.database,
            tonumber(MSync.settings.data.mysql.port) -- Just to be sure it deffinetly is a number
        )

        function MSync.DBServer.onConnected( db )
            local initDatabase = MSync.DBServer:createTransaction()

            MSync.log(MSYNC_DBG_INFO, "Connected to database, running database preparation ( this is done at each startup )")

            initDatabase:addQuery(MSync.DBServer:query([[
                CREATE TABLE IF NOT EXISTS `tbl_msyncdb_version` ( 
                    `version` INT UNSIGNED NOT NULL, 
                    `module_id` VARCHAR(25) NOT NULL,
                    UNIQUE INDEX `module_UNIQUE` (`module_id`)
                );
            ]] ))

            initDatabase:addQuery(MSync.DBServer:query( [[
                CREATE TABLE IF NOT EXISTS `tbl_server_grp` (
                    `p_group_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                    `group_name` VARCHAR(15) NOT NULL,
                    UNIQUE INDEX `group_UNIQUE` (`group_name`)
                );
            ]] ))

            initDatabase:addQuery(MSync.DBServer:query( [[
                INSERT INTO `tbl_server_grp` (group_name) VALUES ('allservers') AS newGroup
                ON DUPLICATE KEY UPDATE group_name=newGroup.group_name;
            ]] ))

            initDatabase:addQuery(MSync.DBServer:query( [[
                CREATE TABLE IF NOT EXISTS `tbl_msync_servers` (
                    `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                    `server_name` VARCHAR(75) NOT NULL,
                    `options` VARCHAR(100) NOT NULL DEFAULT '[]',
                    `ip` VARCHAR(15) NOT NULL,
                    `port` VARCHAR(5) NOT NULL,
                    `server_group` INT UNSIGNED NOT NULL,
                    FOREIGN KEY (server_group) REFERENCES tbl_server_grp(p_group_id),
                    UNIQUE INDEX `server_UNIQUE` (`ip`, `port`)
                );
            ]] ))

            initDatabase:addQuery(MSync.DBServer:query( [[
                CREATE TABLE IF NOT EXISTS `tbl_users` (
                    `p_user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                    `steamid` VARCHAR(20) NOT NULL,
                    `steamid64` VARCHAR(17) NOT NULL,
                    `nickname` VARCHAR(30) NOT NULL,
                    `joined` DATETIME NOT NULL,
                    UNIQUE INDEX `steamid_UNIQUE` (`steamid`),
                    UNIQUE INDEX `steamid64_UNIQUE` (`steamid64`)
                );
            ]] ))

            initDatabase:addQuery(MSync.DBServer:query( [[
                INSERT INTO `tbl_users` (steamid, steamid64, nickname, joined) VALUES ('STEAM_0:0:0', '76561197960265728', '(CONSOLE)', '2004-12-24 12:00:00') AS newUser
                ON DUPLICATE KEY UPDATE nickname=newUser.nickname;
            ]] ))

            function initDatabase.onSuccess()
                MSync.mysql.saveServer()
                MSync.initModules()
                MSync.log(MSYNC_DBG_INFO, "Database prepared")
            end

            function initDatabase.onError(tr, err)
                MSync.log(MSYNC_DBG_ERROR, "There has been a error while initializing the database.\nPlease inform the Developer and send him this:\n"..err)
            end

            initDatabase:start()

        end

        function  MSync.DBServer.onConnectionFailed( db, err )
            MSync.log(MSYNC_DBG_ERROR, "There has been a error while loading the module querys.\nPlease inform the Developer and send him this:\n"..err)
        end

        MSync.DBServer:connect()
    elseif not MSync.settings then
        MSync.log(MSYNC_DBG_ERROR, "Settings not found")
    else
        MSync.log(MSYNC_DBG_ERROR, "Could not locate MySQLoo")
    end
end

--[[
    Description: Adds a user to the users table
    Arguments: player
    Returns: nothing
]]
function MSync.mysql.addUser(ply)
    MSync.log(MSYNC_DBG_DEBUG, "Exec: addUser. Param.: " .. tostring(ply))
    if not MSync.DBServer then MSync.log(MSYNC_DBG_DEBUG, "No Database connected yet. Please connect to a Database to be able to create users."); return end;

    local addUserQ = MSync.DBServer:prepare( [[
        INSERT INTO `tbl_users` (steamid, steamid64, nickname, joined)
        VALUES (?, ?, ?, ?) AS newUser
        ON DUPLICATE KEY UPDATE nickname=newUser.nickname;
    ]] )

    local nickname = ply:Nick()
    if string.len(nickname) > 30 then
        nickname = string.sub( nickname, 1, 30 )
    end

    addUserQ:setString(1, ply:SteamID())
    addUserQ:setString(2, ply:SteamID64())
    addUserQ:setString(3, nickname)
    addUserQ:setString(4, os.date("%Y-%m-%d %H:%M:%S", os.time()))

    function addUserQ.onSuccess()
        MSync.log(MSYNC_DBG_INFO, "User "..ply:Nick().." successfully created")
    end

    function addUserQ.onError(q, err, sql)
        MSync.log(MSYNC_DBG_ERROR, "Failed to create user "..ply:Nick().." !\nPlease report this to the developer: "..err)
    end

    addUserQ:start()
end

--[[
    Description: Adds a userid to the users table
    Arguments: 
        - steamid [string] - the steamid of the player to be added
        - nickname [string] - OPTIONAL: the nickname of the user to be created
    Returns: nothing
]]
function MSync.mysql.addUserID(steamid, nickname)
    MSync.log(MSYNC_DBG_DEBUG, "Exec: addUserID. Param.: " .. steamid .. " " .. (nickname or ""))
    if not MSync.DBServer then MSync.log(MSYNC_DBG_DEBUG, "No Database connected yet. Please connect to a Database to be able to create users."); return end;
    if not string.match( steamid, "^STEAM_[0-1]:[0-1]:[0-9]+$" ) then return end;

    nickname = nickname or "None Given"

    local addUserQ = MSync.DBServer:prepare( [[
        INSERT INTO `tbl_users` (steamid, steamid64, nickname, joined)
        VALUES (?, ?, ?, ?) AS newUser
        ON DUPLICATE KEY UPDATE nickname=newUser.nickname;
    ]] )

    if string.len(nickname) > 30 then
        nickname = string.sub( nickname, 1, 30 )
    end

    addUserQ:setString(1, steamid)
    addUserQ:setString(2, util.SteamIDTo64(steamid))
    addUserQ:setString(3, nickname)
    addUserQ:setString(4, os.date("%Y-%m-%d %H:%M:%S", os.time()))

    function addUserQ.onSuccess()
        MSync.log(MSYNC_DBG_INFO, "User "..steamid.." successfully created")
    end

    function addUserQ.onError(q, err, sql)
        MSync.log(MSYNC_DBG_ERROR, "Failed to create user "..steamid.." !\nPlease report this to the developer: "..err)
    end

    addUserQ:start()
end

--[[
    Description: Function to print the MySQL informations to the console
    Returns: nothing
]]
function MSync.mysql.getInfo()
    print("--Database Server Information--")
    print("Version: "..MSync.DBServer:serverVersion())
    print("Fancy Version: "..MSync.DBServer:serverInfo())
    print("Host Info: "..MSync.DBServer:hostInfo())
end

--[[
    Description: Function to save the server date to the database
    Returns: nothing
]]
function MSync.mysql.saveServer()

    local addServerGroup = MSync.DBServer:prepare( [[
        INSERT INTO `tbl_server_grp` (group_name) VALUES (?) AS newGroup
        ON DUPLICATE KEY UPDATE group_name=newGroup.group_name;
    ]] )
    addServerGroup:setString(1, MSync.settings.data.serverGroup)

    function addServerGroup.onSuccess()
        local addServer = MSync.DBServer:prepare( [[
            INSERT INTO `tbl_msync_servers` (server_name, ip, `port`, server_group)
            SELECT * FROM (
                SELECT ? AS newServerName, ? AS ip, ? AS `port`, tbl_server_grp.p_group_id AS newGroup
                FROM tbl_server_grp
                WHERE
                    tbl_server_grp.group_name=?
            ) AS dataQuery
            ON DUPLICATE KEY UPDATE server_name=newServerName, server_group=newGroup;
        ]] )

        local hostname = GetHostName()
        local gameAddress = string.Split(game.GetIPAddress(), ":")

        if string.len(hostname) > 75 then
            hostname = string.sub( hostname, 1, 75 )
            MSync.log(MSYNC_DBG_WARNING, "Hostname too long, shorting it down to a max of 75 letters")
        end
        addServer:setString(1, hostname)
        addServer:setString(2, gameAddress[1])
        addServer:setString(3, gameAddress[2])
        addServer:setString(4, MSync.settings.data.serverGroup)

        function addServer.onSuccess()
            MSync.log(MSYNC_DBG_INFO, "Server saved to database")
        end

        function addServer.onError(q, err, sql)
            MSync.log(MSYNC_DBG_ERROR, "Failed to create server !\nPlease report this to the developer: "..err)
        end

        addServer:start()
    end

    function addServerGroup.onError(q, err, sql)
        MSync.log(MSYNC_DBG_ERROR, "Failed to create server !\nPlease report this to the developer: "..err)
    end

    addServerGroup:start()
end
