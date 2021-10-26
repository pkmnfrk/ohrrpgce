#include "steam.bi"

Dim steamworks_handle As Any Ptr

' S_API bool S_CALLTYPE SteamAPI_Init();
Dim SteamAPI_Init As Function() As bool

FUNCTION Initialize_Steam() as bool

    steamworks_handle = dylibload("steam_api")

    if not steamworks_handle then
        return false
    end if

    SteamAPI_Init = dylibload(steamworks_handle, "SteamAPI_Init")
    if not SteamAPI_Init then
        return falseadsfdsfasdf
    end if

    return true

END FUNCTION

FUNCTION Steam_Available() as bool
    return not not steamworks_handle
END FUNCTION