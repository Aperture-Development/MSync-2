MSync = MSync or {}
MSync.AdminPanel = MSync.AdminPanel or {}

--[[
    Description: MySQL settings panel
    Arguments: parent sheet
    Returns: panel
]]
function MSync.AdminPanel.InitMySQL( sheet )

    MSync.log(MSYNC_DBG_DEBUG, "Initializing MySQL settings panel")

    local pnl = vgui.Create( "DPanel", sheet )

    local mysqlip_text = vgui.Create( "DLabel", pnl )
    mysqlip_text:SetPos( 25, 10 )
    mysqlip_text:SetColor( Color( 0, 0, 0 ) )
    mysqlip_text:SetText( "Host IP" )

    local mysqlip = vgui.Create( "DTextEntry", pnl )
    mysqlip:SetPos( 25, 30 )
    mysqlip:SetSize( 150, 20 )
    mysqlip:SetText( "127.0.0.1" )

    local mysqlport_text = vgui.Create( "DLabel", pnl )
    mysqlport_text:SetPos( 25, 55 )
    mysqlport_text:SetColor( Color( 0, 0, 0 ) )
    mysqlport_text:SetText( "Host Port" )

    local mysqlport = vgui.Create( "DTextEntry", pnl )
    mysqlport:SetPos( 25, 75 )
    mysqlport:SetSize( 150, 20 )
    mysqlport:SetText( "3306" )

    local mysqldb_text = vgui.Create( "DLabel", pnl )
    mysqldb_text:SetPos( 25, 100 )
    mysqldb_text:SetColor( Color( 0, 0, 0 ) )
    mysqldb_text:SetText( "Database" )

    local mysqldb = vgui.Create( "DTextEntry", pnl )
    mysqldb:SetPos( 25, 120 )
    mysqldb:SetSize( 150, 20 )
    mysqldb:SetText( "MSync" )

    local mysqluser_text = vgui.Create( "DLabel", pnl )
    mysqluser_text:SetPos( 25, 145 )
    mysqluser_text:SetColor( Color( 0, 0, 0 ) )
    mysqluser_text:SetText( "Username" )

    local mysqluser = vgui.Create( "DTextEntry", pnl )
    mysqluser:SetPos( 25, 165 )
    mysqluser:SetSize( 150, 20 )
    mysqluser:SetText( "root" )

    local mysqlpassword_text = vgui.Create( "DLabel", pnl )
    mysqlpassword_text:SetPos( 25, 190 )
    mysqlpassword_text:SetColor( Color( 0, 0, 0 ) )
    mysqlpassword_text:SetText( "Password" )

    local mysqlpassword = vgui.Create( "DTextEntry", pnl )
    mysqlpassword:SetPos( 25, 210 )
    mysqlpassword:SetSize( 150, 20 )
    mysqlpassword:SetText( "*****" )

    local servergroup_text = vgui.Create( "DLabel", pnl )
    servergroup_text:SetPos( 25, 235 )
    servergroup_text:SetColor( Color( 0, 0, 0 ) )
    servergroup_text:SetText( "Server Group" )

    local servergroup = vgui.Create( "DTextEntry", pnl )
    servergroup:SetPos( 25, 255 )
    servergroup:SetSize( 150, 20 )
    servergroup:SetText( "allserver" )

    local title_info = vgui.Create( "DLabel", pnl )
    title_info:SetPos( 200, 25 )
    title_info:SetColor( Color( 0, 0, 0 ) )
    title_info:SetSize(400, 15)
    title_info:SetText( "--Information--" )

    local info = vgui.Create( "RichText", pnl )
    info:SetPos( 200, 45 )
    info:SetSize(350, 150)
    info:InsertColorChange(10, 10, 10, 255)
    info:AppendText("MSync2 - Now with Steak\n\nSupport: ")
    info:InsertColorChange(72, 72, 155, 255)
    info:InsertClickableTextStart("OpenWebsite")
    info:AppendText("https://www.Aperture-Development.de")
    info:InsertClickableTextEnd()
    info:InsertColorChange(10, 10, 10, 255)
    info:AppendText("\nGitHub: ")
    info:InsertColorChange(72, 72, 155, 255)
    info:InsertClickableTextStart("OpenGitHub")
    info:AppendText("https://github.com/Aperture-Development/MSync-2")
    info:InsertClickableTextEnd()
    info:InsertColorChange(10, 10, 10, 255)
    info:AppendText("\nLicence:\n")
    info:InsertColorChange(80, 80, 80, 255)
    info:AppendText("To know what you are allowed to do and what not, read the LICENCE file in the root directory of the addon. If there is no file, the licence GPL 3.0 applies.\n\n")
    info:InsertColorChange(10, 10, 10, 255)
    info:AppendText("This addon was created by Aperture Development\n")
    info:InsertColorChange(10, 10, 10, 255)
    info:AppendText("Copyright 2018 - Aperture Development")

    info.Paint = function( parentPanel, w, h )
        draw.RoundedBox( 5, 0, 0, w, h, Color(215, 215, 215) )
    end

    info.ActionSignal = function( parentPanel, signalName, signalValue )
        if signalName == "TextClicked" then
            if signalValue == "OpenWebsite" then
                gui.OpenURL( "https://www.Aperture-Development.de" )
            elseif signalValue == "OpenGitHub" then
                gui.OpenURL( "https://github.com/Aperture-Development/MSync-2" )
            end
        end
    end

    local dbstatus = vgui.Create( "DLabel", pnl )
    dbstatus:SetPos( 200, 210 )
    dbstatus:SetColor( Color( 0, 0, 0 ) )
    dbstatus:SetSize(400, 15)
    dbstatus:SetText( "Database Status: " )

    local dbstatus_info = vgui.Create( "DLabel", pnl )
    dbstatus_info:SetPos( 300, 210 )
    dbstatus_info:SetColor( Color( 80, 80, 80 ) )
    dbstatus_info:SetSize(400, 15)
    dbstatus_info:SetText( "Please wait..." )

    local function getConnectionStatus()
        dbstatus_info:SetColor( Color( 80, 80, 80 ) )
        dbstatus_info:SetText( "Please wait..." )
        timer.Simple(3, function()
            MSync.net.getDBStatus()
            timer.Create("msync.dbConnectionStatus", 3, 10, function()
                if MSync.DBStatus == nil then return end

                if MSync.DBStatus then
                    dbstatus_info:SetColor( Color( 80, 255, 80 ) )
                    dbstatus_info:SetText( "Connected" )
                else
                    dbstatus_info:SetColor( Color( 255, 80, 80 ) )
                    dbstatus_info:SetText( "Not Connected" )
                end
                timer.Remove("msync.dbConnectionStatus")
            end)
        end)
    end

    local save_button = vgui.Create( "DButton", pnl )
    save_button:SetText( "Save Settings" )
    save_button:SetPos( 25, 290 )
    save_button:SetSize( 130, 30 )
    save_button.DoClick = function()
        MSync.log(MSYNC_DBG_DEBUG, "Saving settings")
        MSync.settings.mysql.host = mysqlip:GetValue()
        MSync.settings.mysql.port = mysqlport:GetValue()
        MSync.settings.mysql.database = mysqldb:GetValue()
        MSync.settings.mysql.username = mysqluser:GetValue()
        MSync.settings.mysql.password = mysqlpassword:GetValue()
        MSync.settings.serverGroup = servergroup:GetValue()
        MSync.net.sendSettings(MSync.settings)
    end

    local saveconnect_button = vgui.Create( "DButton", pnl )
    saveconnect_button:SetText( "Save and Connect" )
    saveconnect_button:SetPos( 155, 290 )
    saveconnect_button:SetSize( 130, 30 )
    saveconnect_button.DoClick = function()
        MSync.log(MSYNC_DBG_DEBUG, "Saving settings and connecting to the database")
        MSync.settings.mysql.host = mysqlip:GetValue()
        MSync.settings.mysql.port = mysqlport:GetValue()
        MSync.settings.mysql.database = mysqldb:GetValue()
        MSync.settings.mysql.username = mysqluser:GetValue()
        MSync.settings.mysql.password = mysqlpassword:GetValue()
        MSync.settings.serverGroup = servergroup:GetValue()
        MSync.net.sendSettings(MSync.settings)
        MSync.net.connectDB()
        getConnectionStatus()
    end

    local connect_button = vgui.Create( "DButton", pnl )
    connect_button:SetText( "Connect" )
    connect_button:SetPos( 285, 290 )
    connect_button:SetSize( 130, 30 )
    connect_button.DoClick = function()
        MSync.log(MSYNC_DBG_DEBUG, "Connecting to the database")
        MSync.net.connectDB()
        getConnectionStatus()
    end

    local reset_button = vgui.Create( "DButton", pnl )
    reset_button:SetText( "Reset Settings" )
    reset_button:SetPos( 415, 290 )
    reset_button:SetSize( 130, 30 )
    reset_button.DoClick = function()
        MSync.log(MSYNC_DBG_DEBUG, "Reset confirm request");

        local resetConfirm_panel = vgui.Create( "DFrame" )
        resetConfirm_panel:SetSize( 350, 100 )
        resetConfirm_panel:SetTitle( "MSync Reset - Confirm" )
        resetConfirm_panel:Center()
        resetConfirm_panel:MakePopup()

        local save_text = vgui.Create( "DLabel", resetConfirm_panel )
        save_text:SetPos( 15, 20 )
        save_text:SetColor( Color( 255, 255, 255 ) )
        save_text:SetText( "This action will reset all MySQL settings back to default, causing MSync to be unable to connect to the database when restarting the server. Are you sure you want to do that?" )
        save_text:SetSize(320, 50)
        save_text:SetWrap( true )

        local accept_button = vgui.Create( "DButton", resetConfirm_panel )
        accept_button:SetText( "Yes" )
        accept_button:SetPos( 15, 70 )
        accept_button:SetSize( 160, 20 )
        accept_button.DoClick = function()
            MSync.log(MSYNC_DBG_DEBUG, "Reset of MySQL configuration confirmed")
            mysqlip:SetText("127.0.0.1")
            mysqlport:SetText("3306")
            mysqldb:SetText("msync")
            mysqluser:SetText("root")
            mysqlpassword:SetText("****")
            servergroup:SetText("allserver")
            MSync.settings.mysql.host = mysqlip:GetValue()
            MSync.settings.mysql.port = mysqlport:GetValue()
            MSync.settings.mysql.database = mysqldb:GetValue()
            MSync.settings.mysql.username = mysqluser:GetValue()
            MSync.settings.mysql.password = ""
            MSync.settings.serverGroup = servergroup:GetValue()
            MSync.net.sendSettings(MSync.settings)

            resetConfirm_panel:Close()
        end

        local deny_button = vgui.Create( "DButton", resetConfirm_panel )
        deny_button:SetText( "No" )
        deny_button:SetPos( 175, 70 )
        deny_button:SetSize( 160, 20 )
        deny_button.DoClick = function()
            MSync.log(MSYNC_DBG_INFO, "Reset of MySQL configuration cancelled");
            resetConfirm_panel:Close()
        end
    end

    if MSync.settings and MSync.settings.mysql then
        mysqlip:SetText(MSync.settings.mysql.host)
        mysqlport:SetText(MSync.settings.mysql.port)
        mysqldb:SetText(MSync.settings.mysql.database)
        mysqluser:SetText(MSync.settings.mysql.username)
        servergroup:SetText(MSync.settings.serverGroup)
    else
        timer.Create("msync.t.checkForSettings", 0.5, 0, function()
            if not MSync.settings or not MSync.settings.mysql then return end;

            MSync.log(MSYNC_DBG_DEBUG, "Got server settings, updating MySQL settings panel")

            mysqlip:SetText(MSync.settings.mysql.host)
            mysqlport:SetText(MSync.settings.mysql.port)
            mysqldb:SetText(MSync.settings.mysql.database)
            mysqluser:SetText(MSync.settings.mysql.username)
            servergroup:SetText(MSync.settings.serverGroup)
            timer.Remove("msync.t.checkForSettings")
        end)
    end

    getConnectionStatus()

    return pnl
