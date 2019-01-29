MSync = MSync or {}
MSync.modules = MSync.modules or {}
MSync.modules.MBSync = MSync.modules.SampleModule or {}
--[[
 * @file       cl_samplemodule.lua
 * @package    Sample Module
 * @author     Aperture Development
 * @license    root_dir/LICENCE
 * @version    1.0.0
]]

--[[
    Define name, description and module identifier
]]
MSync.modules.MBSync.info = {
    Name = "MySQL Ban Sync",
    ModuleIdentifier = "MBSync",
    Description = "Synchronise band across your servers",
    Version = "0.0.1"
}

--[[
    Define additional functions that are later used
]]
function MSync.modules.MBSync.init() 

    function MSync.modules.SampleModule.SampleFunction()
        return true
    end

end

--[[
    Define the admin panel for the settings
]]
function MSync.modules.MBSync.adminPanel(sheet)
    local pnl = vgui.Create( "DPanel", sheet )
    pnl:Dock(FILL)
    return pnl
end

--[[
    Define the client panel for client usage ( or as example: use it as additional admin gui which does not need msync.admingui permission)
]]
function MSync.modules.MBSync.clientPanel()
    local pnl = vgui.Create( "DPanel" )

    return pnl
end

--[[
    Define net receivers and util.AddNetworkString
]]
function MSync.modules.MBSync.net() 
    net.Receive( "my_message", function( len, pl )
        if ( IsValid( pl ) and pl:IsPlayer() ) then
            print( "Message from " .. pl:Nick() .. " received. Its length is " .. len .. "." )
        else
            print( "Message from server received. Its length is " .. len .. "." )
        end
    end )
end

--[[
    Define ulx Commands and overwrite common ulx functions (module does not get loaded until ulx has fully been loaded)
]]
function MSync.modules.MBSync.ulx() 
    
end

--[[
    Define hooks your module is listening on e.g. PlayerDisconnect
]]
function MSync.modules.MBSync.hooks() 
    hook.Add("initialize", "msync_sampleModule_init", function()
        
    end)
end

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules.MBSync.info