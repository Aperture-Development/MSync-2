MSync = MSync or {}

ucl.registerAccess("msync.getTable", "superadmin", "Allows player to get MSync tables", "MSync")
ucl.registerAccess("msync.sendSettings", "superadmin", "Allows player to send settings to server", "MSync")
ucl.registerAccess("msync.connectDB", "superadmin", "Allows player to connect the server to the database server", "MSync")
ucl.registerAccess("msync.resetSettings", "superadmin", "Allows the player to reset the settings", "MSync")
ucl.registerAccess("msync.loadModule", "superadmin", "Allows the player to load a module", "MSync")
ucl.registerAccess("msync.reloadModules", "superadmin", "Allows the player to reload all modules", "MSync")
ucl.registerAccess("msync.toggleModule", "superadmin", "Allows the player to enable/disable modules", "MSync"	)
ucl.registerAccess("msync.openAdminGUI", "superadmin", "Allows the player to see the admin gui", "MSync"	)
--ucl.registerAccess("msync.", "superadmin", "", "MSync"	)
