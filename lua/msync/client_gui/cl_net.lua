MSync = MSync or {}
MSync.net = MSync.net or {}

--[[
    Description: Function to get the server settings
    Returns: nothing
]]
function MSync.net.getSettings()
    MSync.log(MSYNC_DBG_DEBUG, "Exec: net.getSettings")
    net.Start("msync.getSettings")
    net.SendToServer()
end

--[[
    Description: function to get the modules
    Returns: nothing
]]
function MSync.net.getModules()
    MSync.log(MSYNC_DBG_DEBUG, "Exec: net.getModules")
    net.Start("msync.getModules")
    net.SendToServer()
end

--[[
    Description: function to toggle a module
    Returns: nothing
]]
function MSync.net.toggleModule(ident, state)
    MSync.log(MSYNC_DBG_DEBUG, "Exec: net.toggleModule Param.: " .. ident .. " " .. state)
    net.Start("msync.toggleModule")
        net.WriteString(ident)
        net.WriteString(state)
    net.SendToServer()
end

--[[
    Description: function to send settngs to the server
    Returns: nothing
]]
function MSync.net.sendSettings(table)
    MSync.log(MSYNC_DBG_DEBUG, "Exec: net.sendSettings Param.: " .. tostring(table))
    net.Start("msync.sendSettings")
        net.WriteTable(table)
    net.SendToServer()
end

--[[
    Description: function to connect to the database server
    Returns: nothing
]]
function MSync.net.connectDB()
    MSync.log(MSYNC_DBG_DEBUG, "Exec: net.connectDB")
    net.Start("msync.connectDB")
    net.SendToServer()
end

--[[
    Description: Net Receiver - Gets called when the server sends a table to the client
    Returns: nothing
]]
net.Receive( "msync.sendTable", function( len, pl )
    MSync.log(MSYNC_DBG_DEBUG, "Net: msync.sendTable")
    local type = net.ReadString()
    local table = net.ReadTable()

    if type == "settings" then MSync.settings = table; MSync.log(MSYNC_DBG_INFO, "Got settings from server")
    elseif type == "modules" then MSync.serverModules = table; MSync.log(MSYNC_DBG_INFO, "Got modules from server")
    elseif type == "modulestate" then
        MSync.moduleState = table
        MSync.loadModules()
        MSync.log(MSYNC_DBG_INFO, "Got module states from server")
    end
end )

--[[
    Description:  Net Receiver - Gets called when the server sends a message to the client
    Returns: nothing
]]
net.Receive( "msync.sendMessage", function( len, pl )
    MSync.log(MSYNC_DBG_DEBUG, "Net: msync.sendMessage")
    local state = net.ReadString()

    if state == "error" then
        chat.AddText(Color(255,0,0),"[MSync_ERROR] "..net.ReadString())
    elseif state == "advert" then
        chat.AddText(Color(255,255,255), "[MSync] ", Color(0,0,255), net.ReadString())
    else
        chat.AddText(Color(255,255,255), "[MSync] "..net.ReadString())
    end
end )

--[[
    Description:  Net Receiver - Gets called when the client requested to open the admin GUI
    Returns: nothing
]]
net.Receive( "msync.openAdminGUI", function( len, pl )
    MSync.log(MSYNC_DBG_DEBUG, "Net: msync.openAdminGUI")
    MSync.AdminPanel.InitPanel()
end )

--[[
    Description:  Net Receiver - Gets called when server sent the db status
    Returns: nothing
]]
net.Receive( "msync.dbStatus", function( len, pl )
    MSync.DBStatus = net.ReadBool()
    MSync.log(MSYNC_DBG_DEBUG, "Net: msync.dbStatus Return: " .. tostring(MSync.DBStatus))
end )