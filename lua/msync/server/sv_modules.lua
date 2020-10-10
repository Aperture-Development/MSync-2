MSync               = MSync     or {}
MSync.mysql         = MSync.mysql or {}
MSync.settings      = MSync.settings or {}
MSync.modules       = MSync.modules or {}
MSync.loadedModules = MSync.loadedModules or {}

--[[
    Description: Loads all server side modules
    Returns: nothing
]]
function MSync.loadModules()

    MSync.log(MSYNC_DBG_DEBUG, "Loading modules")

    local files, _ = file.Find("msync/server/modules/*.lua", "LUA")
    for k, v in pairs(files) do
        include("msync/server/modules/"..v)
        MSync.log(MSYNC_DBG_DEBUG, "Found module: "..v)
    end
end

--[[
    Description: initializes all modules
    Returns: nothing
]]
function MSync.initModules()

    MSync.log(MSYNC_DBG_DEBUG, "Initializing modules")

    MSync.mysql.dbstatus = false
    if MSync.DBServer then
        local initTransaction = MSync.DBServer:createTransaction()

        for k,v in pairs(MSync.modules) do
            if MSync.settings.data.enabledModules[v["info"].ModuleIdentifier] then
                v["init"](initTransaction)
                v["net"]()
                v["ulx"]()
                v["hooks"]()
                MSync.loadedModules[v["info"].ModuleIdentifier] = true
                MSync.net.sendModuleEnable( v["info"].ModuleIdentifier )
                MSync.log(MSYNC_DBG_INFO, "["..v["info"]["Name"].."] Module loaded")
            end
        end

        function initTransaction.onSuccess()
            MSync.log(MSYNC_DBG_INFO, "Module querys have been completed successfully")
            MSync.mysql.dbstatus = true
        end

        function initTransaction.onError(tr, err)
            MSync.log(MSYNC_DBG_ERROR, "There has been a error while loading the module querys.\nPlease inform the Developer and send him this:\n"..err)
            MSync.mysql.dbstatus = false
        end

        initTransaction:start()
    else
        MSync.log(MSYNC_DBG_ERROR, "No MySQL server connected, aborting module loading.")
    end
end

--[[
    Description: Loads single modules
    Arguments: path to module
    Returns: nothing
]]
function MSync.loadModule(path)
    local initTransaction = MSync.DBServer:createTransaction()
    local info = include(path)

    MSync.modules[info.ModuleIdentifier].init(initTransaction)
    MSync.modules[info.ModuleIdentifier].net()
    MSync.modules[info.ModuleIdentifier].ulx()
    MSync.modules[info.ModuleIdentifier].hooks()

    MSync.log(MSYNC_DBG_INFO, "["..MSync.modules[info.Name].."] Module loaded")

    function initTransaction.onSuccess()
        MSync.log(MSYNC_DBG_INFO, "Module query has been completed successfully")
        --MSync.mysql[info.ModuleIdentifier].dbstatus = true
    end

    function initTransaction.onError(tr, err)
        MSync.log(MSYNC_DBG_ERROR, "There has been a error while loading the module querys.\nPlease inform the Developer and send him this:\n"..err)
        --MSync.mysql[info.ModuleIdentifier].dbstatus = false
    end

    initTransaction:start()
end

--[[
    Description: Enables a single already loaded clientside module
    Arguments:  
        - module [string] - the module to be enabled
    Returns: nothing
]]
function MSync.enableModule( module )
    if MSync.modules[module] then
        MSync.log(MSYNC_DBG_DEBUG, "Module \"" .. module .. "\" enabled?: " .. tostring(MSync.settings.data.enabledModules[module]))
        if not MSync.settings.data.enabledModules[module] then
            if MSync.DBServer:ping() then
                local initTransaction = MSync.DBServer:createTransaction()

                MSync.modules[module].init(initTransaction)
                MSync.modules[module].net()
                MSync.modules[module].ulx()
                MSync.modules[module].hooks()

                function initTransaction.onSuccess()
                    MSync.log(MSYNC_DBG_INFO, "["..MSync.modules[module]["info"]["Name"].."] Module loaded")
                    MSync.net.sendModuleEnable( module )
                    --MSync.mysql[module].dbstatus = true
                end

                function initTransaction.onError(tr, err)
                    MSync.log(MSYNC_DBG_ERROR, "There has been a error while loading the module querys.\nPlease inform the Developer and send him this:\n"..err)
                    --MSync.mysql[module].dbstatus = false
                end

                initTransaction:start()
            else
                MSync.log(MSYNC_DBG_WARNING, "Cannot enable \"" .. module .. "\". Database isn't connected")
            end
        else
            MSync.log(MSYNC_DBG_WARNING, "Module \"" .. module .. "\" is already enabled")
        end
    else
        MSync.log(MSYNC_DBG_WARNING, "Cannot enable non-existant module \"" .. module .. "\"")
    end
end

--[[
    Description: Disabled a single already loaded clientside module
    Arguments: 
        - module [string] - the module to be disabled
    Returns: nothing
]]
function MSync.disableModule( module )
    if MSync.modules[module] then
        if MSync.settings.data.enabledModules[module] then
            if MSync.modules[module].disable then
                MSync.modules[module].disable()
                MSync.log(MSYNC_DBG_INFO, "["..MSync.modules[module]["info"]["Name"].."] Module disabled")
                MSync.net.sendModuleDisable( module )
            else
                MSync.log(MSYNC_DBG_WARNING, "Cannot disable outdated module \"" .. module .. "\"")
            end
        else
            MSync.log(MSYNC_DBG_WARNING, "Module \"" .. module .. "\" is already disabled")
        end
    else
        MSync.log(MSYNC_DBG_WARNING, "Cannot disable non-existant module \"" .. module .. "\"")
    end
end