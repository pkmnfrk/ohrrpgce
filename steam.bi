#IFNDEF STEAM_BI
#DEFINE STEAM_BI

declare function initialize_steam() as boolean
declare sub uninitialize_steam()
declare function steam_available() as boolean
declare sub run_steam_frame()

#ENDIF
