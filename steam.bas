#include "common_base.bi"
#include "steam.bi"
#include "steam_internal.bi"

dim shared steamworks_handle as any ptr = null

' basic init/deinit
' S_API bool S_CALLTYPE SteamAPI_Init();
dim shared SteamAPI_Init as function() As boolint
' S_API void S_CALLTYPE SteamAPI_Shutdown();
dim shared SteamAPI_Shutdown as sub()
' S_API bool S_CALLTYPE SteamAPI_RestartAppIfNecessary( uint32 unOwnAppID );
dim shared SteamAPI_RestartAppIfNecessary as function( byval unOwnAppID as uinteger ) as boolint

' callback infrastructure
' S_API HSteamPipe S_CALLTYPE SteamAPI_GetHSteamPipe();
dim shared SteamAPI_GetHSteamPipe as function() as HSteamPipe
' S_API void S_CALLTYPE SteamAPI_ManualDispatch_Init();
dim shared SteamAPI_ManualDispatch_Init as sub()
' S_API void S_CALLTYPE SteamAPI_ManualDispatch_RunFrame( HSteamPipe hSteamPipe );
dim shared SteamAPI_ManualDispatch_RunFrame as sub( byval hSteamPipe as HSteamPipe )
' S_API bool S_CALLTYPE SteamAPI_ManualDispatch_GetNextCallback( HSteamPipe hSteamPipe, CallbackMsg_t *pCallbackMsg );
dim shared SteamAPI_ManualDispatch_GetNextCallback as function ( hSteamPipe as HSteamPipe, pCallbackMsg as CallbackMsg_t ptr) as boolint
' S_API void S_CALLTYPE SteamAPI_ManualDispatch_FreeLastCallback( HSteamPipe hSteamPipe );
dim shared SteamAPI_ManualDispatch_FreeLastCallback as sub ( hSteamPipe as HSteamPipe)
' S_API bool S_CALLTYPE SteamAPI_ManualDispatch_GetAPICallResult( HSteamPipe hSteamPipe, SteamAPICall_t hSteamAPICall, void *pCallback, int cubCallback, int iCallbackExpected, bool *pbFailed );
dim shared SteamAPI_ManualDispatch_GetAPICallResult as function ( hSteamPipe as HSteamPipe, hSteamAPICall as SteamAPICall_t, pCallback as any ptr, cubCallback as integer,  iCallbackExpected as integer, pbFAiled as boolint ptr) as boolint

' achievements
' S_API ISteamUserStats *SteamAPI_SteamUserStats_v012();
dim shared SteamAPI_SteamUserStats_v012 as function () as ISteamUserStats ptr
' S_API bool SteamAPI_ISteamUserStats_RequestCurrentStats( ISteamUserStats* self );
dim shared SteamAPI_ISteamUserStats_RequestCurrentStats as function(byval self as ISteamUserStats ptr) as boolint
' S_API bool SteamAPI_ISteamUserStats_SetAchievement( ISteamUserStats* self, const char * pchName );
dim shared SteamAPI_ISteamUserStats_SetAchievement as function(byval self as ISteamUserStats ptr, byval name as const zstring ptr) as boolint
' S_API bool SteamAPI_ISteamUserStats_ClearAchievement( ISteamUserStats* self, const char * pchName );
dim shared SteamAPI_ISteamUserStats_ClearAchievement as function(byval self as ISteamUserStats ptr, byval name as const zstring ptr) as boolint
' S_API bool SteamAPI_ISteamUserStats_StoreStats( ISteamUserStats* self );
dim shared SteamAPI_ISteamUserStats_StoreStats as function(byval self as ISteamUserStats ptr) as boolint


dim shared steam_user_stats as ISteamUserStats ptr

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

    #ifdef __FB_WIN32__
        #ifdef __FB_64BIT__
            'Future, although not yet supported
            #define STEAM_LIB "steam_api64"
            #define STEAM_FULL_FNAME "steam_api64.dll"
        #else
            #define STEAM_LIB "steam_api"
            #define STEAM_FULL_FNAME "steam_api.dll"
        #endif
    #elseif defined(__FB_DARWIN__)
        #define STEAM_LIB "steam_api"
        #define STEAM_FULL_FNAME "libsteam_api.dylib"
    #else
        'Either Linux or maybe a BSD (on which Steam isn't officially support but can be run)
        #define STEAM_LIB "steam_api"
        #define STEAM_FULL_FNAME "libsteam_api.so"
    #endif

    steamworks_handle = dylibload(STEAM_LIB)
    if steamworks_handle = null then
        debug "Was not able to open " STEAM_FULL_FNAME
        return false
    end if

    MUSTLOAD(steamworks_handle, SteamAPI_Init)
    MUSTLOAD(steamworks_handle, SteamAPI_Shutdown)
    MUSTLOAD(steamworks_handle, SteamAPI_RestartAppIfNecessary)
    MUSTLOAD(steamworks_handle, SteamAPI_GetHSteamPipe)
    MUSTLOAD(steamworks_handle, SteamAPI_ManualDispatch_Init)
    MUSTLOAD(steamworks_handle, SteamAPI_ManualDispatch_RunFrame)
    MUSTLOAD(steamworks_handle, SteamAPI_ManualDispatch_GetNextCallback)
    MUSTLOAD(steamworks_handle, SteamAPI_ManualDispatch_FreeLastCallback)
    MUSTLOAD(steamworks_handle, SteamAPI_ManualDispatch_GetAPICallResult)
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

    SteamAPI_ManualDispatch_Init()

    ' this section is probably all temporary
    ' also it doesn't work, because of the highly asyncronous nature of steamworks
    steam_user_stats = SteamAPI_SteamUserStats_v012()

    if steam_user_stats = null then
        debug "Unable to obtain user stats object"
    else
        if SteamAPI_ISteamUserStats_RequestCurrentStats(steam_user_stats) = false then
            debug "Unable to request current stats"
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

