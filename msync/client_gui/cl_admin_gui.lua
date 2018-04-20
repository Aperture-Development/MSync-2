AddCSLuaFile()

MSync = MSync or {}
MSync.AdminPanel = MSync.AdminPanel or {}

function MSync.AdminPanel.InitMySQL( sheet ) 
    local pnl = vgui.Create( "DPanel", sheet )

    local mysqlip_text = vgui.Create( "DLabel", pnl )
    mysqlip_text:SetPos( 25, 30 )
    mysqlip_text:SetColor( Color( 0, 0, 0 ) )
    mysqlip_text:SetText( "Host IP" )

    local mysqlip = vgui.Create( "DTextEntry", pnl )
    mysqlip:SetPos( 25, 50 )
    mysqlip:SetSize( 150, 20 )
    mysqlip:SetText( "127.0.0.1" )
    mysqlip.OnEnter = function( self )
        chat.AddText( self:GetValue() )
    end

    local mysqlport_text = vgui.Create( "DLabel", pnl )
    mysqlport_text:SetPos( 25, 75 )
    mysqlport_text:SetColor( Color( 0, 0, 0 ) )
    mysqlport_text:SetText( "Host Port" )

    local mysqlport = vgui.Create( "DTextEntry", pnl )
    mysqlport:SetPos( 25, 95 )
    mysqlport:SetSize( 150, 20 )
    mysqlport:SetText( "3306" )
    mysqlport.OnEnter = function( self )
        chat.AddText( self:GetValue() )
    end

    local mysqldb_text = vgui.Create( "DLabel", pnl )
    mysqldb_text:SetPos( 25, 120 )
    mysqldb_text:SetColor( Color( 0, 0, 0 ) )
    mysqldb_text:SetText( "Database" )

    local mysqldb = vgui.Create( "DTextEntry", pnl )
    mysqldb:SetPos( 25, 140 )
    mysqldb:SetSize( 150, 20 )
    mysqldb:SetText( "127.0.0.1" )
    mysqldb.OnEnter = function( self )
        chat.AddText( self:GetValue() )
    end

    local mysqluser_text = vgui.Create( "DLabel", pnl )
    mysqluser_text:SetPos( 25, 165 )
    mysqluser_text:SetColor( Color( 0, 0, 0 ) )
    mysqluser_text:SetText( "Username" )

    local mysqluser = vgui.Create( "DTextEntry", pnl )
    mysqluser:SetPos( 25, 185 )
    mysqluser:SetSize( 150, 20 )
    mysqluser:SetText( "root" )
    mysqluser.OnEnter = function( self )
        chat.AddText( self:GetValue() )
    end

    local mysqlpassword_text = vgui.Create( "DLabel", pnl )
    mysqlpassword_text:SetPos( 25, 210 )
    mysqlpassword_text:SetColor( Color( 0, 0, 0 ) )
    mysqlpassword_text:SetText( "Password" )

    local mysqlpassword = vgui.Create( "DTextEntry", pnl )
    mysqlpassword:SetPos( 25, 230 )
    mysqlpassword:SetSize( 150, 20 )
    mysqlpassword:SetText( "*****" )
    mysqlpassword.OnEnter = function( self )
        chat.AddText( self:GetValue() )
    end

    local save_button = vgui.Create( "DButton", pnl )
    save_button:SetText( "Save Settings" )					
    save_button:SetPos( 25, 290 )
    save_button:SetSize( 130, 30 )
    save_button.DoClick = function() end

    local saveconnect_button = vgui.Create( "DButton", pnl )
    saveconnect_button:SetText( "Save and Connect" )					
    saveconnect_button:SetPos( 155, 290 )
    saveconnect_button:SetSize( 130, 30 )
    saveconnect_button.DoClick = function() end

    local connect_button = vgui.Create( "DButton", pnl )
    connect_button:SetText( "Connect" )					
    connect_button:SetPos( 285, 290 )
    connect_button:SetSize( 130, 30 )
    connect_button.DoClick = function() end

    local reset_button = vgui.Create( "DButton", pnl )
    reset_button:SetText( "Reset Settings" )					
    reset_button:SetPos( 415, 290 )
    reset_button:SetSize( 130, 30 )
    reset_button.DoClick = function() end

    local breen_img = vgui.Create( "DImage", pnl )
    breen_img:SetPos( 10, 35 )
    breen_img:SetSize( 150, 150 )

    breen_img:SetImage( "msync/apdev_bw" )

    return pnl
end

function MSync.AdminPanel.InitModules( sheet ) 
    local pnl = vgui.Create( "DPanel", sheet )

    return pnl
end

function MSync.AdminPanel.InitModuleSettings( sheet ) 
    local pnl = vgui.Create( "DPanel", sheet )

    return pnl
end


function MSync.AdminPanel.InitPanel()

    --if not LocalPlayer():query("msync_admingui") then return false end;

    local panel = vgui.Create( "DFrame" )
    panel:SetSize( 600, 400 )
    panel:Center()
    panel:MakePopup()

    local sheet = vgui.Create( "DPropertySheet", panel )
    sheet:Dock( FILL )

    sheet:AddSheet( "MySQL", MSync.AdminPanel.InitMySQL( sheet ), "icon16/database.png" )
    sheet:AddSheet( "Modules", MSync.AdminPanel.InitModules( sheet ), "icon16/application.png" )
    sheet:AddSheet( "Module Settings", MSync.AdminPanel.InitModuleSettings( sheet ), "icon16/folder.png" )

end

MSync.AdminPanel.InitPanel() 