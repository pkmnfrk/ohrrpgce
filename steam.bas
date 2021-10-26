#include "common_base.bi"
#include "steam.bi"

type ISteamUserStats as any ptr

dim shared steamworks_handle as any ptr = null

' S_API bool S_CALLTYPE SteamAPI_Init();
dim shared SteamAPI_Init as function() As boolint
' S_API void S_CALLTYPE SteamAPI_Shutdown();
dim shared SteamAPI_Shutdown as sub()
' S_API bool S_CALLTYPE SteamAPI_RestartAppIfNecessary( uint32 unOwnAppID );
dim shared SteamAPI_RestartAppIfNecessary as function( byval unOwnAppID as integer ) as boolint

' S_API ISteamUserStats *SteamAPI_SteamUserStats_v012();
dim shared SteamAPI_SteamUserStats_v012 as function () as ISteamUserStats
' S_API bool SteamAPI_ISteamUserStats_RequestCurrentStats( ISteamUserStats* self );
dim shared SteamAPI_ISteamUserStats_RequestCurrentStats as function(byval self as ISteamUserStats) as boolint
' S_API bool SteamAPI_ISteamUserStats_SetAchievement( ISteamUserStats* self, const char * pchName );
dim shared SteamAPI_ISteamUserStats_SetAchievement as function(byval self as ISteamUserStats, byval name as string) as boolint
' S_API bool SteamAPI_ISteamUserStats_ClearAchievement( ISteamUserStats* self, const char * pchName );
dim shared SteamAPI_ISteamUserStats_ClearAchievement as function(byval self as ISteamUserStats, byval name as string) as boolint
' S_API bool SteamAPI_ISteamUserStats_StoreStats( ISteamUserStats* self );
dim shared SteamAPI_ISteamUserStats_StoreStats as function(byval self as ISteamUserStats) as boolint

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
    MUSTLOAD(steamworks_handle, SteamAPI_SteamUserStats_v012)
    MUSTLOAD(steamworks_handle, SteamAPI_ISteamUserStats_RequestCurrentStats)
    MUSTLOAD(steamworks_handle, SteamAPI_ISteamUserStats_SetAchievement)
    MUSTLOAD(steamworks_handle, SteamAPI_ISteamUserStats_ClearAchievement)
    MUSTLOAD(steamworks_handle, SteamAPI_ISteamUserStats_StoreStats)

    if SteamAPI_Init() = false then
        debug "unable to initialize steamworks"
        uninitialize_Steam()
        return false
    end if

    ' todo: is this necessary?
    ' if SteamAPI_RestartAppIfNecessary( ourAppId ) <> false then
    '     debug "Steam seems to want to restart the application for some reason"
    ' end if

    ' this section is probably all temporary
    ' also it doesn't work, because of the highly asyncronous nature of steamworks
    dim stats as ISteamUserStats = SteamAPI_SteamUserStats_v012()

    if stats = null then
        debug "Unable to obtain user stats object"
    else
        if SteamAPI_ISteamUserStats_RequestCurrentStats(stats) = false then
            debug "Unable to request current stats"
        else
            if SteamAPI_ISteamUserStats_SetAchievement(stats, "ACH_WIN_ONE_GAME") = false then
                debug "unable to set an achievement"
            else
                if SteamAPI_ISteamUserStats_StoreStats(stats) = false then
                    debug "unable to persist stats"
                else
                    debug "rewarded achievement"
                end if
            end if
        end if
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