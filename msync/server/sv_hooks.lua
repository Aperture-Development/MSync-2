--[[
    Description: hook to initialize MSync 2
    Returns: nothing
]]
hook.Add( "Initialize", "msync.initScript", function()
    MSync.func.loadSettings()
    
    --[[
        Description: timer to prevent loading before ULX
        Returns: nothing
    ]]        
    timer.Create("msync.checkForULXandULib", 5, 0, function()
        if not ULX and ULib then return end;

        MSync.mysql.initialize() 
        MSync.ulx.createPermissions()
    end)
end)

--[[
        Description: Creates a entry to the database for every player that joins.
        Returns: nothing
    ]]     
hook.Add("PlayerInitialSpawn", "msync.createUser", function( ply )
    MSync.mysql.addUser(ply)
end)