end

--[[
    Description: Module list panel
    Arguments: parent sheet
    Returns: panel
]]
function MSync.AdminPanel.InitModules( sheet )

    MSync.log(MSYNC_DBG_DEBUG, "Initializing modulestate panel")

    local pnl = vgui.Create( "DPanel", sheet )

    local ModuleList = vgui.Create( "DListView", pnl )
    ModuleList:Dock( FILL )
    ModuleList:SetMultiSelect( false )
    ModuleList:AddColumn( "Name" )
    ModuleList:AddColumn( "Identifier" )
    ModuleList:AddColumn( "Enabled" )

    timer.Create("msync.t.checkForServerModules", 1, 0, function()
        if not MSync.serverModules then return end;

        for k,v in pairs(MSync.serverModules) do
            ModuleList:AddLine(v["Name"], v["ModuleIdentifier"], v["state"])
        end
        timer.Remove("msync.t.checkForServerModules")
    end)
    ModuleList.OnRowRightClick = function(panel, lineID, line)
        local ident = line:GetValue(2)
        local cursor_x, cursor_y = ModuleList:CursorPos()
        local DMenu = vgui.Create("DMenu", ModuleList)
        DMenu:SetPos(cursor_x, cursor_y)
        DMenu:AddOption(MSync.serverModules[ident].Description):SetDisabled(true)
        DMenu:AddSpacer()
        DMenu:AddOption("Enable")
        DMenu:AddOption("Disable")
        DMenu.OptionSelected = function(menu,optPnl,optStr)
            MSync.net.toggleModule(ident, optStr)
            if optStr == "Enable" then
                line:SetColumnText( 3, "true" )
            elseif optStr == "Disable" then
                line:SetColumnText( 3, "false" )
            end
        end
    end
    return pnl
