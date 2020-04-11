MSync = MSync or {}
MSync.modules = MSync.modules or {}
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
    Description = "Synchronise bans across your servers",
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

    MSync.modules[info.ModuleIdentifier].banTable = {}

    MSync.modules[info.ModuleIdentifier].getTablePage = function(tbl, maxResults, page)
        local tempTbl = {}
        local i = 0
        local startPos = 0 + (maxResults*page)
        local endPos = 19 + (maxResults*page)

        for k,v in pairs(tbl) do
            if i >= startPos and i <= endPos then
                tempTbl[k] = v
            end
            i = i + 1
        end

        return tempTbl
    end

    MSync.modules[info.ModuleIdentifier].displayTable = function(panel, tbl, maxResults, page)
        panel:Clear()
        print("displayTable")
        local table = MSync.modules[info.ModuleIdentifier].getTablePage(tbl, maxResults, page)
        PrintTable(table)
        local length = 0
        for k,v in pairs(table) do
            if v['length'] == 0 then
                length = "Permanent"
            else
                length = ULib.secondsToStringTime(v["length"])
            end
            panel:AddLine( v["banId"], v["nickname"], v["adminNickname"], os.date( "%H:%M:%S - %d/%m/%Y" , v["timestamp"]), length, v["reason"] )
        end
    end

    MSync.modules[info.ModuleIdentifier].getTablePages = function(tbl, resultsPerPage)
        return math.Round(#tbl / resultsPerPage)
    end

    MSync.modules[info.ModuleIdentifier].explodeTable = function(tbl, part)
        for k,v in pairs(part) do
            tbl[k] = v
        end
    end

    MSync.modules[info.ModuleIdentifier].banPanel = function( tbl )
        local panel = vgui.Create( "DFrame" )
        panel:SetSize( 350, 500 )
        panel:SetTitle( "MBSync - Ban User " )
        panel:Center()
        panel:MakePopup()
    
        local steamid_text = vgui.Create( "DLabel", panel )
        steamid_text:SetPos( 15, 35 )
        steamid_text:SetColor( Color( 255, 255, 255 ) )
        steamid_text:SetText( "SteamID/SteamID64:" )
        steamid_text:SetSize(380, 15)
    
        local steamid_textentry = vgui.Create( "DTextEntry", panel )
        steamid_textentry:SetPos( 125, 35 )
        steamid_textentry:SetSize( 210, 20 )
        steamid_textentry:SetPlaceholderText( "SteamID/SteamID64" )
        --steamid_textentry:SetUpdateOnType(true)
        --steamid_textentry.OnValueChange = function( pnl, value )
        --    if string.len(value) == 0 then
        --        ban_button:SetDisabled(true)
        --    else
        --        ban_button:SetDisabled(false)
        --    end
        --end
    
        local length_text = vgui.Create( "DLabel", panel )
        length_text:SetPos( 15, 60 )
        length_text:SetColor( Color( 255, 255, 255 ) )
        length_text:SetText( "Length" )
        length_text:SetSize(380, 15)
    
        local length_textentry = vgui.Create( "DTextEntry", panel )
        length_textentry:SetPos( 125, 60 )
        length_textentry:SetSize( 210, 20 )
        length_textentry:SetPlaceholderText( "Ban Length in Minutes, 0 = Permanent" )
    
        local allservers_text = vgui.Create( "DLabel", panel )
        allservers_text:SetPos( 15, 85 )
        allservers_text:SetColor( Color( 255, 255, 255 ) )
        allservers_text:SetText( "Banned everywhere:" )
        allservers_text:SetSize(380, 15)
    
        local allservers_dropdown = vgui.Create( "DComboBox", panel )
        allservers_dropdown:SetPos( 125, 85 )
        allservers_dropdown:SetSize( 210, 20 )
        allservers_dropdown:SetValue( "True" )
        allservers_dropdown:AddChoice( "True" )
        allservers_dropdown:AddChoice( "False" )
        allservers_dropdown:SetSortItems( false )
        allservers_dropdown.OnSelect = function( self, index, value )
            --
        end
    
        local reason_text = vgui.Create( "DLabel", panel )
        reason_text:SetPos( 15, 110 )
        reason_text:SetColor( Color( 255, 255, 255 ) )
        reason_text:SetText( "Reason" )
        reason_text:SetSize(380, 15)
    
        local reasonMaxLen_text = vgui.Create( "DLabel", panel )
        reasonMaxLen_text:SetPos( 280, 185 )
        reasonMaxLen_text:SetColor( Color( 255, 255, 255 ) )
        reasonMaxLen_text:SetText( "0/100" )
        reasonMaxLen_text:SetSize(50, 15)
        reasonMaxLen_text:SetContentAlignment( 9 )
    
        local reason_textentry = vgui.Create( "DTextEntry", panel )
        reason_textentry:SetPos( 15, 125 )
        reason_textentry:SetSize( 320, 60 )
        reason_textentry:SetPlaceholderText( "Leave empty for 'No Reason given'" )
        reason_textentry:SetMultiline(true)
        reason_textentry:SetUpdateOnType(true)
        reason_textentry.OnValueChange = function( pnl, value )
            print(value)
            reasonMaxLen_text:SetText(string.len( value ).."/100")
    
            if string.len( value ) > 100 then
                reasonMaxLen_text:SetColor( Color( 255, 120, 120 ) )
            else
                reasonMaxLen_text:SetColor( Color( 255, 255, 255 ) )
            end
        end
    
        --local bantype_dropdown = vgui.Create( "DComboBox", panel )
        --bantype_dropdown:SetPos( 125, 35 )
        --bantype_dropdown:SetSize( 210, 20 )
        --bantype_dropdown:SetValue( "Recently Disconnected" )
        --bantype_dropdown:AddChoice( "Recently Disconnected" )
        --bantype_dropdown:AddChoice( "SteamID" )
        --bantype_dropdown:SetSortItems( false )
        --bantype_dropdown.OnSelect = function( self, index, value )
            --
        --end
    
        local reasonMaxLen_text = vgui.Create( "DLabel", panel )
        reasonMaxLen_text:SetPos( 15, 205 )
        reasonMaxLen_text:SetColor( Color( 255, 255, 255 ) )
        reasonMaxLen_text:SetText( "Recently Disconnected Players" )
        reasonMaxLen_text:SetSize(380, 15)
    
        local ban_table = vgui.Create( "DListView", panel )
        ban_table:SetPos( 15, 220 )
        ban_table:SetSize( 320, 200 )
        ban_table:SetMultiSelect( false )
        ban_table:AddColumn( "Nickname" )
        ban_table:AddColumn( "SteamID" )
        ban_table:AddColumn( "SteamID64" )
        ban_table.OnRowSelected = function( lst, index, pnl )
            steamid_textentry:SetText(pnl:GetColumnText( 2 ))
        end
    
        if tbl then
            for k,v in pairs(tbl) do
                ban_table:AddLine( v.name, v.steamid, v.steamid64 )
            end
        end

        local ban_button = vgui.Create( "DButton", panel )
        ban_button:SetText( "Ban User" )
        ban_button:SetPos( 15, 425 )
        ban_button:SetSize( 320, 30 )
        ban_button:SetDisabled(true)
        ban_button.DoClick = function()
            local banConfirm_panel = vgui.Create( "DFrame" )
            banConfirm_panel:SetSize( 350, 100 )
            banConfirm_panel:SetTitle( "MBSync Ban - Confirm" )
            banConfirm_panel:Center()
            banConfirm_panel:MakePopup()

            local save_text = vgui.Create( "DLabel", banConfirm_panel )
            save_text:SetPos( 15, 20 )
            save_text:SetColor( Color( 255, 255, 255 ) )
            save_text:SetText( "This action will ban the user with the given data, are you sure you want to do that?" )
            save_text:SetSize(320, 50)
            save_text:SetWrap( true )

            local accept_button = vgui.Create( "DButton", banConfirm_panel )
            accept_button:SetText( "Accept" )
            accept_button:SetPos( 15, 70 )
            accept_button:SetSize( 160, 20 )
            accept_button.DoClick = function()
                -- Ban user and close panel
                panel:Close()
                banConfirm_panel:Close()
            end

            local deny_button = vgui.Create( "DButton", banConfirm_panel )
            deny_button:SetText( "Deny" )
            deny_button:SetPos( 175, 70 )
            deny_button:SetSize( 160, 20 )
            deny_button.DoClick = function()
                banConfirm_panel:Close()
            end
        end

        local cancel_button = vgui.Create( "DButton", panel )
        cancel_button:SetText( "Cancel" )
        cancel_button:SetPos( 15, 460 )
        cancel_button:SetSize( 320, 30 )
        cancel_button.DoClick = function()
            local cancel_panel = vgui.Create( "DFrame" )
            cancel_panel:SetSize( 350, 100 )
            cancel_panel:SetTitle( "MBSync Ban - Confirm" )
            cancel_panel:Center()
            cancel_panel:MakePopup()

            local save_text = vgui.Create( "DLabel", cancel_panel )
            save_text:SetPos( 15, 20 )
            save_text:SetColor( Color( 255, 255, 255 ) )
            save_text:SetText( "This action will cancel the ban, are you sure you want to do that?" )
            save_text:SetSize(320, 50)
            save_text:SetWrap( true )

            local accept_button = vgui.Create( "DButton", cancel_panel )
            accept_button:SetText( "Accept" )
            accept_button:SetPos( 15, 70 )
            accept_button:SetSize( 160, 20 )
            accept_button.DoClick = function()
                -- do nothing and close panel
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
    
        ban_table:AddLine( "[ApDev] Rainbow Dash", "STEAM_0:0:0", "76000000000" )
    end

end

--[[
    Define the admin panel for the settings
]]
MSync.modules[info.ModuleIdentifier].adminPanel = function(sheet)
    local pnl = vgui.Create( "DPanel", sheet )
    pnl:Dock(FILL)

    local delay_text = vgui.Create( "DLabel", pnl )
    delay_text:SetPos( 10, 5 )
    delay_text:SetColor( Color( 0, 0, 0 ) )
    delay_text:SetText( "Set the delay when MBSync should re-synchronize the bans." )
    delay_text:SetSize(380, 15)

    local delay_textentry = vgui.Create( "DTextEntry", pnl )
    delay_textentry:SetPos( 10, 20 )
    delay_textentry:SetSize( 220, 20 )
    delay_textentry:SetPlaceholderText( "Timer Delay in seconds ( example: 300 )" )

    local save_button = vgui.Create( "DButton", pnl )
    save_button:SetText( "Save" )
    save_button:SetPos( 230, 20 )
    save_button:SetSize( 100, 20 )
    save_button.DoClick = function()
        if save_button:GetValue() and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    local bantable_text = vgui.Create( "DLabel", pnl )
    bantable_text:SetPos( 10, 50 )
    bantable_text:SetColor( Color( 0, 0, 0 ) )
    bantable_text:SetText( "Ban table with ALL bans" )
    bantable_text:SetSize(380, 15)

    local search_textentry = vgui.Create( "DTextEntry", pnl )
    search_textentry:SetPos( 10, 65 )
    search_textentry:SetSize( 170, 20 )
    search_textentry:SetPlaceholderText( "Nickname/SteamID/SID64/Admin" )

    local search_button = vgui.Create( "DButton", pnl )
    search_button:SetText( "Search" )
    search_button:SetPos( 180, 65 )
    search_button:SetSize( 60, 20 )
    search_button.DoClick = function()
        if search_button:GetValue() and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    --[[
    local sort_button = vgui.Create( "DButton", pnl )
    sort_button:SetText( "Sort by: [INSERT]" )
    sort_button:SetPos( 240, 65 )
    sort_button:SetSize( 120, 20 )
    sort_button.DoClick = function()
        if search_button:GetValue() and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end
    ]]

    local reload_button = vgui.Create( "DButton", pnl )
    reload_button:SetText( "Reload" )
    reload_button:SetPos( 380, 65 )
    reload_button:SetSize( 65, 20 )
    reload_button.DoClick = function()
        if reload_button:GetValue() and not MSync.modules.MRSync.settings.nosync[allserver_textentry:GetValue()] and not MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] then
            allserver_table:AddLine(allserver_textentry:GetValue())
            MSync.modules.MRSync.settings.syncall[allserver_textentry:GetValue()] = true
            allserver_textentry:SetText("")
            MSync.modules.MRSync.sendSettings()
        end
    end

    local ban_table = vgui.Create( "DListView", pnl )
    ban_table:SetPos( 10, 85 )
    ban_table:SetSize( 435, 240 )
    ban_table:SetMultiSelect( false )
    ban_table:AddColumn( "Ban ID" ):SetFixedWidth( 40 )
    ban_table:AddColumn( "SteamID" )
    ban_table:AddColumn( "Admin" )
    ban_table:AddColumn( "Ban Length" )
    ban_table:AddColumn( "Ban Reason" )
    ban_table:AddColumn( "Unbanned" )
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
                MSync.modules[info.ModuleIdentifier].editBanPanel(line:GetColumnText( 1 ))
            elseif optStr == "Advanced Info" then
                MSync.modules[info.ModuleIdentifier].advancedInfoPanel(line:GetColumnText( 1 ))
            end
        end
    end

    --ban_table:AddLine( "1", "[ApDev] Rainbow Dash", "X-Coder", "Permanent", "Fucking Around", "" )
    --ban_table:AddLine( "2", "X-Coder", "Altesismein", "3d", "Bugs", "[ApDev] Rainbow Dash" )
    --ban_table:AddLine( "3", "Altesismein", "[ApDev] Rainbow Dash", "20d", "Test", "X-Coder" )

    --[[
        Define sortby variable for sorting the ban table
    ]]

    local sortby = {
        Column = 1,
        Descending = true
    }
    ban_table:SortByColumn( sortby.Column, sortby.Descending )

    local sortby_dropdown = vgui.Create( "DComboBox", pnl )
    sortby_dropdown:SetPos( 240, 65 )
    sortby_dropdown:SetSize( 140, 20 )
    sortby_dropdown:SetValue( "Sort by: Ban ID/Desc" )
    sortby_dropdown:AddChoice( "Ban ID" )
    sortby_dropdown:AddChoice( "SteamID" )
    sortby_dropdown:AddChoice( "Admin" )
    sortby_dropdown:AddChoice( "Ban Length" )
    sortby_dropdown:AddChoice( "Ban Reason" )
    sortby_dropdown:AddChoice( "Unbanned" )
    sortby_dropdown:SetSortItems( false )
    sortby_dropdown.OnSelect = function( self, index, value )
        --ban_table
        if value == "Ban ID" then
            sortby.Column = 1
            if sortby.Descending then
                sortby.Descending = false
                sortby_dropdown:SetValue( "Sort by: Ban ID/Asc" )
            else
                sortby.Descending = true
                sortby_dropdown:SetValue( "Sort by: Ban ID/Desc" )
            end
        elseif value == "SteamID" then
            sortby.Column = 2
            if sortby.Descending then
                sortby.Descending = false
                sortby_dropdown:SetValue( "Sort by: SID/ASC" )
            else
                sortby.Descending = true
                sortby_dropdown:SetValue( "Sort by: SID/Desc" )
            end
        elseif value == "Admin" then
            sortby.Column = 3
            if sortby.Descending then
                sortby.Descending = false
                sortby_dropdown:SetValue( "Sort by: Admin/Asc" )
            else
                sortby.Descending = true
                sortby_dropdown:SetValue( "Sort by: Admin/Desc" )
            end
        elseif value == "Ban Length" then
            sortby.Column = 4
            if sortby.Descending then
                sortby.Descending = false
                sortby_dropdown:SetValue( "Sort by: Length/Asc" )
            else
                sortby.Descending = true
                sortby_dropdown:SetValue( "Sort by: Length/Desc" )
            end
        elseif value == "Ban Reason" then
            sortby.Column = 5
            if sortby.Descending then
                sortby.Descending = false
                sortby_dropdown:SetValue( "Sort by: Reason/Asc" )
            else
                sortby.Descending = true
                sortby_dropdown:SetValue( "Sort by: Reason/Desc" )
            end
        elseif value == "Unbanned" then
            sortby.Column = 6
            if sortby.Descending then
                sortby.Descending = false
                sortby_dropdown:SetValue( "Sort by: Unbanned/Asc" )
            else
                sortby.Descending = true
                sortby_dropdown:SetValue( "Sort by: Unbanned/Desc" )
            end
        end

        if value then
            ban_table:SortByColumn( sortby.Column, sortby.Descending )
        end
    end

    return pnl
