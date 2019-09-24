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

    MSync.modules[info.ModuleIdentifier].advancedInfoPanel = function()
        local panel = vgui.Create( "DFrame" )
        panel:SetSize( 350, 500 )
        panel:SetTitle( "MBSync Advanced Ban Info" )
        panel:Center()
        panel:MakePopup()

        --[[
            Info about the banned user
        ]]

        local nickname_text = vgui.Create( "DLabel", panel )
        nickname_text:SetPos( 15, 35 )
        nickname_text:SetColor( Color( 255, 255, 255 ) )
        nickname_text:SetText( "Nickname:" )
        nickname_text:SetSize(380, 15)

        local nickname_textentry = vgui.Create( "DTextEntry", panel )
        nickname_textentry:SetPos( 125, 35 )
        nickname_textentry:SetSize( 210, 20 )
        nickname_textentry:SetText( "[ApDev] Rainbow Dash" )
        nickname_textentry:SetDisabled(true)

        local steamid_text = vgui.Create( "DLabel", panel )
        steamid_text:SetPos( 15, 60 )
        steamid_text:SetColor( Color( 255, 255, 255 ) )
        steamid_text:SetText( "SteamID:" )
        steamid_text:SetSize(380, 15)

        local steamid_textentry = vgui.Create( "DTextEntry", panel )
        steamid_textentry:SetPos( 125, 60 )
        steamid_textentry:SetSize( 210, 20 )
        steamid_textentry:SetText( "STEAM_0:0:0" )
        steamid_textentry:SetDisabled(true)

        local steamid64_text = vgui.Create( "DLabel", panel )
        steamid64_text:SetPos( 15, 85 )
        steamid64_text:SetColor( Color( 255, 255, 255 ) )
        steamid64_text:SetText( "SteamID64:" )
        steamid64_text:SetSize(380, 15)

        local steamid64_textentry = vgui.Create( "DTextEntry", panel )
        steamid64_textentry:SetPos( 125, 85 )
        steamid64_textentry:SetSize( 210, 20 )
        steamid64_textentry:SetText( "7600000000" )
        steamid64_textentry:SetDisabled(true)

        --local adminheader_text = vgui.Create( "DLabel", panel )
        --adminheader_text:SetPos( 15, 110 )
        --adminheader_text:SetColor( Color( 255, 255, 255 ) )
        --adminheader_text:SetText( "Admin" )
        --adminheader_text:SetSize(320, 15)
        --adminheader_text:SetContentAlignment( 5 )

        --[[
            Info about the banning Admin
        ]]

        local adminnickname_text = vgui.Create( "DLabel", panel )
        adminnickname_text:SetPos( 15, 120 )
        adminnickname_text:SetColor( Color( 255, 255, 255 ) )
        adminnickname_text:SetText( "Admin Nickname:" )
        adminnickname_text:SetSize(380, 15)

        local adminnickname_textentry = vgui.Create( "DTextEntry", panel )
        adminnickname_textentry:SetPos( 125, 120 )
        adminnickname_textentry:SetSize( 210, 20 )
        adminnickname_textentry:SetText( "[ApDev] Rainbow Dash" )
        adminnickname_textentry:SetDisabled(true)

        local adminsteamid_text = vgui.Create( "DLabel", panel )
        adminsteamid_text:SetPos( 15, 145 )
        adminsteamid_text:SetColor( Color( 255, 255, 255 ) )
        adminsteamid_text:SetText( "Admin SteamID:" )
        adminsteamid_text:SetSize(380, 15)

        local adminsteamid_textentry = vgui.Create( "DTextEntry", panel )
        adminsteamid_textentry:SetPos( 125, 145 )
        adminsteamid_textentry:SetSize( 210, 20 )
        adminsteamid_textentry:SetText( "STEAM_0:0:0" )
        adminsteamid_textentry:SetDisabled(true)

        local adminsteamid64_text = vgui.Create( "DLabel", panel )
        adminsteamid64_text:SetPos( 15, 170 )
        adminsteamid64_text:SetColor( Color( 255, 255, 255 ) )
        adminsteamid64_text:SetText( "Admin SteamID64:" )
        adminsteamid64_text:SetSize(380, 15)

        local adminsteamid64_textentry = vgui.Create( "DTextEntry", panel )
        adminsteamid64_textentry:SetPos( 125, 170 )
        adminsteamid64_textentry:SetSize( 210, 20 )
        adminsteamid64_textentry:SetText( "7600000000" )
        adminsteamid64_textentry:SetDisabled(true)

        --[[
            Info about the ban
        ]]

        local bandate_text = vgui.Create( "DLabel", panel )
        bandate_text:SetPos( 15, 205 )
        bandate_text:SetColor( Color( 255, 255, 255 ) )
        bandate_text:SetText( "Ban Date:" )
        bandate_text:SetSize(380, 15)

        local bandate_textentry = vgui.Create( "DTextEntry", panel )
        bandate_textentry:SetPos( 125, 205 )
        bandate_textentry:SetSize( 210, 20 )
        bandate_textentry:SetText( "24.09.2019 23:11" )
        bandate_textentry:SetDisabled(true)

        local banlength_text = vgui.Create( "DLabel", panel )
        banlength_text:SetPos( 15, 230 )
        banlength_text:SetColor( Color( 255, 255, 255 ) )
        banlength_text:SetText( "Ban Length:" )
        banlength_text:SetSize(380, 15)

        local banlength_textentry = vgui.Create( "DTextEntry", panel )
        banlength_textentry:SetPos( 125, 230 )
        banlength_textentry:SetSize( 210, 20 )
        banlength_textentry:SetText( "Permanent" )
        banlength_textentry:SetDisabled(true)

        local unbandate_text = vgui.Create( "DLabel", panel )
        unbandate_text:SetPos( 15, 255 )
        unbandate_text:SetColor( Color( 255, 255, 255 ) )
        unbandate_text:SetText( "Unban Date:" )
        unbandate_text:SetSize(380, 15)

        local unbandate_textentry = vgui.Create( "DTextEntry", panel )
        unbandate_textentry:SetPos( 125, 255 )
        unbandate_textentry:SetSize( 210, 20 )
        unbandate_textentry:SetText( "24.09.2019 23:11" )
        unbandate_textentry:SetDisabled(true)

        local remainingtime_text = vgui.Create( "DLabel", panel )
        remainingtime_text:SetPos( 15, 280 )
        remainingtime_text:SetColor( Color( 255, 255, 255 ) )
        remainingtime_text:SetText( "Time Remaining:" )
        remainingtime_text:SetSize(380, 15)

        local remainingtime_textentry = vgui.Create( "DTextEntry", panel )
        remainingtime_textentry:SetPos( 125, 280 )
        remainingtime_textentry:SetSize( 210, 20 )
        remainingtime_textentry:SetText( "1d,13h" )
        remainingtime_textentry:SetDisabled(true)

        local banreason_text = vgui.Create( "DLabel", panel )
        banreason_text:SetPos( 15, 320 )
        banreason_text:SetColor( Color( 255, 255, 255 ) )
        banreason_text:SetText( "Ban Reason:" )
        banreason_text:SetSize(380, 15)
        banreason_text:SetDark(1)

        local banreason_panel = vgui.Create( "DPanel", panel )
        banreason_panel:SetPos( 15, 340 )
        banreason_panel:SetSize( 320, 110 )

        local banreasonreason_text = vgui.Create( "DLabel", banreason_panel )
        banreasonreason_text:SetPos( 5, 5 )
        banreasonreason_text:SetColor( Color( 0, 0, 0 ) )
        banreasonreason_text:SetText( "This is a very long ban reason i am setting to see if the text wrapping does actually work. Maybe it doesnt this is why I test it. Please excuse my typos when you find this prototype commit" )
        banreasonreason_text:SetSize(310, 100)
        banreasonreason_text:SetWrap( true )
        banreasonreason_text:SetContentAlignment( 7 )

        local close_button = vgui.Create( "DButton", panel )
        close_button:SetText( "Close" )	
        close_button:SetPos( 15, 455 )
        close_button:SetSize( 320, 30 )
        close_button.DoClick = function() 
            panel:Close()
        end

    end

    MSync.modules[info.ModuleIdentifier].editBanPanel = function()

    end

    MSync.modules[info.ModuleIdentifier].advancedInfoPanel()
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