MSync = MSync or {}
MSync.AdminPanel = MSync.AdminPanel or {}

--[[
    Description: MySQL settings panel
    Arguments: parent sheet
    Returns: panel
]]
function MSync.AdminPanel.InitMySQL( sheet )
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

    local info = vgui.Create( "DLabel", pnl )
    info:SetPos( 200, 30 )
    info:SetColor( Color( 0, 0, 0 ) )
    info:SetSize(400, 200)
    info:SetText( [[
        Support: https://www.Aperture-Development.de
        GitHub: https://github.com/Aperture-Development/MSync-2
        LICENCE: To know what you are allowed to do and what not, 
            read the LICENCE file in the root directory of the addon.
            If there is no file, the Licence by-nc-sa 4.0 International applies.
        
        Developer: This Addon was created by Aperture Development.
        Copyright 2018 - Aperture Development
    ]] )

    local dbstatus = vgui.Create( "DLabel", pnl )
    dbstatus:SetPos( 200, 210 )
    dbstatus:SetColor( Color( 0, 0, 0 ) )
    dbstatus:SetSize(400, 15)
    dbstatus:SetText( "DB Connection status: -Not Implemented-" )

    local save_button = vgui.Create( "DButton", pnl )
    save_button:SetText( "Save Settings" )
    save_button:SetPos( 25, 290 )
    save_button:SetSize( 130, 30 )
    save_button.DoClick = function()
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
        MSync.settings.mysql.host = mysqlip:GetValue()
        MSync.settings.mysql.port = mysqlport:GetValue()
        MSync.settings.mysql.database = mysqldb:GetValue()
        MSync.settings.mysql.username = mysqluser:GetValue()
        MSync.settings.mysql.password = mysqlpassword:GetValue()
        MSync.settings.serverGroup = servergroup:GetValue()
        MSync.net.sendSettings(MSync.settings)
        MSync.net.connectDB()
    end

    local connect_button = vgui.Create( "DButton", pnl )
    connect_button:SetText( "Connect" )
    connect_button:SetPos( 285, 290 )
    connect_button:SetSize( 130, 30 )
    connect_button.DoClick = function()
        MSync.net.connectDB()
    end

    local reset_button = vgui.Create( "DButton", pnl )
    reset_button:SetText( "Reset Settings" )
    reset_button:SetPos( 415, 290 )
    reset_button:SetSize( 130, 30 )
    reset_button.DoClick = function()
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
    end

    if not MSync.settings == nil then
        mysqlip:SetText(MSync.settings.mysql.host)
        mysqlport:SetText(MSync.settings.mysql.port)
        mysqldb:SetText(MSync.settings.mysql.database)
        mysqluser:SetText(MSync.settings.mysql.username)
        servergroup:SetText(MSync.settings.serverGroup)
    else
        timer.Create("msync.t.checkForSettings", 0.5, 0, function()
            if not MSync.settings or not MSync.settings.mysql then return end;

            mysqlip:SetText(MSync.settings.mysql.host)
            mysqlport:SetText(MSync.settings.mysql.port)
            mysqldb:SetText(MSync.settings.mysql.database)
            mysqluser:SetText(MSync.settings.mysql.username)
            servergroup:SetText(MSync.settings.serverGroup)
            timer.Remove("msync.t.checkForSettings")
        end)
    end

    return pnl
end

--[[
    Description: Module list panel
    Arguments: parent sheet
    Returns: panel
]]
function MSync.AdminPanel.InitModules( sheet )
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
        DMenu:AddOption(MSync.serverModules[ident].Description)
        DMenu:AddSpacer()
        DMenu:AddOption("Enable")
        DMenu:AddOption("Disable")
        DMenu.OptionSelected = function(menu,optPnl,optStr)
            MSync.net.toggleModule(ident, optStr)
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
    local pnl = vgui.Create( "DColumnSheet", sheet )

    local files, _ = file.Find("msync/client_gui/modules/*.lua", "LUA")

    for k, v in pairs(files) do
        local info = include("msync/client_gui/modules/"..v)

        if MSync.moduleState[info["ModuleIdentifier"]] then
            MSync.modules[info.ModuleIdentifier]["init"]()
            MSync.modules[info.ModuleIdentifier]["net"]()
            pnl:AddSheet( info.Name, MSync.modules[info.ModuleIdentifier].adminPanel(pnl))
        end
    end

    return pnl
end

--[[
    Description: MSync 2 panel
    Returns: nothing
]]
function MSync.AdminPanel.InitPanel()

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