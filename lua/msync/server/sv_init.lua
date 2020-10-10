MSync               = MSync     or {}
MSync.net           = MSync.net or {}
MSync.mysql         = MSync.mysql or {}
MSync.modules       = MSync.modules or {}
MSync.settings      = MSync.settings or {}
MSync.func          = MSync.func or {}
MSync.ulx           = MSync.ulx or {}
MSync.loadedModules = MSync.loadedModules or {}

--[[
    Description: Function to load the server side files
    Returns: nothing
]]
function MSync.func.loadServer()

    MSync.log(MSYNC_DBG_DEBUG, "Loading Server")

    include("msync/server/sv_net.lua")
    include("msync/server/sv_mysql.lua")
    include("msync/server/sv_modules.lua")
    include("msync/server/sv_hooks.lua")
    include("msync/server/sv_ulx.lua")

    MSync.func.loadSettings()

    timer.Create("msync.t.checkForULXandULib", 5, 0, function()
        if not ulx or not ULib then return end;

        MSync.log(MSYNC_DBG_DEBUG, "ULX Loaded, continuing startup")

        timer.Remove("msync.t.checkForULXandULib")
        MSync.ulx.createPermissions()
        MSync.ulx.createCommands()
        MSync.mysql.initialize()
    end)

    MSync.loadModules()

    local files, _ = file.Find("msync/client_gui/*.lua", "LUA")
    for k, v in pairs(files) do
        AddCSLuaFile("msync/client_gui/"..v)
        MSync.log(MSYNC_DBG_DEBUG, "Added client Lua file: "..v)
    end

    local files, _ = file.Find("msync/client_gui/modules/*.lua", "LUA")
    for k, v in pairs(files) do
        AddCSLuaFile("msync/client_gui/modules/"..v)
        MSync.log(MSYNC_DBG_DEBUG, "Added client module file: "..v)
    end
end

--[[
    Description: Function to load the MSync settings file
    Returns: true
]]
function MSync.func.loadSettings()
    MSync.log(MSYNC_DBG_INFO, "Loading Settings")
    if not file.Exists("msync/settings.txt", "DATA") then
        MSync.settings.data = {
            mysql = {
                host = "127.0.0.1",
                port = 3306,
                username = "root",
                password = "",
                database = "msync"
            },
            enabledModules = {
                ["MRSync"] = true
            },
            serverGroup = "allservers"
        }
        file.CreateDir("msync")
        file.Write("msync/settings.txt", util.TableToJSON(MSync.settings.data, true))
        MSync.log(MSYNC_DBG_DEBUG, "Created new configuration")
    else
        MSync.settings.data = util.JSONToTable(file.Read("msync/settings.txt", "DATA"))

        if MSync.settings.data.EnabledModules and MSync.settings.data.DisabledModules then
            MSync.log(MSYNC_DBG_WARNING, "Old settings file found! Updating to new format")
            file.Delete( "msync/settings.txt" )

            local oldSettings = table.Copy(MSync.settings.data)
            MSync.settings.data = {
                mysql = {
                    host = oldSettings.mysql.Host,
                    port = oldSettings.mysql.Port,
                    username = oldSettings.mysql.Username,
                    password = oldSettings.mysql.Password,
                    database = oldSettings.mysql.Database
                },
                enabledModules = {
                    ["MRSync"] = true
                },
                serverGroup = "allservers"
            }

            file.Write("msync/settings.txt", util.TableToJSON(MSync.settings.data, true))
            MSync.log(MSYNC_DBG_WARNING, "Settings imported! Module settings cannot be ported and need to be re-done")
        end
        MSync.log(MSYNC_DBG_DEBUG, "Loaded found configuration")
    end

    return true
end

--[[
    Description: Function to save the MSync settings to the settings file
    Returns: true if the settings file exists
]]
function MSync.func.saveSettings()
    file.Write("msync/settings.txt", util.TableToJSON(MSync.settings.data, true))

    MSync.log(MSYNC_DBG_INFO, "Saved configuration")

    return file.Exists("msync/settings.txt", "DATA")
end

--[[
    Description: Function to get a table of the module informations
    Returns: table with Module informations
]]
function MSync.func.getModuleInfos()
    local infoTable = {}

    MSync.log(MSYNC_DBG_DEBUG, "Getting module informations...")

    for k,v in pairs(MSync.modules) do
        infoTable[k] = v.info
        infoTable[k].state = MSync.settings.data.enabledModules[v.info.ModuleIdentifier] or false
        MSync.log(MSYNC_DBG_DEBUG, "[getModuleInfos] Got info for "..k)
    end

    return infoTable
end

--[[
    Description: Function to return settings without the MySQL password
                We have decided that its better to Re-Enter the password always, and not be able to see the MySQL password client side
    Returns: safe settings table
]]
function MSync.func.getSafeSettings()
    local settings = table.Copy(MSync.settings.data)

    MSync.log(MSYNC_DBG_DEBUG, "Generating safe settings to be sent to the player")

    settings.mysql.password = nil

    return settings
end