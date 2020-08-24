MSync = MSync or {}
MSync.net = MSync.net or {}

MSYNC_DBG_ERROR = 0
MSYNC_DBG_WARNING = 1
MSYNC_DBG_INFO = 2
MSYNC_DBG_DEBUG = 3

local debugLevels = {
    [MSYNC_DBG_ERROR] = {
        color = Color(255, 44, 44),
        prefix = "[MSync_ERROR]"
    },
    [MSYNC_DBG_WARNING] = {
        color = Color(255, 160, 17),
        prefix = "[MSync_WARN]"
    },
    [MSYNC_DBG_INFO] = {
        color = Color(255, 255, 255),
        prefix = "[MSync_INFO]"
    },
    [MSYNC_DBG_DEBUG] = {
        color = Color(180, 180, 180),
        prefix = "[MSync_DEGUB]"
    }
}

--[[
    MSync debug level convar
]]
MSync.DebugCVar = CreateConVar( "msync_debug", 0, FCVAR_REPLICATED+FCVAR_ARCHIVE, "Set the MSync debug level. 0 = Error, 1 = Warning, 2 = Info, 3 = Debug", 0, 3 )

--[[
    Description: MSync logging function, allowing log levels and formated console logs
    Arguments:
        - logLevel [number] - The log level this message requires to be sent. Valid Globals are: MSYNC_DBG_ERROR, MSYNC_DBG_WARNING, MSYNC_DBG_INFO and MSYNC_DBG_DEBUG
        - logMessage [string] - The log message to be sent into the console ( should Prefix the module like "[MBSync]...")
    Returns:
        - Nothing
]]
MSync.log = function(logLevel, logMessage)
    if not type(logLevel) == "number" then return end

    local DebugCvarValue = MSync.DebugCVar:GetInt()

    if DebugCvarValue >= logLevel then
        if debugLevels[logLevel] then
            MsgC(debugLevels[logLevel].color, debugLevels[logLevel].prefix.." "..logMessage.."\n")
        else
            MsgC(Color(255, 255, 255), "[MSync_LOG] "..logMessage.."\n")
        end
        -- Feature(?): Log files? Client GUI log viewer?
        --file.Append( "msync/logs/msync_"..os.date("[]")..".log", os.date("[]") )
    end
end