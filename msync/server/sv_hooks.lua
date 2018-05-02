hook.Add( "Initialize", "msync.initScript", function()
    MSync.function.loadSettings()

    timer.Create("msync.checkForULXandULib", 5, 0, function()
        if not ULX and ULib then return end;

        MSync.mysql.initialize() 
    end)
end)

hook.Add("PlayerInitialSpawn", "msync.createUser", function( ply )
    MSync.mysql.addUser(ply)
end)