MSync = MSync or {}
MSync.modules = MSync.modules or {}
--[[
 * @file       cl_mbsync.lua
 * @package    MySQL Ban Sync
 * @author     Aperture Development
 * @license    root_dir/LICENCE
 * @version    1.4.0
]]

--[[
    Define name, description and module identifier
]]
local info = {
    Name = "MySQL Ban Sync",
    ModuleIdentifier = "MBSync",
    Description = "Synchronise bans across your servers",
    Version = "1.4.0"
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
    MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Initializing");

    MSync.modules[info.ModuleIdentifier].banTable = {}

    MSync.modules[info.ModuleIdentifier].getTablePage = function(tbl, maxResults, page)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.getTablePage Param.: $tbl $maxResults $page",{["tbl"] = tbl,["maxResults"] = maxResults,["page"] = page}));
        local tempTbl = {}
        local i = 0
        local startPos = 0 + (maxResults * page)
        local endPos = 19 + (maxResults * page)

        for k,v in pairs(tbl) do
            if i >= startPos and i <= endPos then
                tempTbl[k] = v
            end
            i = i + 1
        end

        return tempTbl
    end

    MSync.modules[info.ModuleIdentifier].displayTable = function(panel, tbl, maxResults, page)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.displayTable Param.: $panel $tbl $maxResults $page",{["panel"] = panel,["tbl"] = tbl,["maxResults"] = maxResults,["page"] = page}));
        panel:Clear()
        local table = MSync.modules[info.ModuleIdentifier].getTablePage(tbl, maxResults, page)
        local length = 0
        for k,v in pairs(table) do
            if v["length"] == 0 then
                length = "Permanent"
            else
                length = ULib.secondsToStringTime(v["length"])
            end
            panel:AddLine( v["banId"], v["nickname"], v["adminNickname"], os.date( "%H:%M:%S - %d/%m/%Y" , v["timestamp"]), length, v["reason"] )
        end
    end

    MSync.modules[info.ModuleIdentifier].getTablePages = function(tbl, resultsPerPage)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.getTablePages Param.: $tbl $resultsPerPage",{["tbl"] = tbl, ["resultsPerPage"] = resultsPerPage}));
        return math.Round(#tbl / resultsPerPage)
    end

    MSync.modules[info.ModuleIdentifier].explodeTable = function(tbl, part)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.explodeTable Param.: $tbl $part",{["tbl"] = tbl, ["part"] = part}));
        for k,v in pairs(part) do
            tbl[k] = v
        end
    end

    MSync.modules[info.ModuleIdentifier].sortTable = function(tbl, key, asc)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.sortTable Param.: $tbl $key $asc",{["tbl"] = tbl, ["key"] = key, ["asc"] = asc}));
        local sorting = true
        local tempTable = table.DeSanitise( tbl )
        local keys = table.GetKeys( tempTable )

        while sorting do
            sorting = false
            for k,v in pairs(keys) do
                local a, b
                if not keys[k + 1] then break end

                if type( tempTable[v][key] ) == "string" then
                    a = tempTable[v][key]:lower()
                    b = tempTable[keys[k + 1]][key]:lower()
                else
                    a = tempTable[v][key]
                    b = tempTable[keys[k + 1]][key]
                end

                if asc then
                    if a > b then
                        sorting = true
                        local temp = tempTable[v]
                        tempTable[v] = tempTable[keys[k + 1]]
                        tempTable[keys[k + 1]] = temp
                        break
                    end
                else
                    if a < b then
                        sorting = true
                        local temp = tempTable[keys[k + 1]]
                        tempTable[keys[k + 1]] = tempTable[v]
                        tempTable[v] = temp
                        break
                    end
                end
            end
        end
        return tempTable
    end

    MSync.modules[info.ModuleIdentifier].searchTable = function(tbl, term)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.searchTable Param.: $tbl $term", {["tbl"] = tbl,["term"] = term}));
        local searchTerm = ""

        if type(term) == "string" then
            searchTerm = term:lower()
        else
            searchTerm = tostring(term):lower()
        end

        local tempTbl = {}
        local matches = false

        for k, v in pairs(tbl) do
            matches = false
            for k2, v2 in pairs(v) do
                if type(v2) == "string" then
                    if string.match(v2:lower(), ".*" .. searchTerm .. ".*") then
                        matches = true
                    end
                else
                    if string.match(tostring( v2 ):lower(), ".*" .. searchTerm .. ".*") then
                        matches = true
                    end
                end
            end

            if matches then
                MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Search: Found match " .. k);
                tempTbl[k] = v
            end
        end

        return tempTbl
    end

    MSync.modules[info.ModuleIdentifier].banPanel = function( tbl )
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.banPanel Param.: $tbl",{["tbl"] = tbl}));

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
            reasonMaxLen_text:SetText(string.len( value ) .. "/100")

            if string.len( value ) > 100 then
                reasonMaxLen_text:SetColor( Color( 255, 120, 120 ) )
            else
                reasonMaxLen_text:SetColor( Color( 255, 255, 255 ) )
            end
        end

        local disconnectedPly_text = vgui.Create( "DLabel", panel )
        disconnectedPly_text:SetPos( 15, 205 )
        disconnectedPly_text:SetColor( Color( 255, 255, 255 ) )
        disconnectedPly_text:SetText( "Recently Disconnected Players" )
        disconnectedPly_text:SetSize(380, 15)

        local ban_table = vgui.Create( "DListView", panel )
        ban_table:SetPos( 15, 220 )
        ban_table:SetSize( 320, 200 )
        ban_table:SetMultiSelect( false )
        ban_table:AddColumn( "Nickname" )
        ban_table:AddColumn( "SteamID" )
        ban_table:AddColumn( "SteamID64" )
        ban_table.OnRowSelected = function( lst, index, pnl )
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Ban Panel: Selected row " .. index);

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
        ban_button.DoClick = function()
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Ban confirm request");

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
                MSync.log(MSYNC_DBG_INFO, "[MBSync] Ban confirmed, banning player and closing panel");

                RunConsoleCommand("msync.MBSync.banSteamID", steamid_textentry:GetValue(), length_textentry:GetValue(), allservers_dropdown:GetValue(), reason_textentry:GetValue())
                panel:Close()
                banConfirm_panel:Close()
            end

            local deny_button = vgui.Create( "DButton", banConfirm_panel )
            deny_button:SetText( "Deny" )
            deny_button:SetPos( 175, 70 )
            deny_button:SetSize( 160, 20 )
            deny_button.DoClick = function()
                MSync.log(MSYNC_DBG_INFO, "[MBSync] Ban denied, closing confirmation panel");

                banConfirm_panel:Close()
            end
        end

        local cancel_button = vgui.Create( "DButton", panel )
        cancel_button:SetText( "Cancel" )
        cancel_button:SetPos( 15, 460 )
        cancel_button:SetSize( 320, 30 )
        cancel_button.DoClick = function()
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Ban cancellation request");
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
                MSync.log(MSYNC_DBG_INFO, "[MBSync] Ban canceled, closing panels");
                -- do nothing and close panel
                panel:Close()
                cancel_panel:Close()
            end

            local deny_button = vgui.Create( "DButton", cancel_panel )
            deny_button:SetText( "Deny" )
            deny_button:SetPos( 175, 70 )
            deny_button:SetSize( 160, 20 )
            deny_button.DoClick = function()
                MSync.log(MSYNC_DBG_INFO, "[MBSync] Ban cancel aborted, returning to ban panel");
                cancel_panel:Close()
            end
        end

    end

    MSync.modules[info.ModuleIdentifier].advancedInfoPanel = function(tbl)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.advancedInfoPanel Param.: $tbl",{["tbl"] = tbl}));

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
        nickname_textentry:SetDisabled(true)

        local steamid_text = vgui.Create( "DLabel", panel )
        steamid_text:SetPos( 15, 60 )
        steamid_text:SetColor( Color( 255, 255, 255 ) )
        steamid_text:SetText( "SteamID:" )
        steamid_text:SetSize(380, 15)

        local steamid_textentry = vgui.Create( "DTextEntry", panel )
        steamid_textentry:SetPos( 125, 60 )
        steamid_textentry:SetSize( 210, 20 )
        steamid_textentry:SetDisabled(true)

        local steamid64_text = vgui.Create( "DLabel", panel )
        steamid64_text:SetPos( 15, 85 )
        steamid64_text:SetColor( Color( 255, 255, 255 ) )
        steamid64_text:SetText( "SteamID64:" )
        steamid64_text:SetSize(380, 15)

        local steamid64_textentry = vgui.Create( "DTextEntry", panel )
        steamid64_textentry:SetPos( 125, 85 )
        steamid64_textentry:SetSize( 210, 20 )
        steamid64_textentry:SetDisabled(true)

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
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Close info panel");
            panel:Close()
        end

        --[[
            ############
            FILL DATA
            ############
        ]]

        if (tbl ~= nil) then
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Filling in ban data");

            nickname_textentry:SetText( tbl["nickname"] )
            steamid_textentry:SetText( tbl["steamid"] )
            steamid64_textentry:SetText( tbl["steamid64"] )
            adminnickname_textentry:SetText( tbl["adminNickname"] )
            bandate_textentry:SetText( os.date( "%H:%M:%S - %d/%m/%Y" ,tbl["timestamp"]) )
            if (tbl["length"] ~= 0) then
                banlength_textentry:SetText( ULib.secondsToStringTime(tbl["length"]) )
                unbandate_textentry:SetText( os.date( "%H:%M:%S - %d/%m/%Y" ,tbl["timestamp"] + tbl["length"]) )
                remainingtime_textentry:SetText( ULib.secondsToStringTime((tbl["timestamp"] + tbl["length"]) - os.time()) )
            else
                banlength_textentry:SetText( "Permanent" )
                unbandate_textentry:SetText( "Never" )
                remainingtime_textentry:SetText( "Forever" )
            end
            bangroup_textentry:SetText( tbl["servergroup"] )
            banreasonreason_text:SetText( tbl["reason"] )
        end

    end

    MSync.modules[info.ModuleIdentifier].editBanPanel = function(tbl)
        MSync.log(MSYNC_DBG_DEBUG, MSync.formatString("[MBSync] Exec: MBSync.editBanPanel Param.: $tbl",{["tbl"] = tbl}));

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
        steamid64_text:SetText( "SteamID64:" )
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
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Ban on all servers: " .. value);
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
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Ban edit confirmation request");
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
                MSync.log(MSYNC_DBG_INFO, "[MBSync] Edited data accepted, editing ban and closing panel");
                RunConsoleCommand( "msync.MBSync.editBan", tbl["banId"], banlength_textentry:GetValue(), banallservers_textentry:GetValue(), banreason_textentry:GetValue())
                panel:Close()
                save_panel:Close()
            end

            local deny_button = vgui.Create( "DButton", save_panel )
            deny_button:SetText( "Deny" )
            deny_button:SetPos( 175, 70 )
            deny_button:SetSize( 160, 20 )
            deny_button.DoClick = function()
                MSync.log(MSYNC_DBG_INFO, "[MBSync] Edited data denied, closing panel");
                -- CLOSE ACCEPT PANEL
                save_panel:Close()
            end
        end

        local cancel_button = vgui.Create( "DButton", panel )
        cancel_button:SetText( "Cancel" )
        cancel_button:SetPos( 15, 235 )
        cancel_button:SetSize( 320, 30 )
        cancel_button.DoClick = function()
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Ban edit cancellation request");
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
                MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Ban edit cancelled");
                panel:Close()
                cancel_panel:Close()
            end

            local deny_button = vgui.Create( "DButton", cancel_panel )
            deny_button:SetText( "Deny" )
            deny_button:SetPos( 175, 70 )
            deny_button:SetSize( 160, 20 )
            deny_button.DoClick = function()
                MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Ban edit cancellation request denied");
                cancel_panel:Close()
            end
        end

        --[[
            ###########
            FILL DATA
            ###########
        ]]

        if (tbl ~= nil) then
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Filling in ban data");
            nickname_textentry:SetText( tbl["nickname"] )
            steamid_textentry:SetText( tbl["steamid"] )
            steamid64_textentry:SetText( tbl["steamid64"] )
            banlength_textentry:SetText( tbl["length"] )
            if tbl["servergroup"] == "allservers" then
                banallservers_textentry:SetValue( "true" )
            else
                banallservers_textentry:SetValue( "false" )
            end
            banreason_textentry:SetText( tbl["reason"] )
        end
    end

end

--[[
    Define the admin panel for the settings
]]
MSync.modules[info.ModuleIdentifier].adminPanel = function(sheet)
    local pnl = vgui.Create( "DPanel", sheet )
    local tempTable = {};
    pnl:Dock(FILL)

    MSync.modules[info.ModuleIdentifier].getSettings()

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

    local reload_button = vgui.Create( "DButton", pnl )
    reload_button:SetText( "Load Data" )
    reload_button:SetPos( 380, 65 )
    reload_button:SetSize( 65, 20 )

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

    --[[
        ############################
        FUNCTIONALITY PART
        ############################
    ]]

    local sortby = {
        Column = 1,
        Descending = true
    }
    ban_table:SortByColumn( sortby.Column, sortby.Descending )

    function displayTable(tbl)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Displaying data to table");
        ban_table:Clear()
        for k,v in pairs(tbl) do
            local length = ""
            local unbanned = "false"

            if v["unBanningAdmin"] then
                unbanned = "true"
            end

            if v["length"] == 0 then
                length = "Permanent"
            else
                length = ULib.secondsToStringTime(v["length"])
            end

            ban_table:AddLine( v["banId"], v["steamid"], v["adminNickname"], length, v["reason"], unbanned)
        end
    end

    save_button.DoClick = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Save settings requested");
        local num = tonumber(delay_textentry:GetValue())
        if num then
            if num < 30 then
                MSync.log(MSYNC_DBG_ERROR, "[MBSync] You should not select a value below \"30\" seconds. We recommend to have it at \"300\" seconds");
                chat.AddText(Color(255, 60, 60),"[MBSync_ERROR] ",Color(255,170,0),"You should not select a value below ",Color(60, 255, 60),"30",Color(255,170,0)," seconds. We recommend to have it at ",Color(60, 255, 60),"300",Color(255,170,0)," seconds")
            else
                MSync.modules[info.ModuleIdentifier].settings["syncDelay"] = num
                MSync.modules[info.ModuleIdentifier].sendSettings()
            end
        else
            MSync.log(MSYNC_DBG_ERROR, "[MBSync] The value you entered is invalid");
            chat.AddText(Color(255, 60, 60),"[MBSync_ERROR] ",Color(255,170,0),"That is not a valid value!")
        end
    end

    search_button.DoClick = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Searching table");
        if search_textentry:GetValue() then
            tempTable = {}
            tempTable = MSync.modules[info.ModuleIdentifier].searchTable(MSync.modules[info.ModuleIdentifier].banTable, search_textentry:GetValue())
            displayTable(tempTable)
            ban_table:SortByColumn( sortby.Column, sortby.Descending )
        else
            tempTable = MSync.modules[info.ModuleIdentifier].banTable
            displayTable(tempTable)
            ban_table:SortByColumn( sortby.Column, sortby.Descending )
        end
    end

    reload_button.DoClick = function()
        MSync.log(MSYNC_DBG_INFO, "[MBSync] Reloading data");
        MSync.modules[info.ModuleIdentifier].getBanTable(true)
        ban_table:Clear()

        timer.Create("msync.mbsync.waitForBanTable", 1, 0, function()
            if MSync.modules[info.ModuleIdentifier].temporary["unfinished"] then return end

            tempTable = MSync.modules[info.ModuleIdentifier].banTable
            for k,v in pairs(tempTable) do
                local length = ""
                local unbanned = "false"

                if v["unBanningAdmin"] then
                    unbanned = "true"
                end

                if v["length"] == 0 then
                    length = "Permanent"
                else
                    length = ULib.secondsToStringTime(v["length"])
                end

                ban_table:AddLine( v["banId"], v["steamid"], v["adminNickname"], length, v["reason"], unbanned)
            end
            timer.Remove("msync.mbsync.waitForBanTable")
        end)
        reload_button:SetText("Reload")
    end

    ban_table.OnRowRightClick = function(panel, lineID, line)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Row " .. lineID .. " right clicked");

        --local ident = line:GetValue(1)
        local cursor_x, cursor_y = panel:CursorPos()
        local DMenu = vgui.Create("DMenu", panel)

        if cursor_y > 170 then
            cursor_y = 170
        end

        if cursor_x > 290 then
            cursor_x = 290
        end

        DMenu:SetPos(cursor_x, cursor_y)
        DMenu:AddOption("Unban")
        DMenu:AddOption("Edit")
        DMenu:AddOption("Advanced Info")
        DMenu.OptionSelected = function(menu,optPnl,optStr)
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Option \"" .. optStr .. "\" selected");
            if optStr == "Unban" then
                MSync.modules[info.ModuleIdentifier].unban(line:GetColumnText( 1 ))
            elseif optStr == "Edit" then
                MSync.modules[info.ModuleIdentifier].editBanPanel(MSync.modules[info.ModuleIdentifier].banTable[line:GetColumnText( 1 )])
            elseif optStr == "Advanced Info" then
                MSync.modules[info.ModuleIdentifier].advancedInfoPanel(MSync.modules[info.ModuleIdentifier].banTable[line:GetColumnText( 1 )])
            end
        end
    end

    sortby_dropdown.OnSelect = function( self, index, value )
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Sortby dropdown selected");
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

    timer.Create("msync.mbsync.waitForSettings", 1, 0, function()
        if not MSync.modules[info.ModuleIdentifier].settings then return end

        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Got settings from server, filling in data");

        delay_textentry:SetText(MSync.modules[info.ModuleIdentifier].settings["syncDelay"])

        timer.Remove("msync.mbsync.waitForSettings")
    end)

    return pnl
end

--[[
    Define the client panel for client usage ( or as example: use it as additional admin gui which does not need msync.admingui permission)
]]
MSync.modules[info.ModuleIdentifier].clientPanel = function()
    MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.clientPanel");

    --[[
        Get Ban table and then wait for the reply before showing it
    ]]

    MSync.modules[info.ModuleIdentifier].getBanTable()

    local tempTable = {}
    local pages = 0
    local tablePage = 0

    local panel = vgui.Create( "DFrame" )
    panel:SetSize( 800, 450 )
    panel:SetTitle( "MSync Admin Menu" )
    panel:Center()
    panel:MakePopup()
    panel:SetBackgroundBlur( true )

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
    pageof_text:SetText( "1/" .. pages )
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

    --[[
        #############
        FUNCTION PART
        #############
    ]]
    --[[
        Define sortby variable for sorting the ban table
    ]]
    local sortby = {
        Column = "banId",
        Descending = false
    }

    local function checkPage()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: checkPage");
        if ( (tablePage + 1) >= pages ) then
            lastpage_button:SetDisabled(true)
            nextpage_button:SetDisabled(true)
        else
            lastpage_button:SetDisabled(false)
            nextpage_button:SetDisabled(false)
        end

        if (tablePage >= 1) then
            firstpage_button:SetDisabled(false)
            previouspage_button:SetDisabled(false)
        else
            firstpage_button:SetDisabled(true)
            previouspage_button:SetDisabled(true)
        end
    end

    ban_table.OnRowRightClick = function(parentPanel, lineID, line)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Row \"" .. lineID .. "\" right clicked");
        --local ident = line:GetValue(1)
        local cursor_x, cursor_y = panel:CursorPos()
        local DMenu = vgui.Create("DMenu", panel)
        DMenu:SetPos(cursor_x, cursor_y)
        DMenu:AddOption("Unban")
        DMenu:AddOption("Edit")
        DMenu:AddOption("Advanced Info")
        DMenu.OptionSelected = function(menu,optPnl,optStr)
            MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Option \"" .. optStr .. "\" selected");
            if optStr == "Unban" then
                MSync.modules[info.ModuleIdentifier].unban(line:GetColumnText( 1 ))
            elseif optStr == "Edit" then
                MSync.modules[info.ModuleIdentifier].editBanPanel(MSync.modules[info.ModuleIdentifier].banTable[line:GetColumnText( 1 )])
            elseif optStr == "Advanced Info" then
                MSync.modules[info.ModuleIdentifier].advancedInfoPanel(MSync.modules[info.ModuleIdentifier].banTable[line:GetColumnText( 1 )])
            end
        end
    end

    sortby_dropdown.OnSelect = function( self, index, value )
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Sortby: Selected \"" .. value .. "\"");
        --ban_table
        if value == "Ban ID" then
            sortby.Column = "banId"
            sortby_dropdown:SetValue( "Sort by: Ban ID" )
        elseif value == "Nickname" then
            sortby.Column = "nickname"
            sortby_dropdown:SetValue( "Sort by: Nickname" )
        elseif value == "Admin" then
            sortby.Column = "adminNickname"
            sortby_dropdown:SetValue( "Sort by: Admin" )
        elseif value == "Ban Date" then
            sortby.Column = "timestamp"
            sortby_dropdown:SetValue( "Sort by: Ban Length" )
        elseif value == "Ban Length" then
            sortby.Column = "length"
            sortby_dropdown:SetValue( "Sort by: Ban Length" )
        elseif value == "Ban Reason" then
            sortby.Column = "reason"
            sortby_dropdown:SetValue( "Sort by: Ban Reason" )
        end

        if value then
            tempTable = MSync.modules[info.ModuleIdentifier].sortTable(tempTable, sortby.Column, sortby.Descending)
            MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, 0)
            checkPage()
        end
    end

    listascdesc_button.DoClick = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Changing if list should be ascending or descending");
        if sortby.Descending then
            sortby.Descending = false
            listascdesc_button:SetText( "List: Desc" )
        else
            sortby.Descending = true
            listascdesc_button:SetText( "List: Asc" )
        end
        tempTable = MSync.modules[info.ModuleIdentifier].sortTable(tempTable, sortby.Column, sortby.Descending)
        MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, 0)
        checkPage()
    end

    search_button.DoClick = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Searching table");
        if search_textentry:GetValue() then
            tempTable = {}
            tempTable = MSync.modules[info.ModuleIdentifier].searchTable(MSync.modules[info.ModuleIdentifier].banTable, search_textentry:GetValue())
            tempTable = MSync.modules[info.ModuleIdentifier].sortTable(tempTable, sortby.Column, sortby.Descending)
            MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, 0)
            checkPage()
        else
            tempTable = MSync.modules[info.ModuleIdentifier].sortTable(MSync.modules[info.ModuleIdentifier].banTable, sortby.Column, sortby.Descending)
            MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, 0)
            checkPage()
        end
    end

    sync_button.DoClick = function()
        MSync.log(MSYNC_DBG_INFO, "[MBSync] Reloading ban table");
        MSync.modules[info.ModuleIdentifier].getBanTable()
        timer.Create("msync.mbsync.waitForBanTable", 3, 0, function()
            if MSync.modules[info.ModuleIdentifier].temporary["unfinished"] then MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Still waiting for some data from server"); return end

            MSync.log(MSYNC_DBG_INFO, "[MBSync] Got all ban data from server! Reloading table now");
            tempTable = MSync.modules[info.ModuleIdentifier].sortTable(MSync.modules[info.ModuleIdentifier].banTable, sortby.Column, sortby.Descending)
            pages = MSync.modules[info.ModuleIdentifier].getTablePages(tempTable, 20)
            tablePage = 0

            pageof_text:SetText( (tablePage + 1) .. "/" .. pages )

            if pages > 1 then
                nextpage_button:SetDisabled(false)
                lastpage_button:SetDisabled(false)
            end

            MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, tablePage)
            timer.Remove("msync.mbsync.waitForBanTable")
        end)
    end

    firstpage_button.DoClick = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Go to first page");

        tablePage = 0
        pageof_text:SetText( (tablePage + 1) .. "/" .. pages )
        MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, tablePage)
        checkPage()
    end

    previouspage_button.DoClick = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Go to previous page");

        tablePage = tablePage - 1
        pageof_text:SetText( (tablePage + 1) .. "/" .. pages )
        MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, tablePage)
        checkPage()
    end

    nextpage_button.DoClick = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Go to next page");

        tablePage = tablePage + 1
        pageof_text:SetText( (tablePage + 1) .. "/" .. pages )
        MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, tablePage)
        checkPage()
    end

    lastpage_button.DoClick = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Go to last page");

        tablePage = pages-1
        pageof_text:SetText( (tablePage + 1) .. "/" .. pages )
        MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, tablePage)
        checkPage()
    end

    if pages > 1 then
        nextpage_button:SetDisabled(false)
        lastpage_button:SetDisabled(false)
    end

    timer.Create("msync.mbsync.waitForBanTable", 1, 0, function()
        if MSync.modules[info.ModuleIdentifier].temporary["unfinished"] then MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Still waiting for some data from server");return end

        MSync.log(MSYNC_DBG_INFO, "[MBSync] Got all ban data from server! Reloading table now");

        tempTable = MSync.modules[info.ModuleIdentifier].sortTable(MSync.modules[info.ModuleIdentifier].banTable, sortby.Column, sortby.Descending)
        pages = MSync.modules[info.ModuleIdentifier].getTablePages(tempTable, 20)
        tablePage = 0

        pageof_text:SetText( (tablePage + 1) .. "/" .. pages )

        if pages > 1 then
            nextpage_button:SetDisabled(false)
            lastpage_button:SetDisabled(false)
        end

        MSync.modules[info.ModuleIdentifier].displayTable(ban_table, tempTable, 20, tablePage)
        timer.Remove("msync.mbsync.waitForBanTable")
    end)


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
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.unban Param.:" .. userid);

        if type(userid) ~= "number" then
            userid = tonumber(userid)
        end

        net.Start("msync." .. info.ModuleIdentifier .. ".unban")
            net.WriteFloat(userid)
        net.SendToServer()
    end
    --[[
        Description: Net Receiver - Gets called when the server wants to print something to the user chat
        Returns: nothing
    ]]
    net.Receive( "msync." .. info.ModuleIdentifier .. ".sendMessage", function( len, ply )
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Net: msync.MBSync.sendMessage");

        local msgType = net.ReadFloat()
        if msgType == 0 then
            chat.AddText( Color( 237, 135, 26 ), "[MBSync] ", Color( 255, 255, 255), net.ReadString())
        end
    end )

    --[[
        Description: Net Receiver - Gets called when the client entered '!mban'
        Returns: nothing
    ]]
    net.Receive( "msync." .. info.ModuleIdentifier .. ".openBanGUI", function( len, ply )
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Net: msync.MBSync.openBanGUI");

        MSync.modules[info.ModuleIdentifier].banPanel(net.ReadTable())
    end )

    --[[
        Description: Net Receiver - Gets called when the client entered '!mbsync'
        Returns: nothing
    ]]
    net.Receive( "msync." .. info.ModuleIdentifier .. ".openBanTable", function( len, ply )
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Net: msync.MBSync.openBanTable");

        MSync.modules[info.ModuleIdentifier].clientPanel()
    end )

    --[[
        Description: Function to unban a user using the banid
        Arguments:
            userid [number] - the ban id of the to be lifted ban
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].getBanTable = function(fulltable)
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.getBanTable Param.: " .. tostring(fulltable));

        MSync.modules[info.ModuleIdentifier].temporary = {}
        MSync.modules[info.ModuleIdentifier].banTable = {}

        net.Start("msync." .. info.ModuleIdentifier .. ".getBanTable")
            net.WriteBool(fulltable)
        net.SendToServer()
    end

    --[[
        Description: Net Receiver - Gets called when the client entered '!mban'
        Returns: nothing
    ]]
    net.Receive( "msync." .. info.ModuleIdentifier .. ".recieveDataCount", function( len, ply )
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Net: msync.MBSync.recieveDataCount");

        local num = net.ReadFloat()
        if num > 0 and not MSync.modules[info.ModuleIdentifier].temporary["unfinished"] then
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
    net.Receive( "msync." .. info.ModuleIdentifier .. ".recieveData", function( len, ply )
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] msync.MBSync.recieveData");

        MSync.modules[info.ModuleIdentifier].explodeTable(MSync.modules[info.ModuleIdentifier].banTable, net.ReadTable())

        MSync.modules[info.ModuleIdentifier].temporary["recieved"] = MSync.modules[info.ModuleIdentifier].temporary["recieved"] + 1

        if MSync.modules[info.ModuleIdentifier].temporary["recieved"] == MSync.modules[info.ModuleIdentifier].temporary["count"] then
            MSync.modules[info.ModuleIdentifier].temporary = {}
            local tempTable = {}
            for k,v in pairs(MSync.modules[info.ModuleIdentifier].banTable) do
                tempTable[v["banId"]]                   = {}
                tempTable[v["banId"]]["banId"]          = v["banId"]
                tempTable[v["banId"]]["adminNickname"]  = v["adminNickname"]
                tempTable[v["banId"]]["nickname"]       = v["banned"]["nickname"]
                tempTable[v["banId"]]["steamid"]        = v["banned"]["steamid"]
                tempTable[v["banId"]]["steamid64"]      = k
                tempTable[v["banId"]]["length"]         = v["length"]
                tempTable[v["banId"]]["reason"]         = v["reason"]
                tempTable[v["banId"]]["timestamp"]      = v["timestamp"]
                tempTable[v["banId"]]["servergroup"]    = v["servergroup"]
                if v["banningAdmin"] then
                    tempTable[v["banId"]]["adminNickname"]  = v["banningAdmin"]["nickname"]
                end
                if v["unBanningAdmin"] then
                    tempTable[v["banId"]]["unBanningAdmin"]  = v["unBanningAdmin"]["nickname"]
                end
            end
            MSync.modules[info.ModuleIdentifier].banTable = tempTable
        end
    end )

    --[[
        Description: Net Receiver - Gets called when the server sent settings
        Returns: nothing
    ]]
    net.Receive( "msync." .. info.ModuleIdentifier .. ".sendSettingsPly", function( len, ply )
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Net: msync.MBSync.sendSettingsPly");

        MSync.modules[info.ModuleIdentifier].settings = net.ReadTable()
    end )

    --[[
        Description: Function to request the settings from the server
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].getSettings = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.getSettings");

        net.Start("msync." .. info.ModuleIdentifier .. ".getSettings")
        net.SendToServer()
    end

    --[[
        Description: Function to request the settings from the server
        Returns: nothing
    ]]
    MSync.modules[info.ModuleIdentifier].sendSettings = function()
        MSync.log(MSYNC_DBG_DEBUG, "[MBSync] Exec: MBSync.sendSettings");

        net.Start("msync." .. info.ModuleIdentifier .. ".sendSettings")
            net.WriteTable(MSync.modules[info.ModuleIdentifier].settings)
        net.SendToServer()
    end
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

--[[
    Define a function to run on the clients when the module gets disabled
]]
MSync.modules[info.ModuleIdentifier].disable = function()

end

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules[info.ModuleIdentifier].info