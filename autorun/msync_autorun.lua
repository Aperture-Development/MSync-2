if SERVER then 
    include("/msync/sh_init.lua")
    AddCSLuaFile("/msync/sh_init.lua")

    include("/msync/server/sv_init.lua")

    MSync.function.loadServer()

    for k, v in pairs(file.Find("msync/client_gui/*.lua", "LUA")[1]) do
        AddCSLuaFile("msync/client_gui/"..v)
    end
elseif CLIENT then
    include("/msync/sh_init.lua")

    include("/msync/client_gui/cl_admin_gui.lua")
    include("/msync/client_gui/cl_init.lua")
    include("/msync/client_gui/cl_net.lua")
    include("/msync/client_gui/cl_modules.lua")

end