end

--[[
    Define the client panel for client usage ( or as example: use it as additional admin gui which does not need msync.admingui permission)
]]
MSync.modules[info.ModuleIdentifier].clientPanel = function()

    --[[
        Fake Data generator for testing purposes
    ]]
    local function fakeData() 
        local data = {}
        for i=0,111,1 do
            --ban_table:AddLine( "1", "[ApDev] Rainbow Dash", "X-Coder", "Permanent", "Fucking Around" )
            data[#data+1] = {
                id = i+30,
                nickname = "Fake Data "..i,
                admin = "Fake Admin"..i+200,
                length = i.."d",
                reason = "Fake Reason"..i+400
            }
        end

        return data;
    end

    local tempTable = MSync.modules[info.ModuleIdentifier].banTable
    local pages = MSync.modules[info.ModuleIdentifier].getTablePages(tempTable, 20)
    local tablePage = 0

    local panel = vgui.Create( "DFrame" )
    panel:SetSize( 800, 450 )
    panel:SetTitle( "MSync Admin Menu" )
    panel:Center()
    panel:MakePopup()

    local search_textentry = vgui.Create( "DTextEntry", panel )
    search_textentry:SetPos( 15, 35 )
    search_textentry:SetSize( 250, 20 )
    search_textentry:SetPlaceholderText( "Nickname/SteamID/SID64/Admin" )

    local ban_table = vgui.Create( "DListView", panel )
    ban_table:SetPos( 15, 60 )
    ban_table:SetSize( 770, 360 )
    ban_table:SetMultiSelect( false )
    ban_table:AddColumn( "Ban ID" ):SetFixedWidth( 50 )
    ban_table:AddColumn( "Nickname" ):SetFixedWidth( 120 )
    ban_table:AddColumn( "Admin" ):SetFixedWidth( 120 )
    ban_table:AddColumn( "Ban Date" ):SetFixedWidth( 120 )
    ban_table:AddColumn( "Ban Length" ):SetFixedWidth( 120 )
    ban_table:AddColumn( "Ban Reason" )

    local search_button = vgui.Create( "DButton", panel )
    search_button:SetText( "Search" )
    search_button:SetPos( 270, 35 )
    search_button:SetSize( 130, 20 )

    local sortby_dropdown = vgui.Create( "DComboBox", panel )
    sortby_dropdown:SetPos( 405, 35 )
    sortby_dropdown:SetSize( 130, 20 )
    sortby_dropdown:SetValue( "Sort by: Ban ID" )
    sortby_dropdown:AddChoice( "Ban ID" )
    sortby_dropdown:AddChoice( "Nickname" )
    sortby_dropdown:AddChoice( "Admin" )
    sortby_dropdown:AddChoice( "Ban Length" )
    sortby_dropdown:AddChoice( "Ban Reason" )
    sortby_dropdown:SetSortItems( false )

    local listascdesc_button = vgui.Create( "DButton", panel )
    listascdesc_button:SetText( "List: Desc" )
    listascdesc_button:SetPos( 540, 35 )
    listascdesc_button:SetSize( 110, 20 )

    local sync_button = vgui.Create( "DButton", panel )
    sync_button:SetText( "Reload Bans" )
    sync_button:SetPos( 655, 35 )
    sync_button:SetSize( 130, 20 )

    local firstpage_button = vgui.Create( "DButton", panel )
    firstpage_button:SetText( "<< First" )
    firstpage_button:SetPos( 15, 421 )
    firstpage_button:SetSize( 185, 20 )
    firstpage_button:SetDisabled(true)

    local previouspage_button = vgui.Create( "DButton", panel )
    previouspage_button:SetText( "< Previous" )
    previouspage_button:SetPos( 200, 421 )
    previouspage_button:SetSize( 185, 20 )
    previouspage_button:SetDisabled(true)

    local pageof_text = vgui.Create( "DLabel", panel )
    pageof_text:SetPos( 385, 421 )
    pageof_text:SetColor( Color( 255, 255, 255 ) )
    pageof_text:SetText( "1/"..pages )
    pageof_text:SetSize(30, 20)
    pageof_text:SetContentAlignment( 5 )

    local nextpage_button = vgui.Create( "DButton", panel )
    nextpage_button:SetText( "Next >" )
    nextpage_button:SetPos( 415, 421 )
    nextpage_button:SetSize( 185, 20 )
    nextpage_button:SetDisabled(true)

    local lastpage_button = vgui.Create( "DButton", panel )
    lastpage_button:SetText( "Last >>" )
    lastpage_button:SetPos( 600, 421 )
    lastpage_button:SetSize( 185, 20 )
    lastpage_button:SetDisabled(true)

    MSync.modules[info.ModuleIdentifier].advancedInfoPanel = function(tbl)

        local panel = vgui.Create( "DFrame" )
        panel:SetSize( 350, 455 )
        panel:SetTitle( "MBSync Advanced Ban Info" )
        panel:Center()
        panel:MakePopup()

        --[[
            {
                banNick = "Nickname",
                banSteamID = "SteamID"
                banSTeamID64 = "SteamID64"
                adminNick = "Nickname"
                adminSteamID = "SteamID"
                adminSteamID64 = "SteamID64"
                banDate = "Date"
                banLength = "length"
                unbanDate = "Date"
                banRemaining = "Time"
                banServerGroup = "Servergroup"
                banReason = "Reason"
            }
        ]]

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
        --nickname_textentry:SetText( "[ApDev] Rainbow Dash" )
        nickname_textentry:SetDisabled(true)

        local steamid_text = vgui.Create( "DLabel", panel )
        steamid_text:SetPos( 15, 60 )
        steamid_text:SetColor( Color( 255, 255, 255 ) )
        steamid_text:SetText( "SteamID:" )
        steamid_text:SetSize(380, 15)

        local steamid_textentry = vgui.Create( "DTextEntry", panel )
        steamid_textentry:SetPos( 125, 60 )
        steamid_textentry:SetSize( 210, 20 )
        --steamid_textentry:SetText( "STEAM_0:0:0" )
        steamid_textentry:SetDisabled(true)

        local steamid64_text = vgui.Create( "DLabel", panel )
        steamid64_text:SetPos( 15, 85 )
        steamid64_text:SetColor( Color( 255, 255, 255 ) )
        steamid64_text:SetText( "SteamID64:" )
        steamid64_text:SetSize(380, 15)

        local steamid64_textentry = vgui.Create( "DTextEntry", panel )
        steamid64_textentry:SetPos( 125, 85 )
        steamid64_textentry:SetSize( 210, 20 )
        --steamid64_textentry:SetText( "7600000000" )
        steamid64_textentry:SetDisabled(true)

        --local adminheader_text = vgui.Create( "DLabel", panel )
        --adminheader_text:SetPos( 15, 110 )
        --adminheader_text:SetColor( Color( 255, 255, 255 ) )
        --adminheader_text:SetText( "Admin" )
        --adminheader_text:SetSize(320, 15)
        --adminheader_text:SetContentAlignment( 5 )

        --[[ (i*30)+1
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
        --adminnickname_textentry:SetText( "[ApDev] Rainbow Dash" )
        adminnickname_textentry:SetDisabled(true)

        --[[
            Info about the ban
        ]]

        local bandate_text = vgui.Create( "DLabel", panel )
        bandate_text:SetPos( 15, 155 )
        bandate_text:SetColor( Color( 255, 255, 255 ) )
        bandate_text:SetText( "Ban Date:" )
        bandate_text:SetSize(380, 15)

        local bandate_textentry = vgui.Create( "DTextEntry", panel )
        bandate_textentry:SetPos( 125, 155 )
        bandate_textentry:SetSize( 210, 20 )
        --bandate_textentry:SetText( "24.09.2019 23:11" )
        bandate_textentry:SetDisabled(true)

        local banlength_text = vgui.Create( "DLabel", panel )
        banlength_text:SetPos( 15, 180 )
        banlength_text:SetColor( Color( 255, 255, 255 ) )
        banlength_text:SetText( "Ban Length:" )
        banlength_text:SetSize(380, 15)

        local banlength_textentry = vgui.Create( "DTextEntry", panel )
        banlength_textentry:SetPos( 125, 180 )
        banlength_textentry:SetSize( 210, 20 )
        --banlength_textentry:SetText( "Permanent" )
        banlength_textentry:SetDisabled(true)

        local unbandate_text = vgui.Create( "DLabel", panel )
        unbandate_text:SetPos( 15, 205 )
        unbandate_text:SetColor( Color( 255, 255, 255 ) )
        unbandate_text:SetText( "Unban Date:" )
        unbandate_text:SetSize(380, 15)

        local unbandate_textentry = vgui.Create( "DTextEntry", panel )
        unbandate_textentry:SetPos( 125, 205 )
        unbandate_textentry:SetSize( 210, 20 )
        --unbandate_textentry:SetText( "24.09.2019 23:11" )
        unbandate_textentry:SetDisabled(true)

        local remainingtime_text = vgui.Create( "DLabel", panel )
        remainingtime_text:SetPos( 15, 230 )
        remainingtime_text:SetColor( Color( 255, 255, 255 ) )
        remainingtime_text:SetText( "Time Remaining:" )
        remainingtime_text:SetSize(380, 15)

        local remainingtime_textentry = vgui.Create( "DTextEntry", panel )
        remainingtime_textentry:SetPos( 125, 230 )
        remainingtime_textentry:SetSize( 210, 20 )
        --remainingtime_textentry:SetText( "1d,13h" )
        remainingtime_textentry:SetDisabled(true)

        local bangroup_text = vgui.Create( "DLabel", panel )
        bangroup_text:SetPos( 15, 255 )
        bangroup_text:SetColor( Color( 255, 255, 255 ) )
        bangroup_text:SetText( "Ban Server Group:" )
        bangroup_text:SetSize(380, 15)

        local bangroup_textentry = vgui.Create( "DTextEntry", panel )
        bangroup_textentry:SetPos( 125, 255 )
        bangroup_textentry:SetSize( 210, 20 )
        --bangroup_textentry:SetText( "allservers" )
        bangroup_textentry:SetDisabled(true)

        local banreason_text = vgui.Create( "DLabel", panel )
        banreason_text:SetPos( 15, 300 )
        banreason_text:SetColor( Color( 255, 255, 255 ) )
        banreason_text:SetText( "Ban Reason:" )
        banreason_text:SetSize(380, 15)
        banreason_text:SetDark(1)

        local banreason_panel = vgui.Create( "DPanel", panel )
        banreason_panel:SetPos( 15, 320 )
        banreason_panel:SetSize( 320, 80 )

        local banreasonreason_text = vgui.Create( "DLabel", banreason_panel )
        banreasonreason_text:SetPos( 5, 5 )
        banreasonreason_text:SetColor( Color( 0, 0, 0 ) )
        banreasonreason_text:SetText( "" )
        banreasonreason_text:SetSize(310, 100)
        banreasonreason_text:SetWrap( true )
        banreasonreason_text:SetContentAlignment( 7 )

        local close_button = vgui.Create( "DButton", panel )
        close_button:SetText( "Close" )
        close_button:SetPos( 15, 410 )
        close_button:SetSize( 320, 30 )
        close_button.DoClick = function()
            panel:Close()
        end

        --[[
            ############
            FILL DATA
            ############
        ]]

        if not (tbl == nil) then
            nickname_textentry:SetText( tbl["nickname"] )
            steamid_textentry:SetText( tbl["steamid"] )
            steamid64_textentry:SetText( tbl["steamid64"] )
            adminnickname_textentry:SetText( tbl["adminNickname"] )
            bandate_textentry:SetText( os.date( "%H:%M:%S - %d/%m/%Y" ,tbl["timestamp"]) )
            banlength_textentry:SetText( ULib.secondsToStringTime(tbl["length"]) )
            unbandate_textentry:SetText( os.date( "%H:%M:%S - %d/%m/%Y" ,tbl["timestamp"] + tbl["length"]) )
            remainingtime_textentry:SetText( ULib.secondsToStringTime((tbl["timestamp"] + tbl["length"])-os.time()) )
            bangroup_textentry:SetText( '--NOT IMPLEMENTED YET--' )
            banreasonreason_text:SetText( tbl["reason"] )
        end

    end

    MSync.modules[info.ModuleIdentifier].editBanPanel = function(tbl)
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
        --nickname_textentry:SetText( "[ApDev] Rainbow Dash" )
        nickname_textentry:SetDisabled(true)

        local steamid_text = vgui.Create( "DLabel", panel )
        steamid_text:SetPos( 15, 60 )
        steamid_text:SetColor( Color( 255, 255, 255 ) )
        steamid_text:SetText( "SteamID:" )
        steamid_text:SetSize(380, 15)

        local steamid_textentry = vgui.Create( "DTextEntry", panel )
        steamid_textentry:SetPos( 125, 60 )
        steamid_textentry:SetSize( 210, 20 )
        --steamid_textentry:SetText( "STEAM_0:0:0" )
        steamid_textentry:SetDisabled(true)

        local steamid64_text = vgui.Create( "DLabel", panel )
        steamid64_text:SetPos( 15, 85 )
        steamid64_text:SetColor( Color( 255, 255, 255 ) )
        --steamid64_text:SetText( "SteamID64:" )
        steamid64_text:SetSize(380, 15)

        local steamid64_textentry = vgui.Create( "DTextEntry", panel )
        steamid64_textentry:SetPos( 125, 85 )
        steamid64_textentry:SetSize( 210, 20 )
        --steamid64_textentry:SetText( "7600000000" )
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
        --banlength_textentry:SetText( "Permanent" )
        banlength_textentry:SetDisabled(false)

        local banallservers_text = vgui.Create( "DLabel", panel )
        banallservers_text:SetPos( 15, 145 )
        banallservers_text:SetColor( Color( 255, 255, 255 ) )
        banallservers_text:SetText( "Banned everywhere:" )
        banallservers_text:SetSize(380, 15)

        local banallservers_textentry = vgui.Create( "DComboBox", panel )
        banallservers_textentry:SetPos( 125, 145 )
        banallservers_textentry:SetSize( 210, 20 )
        --banallservers_textentry:SetValue( "true" )
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
        --banreason_textentry:SetText( "Permanent" )
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
                print( "msync.MBSync.editBan", tbl["banId"], banlength_textentry:GetValue(), banallservers_textentry:GetValue(), banreason_textentry:GetValue())
                panel:Close()
                save_panel:Close()
            end

            local deny_button = vgui.Create( "DButton", save_panel )
            deny_button:SetText( "Deny" )
            deny_button:SetPos( 175, 70 )
            deny_button:SetSize( 160, 20 )
            deny_button.DoClick = function()
                -- CLOSE ACCEPT PANEL
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

        --[[
            ###########
            FILL DATA
            ###########
        ]]

        if not (tbl == nil) then
            nickname_textentry:SetText( tbl["nickname"] )
            steamid_textentry:SetText( tbl["steamid"] )
            steamid64_textentry:SetText( tbl["steamid64"] )
            banlength_textentry:SetText( tbl["length"] )
            banallservers_textentry:SetValue( "--NOT IMPLEMENTED--" )
            banreason_textentry:SetText( tbl["reason"] )
        end
    end


    --[[
        TODO: 
        - Get Data from server on opening the panel
        - Display data on table
            - Each page has a 20 lines limit
            - selecting the next page should be possible
        - Function to select entry based on their BanID
        - Function to search the data
        - Function to Sort data beforehand
        - 
    ]]
    --[[
        #############
        FUNCTION PART
        #############
    ]]
    --[[
        Define sortby variable for sorting the ban table
    ]]
    local sortby = {
        Column = "banid",
        Descending = false
    }

    local function checkPage()
        if ( (tablePage+1) >= pages ) then
            lastpage_button:SetDisabled(true)
            nextpage_button:SetDisabled(true)
        else
            lastpage_button:SetDisabled(false)
            nextpage_button:SetDisabled(false)
        end

        if(tablePage>=1)then
            firstpage_button:SetDisabled(false)
            previouspage_button:SetDisabled(false)
        else
            firstpage_button:SetDisabled(true)
            previouspage_button:SetDisabled(true)
        end
    end

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
                MSync.modules[info.ModuleIdentifier].unban(line:GetColumnText( 1 ))
            elseif optStr == "Edit" then
                MSync.modules[info.ModuleIdentifier].editBanPanel(tempTable[line:GetColumnText( 1 )])
            elseif optStr == "Advanced Info" then
                MSync.modules[info.ModuleIdentifier].advancedInfoPanel(tempTable[line:GetColumnText( 1 )])
            end
        end
    end

    sortby_dropdown.OnSelect = function( self, index, value )
        --ban_table
        if value == "Ban ID" then
            sortby.Column = 1
            sortby_dropdown:SetValue( "Sort by: Ban ID" )
        elseif value == "Nickname" then
            sortby.Column = 2
            sortby_dropdown:SetValue( "Sort by: Nickname" )
        elseif value == "Admin" then
            sortby.Column = 3
            sortby_dropdown:SetValue( "Sort by: Admin" )
        elseif value == "Ban Date" then
            sortby.Column = 4
            sortby_dropdown:SetValue( "Sort by: Ban Length" )
        elseif value == "Ban Length" then
            sortby.Column = 4
            sortby_dropdown:SetValue( "Sort by: Ban Length" )
        elseif value == "Ban Reason" then
            sortby.Column = 5
            sortby_dropdown:SetValue( "Sort by: Ban Reason" )
        end

        if value then
            tempTable = table.SortByMember( MSync.modules[info.ModuleIdentifier].banTable, sortby.Column, sortby.Descending )
            MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, 0)
            checkPage()
        end
    end

    listascdesc_button.DoClick = function()
        if sortby.Descending then
            sortby.Descending = false
            listascdesc_button:SetText( "List: Asc" )
        else
            sortby.Descending = true
            listascdesc_button:SetText( "List: Desc" )
        end
        tempTable = table.SortByMember( MSync.modules[info.ModuleIdentifier].banTable, sortby.Column, sortby.Descending )
        MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, 0)
        checkPage()
    end

    search_button.DoClick = function()
        if search_textentry:GetValue() then
            -- ASK SERVER FOR MATCHING DATA
        end
        --MSync.modules[info.ModuleIdentifier].findMatchingData(tbl, term)
    end

    sync_button.DoClick = function()
        -- DISABLE PANEL AND RE-ENABLE WHEN DATA RETURNED
    end

    firstpage_button.DoClick = function()
        tablePage = 0
        pageof_text:SetText( (tablePage+1).."/"..pages )
        MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, tablePage)
        checkPage()
    end

    previouspage_button.DoClick = function()
        tablePage = tablePage - 1
        pageof_text:SetText( (tablePage+1).."/"..pages )
        MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, tablePage)
        checkPage()
    end

    nextpage_button.DoClick = function()
        tablePage = tablePage + 1
        pageof_text:SetText( (tablePage+1).."/"..pages )
        MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, tablePage)
        checkPage()
    end

    lastpage_button.DoClick = function()
        tablePage = pages-1
        pageof_text:SetText( (tablePage+1).."/"..pages )
        MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, tablePage)
        checkPage()
    end

    if pages > 1 then
        nextpage_button:SetDisabled(false)
        lastpage_button:SetDisabled(false)
    end

    MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, tablePage)


    return panel
