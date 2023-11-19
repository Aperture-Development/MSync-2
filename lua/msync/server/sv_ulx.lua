MSync = MSync or {}
MSync.ulx = MSync.ulx or {}

--[[
    Description: Function to create the ULX permissions
    Returns: nothing
]]
function MSync.ulx.createPermissions()
    MSync.log(MSYNC_DBG_DEBUG, "Creating ULX permissions")
    ULib.ucl.registerAccess("msync.getTable", "superadmin", "Allows player to get MSync tables", "MSync")
    ULib.ucl.registerAccess("msync.sendSettings", "superadmin", "Allows player to send settings to server", "MSync")
    ULib.ucl.registerAccess("msync.connectDB", "superadmin", "Allows player to connect the server to the database server", "MSync")
    ULib.ucl.registerAccess("msync.resetSettings", "superadmin", "Allows the player to reset the settings", "MSync")
    ULib.ucl.registerAccess("msync.loadModule", "superadmin", "Allows the player to load a module", "MSync")
    ULib.ucl.registerAccess("msync.reloadModules", "superadmin", "Allows the player to reload all modules", "MSync")
    ULib.ucl.registerAccess("msync.toggleModule", "superadmin", "Allows the player to enable/disable modules", "MSync"	)
    ULib.ucl.registerAccess("msync.getSettings", "superadmin", "Allows the player to get the server settings", "MSync"	)
    ULib.ucl.registerAccess("msync.getModules", "superadmin", "Allows the player to get the server settings", "MSync"	)
end

--[[
    Description: Function to create the ULX commands
    Returns: nothing
]]
function MSync.ulx.createCommands()
    MSync.log(MSYNC_DBG_DEBUG, "Creating ULX commands")
    function MSync.func.openAdminGUI(calling_ply)
        if not IsValid(calling_ply) then return end;
        if not calling_ply:query("msync.openAdminGUI") then return end;

        MSync.net.openAdminGUI(calling_ply)
    end
    local OpenAdminGUI = ulx.command( "MSync", "msync.openAdminGUI", MSync.func.openAdminGUI, "!msync" )
    OpenAdminGUI:defaultAccess( ULib.ACCESS_SUPERADMIN )
    OpenAdminGUI:help( "Opens MSync Settings." )
end
--ucl.registerAccess("msync.", "superadmin", "", "MSync"	)
