if SERVER then
    include("msync/sh_init.lua")
    AddCSLuaFile("msync/sh_init.lua")

    include("msync/server/sv_init.lua")

    MSync.func.loadServer()
elseif CLIENT then
    include("msync/sh_init.lua")

    include("msync/client_gui/cl_admin_gui.lua")
    include("msync/client_gui/cl_init.lua")
    include("msync/client_gui/cl_net.lua")
    include("msync/client_gui/cl_modules.lua")

end