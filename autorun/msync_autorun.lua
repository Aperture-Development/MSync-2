hook.Add("Initialize", "msync_init", function()
    include("/msync/sh_init.lua")
    include("/msync/server/sv_init.lua")
    include("/msync/client_gui/cl_init.lua")

    print("[MSync2] Initialize")
end)