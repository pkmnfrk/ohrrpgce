#IFNDEF STEAM_BI
#DEFINE STEAM_BI

declare function initialize_steam() as boolean
declare sub uninitialize_steam()
declare function steam_available() as boolean
declare sub run_steam_frame()
declare sub reward_achievement(id as string)
declare sub clear_achievement(id as string)
declare sub notify_achievement_progress(id as string, progress as integer, max_progress as integer)

#ENDIF
