MSync = Msync or {}
MSync.modules = MSync.modules = {}
MSync.modules.SampleModule = MSync.modules.SampleModule or {}

MSync.modules.SampleModule.info = {
    Name = "Sample Module",
    Description = "A basic example module on how to create modules"
}


function MSync.Modules.SampleModule.init() 
    MSync.DBServer:query( [[
        CREATE TABLE IF NOT EXISTS `tbl_SampleModule` (
            SampleData INT
        );
    ]] )


end

function MSync.Modules.SampleModule.net() 
    net.Receive( "my_message", function( len, pl )
        if ( IsValid( pl ) and pl:IsPlayer() ) then
            print( "Message from " .. pl:Nick() .. " received. Its length is " .. len .. "." )
        else
            print( "Message from server received. Its length is " .. len .. "." )
        end
    end )
end

function MSync.Modules.SampleModule.ulx() 
    
end

function MSync.Modules.SampleModule.hooks() 
    hook.Add("initialize", "msync_sampleModule_init", function()
        
    end)
end