end

--[[
    Define net receivers and util.AddNetworkString
]]
MSync.modules[info.ModuleIdentifier].net = function()
    --[[
        So basically we run into a problem as data packages have a size limit of 64KB, so if the ban table is big enough we cant send it over net.WriteTable.
        The solution? We send it in single chunks.
        We first need to request the table, that should return how much entries we have and then send us each data and at the end a "finished"
        So first we need a net sender to request the data, then we need a reciever to recieve the package count, then one to recieve the actuall packages and last but not least one to finish the process.
        Should not be that hard, eh? 

        Notice: 
        For future usage we may should make that a MSync function and not a MBSync function
    ]]

    --[[
        Description: Function to unban a user using the banid
        Arguments:
            userid [number] - the ban id of the to be lifted ban
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].unban = function(userid)
        if not type(userid) == "number" then
            userid = tonumber(userid)
        end

        net.Start("msync."..(info.ModuleIdentifier)..".unban")
            net.WriteInt(userid)
        net.SendToServer()
    end
    --[[
        Description: Net Receiver - Gets called when the server wants to print something to the user chat
        Returns: nothing
    ]]
    net.Receive( "msync."..(info.ModuleIdentifier)..".sendMessage", function( len, ply )
        chat.AddText( Color( 237, 135, 26 ), "[MBSync] ", Color( 255, 255, 255), net.ReadString())
    end )

    --[[
        Description: Net Receiver - Gets called when the client entered '!mban'
        Returns: nothing
    ]]
    net.Receive( "msync."..(info.ModuleIdentifier)..".openBanGUI", function( len, ply )
        MSync.modules[info.ModuleIdentifier].banPanel(net.ReadTable())
    end )

    --[[
        Description: Function to unban a user using the banid
        Arguments:
            userid [number] - the ban id of the to be lifted ban
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].getBanTable = function()
        MSync.modules[info.ModuleIdentifier].temporary = {}

        net.Start("msync."..(info.ModuleIdentifier)..".getBanTable")
        net.SendToServer()
    end

    --[[
        Description: Net Receiver - Gets called when the client entered '!mban'
        Returns: nothing
    ]]
    net.Receive( "msync."..(info.ModuleIdentifier)..".recieveDataCount", function( len, ply )
        local num = net.ReadFloat()
        if not MSync.modules[info.ModuleIdentifier].temporary["unfinished"] then
            MSync.modules[info.ModuleIdentifier].temporary["count"] = num
            MSync.modules[info.ModuleIdentifier].temporary["recieved"] = 0
            MSync.modules[info.ModuleIdentifier].temporary["unfinished"] = true
            MSync.modules[info.ModuleIdentifier].banTable = {}
        end
    end )

    --[[
        Description: Net Receiver - Gets called when the client entered '!mban'
        Returns: nothing
    ]]
    net.Receive( "msync."..(info.ModuleIdentifier)..".recieveData", function( len, ply )
        MSync.modules[info.ModuleIdentifier].explodeTable(MSync.modules[info.ModuleIdentifier].banTable, net.ReadTable())
        MSync.modules[info.ModuleIdentifier].temporary["recieved"] = MSync.modules[info.ModuleIdentifier].temporary["recieved"] + 1

        if MSync.modules[info.ModuleIdentifier].temporary["recieved"] == MSync.modules[info.ModuleIdentifier].temporary["count"] then
            MSync.modules[info.ModuleIdentifier].temporary = {}
            local tempTable = {}
            for k,v in pairs(MSync.modules[info.ModuleIdentifier].banTable) do
                tempTable[v['banId']]                   = {}
                tempTable[v['banId']]['banId']          = v['banId']
                tempTable[v['banId']]['adminNickname']  = v['adminNickname']
                tempTable[v['banId']]['nickname']       = v['banned']['nickname']
                tempTable[v['banId']]['steamid']        = v['banned']['steamid']
                tempTable[v['banId']]['steamid64']      = k
                tempTable[v['banId']]['length']         = v['length']
                tempTable[v['banId']]['reason']         = v['reason']
                tempTable[v['banId']]['timestamp']      = v['timestamp']
            end
            MSync.modules[info.ModuleIdentifier].banTable = tempTable
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
    --
end


--MSync.modules[info.ModuleIdentifier].clientPanel()
--MSync.AdminPanel.InitPanel()

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules[info.ModuleIdentifier].info