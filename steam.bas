#include "common_base.bi"
#include "steam.bi"


dim shared steamworks_handle as any ptr = null

' S_API bool S_CALLTYPE SteamAPI_Init();
dim shared SteamAPI_Init as function() As boolint
' S_API void S_CALLTYPE SteamAPI_Shutdown();
dim shared SteamAPI_Shutdown as sub()
' S_API bool S_CALLTYPE SteamAPI_RestartAppIfNecessary( uint32 unOwnAppID );
dim shared SteamAPI_RestartAppIfNecessary as function( byval unOwnAppID as integer ) as boolint

#macro MUSTLOAD(hfile, procedure)
	procedure = dylibsymbol(hfile, #procedure)
	if procedure = NULL then
        debug "Was not able to find " & #procedure
        ' do this instead of uninitialize_steam(), since it assumes we succeeded in initializing
        dylibfree(hFile)
        hFile = null
		return NO
	end if
#endmacro

function initialize_steam() as boolean

    steamworks_handle = dylibload("steam_api")

    if steamworks_handle = null then
        debug "Was not able to open steam_api.dll"
        return false
    end if

    MUSTLOAD(steamworks_handle, SteamAPI_Init)
    MUSTLOAD(steamworks_handle, SteamAPI_Shutdown)
    MUSTLOAD(steamworks_handle, SteamAPI_RestartAppIfNecessary)

    if SteamAPI_Init() = false then
        debug "unable to initialize steamworks"
        uninitialize_Steam()
        return false
    end if

    ' todo: is this necessary?
    ' if SteamAPI_RestartAppIfNecessary( ourAppId ) <> false then
    '     debug "Steam seems to want to restart the application for some reason"
    ' end if

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