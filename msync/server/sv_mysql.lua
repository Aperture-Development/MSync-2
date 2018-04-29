MSync           = MSync     or {}
MSync.net       = MSync.net or {}
MSync.mysql     = MSync.mysql or {}
MSync.settings  = MSync.settings or {}
MSync.function  = MSync.function or {}

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
            local initVersion = MSync.DBServer:query([[
                CREATE TABLE IF NOT EXISTS `tbl_msyncdb_version` ( `version` float NOT NULL );
            ]])

            initVersion:start()

            MSync.initModules()
        end

        function  MSync.DBServer.onConnectionFailed( db, err )
            print("[MSync] There has been a error while loading the module querys.\nPlease inform the Developer and send him this:\n"..err)
        end

        MSync.DBServer:connect()
    elseif !MSync.settings.data.mysql then
        print("[MSync] Settings not found")
    else
        print("[MSync] Could not locate MySQLoo")
    end
end

function MSync.mysql.getInfo() 
    print("--Database Server Information--")
    print("Version: "..MSync.DBServer:serverVersion())
    print("Fancy Version: "..MSync.DBServer:serverInfo())
    print("Host Info: "..MSync.DBServer:hostInfo())
end