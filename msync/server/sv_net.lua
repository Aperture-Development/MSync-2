MSync = MSync or {}
MSync.net = MSync.net or {}

function MSync.net.sendTable(ply, identifier, table)
    identifier = identifier or "settings"

    net.Start("msync.sendTable")
        net.WriteString(identifier)
        net.WriteTable(table)
    net.Send(ply)

end

function MSync.net.sendMessage(ply, state, string)
    state = state or "info"

    net.Start("msync.sendMessage")
        net.WriteString(state)
        net.WriteString(string)
    net.Send(ply)

end

net.Receive("msync.getTable", function(len, ply)
    if not ply:query("msync.getTable") then return end
    
    local identifier = net.ReadString()
    MSync.net.sendTable(ply, identifier, MSync[identifier])
end )

net.Receive("msync.sendSettings", function(len, ply)
    if not ply:query("msync.sendSettings") then return end
    
    MSync.settings.data = net.ReadTable()
    MSync.function.saveSettings()
end )