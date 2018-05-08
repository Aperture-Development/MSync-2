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

--[[
    Description: Net Receiver - Gets called when the client requests a table
    Returns: nothing
]]   
net.Receive("msync.getTable", function(len, ply)
    if not ply:query("msync.getTable") then return end
    
    local identifier = net.ReadString()
    MSync.net.sendTable(ply, identifier, MSync[identifier])
end )

--[[
    Description: Net Receiver - Gets called when the client sends the settings table to the server
    Returns: nothing
]]   
net.Receive("msync.sendSettings", function(len, ply)
    if not ply:query("msync.sendSettings") then return end
    
    MSync.settings.data = net.ReadTable()
    MSync.function.saveSettings()
end )

--[[
    Description: Net Receiver - Gets called when the client requests the settings table
    Returns: nothing
]]   
net.Receive("msync.getSettings", function(len, ply)
    if not ply:query("msync.getSettings") then return end
    
    MSync.net.sendTable(ply, "settings", MSync.function.getSafeSettings())
end )

--[[
    Description: Net Receiver - Gets called when the client requests the module table
    Returns: nothing
]]   
net.Receive("msync.getModules", function(len, ply)
    if not ply:query("msync.getModules") then return end
    
    MSync.net.sendTable(ply, "modules", MSync.function.getModuleInfos())
end )