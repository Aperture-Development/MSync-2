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
    if (file.Exists( "bin/gmsv_mysqloo_linux.dll", "LUA" ) or file.Exists( "bin/gmsv_mysqloo_win32.dll", "LUA" )) and MSync.settings.data.mysql then
        require("mysqloo")
        
        MSync.DBServer = mysqloo.connect(
            MSync.settings.data.mysql.host,
            MSync.settings.data.mysql.username,
            MSync.settings.data.mysql.password,
            MSync.settings.data.mysql.database,
            MSync.settings.data.mysql.port
        )

        function MSync.DBServer.onConnected( db )
            local initDatabase = MSync.DBServer:createTransaction()

            initDatabase:addQuery(MSync.DBServer:query([[
                CREATE TABLE IF NOT EXISTS `tbl_msyncdb_version` ( `version` float NOT NULL );
            ]] ))

            initDatabase:addQuery(MSync.DBServer:query( [[
                CREATE TABLE IF NOT EXISTS `tbl_msync_servers` (
                    `p_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                    `server_name` VARCHAR(15) NOT NULL,
                    `options` VARCHAR(100) NOT NULL DEFAULT '[]',
                    `server_group` VARCHAR(45)
                );
            ]] ))

            initDatabase:addQuery(MSync.DBServer:query( [[
                CREATE TABLE IF NOT EXISTS `tbl_server_grp` (
                    `p_group_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                    `group_name` VARCHAR(15) NOT NULL
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
            
            function initDatabase.onSuccess()
                MSync.initModules()
            end

            function initDatabase.onError(tr, err)
                print("[MSync] There has been a error while initializing the database.\nPlease inform the Developer and send him this:\n"..err)
            end

            initDatabase:start()

        end

        function  MSync.DBServer.onConnectionFailed( db, err )
            print("[MSync] There has been a error while loading the module querys.\nPlease inform the Developer and send him this:\n"..err)
        end

        MSync.DBServer:connect()
    elseif not MSync.settings then
        print("[MSync] Settings not found")
    else
        print("[MSync] Could not locate MySQLoo")
    end
end

--[[
    Description: Adds a user to the users table
    Arguments: player
    Returns: nothing
]]   
function MSync.mysql.addUser(ply)
    if not MSync.DBServer then print("[MSync] No Database connected yet. Please connect to a Database to be able to create users."); return end;
    
    local addUserQ = MSync.DBServer:prepare( [[
        INSERT INTO `tbl_users` (steamid, steamid64, nickname, joined)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE nickname=VALUES(nickname);
    ]] )
    addUserQ:setString(1, ply:SteamID())
    addUserQ:setString(2, ply:SteamID64())
    addUserQ:setString(3, ply:Nick())
    addUserQ:setString(4, os.date("%Y-%m-%d %H:%M:%S", os.time()))

    function addUserQ.onSuccess()
        print("[MSync] User "..ply:Nick().." successfully created")
    end

    function addUserQ.onError(q, err, sql)
        print("[MSync] Failed to create user "..ply:Nick().." !\nPlease report this to the developer: "..err)
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