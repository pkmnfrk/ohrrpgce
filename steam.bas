#include "common_base.bi"
#include "steam.bi"


dim shared steamworks_handle as any ptr = null

' S_API bool S_CALLTYPE SteamAPI_Init();
dim shared SteamAPI_Init as function() As boolint

function initialize_steam() as boolean

    steamworks_handle = dylibload("steam_api")

    if steamworks_handle = null then
        debug "Was not able to open steam_api.dll"
        return false
    end if

    SteamAPI_Init = dylibsymbol(steamworks_handle, "SteamAPI_Init")
    if SteamAPI_Init = 0 then
        debug "was not able to find SteamAPI_Init"
        return false
    end if

    if SteamAPI_Init() = false then
        debug "unable to initialize steamworks"
        uninitialize_Steam()
        return false
    end if

    return true

end function

sub uninitialize_steam()
    if steamworks_handle <> null then
        dylibfree(steamworks_handle)
        steamworks_handle = null
    end if
end sub

function steam_available() as boolean
    return steamworks_handle <> null
end function