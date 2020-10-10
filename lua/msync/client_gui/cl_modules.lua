MSync           = MSync     or {}
MSync.mysql     = MSync.mysql or {}
MSync.settings  = MSync.settings or {}
MSync.modules   = MSync.modules or {}

--[[
    Description: loads the client side modules
    Returns: nothing
]]
function MSync.loadModules()
    local files, _ = file.Find("msync/client_gui/modules/*.lua", "LUA")
    for k, v in pairs(files) do
        include("msync/client_gui/modules/"..v)
    end
    MSync.initModules()
end

--[[
    Description: initializes the client modules
    Returns: nothing
]]
function MSync.initModules()

    for k,v in pairs(MSync.modules) do
        if MSync.moduleState[v["info"]["ModuleIdentifier"]] then
            v["init"]()
            v["net"]()
            v["ulx"]()
            v["hooks"]()
            MSync.log(MSYNC_DBG_INFO, "["..v["info"]["Name"].."] Module loaded")
        end
    end

end

--[[
    Description: loads a single client side module
    Arguments: Module path
    Returns: nothing
]]
function MSync.loadModule(path)
    local info = include(path)

    MSync.modules[info.ModuleIdentifier].init()
    MSync.modules[info.ModuleIdentifier].net()
    MSync.modules[info.ModuleIdentifier].ulx()
    MSync.modules[info.ModuleIdentifier].hooks()

    MSync.log(MSYNC_DBG_INFO, "["..MSync.modules[info.ModuleIdentifier]["info"]["Name"].."] Module loaded")

end

--[[
    Description: Enables a single already loaded clientside module
    Arguments: Module path
    Returns: nothing
]]
function MSync.enableModule( module )
    if MSync.modules[module] then
        MSync.modules[module].init()
        MSync.modules[module].net()
        MSync.modules[module].ulx()
        MSync.modules[module].hooks()
        MSync.log(MSYNC_DBG_INFO, "["..MSync.modules[module]["info"]["Name"].."] Module loaded")
    else
        MSync.log(MSYNC_DBG_WARNING, "Cannot enable non-existant module \"" .. module .. "\"")
    end
end

--[[
    Description: Disabled a single already loaded clientside module
    Arguments: Module path
    Returns: nothing
]]
function MSync.disableModule( module )
    if MSync.modules[module] then
        if MSync.modules[module].disable then
            MSync.modules[module].disable()
            MSync.log(MSYNC_DBG_INFO, "["..MSync.modules[module]["info"]["Name"].."] Module disabled")
        else
            MSync.log(MSYNC_DBG_WARNING, "Cannot disable outdated module \"" .. module .. "\"")
        end
    else
        MSync.log(MSYNC_DBG_WARNING, "Cannot disable non-existant module \"" .. module .. "\"")
    end
end