end

--[[
    Description: Module settings panel
    Arguments: parent sheet
    Returns: panel
]]
function MSync.AdminPanel.InitModuleSettings( sheet )

    MSync.log(MSYNC_DBG_DEBUG, "Initializing module settings panel")

    local pnl = vgui.Create( "DColumnSheet", sheet )

    local files, _ = file.Find("msync/client_gui/modules/*.lua", "LUA")

    for k, v in pairs(files) do
        local info = include("msync/client_gui/modules/" .. v)

        if MSync.moduleState[info["ModuleIdentifier"]] then
            MSync.modules[info.ModuleIdentifier]["init"]()
            MSync.modules[info.ModuleIdentifier]["net"]()
            pnl:AddSheet( info.Name, MSync.modules[info.ModuleIdentifier].adminPanel(pnl))
            MSync.log(MSYNC_DBG_DEBUG, "Added settings tab for module: ")
        end
    end

    return pnl
end

--[[
    Description: MSync 2 panel
    Returns: nothing
]]
function MSync.AdminPanel.InitPanel()

    MSync.log(MSYNC_DBG_DEBUG, "Opening Admin GUI")

    --if not LocalPlayer():query("msync.admingui") then return false end;

    MSync.net.getSettings()
    MSync.net.getModules()

    local panel = vgui.Create( "DFrame" )
    panel:SetSize( 600, 400 )
    panel:SetTitle( "MSync Admin Menu" )
    panel:Center()
    panel:MakePopup()

    local sheet = vgui.Create( "DPropertySheet", panel )
    sheet:Dock( FILL )

    sheet:AddSheet( "MySQL", MSync.AdminPanel.InitMySQL( sheet ), "icon16/database.png" )
    sheet:AddSheet( "Modules", MSync.AdminPanel.InitModules( sheet ), "icon16/application.png" )
    sheet:AddSheet( "Module Settings", MSync.AdminPanel.InitModuleSettings( sheet ), "icon16/folder.png" )

end