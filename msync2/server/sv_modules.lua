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
    if MSync.DBServer then
        for k,v in pairs(MSync.Modules) do
            v["init"]()
            v["net"]()
            v["ulx"]()
            v["hooks"]()
            print("["..v[info][Name].."] Module loaded")
        end
    else
        print("[MSync] No MySQL server connected, aborting module loading.")
    end
end