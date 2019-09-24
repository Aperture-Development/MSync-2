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
            if optStr == "Unban" then
                --
            elseif optStr == "Edit" then
                MSync.modules[info.ModuleIdentifier].editBanPanel()
                print(line:GetColumnText( 1 ))
            elseif optStr == "Advanced Info" then
                MSync.modules[info.ModuleIdentifier].advancedInfoPanel()
            end
        end
    end

    ban_table:AddLine( "1", "[ApDev] Rainbow Dash", "[ApDev] Rainbow Dash", "Permanent", "Fucking Around" )

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
        local panel = vgui.Create( "DFrame" )
        panel:SetSize( 350, 280 )
        panel:SetTitle( "MBSync Edit Ban" )
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

        --[[
            Editable Data
        ]]

        local banlength_text = vgui.Create( "DLabel", panel )
        banlength_text:SetPos( 15, 120 )
        banlength_text:SetColor( Color( 255, 255, 255 ) )
        banlength_text:SetText( "Ban Length:" )
        banlength_text:SetSize(380, 15)

        local banlength_textentry = vgui.Create( "DTextEntry", panel )
        banlength_textentry:SetPos( 125, 120 )
        banlength_textentry:SetSize( 210, 20 )
        banlength_textentry:SetText( "Permanent" )
        banlength_textentry:SetDisabled(false)

        local banallservers_text = vgui.Create( "DLabel", panel )
        banallservers_text:SetPos( 15, 145 )
        banallservers_text:SetColor( Color( 255, 255, 255 ) )
        banallservers_text:SetText( "Banned everywhere:" )
        banallservers_text:SetSize(380, 15)

        local banallservers_textentry = vgui.Create( "DComboBox", panel )
        banallservers_textentry:SetPos( 125, 145 )
        banallservers_textentry:SetSize( 210, 20 )
        banallservers_textentry:SetValue( "true" )
        banallservers_textentry:AddChoice( "true" )
        banallservers_textentry:AddChoice( "false" )
        banallservers_textentry:SetSortItems( false )
        banallservers_textentry.OnSelect = function( self, index, value )
            if value == "true" then
                print("True")
            elseif value == "false" then
                print("False")
            end
        end

        local banlreason_text = vgui.Create( "DLabel", panel )
        banlreason_text:SetPos( 15, 170 )
        banlreason_text:SetColor( Color( 255, 255, 255 ) )
        banlreason_text:SetText( "Ban Reason:" )
        banlreason_text:SetSize(380, 15)

        local banreason_textentry = vgui.Create( "DTextEntry", panel )
        banreason_textentry:SetPos( 125, 170 )
        banreason_textentry:SetSize( 210, 20 )
        banreason_textentry:SetText( "Permanent" )
        banreason_textentry:SetDisabled(false)

        --[[ 
            Save and Cancel button
        ]]

        local save_button = vgui.Create( "DButton", panel )
        save_button:SetText( "Save" )
        save_button:SetPos( 15, 200 )
        save_button:SetSize( 320, 30 )
        save_button.DoClick = function()
            local save_panel = vgui.Create( "DFrame" )
            save_panel:SetSize( 350, 100 )
            save_panel:SetTitle( "MBSync Edit Ban - Edit" )
            save_panel:Center()
            save_panel:MakePopup()

            local save_text = vgui.Create( "DLabel", save_panel )
            save_text:SetPos( 15, 20 )
            save_text:SetColor( Color( 255, 255, 255 ) )
            save_text:SetText( "This action will overwrite the ban with your edited data, are you sure you want to do that?" )
            save_text:SetSize(320, 50)
            save_text:SetWrap( true )

            local accept_button = vgui.Create( "DButton", save_panel )
            accept_button:SetText( "Accept" )
            accept_button:SetPos( 15, 70 )
            accept_button:SetSize( 160, 20 )
            accept_button.DoClick = function()
                panel:Close()
                save_panel:Close()
            end

            local deny_button = vgui.Create( "DButton", save_panel )
            deny_button:SetText( "Deny" )
            deny_button:SetPos( 175, 70 )
            deny_button:SetSize( 160, 20 )
            deny_button.DoClick = function()
                save_panel:Close()
            end
        end

        local cancel_button = vgui.Create( "DButton", panel )
        cancel_button:SetText( "Cancel" )
        cancel_button:SetPos( 15, 235 )
        cancel_button:SetSize( 320, 30 )
        cancel_button.DoClick = function()
            local cancel_panel = vgui.Create( "DFrame" )
            cancel_panel:SetSize( 350, 100 )
            cancel_panel:SetTitle( "MBSync Edit Ban - Cancel" )
            cancel_panel:Center()
            cancel_panel:MakePopup()

            local cancel_text = vgui.Create( "DLabel", cancel_panel )
            cancel_text:SetPos( 15, 20 )
            cancel_text:SetColor( Color( 255, 255, 255 ) )
            cancel_text:SetText( "When you cancel the edit, your progress will be lost. Are you sure you want to do that?" )
            cancel_text:SetSize(320, 50)
            cancel_text:SetWrap( true )

            local accept_button = vgui.Create( "DButton", cancel_panel )
            accept_button:SetText( "Accept" )
            accept_button:SetPos( 15, 70 )
            accept_button:SetSize( 160, 20 )
            accept_button.DoClick = function()
                panel:Close()
                cancel_panel:Close()
            end

            local deny_button = vgui.Create( "DButton", cancel_panel )
            deny_button:SetText( "Deny" )
            deny_button:SetPos( 175, 70 )
            deny_button:SetSize( 160, 20 )
            deny_button.DoClick = function()
                cancel_panel:Close()
            end
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
    --
end

--[[
    Define hooks your module is listening on e.g. PlayerDisconnect
]]
MSync.modules[info.ModuleIdentifier].hooks = function()
    hook.Add("initialize", "msync_sampleModule_init", function()
        --
    end)
end


MSync.modules[info.ModuleIdentifier].clientPanel()

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules[info.ModuleIdentifier].info