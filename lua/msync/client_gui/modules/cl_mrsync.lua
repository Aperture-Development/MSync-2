MSync = MSync or {}
MSync.modules = MSync.modules or {}
MSync.modules.MRSync = MSync.modules.MRSync or {}
--[[
 * @file       cl_mrsync.lua
 * @package    MySQL Rank Sync
 * @author     Aperture Development
 * @license    root_dir/LICENCE
 * @version    2.2.1
]]

--[[
    Define name, description and module identifier
]]
MSync.modules.MRSync.info = {
    Name = "MySQL Rank Sync",
    ModuleIdentifier = "MRSync",
    Description = "Synchronise your ranks across your servers",
    Version = "2.2.1"
}

--[[
    Define additional functions that are later used
]]
function MSync.modules.MRSync.init()

end

--[[
    Define the admin panel for the settings
]]
function MSync.modules.MRSync.adminPanel(sheet)
    MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Initializing AdminGUI panel");
    local pnl = vgui.Create( "DPanel", sheet )
    pnl:Dock(FILL)

    local allserver_text = vgui.Create( "DLabel", pnl )
    allserver_text:SetPos( 25, 0 )
    allserver_text:SetColor( Color( 0, 0, 0 ) )
    allserver_text:SetText( "Add Allserver ranks. Those ranks get Synced across all servers." )
    allserver_text:SetSize(380, 15)

    local allserver_textentry = vgui.Create( "DTextEntry", pnl )
    allserver_textentry:SetPos( 25, 15 )
    allserver_textentry:SetSize( 250, 20 )
    allserver_textentry:SetPlaceholderText( "Rank name as string. Example: superadmin" )

    local allserver_table = vgui.Create( "DListView", pnl )
    allserver_table:SetPos( 25, 35 )
    allserver_table:SetSize( 380, 100 )
    allserver_table:SetMultiSelect( false )
    allserver_table:AddColumn( "Allserver Ranks" )
    allserver_table.OnRowRightClick = function(panel, lineID, line)
        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Right clicked " .. line:GetValue(1));
        local ident = line:GetValue(1)
        local cursor_x, cursor_y = panel:CursorPos()
        local DMenu = vgui.Create("DMenu", panel)
        DMenu:SetPos(cursor_x, cursor_y)
        DMenu:AddOption("Remove")
        DMenu.OptionSelected = function(menu,optPnl,optStr)
            if MSync.modules.MRSync.settings.syncall[line:GetValue(1)] then

                MSync.log(MSYNC_DBG_INFO, "[MRSync] Removing \"" .. line:GetValue(1) .. "\" from allservers ranks");
                allserver_table:RemoveLine(lineID)
                MSync.modules.MRSync.settings.syncall[line:GetValue(1)] = nil
                MSync.modules.MRSync.sendSettings()

            end
        end
    end

    local allserver_button = vgui.Create( "DButton", pnl )
    allserver_button:SetText( "Add" )
    allserver_button:SetPos( 275, 15 )
    allserver_button:SetSize( 130, 20 )
    allserver_button.DoClick = function()
        if string.len(allserver_textentry:GetValue()) > 0 and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            if string.match(allserver_textentry:GetValue(), "^%s*$") or string.match(allserver_textentry:GetValue(), "^%s") or string.match(allserver_textentry:GetValue(), "%s$") then MSync.log(MSYNC_DBG_WARNING, "[MRSync] String contains one or more whitespaces at the end or the beginning, not adding to list"); return end

            MSync.log(MSYNC_DBG_INFO, "[MRSync] Adding \"" .. allserver_textentry:GetValue() .. "\" to allservers rank list");
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    local nosync_text = vgui.Create( "DLabel", pnl )
    nosync_text:SetPos( 25, 140 )
    nosync_text:SetColor( Color( 0, 0, 0 ) )
    nosync_text:SetText( "Add Nosync ranks. Those ranks do not get Synced at all." )
    nosync_text:SetSize(380, 15)

    local nosync_textentry = vgui.Create( "DTextEntry", pnl )
    nosync_textentry:SetPos( 25, 155 )
    nosync_textentry:SetSize( 250, 20 )
    nosync_textentry:SetPlaceholderText( "Rank name as string. Example: superadmin" )

    local nosync_table = vgui.Create( "DListView", pnl )
    nosync_table:SetPos( 25, 175 )
    nosync_table:SetSize( 380, 100 )
    nosync_table:SetMultiSelect( false )
    nosync_table:AddColumn( "Nosync Ranks" )
    nosync_table.OnRowRightClick = function(panel, lineID, line)
        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Right clicked " .. line:GetValue(1));
        local ident = line:GetValue(1)
        local cursor_x, cursor_y = panel:CursorPos()
        local DMenu = vgui.Create("DMenu", panel)
        DMenu:SetPos(cursor_x, cursor_y)
        DMenu:AddOption("Remove")
        DMenu.OptionSelected = function(menu,optPnl,optStr)
            if MSync.modules.MRSync.settings.nosync[line:GetValue(1)] then

                MSync.log(MSYNC_DBG_INFO, "[MRSync] Removing \"" .. line:GetValue(1) .. "\" from nosync ranks");
                nosync_table:RemoveLine(lineID)
                MSync.modules.MRSync.settings.nosync[line:GetValue(1)] = nil
                MSync.modules.MRSync.sendSettings()

            end
        end
    end

    local nosync_button = vgui.Create( "DButton", pnl )
    nosync_button:SetText( "Add" )
    nosync_button:SetPos( 275, 155 )
    nosync_button:SetSize( 130, 20 )
    nosync_button.DoClick = function()
        if string.len(nosync_textentry:GetValue()) > 0 and not MSync.modules.MRSync.settings.nosync[nosync_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[nosync_textentry:GetValue()] then
            if string.match(nosync_textentry:GetValue(), "^%s*$") or string.match(nosync_textentry:GetValue(), "^%s") or string.match(nosync_textentry:GetValue(), "%s$") then MSync.log(MSYNC_DBG_WARNING, "[MRSync] String contains one or more whitespaces at the end or the beginning, not adding to list"); return end

            MSync.log(MSYNC_DBG_INFO, "[MRSync] Adding \"" .. allserver_textentry:GetValue() .. "\" to nosync rank list");
            nosync_table:AddLine(nosync_textentry:GetValue())
            MSync.modules.MRSync.settings.nosync[nosync_textentry:GetValue()] = true
            nosync_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    -- Load settings from the server
    MSync.modules.MRSync.getSettings()

    -- Wait for settings from the server
    if not MSync.modules.MRSync.settings then
        timer.Create("mrsync.t.checkSettings", 1, 0, function()
            if not MSync.modules.MRSync.settings then return end

            MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Got settings from server, adding to panel");
            for k,_ in pairs(MSync.modules.MRSync.settings.syncall) do
                allserver_table:AddLine(k)
            end

            for k,_ in pairs(MSync.modules.MRSync.settings.nosync) do
                nosync_table:AddLine(k)
            end

            timer.Remove("mrsync.t.checkSettings")
        end)
    else

        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Settings found, adding to panel");
        for k,_ in pairs(MSync.modules.MRSync.settings.syncall) do
            allserver_table:AddLine(k)
        end

        for k,_ in pairs(MSync.modules.MRSync.settings.nosync) do
            nosync_table:AddLine(k)
        end
    end

    return pnl
end

--[[
    Define the client panel for client usage ( or as example: use it as additional admin gui which does not need msync.admingui permission)
]]
function MSync.modules.MRSync.clientPanel()
    local pnl = vgui.Create( "DPanel" )

    return pnl
end

--[[
    Define net receivers and util.AddNetworkString
]]
function MSync.modules.MRSync.net()

    --[[
        Description: Function to send the mrsync settings to the client
        Arguments:
            player [player] - the player that wants to open the admin GUI
        Returns: nothing
    ]]
    function MSync.modules.MRSync.sendSettings()
        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Exec: MRSync.sendSettings");
        net.Start("msync.mrsync.sendSettings")
            net.WriteTable(MSync.modules.MRSync.settings)
        net.SendToServer()
    end

    --[[
        Description: Function to send the mrsync settings to the client
        Arguments:
            player [player] - the player that wants to open the admin GUI
        Returns: nothing
    ]]
    function MSync.modules.MRSync.getSettings()
        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Exec: MRSync.getSettings");
        net.Start("msync.mrsync.getSettings")
        net.SendToServer()
    end

    --[[
        Description: Net Receiver - Gets called when the client requests the settings table
        Returns: nothing
    ]]
    net.Receive("msync.mrsync.sendSettingsPly", function(len, ply)
        MSync.log(MSYNC_DBG_DEBUG, "[MRSync] Net: msync.mrsync.sendSettingsPly");
        MSync.modules.MRSync.settings = net.ReadTable()
    end )
end

--[[
    Define ulx Commands and overwrite common ulx functions (module does not get loaded until ulx has fully been loaded)
]]
function MSync.modules.MRSync.ulx()

end

--[[
    Define hooks your module is listening on e.g. PlayerDisconnect
]]
function MSync.modules.MRSync.hooks()

end

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules.MRSync.info