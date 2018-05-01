MSync = MSync or {}
MSync.net = MSync.net or {}

function MSync.net.getSettings()
    net.Start("msync.getSettings")
    net.SendToServer()
end

function MSync.net.getModules()
    net.Start("msync.getModules")
    net.SendToServer()
end

function MSync.net.sendSettings(table)
    net.Start("msync.sendSettings")
        net.WriteTable(table)
    net.SendToServer()
end

net.Receive( "msync.sendTable", function( len, pl )
    local type = net.ReadString()
    local table = net.ReadTable()

    if type == "settings" then MSync.settings = table
    elseif type == "modules" then MSync.modules = table end
end )

net.Receive( "msync.sendMessage", function( len, pl )
    local state = net.ReadString()

    if state == "error" then
        chat.AddText(Color(255,0,0),"[MSync_ERROR] "..net.ReadString())
    elseif state == "advert" then
        chat.AddText(Color(255,255,255), "[MSync] ", Color(0,0,255), net.ReadString())
    else
        chat.AddText(Color(255,255,255), "[MSync] "..net.ReadString())
    end
end )