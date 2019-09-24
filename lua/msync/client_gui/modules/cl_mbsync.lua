MSync = MSync or {}
MSync.modules = MSync.modules or {}
MSync.modules.MBSync = MSync.modules.SampleModule or {}
--[[
 * @file       cl_mbsync.lua
 * @package    MySQL Ban Sync
 * @author     Aperture Development
 * @license    root_dir/LICENCE
 * @version    0.0.5
]]

--[[
    Define name, description and module identifier
]]
local info = {
    Name = "MySQL Ban Sync",
    ModuleIdentifier = "MBSync",
    Description = "Synchronise band across your servers",
    Version = "0.0.5"
}

--[[
    Prepare Module
]]

MSync.modules[info.ModuleIdentifier] = MSync.modules[info.ModuleIdentifier] or {}
MSync.modules[info.ModuleIdentifier].info = info

--[[
    Define additional functions that are later used
]]
MSync.modules[info.ModuleIdentifier].init = function() 

    function MSync.modules.SampleModule.SampleFunction()
        return true
    end

end

--[[
    Define the admin panel for the settings
]]
MSync.modules[info.ModuleIdentifier].adminPanel = function(sheet)
    local pnl = vgui.Create( "DPanel", sheet )
    pnl:Dock(FILL)
    return pnl
end

--[[
    Define the client panel for client usage ( or as example: use it as additional admin gui which does not need msync.admingui permission)
]]
MSync.modules[info.ModuleIdentifier].clientPanel = function()
    local panel = vgui.Create( "DFrame" )
    panel:SetSize( 800, 500 )
    panel:SetTitle( "MSync Admin Menu" )
    panel:Center()
    panel:MakePopup()

    local search_textentry = vgui.Create( "DTextEntry", panel )
    search_textentry:SetPos( 15, 35 )
    search_textentry:SetSize( 250, 20 )
    search_textentry:SetPlaceholderText( "Nickname/SteamID/SID64/Admin" )

    local ban_table = vgui.Create( "DListView", panel )
    ban_table:SetPos( 15, 60 )
    ban_table:SetSize( 770, 400 )
    ban_table:SetMultiSelect( false )
    ban_table:AddColumn( "Ban ID" ):SetFixedWidth( 50 )
    ban_table:AddColumn( "Nickname" )
    --ban_table:AddColumn( "SteamID" )
    ban_table:AddColumn( "Admin" )
    --ban_table:AddColumn( "Ban Date" )
    ban_table:AddColumn( "Ban Length" )
    ban_table:AddColumn( "Ban Reason" )
    --local test = allserver_table:AddColumn( "Test" )
    ban_table.OnRowRightClick = function(panel, lineID, line)
        local ident = line:GetValue(1)
        local cursor_x, cursor_y = panel:CursorPos()
        local DMenu = vgui.Create("DMenu", panel)
        DMenu:SetPos(cursor_x, cursor_y)
        DMenu:AddOption("Unban")
        DMenu:AddOption("Edit")
        DMenu:AddOption("Advanced Info")
        DMenu.OptionSelected = function(menu,optPnl,optStr)
            if MSync.modules.MRSync.settings.syncall[line:GetValue(1)] then

                ban_table:RemoveLine(lineID)
                MSync.modules.MRSync.settings.syncall[line:GetValue(1)] = nil
                MSync.modules.MRSync.sendSettings()

            end
        end
    end

    --test:SetFixedWidth( 0 )

    local search_button = vgui.Create( "DButton", panel )
    search_button:SetText( "Search" )					
    search_button:SetPos( 270, 35 )
    search_button:SetSize( 130, 20 )
    search_button.DoClick = function() 
        if search_button:GetValue() and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    local sortby_button = vgui.Create( "DButton", panel )
    sortby_button:SetText( "Sort by: [INSERT]" )					
    sortby_button:SetPos( 405, 35 )
    sortby_button:SetSize( 130, 20 )
    sortby_button.DoClick = function() 
        if allserver_textentry:GetValue() and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    local listascdesc_button = vgui.Create( "DButton", panel )
    listascdesc_button:SetText( "List: Asc/Desc" )					
    listascdesc_button:SetPos( 540, 35 )
    listascdesc_button:SetSize( 110, 20 )
    listascdesc_button.DoClick = function() 
        if allserver_textentry:GetValue() and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    local sync_button = vgui.Create( "DButton", panel )
    sync_button:SetText( "Reload Bans" )					
    sync_button:SetPos( 655, 35 )
    sync_button:SetSize( 130, 20 )
    sync_button.DoClick = function() 
        if allserver_textentry:GetValue() and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    local firstpage_button = vgui.Create( "DButton", panel )
    firstpage_button:SetText( "<< First" )					
    firstpage_button:SetPos( 15, 461 )
    firstpage_button:SetSize( 191, 20 )
    firstpage_button:SetDisabled(true)
    firstpage_button.DoClick = function() 
        if allserver_textentry:GetValue() and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    local previouspage_button = vgui.Create( "DButton", panel )
    previouspage_button:SetText( "< Previous" )					
    previouspage_button:SetPos( 208, 461 )
    previouspage_button:SetSize( 191, 20 )
    previouspage_button:SetDisabled(true)
    previouspage_button.DoClick = function() 
        if allserver_textentry:GetValue() and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    local nextpage_button = vgui.Create( "DButton", panel )
    nextpage_button:SetText( "Next >" )					
    nextpage_button:SetPos( 401, 461 )
    nextpage_button:SetSize( 191, 20 )
    nextpage_button.DoClick = function() 
        if allserver_textentry:GetValue() and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    local lastpage_button = vgui.Create( "DButton", panel )
    lastpage_button:SetText( "Last >>" )					
    lastpage_button:SetPos( 594, 461 )
    lastpage_button:SetSize( 191, 20 )
    lastpage_button.DoClick = function() 
        if allserver_textentry:GetValue() and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    return panel
end

--[[
    Define net receivers and util.AddNetworkString
]]
MSync.modules[info.ModuleIdentifier].net = function() 
    net.Receive( "my_message", function( len, pl )
        if ( IsValid( pl ) and pl:IsPlayer() ) then
            print( "Message from " .. pl:Nick() .. " received. Its length is " .. len .. "." )
        else
            print( "Message from server received. Its length is " .. len .. "." )
        end
    end )
end

--[[
    Define ulx Commands and overwrite common ulx functions (module does not get loaded until ulx has fully been loaded)
]]
MSync.modules[info.ModuleIdentifier].ulx = function() 
    
end

--[[
    Define hooks your module is listening on e.g. PlayerDisconnect
]]
MSync.modules[info.ModuleIdentifier].hooks = function() 
    hook.Add("initialize", "msync_sampleModule_init", function()
        
    end)
end


MSync.modules[info.ModuleIdentifier].clientPanel() 

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules[info.ModuleIdentifier].info