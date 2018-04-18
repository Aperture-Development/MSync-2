MSync           = MSync     or {}
MSync.net       = MSync.net or {}
MSync.mrs       = MSync.mrs or {}
MSync.mws       = MSync.mws or {}
MSync.mbsync    = MSync.mbsync or {}
MSync.mrsync    = MSync.mrsync or {}
MSync.mysql     = MSync.mysql or {}
MSync.settings  = MSync.settings or {}
MSync.function  = MSync.function or {}


function MSync.function.loadServer()

    include("/msync/server/sv_net.lua")
    include("/msync/server/sv_settings.lua")
    include("/msync/server/sv_mysql.lua")
    include("/msync/server/")
    include("/msync/server/")

end