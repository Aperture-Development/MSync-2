MSync = MSync or {}
MSync.ulx = MSync.ulx or {}

function MSync.ulx.createPermissions()
    ULib.ucl.registerAccess("msync.getTable", "superadmin", "Allows player to get MSync tables", "MSync")
    ULib.ucl.registerAccess("msync.sendSettings", "superadmin", "Allows player to send settings to server", "MSync")
    ULib.ucl.registerAccess("msync.connectDB", "superadmin", "Allows player to connect the server to the database server", "MSync")
    ULib.ucl.registerAccess("msync.resetSettings", "superadmin", "Allows the player to reset the settings", "MSync")
    ULib.ucl.registerAccess("msync.loadModule", "superadmin", "Allows the player to load a module", "MSync")
    ULib.ucl.registerAccess("msync.reloadModules", "superadmin", "Allows the player to reload all modules", "MSync")
    ULib.ucl.registerAccess("msync.toggleModule", "superadmin", "Allows the player to enable/disable modules", "MSync"	)
    ULib.ucl.registerAccess("msync.openAdminGUI", "superadmin", "Allows the player to see the admin gui", "MSync"	)
end
--ucl.registerAccess("msync.", "superadmin", "", "MSync"	)