#macro CALLBACK_HANDLER(typ, handler)
    case typ.k_iCallback
        debug "Steam: " & #typ
        debug "message length: " & callback.m_cubParam
        dim typ##Msg as typ ptr = cast(typ ptr, callback.m_pubParam)
        handler(typ##Msg)
#endmacro

#macro IGNORE(id)
    case id
        debug "Ignored Steam id: " & id
#endmacro

dim shared achieve_timer as integer = -1

sub run_steam_frame()
    if steam_available() = false then return

    if achieve_timer >= 0 then
        achieve_timer -= 1
        if achieve_timer < 0 then
            if SteamAPI_ISteamUserStats_SetAchievement(steam_user_stats, "ACH_WIN_ONE_GAME") = false then
                debug "unable to set an achievement"
            else
                if SteamAPI_ISteamUserStats_StoreStats(steam_user_stats) = false then
                    debug "unable to persist stats"
                else
                    debug "rewarded achievement"
                end if
            end if
        end if
    end if

    ' debug "run_steam_frame"

    ' HSteamPipe hSteamPipe = SteamAPI_GetHSteamPipe(); // See also SteamGameServer_GetHSteamPipe()
    dim hSteamPipe as HSteamPipe = SteamAPI_GetHSteamPipe()
	' SteamAPI_ManualDispatch_RunFrame( hSteamPipe )
    SteamAPI_ManualDispatch_RunFrame(hSteamPipe)
	' CallbackMsg_t callback;
    dim callback as CallbackMsg_t
	' while ( SteamAPI_ManualDispatch_GetNextCallback( hSteamPipe, &callback ) )
    while SteamAPI_ManualDispatch_GetNextCallback(hSteamPipe, @callback)
	' {
	' 	// Check for dispatching API call results
	' 	if ( callback.m_iCallback == SteamAPICallCompleted_t::k_iCallback )
        if callback.m_iCallback = 703 then
	' 	{
	' 		SteamAPICallCompleted_t *pCallCompleted = (SteamAPICallCompleted_t *)callback.
            dim pCallCompleted as SteamAPICallCompleted_t ptr = @callback
	' 		void *pTmpCallResult = malloc( pCallback->m_cubParam );
            dim pTmpCallResult as any ptr = allocate(pCallCompleted->m_cubParam)
	' 		bool bFailed;
            dim bFailed as boolint
	' 		if ( SteamAPI_ManualDispatch_GetAPICallResult( hSteamPipe, pCallCompleted->m_hAsyncCall, pTmpCallResult, pCallback->m_cubParam, pCallback->m_iCallback, &bFailed ) )
            if SteamAPI_ManualDispatch_GetAPICallResult ( hSteamPipe, pCallCompleted->m_hAsyncCall, pTmpCallResult, pCallCompleted->m_cubParam, pCallCompleted->m_iCallback, @bFailed ) then
	' 		{
	' 			// Dispatch the call result to the registered handler(s) for the
	' 			// call identified by pCallCompleted->m_hAsyncCall
                debug "Steam: Call Completed handler"
	' 		}
            end if
	' 		free( pTmpCallResult );
            deallocate(pTmpCallResult)
	' 	}
	' 	else
        else
	' 	{
	' 		// Look at callback.m_iCallback to see what kind of callback it is,
	' 		// and dispatch to appropriate handler(s)
            select case callback.m_iCallback
                CALLBACK_HANDLER(UserStatsReceived_t, OnUserStatsReceived)
                ' these are messages that we either don't know the identity of, or we don't care
                IGNORE(715)
                IGNORE(304)
                IGNORE(711)
                IGNORE(903)
                IGNORE(501)
                IGNORE(502) ' favorites list changed
                IGNORE(1006)
                case else
                    debug "Steam: Some other handler: " & callback.m_iCallback
            end select
	' 	}
        end if
	' 	SteamAPI_ManualDispatch_FreeLastCallback( hSteamPipe );
        SteamAPI_ManualDispatch_FreeLastCallback(hSteamPipe)
	' }
    wend
end sub

sub OnUserStatsReceived(msg as UserStatsReceived_t ptr)
    debug "On User Stats Received"
    if SteamAPI_ISteamUserStats_ClearAchievement(steam_user_stats, "ACH_WIN_ONE_GAME") = false then
        debug "unable to clear an achievement"
    end if

    achieve_timer = 1000
end sub