MSync = MSync or {}
MSync.net = MSync.net or {}

--[[
    Description: Function to send a table to the client
    Arguments:
        player [player] - the player to send the table to
        identifier [string] - what kind of table you are sending to the client
        table [table] - the table you send
    Returns: nothing
]]   
function MSync.net.sendTable(ply, identifier, table)
    local identifier = identifier or "settings"

    net.Start("msync.sendTable")
        net.WriteString(identifier)
        net.WriteTable(table)
    net.Send(ply)
end
util.AddNetworkString("msync.sendTable")

--[[
    Description: Function to send a text message to the client
    Arguments:
        player [player] - the player you want to send the message to
        state [string] - the state of the message, can be "info", "error", "advert"
        message [string] - the message you want to send to the client
    Returns: nothing
]]   
function MSync.net.sendMessage(ply, state, string)
    local state = state or "info"

    net.Start("msync.sendMessage")
        net.WriteString(state)
        net.WriteString(string)
    net.Send(ply)
end
util.AddNetworkString("msync.sendMessage")

--[[
    Description: Function to open the admin GUI on the client
    Arguments:
        player [player] - the player that wants to open the admin GUI
    Returns: nothing
]]   
function MSync.net.openAdminGUI(ply)
    net.Start("msync.openAdminGUI")
    net.Send(ply)
end
util.AddNetworkString("msync.openAdminGUI")

--[[
    Description: Net Receiver - Gets called when the client requests a table
    Returns: nothing
]]   
util.AddNetworkString("msync.getTable")
net.Receive("msync.getTable", function(len, ply)
    if not ply:query("msync.getTable") then return end
    
    local identifier = net.ReadString()
    MSync.net.sendTable(ply, identifier, MSync[identifier])
end )

--[[
    Description: Net Receiver - Gets called when the client sends the settings table to the server
    Returns: nothing
]]   
util.AddNetworkString("msync.sendSettings")
net.Receive("msync.sendSettings", function(len, ply)
    if not ply:query("msync.sendSettings") then return end
    
    MSync.settings.data = net.ReadTable()
    MSync.func.saveSettings()
end )

--[[
    Description: Net Receiver - Gets called when the client requests the settings table
    Returns: nothing
]]   
util.AddNetworkString("msync.getSettings")
net.Receive("msync.getSettings", function(len, ply)
    if not ply:query("msync.getSettings") then return end
    
    MSync.net.sendTable(ply, "settings", MSync.func.getSafeSettings())
end )

--[[
    Description: Net Receiver - Gets called when the client requests the module table
    Returns: nothing
]]   
util.AddNetworkString("msync.getModules")
net.Receive("msync.getModules", function(len, ply)
    if not ply:query("msync.getModules") then return end

    MSync.net.sendTable(ply, "modules", MSync.func.getModuleInfos())
end )

--[[
    Description: Net Receiver - Gets called when the client requests a module toggle
    Returns: nothing
]]   
util.AddNetworkString("msync.toggleModule")
net.Receive("msync.toggleModule", function(len, ply)
    if not ply:query("msync.toggleModule") then return end
    
    local ident = net.ReadString()
    local state = net.ReadString()

    if state == "Enable" then
        MSync.settings.data.enabledModules[ident] = true
    elseif state == "Disable" then
        MSync.settings.data.enabledModules[ident] = nil
    end
    MSync.func.saveSettings()
    MSync.net.sendMessage(ply, "info", state.."d module "..ident)
end )

--[[
    Description: Net Receiver - Gets called when the client requests db connection
    Returns: nothing
]]   
util.AddNetworkString("msync.connectDB")
net.Receive("msync.connectDB", function(len, ply)
    if not ply:query("msync.connectDB") then return end

    MSync.mysql.initialize() 
end )