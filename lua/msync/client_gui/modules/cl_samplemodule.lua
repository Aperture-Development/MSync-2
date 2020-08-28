MSync = MSync or {}
MSync.modules = MSync.modules or {}
MSync.modules.SampleModule = MSync.modules.SampleModule or {}
--[[
 * @file       cl_samplemodule.lua
 * @package    Sample Module
 * @author     Aperture Development
 * @license    root_dir/LICENCE
 * @version    1.0.1
]]

--[[
    Define name, description and module identifier
]]
local info = {
    Name = "Sample Module",
    ModuleIdentifier = "SampleModule",
    Description = "A basic example module on how to create modules",
    Version = "1.0.1"
}

--[[
    Prepare Module
]]
MSync.modules[info.ModuleIdentifier] = MSync.modules[info.ModuleIdentifier] or {}
MSync.modules[info.ModuleIdentifier].info = info

--[[
    Define additional functions that are later used
]]
MSync.modules[info.ModuleIdentifier].init = function()

    function MSync.modules.SampleModule.SampleFunction()
        return true
    end

end

--[[
    Define the admin panel for the settings
]]
MSync.modules[info.ModuleIdentifier].adminPanel = function(sheet)
    local pnl = vgui.Create( "DPanel", sheet )
    pnl:Dock(FILL)
    return pnl
end

--[[
    Define the client panel for client usage ( or as example: use it as additional admin gui which does not need msync.admingui permission)
]]
MSync.modules[info.ModuleIdentifier].clientPanel = function()
    local pnl = vgui.Create( "DPanel" )

    return pnl
end

--[[
    Define net receivers and util.AddNetworkString
]]
MSync.modules[info.ModuleIdentifier].net = function()
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
MSync.modules[info.ModuleIdentifier].ulx = function()

end

--[[
    Define hooks your module is listening on e.g. PlayerDisconnect
]]
MSync.modules[info.ModuleIdentifier].hooks = function()
    hook.Add("initialize", "msync_sampleModule_init", function()

    end)
end

--[[
    Define a function to run on the clients when the module gets disabled
]]
MSync.modules[info.ModuleIdentifier].disable = function()

end

--[[
    Return info ( Just for single module loading )
]]
return MSync.modules[info.ModuleIdentifier].info