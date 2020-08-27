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
    local initTransaction = MSync.DBServer:createTransaction()
    local info = include(path)

    MSync.modules[info.ModuleIdentifier].init()
    MSync.modules[info.ModuleIdentifier].net()
    MSync.modules[info.ModuleIdentifier].ulx()
    MSync.modules[info.ModuleIdentifier].hooks()

    MSync.log(MSYNC_DBG_INFO, "["..MSync.modules[info.Name].."] Module loaded")

end
