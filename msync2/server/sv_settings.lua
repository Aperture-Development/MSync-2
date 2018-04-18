MSync           = MSync     or {}
MSync.settings  = MSync.settings or {}

function MSync.settings.func.loadSettings()
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

function MSync.settings.func.saveSettings()
    file.Write("msync/settings.txt", util.TableToJSON(MSync.settings.data, true))
    return file.Exists("msync/settings.txt", "DATA")
end