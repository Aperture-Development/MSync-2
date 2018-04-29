MSync           = MSync     or {}
MSync.mysql     = MSync.mysql or {}
MSync.settings  = MSync.settings or {}
MSync.modules   = MSync.modules or {}

function MSync.loadModules()
    for k, v in pairs(file.Find("msync/server/modules/*.lua", "LUA")[1]) do
        include("msync/server/modules/"..v)
    end
end

function MSync.initModules()
    MSync.mysql.dbstatus = false
    if MSync.DBServer then
        local initTransaction = MSync.DBServer:createTransaction()

        for k,v in pairs(MSync.Modules) do
            v["init"](initTransaction)
            v["net"]()
            v["ulx"]()
            v["hooks"]()
            print("["..v[info][Name].."] Module loaded")
        end

        function initTransaction.onSuccess()
            print("[MSync] Module querys have been completed successfully")
            MSync.mysql.dbstatus = true
        end

        function initTransaction.onError(tr, err)
            print("[MSync] There has been a error while loading the module querys.\nPlease inform the Developer and send him this:\n"..err)
            MSync.mysql.dbstatus = false
        end

        initTransaction:start()
    else
        print("[MSync] No MySQL server connected, aborting module loading.")
    end
end

function MSync.loadModule(path)
    local initTransaction = MSync.DBServer:createTransaction()
    local info = include(path)

    MSync.modules[info.ModuleIdentifier].init(initTransaction)
    MSync.modules[info.ModuleIdentifier].net()
    MSync.modules[info.ModuleIdentifier].ulx()
    MSync.modules[info.ModuleIdentifier].hooks()

    print("["..MSync.modules[info.Name].."] Module loaded")

    function initTransaction.onSuccess()
        print("[MSync] Module query has been completed successfully")
        MSync.mysql[info.ModuleIdentifier].dbstatus = true
    end

    function initTransaction.onError(tr, err)
        print("[MSync] There has been a error while loading the module querys.\nPlease inform the Developer and send him this:\n"..err)
        MSync.mysql[info.ModuleIdentifier].dbstatus = false
    end

    initTransaction:start()
end