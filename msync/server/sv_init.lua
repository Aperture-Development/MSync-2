MSync           = MSync     or {}
MSync.net       = MSync.net or {}
MSync.mysql     = MSync.mysql or {}
MSync.modules = MSync.modules or {}
MSync.settings  = MSync.settings or {}
MSync.function  = MSync.function or {}


function MSync.function.loadServer()

    include("/msync/server/sv_net.lua")
    include("/msync/server/sv_mysql.lua")
    include("/msync/server/sv_modules.lua")
    include("/msync/server/sv_hooks.lua")

end

function MSync.function.loadSettings()
    if not file.Exists("msync/settings.txt", "DATA") then
        MSync.settings.data = {
            mysql = {
                host = "127.0.0.1",
                port = "3306",
                username = "root",
                password = "",
                database = "msync"
            },
            enabledModules = {
                "mrsync"
            },
            serverGroup = "allservers"
        }
        file.CreateDir("msync")
        file.Write("msync/settings.txt", util.TableToJSON(MSync.settings.data, true))
    else
        MSync.settings.data = util.JSONToTable(file.Read("msync/settings.txt", "DATA"))
    end

    return true
end

function MSync.function.saveSettings()
    file.Write("msync/settings.txt", util.TableToJSON(MSync.settings.data, true))
    return file.Exists("msync/settings.txt", "DATA")
end

function MSync.function.getModuleInfos()
    local infoTable = {}

    for k,v in pairs(MSync.modules) do
        infoTable[k] = v.info
        infoTable[k].state = table.HasValue( MSync.settings.data.enabledModules, v.info["ModuleIdentifier"] ) 
    end

    return infoTable
end

function MSync.function.getSafeSettings()
    local settings = MSync.settings.data
    settings.mysql.password = nil

    return settings
end