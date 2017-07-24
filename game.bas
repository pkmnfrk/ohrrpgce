'OHRRPGCE GAME - Main module
'(C) Copyright 1997-2017 James Paige and Hamster Republic Productions
'Please read LICENSE.txt for GPL License details and disclaimer of liability
'See README.txt for code docs and apologies for crappyness of this code ;)
'

#include "config.bi"
#include "ver.txt"
#include "udts.bi"
#include "game_udts.bi"
#include "slices.bi"
#include "allmodex.bi"
#include "common.bi"
#include "gglobals.bi"
#include "const.bi"
#include "scrconst.bi"
#include "uiconst.bi"
#include "loading.bi"
#include "savegame.bi"
#include "scriptcommands.bi"
#include "yetmore2.bi"
#include "moresubs.bi"
#include "walkabouts.bi"
#include "menustuf.bi"
#include "bmodsubs.bi"
#include "bmod.bi"
#include "scripting.bi"
#include "sliceedit.bi"
#include "purchase.bi"
#include "game.bi"
#include "gfx.bi"
#include "pathfinding.bi"


'local subs and functions
DECLARE SUB checkdoors ()
DECLARE SUB usedoor (byval door_id as integer)
DECLARE FUNCTION want_to_check_for_walls(byval who as integer) as bool
DECLARE FUNCTION hero_should_ignore_walls(byval who as integer) as bool
DECLARE SUB update_npcs ()
DECLARE SUB pick_npc_action(npci as NPCInst, npcdata as NPCType)
DECLARE FUNCTION perform_npc_move(byval npcnum as integer, npci as NPCInst, npcdata as NPCType) as bool
DECLARE SUB npchitwall (npci as NPCInst, npcdata as NPCType)
DECLARE FUNCTION find_useable_npc () as integer
DECLARE SUB interpret_scripts ()
DECLARE SUB update_heroes(force_step_check as bool=NO)
DECLARE SUB doloadgame(byval load_slot as integer)
DECLARE SUB reset_game_final_cleanup()
DECLARE FUNCTION should_skip_this_timer(timercontext as TimerContextEnum, tmr as PlotTimer) as bool
DECLARE SUB update_menu_states ()
DECLARE SUB check_debug_keys()
DECLARE SUB battle_formation_testing_menu()
DECLARE SUB queue_music_change (byval song as integer)
DECLARE SUB check_for_queued_music_change ()
DECLARE SUB npcmove_random_wander(npci as NPCInst)
DECLARE SUB npcmove_walk_ahead(npci as NPCInst)
DECLARE SUB npcmove_meandering_chase(npci as NPCInst, byval avoid_instead as bool = NO)
DECLARE SUB npcmove_meandering_avoid(npci as NPCInst)
DECLARE SUB npcmove_walk_in_place(npci as NPCInst)
DECLARE SUB npcmove_direct_chase(npci as NPCInst, npcdata as NPCType)
DECLARE SUB npcmove_direct_avoid(npci as NPCInst, npcdata as NPCType)
DECLARE SUB npcmove_change_dir_and_walk_ahead(npci as NPCInst, byval new_dir as integer)
DECLARE SUB npcmove_rotate_and_walk_ahead(npci as NPCInst, byval rota as integer, byval amount as integer = 1)
DECLARE SUB npcmove_follow_walls(npci as NPCInst, npcdata as NPCType, byval direction as integer)
DECLARE SUB npcmove_pathfinding_chase(npci as NPCInst, npcdata as NPCType)
DECLARE FUNCTION catindex(byval rank as integer) as integer
DECLARE FUNCTION user_triggered_main_menu() as bool
DECLARE FUNCTION player_menu_should_close() as bool
DECLARE SUB debug_mouse_state()
DECLARE FUNCTION find_doorlink_id (byval door_id as integer, thisdoor as door, door_links() as Doorlink) as integer

'=================================== Globals ==================================

'shared module variables
DIM SHARED harmtileflash as bool = NO

'global variables
DIM gam as GameState
gam.timer_offset = TIMER
DIM txt as TextBoxState
REDIM gen(499) as integer
DIM gen_reld_doc as DocPtr
DIM persist_reld_doc as DocPtr
REDIM tag(1000) as integer '16000 bitsets
REDIM onetime(1000) as integer '16000 bitsets

REDIM herotags(maxMaxHero) as HeroTagsCache
REDIM itemtags(maxMaxItems) as ItemTagsCache
REDIM statnames() as string

'Party stuff
REDIM spell(40, 3, 23) as integer
REDIM lmp(40, 7) as integer
REDIM eqstuf(40, 4) as integer
REDIM inventory(inventoryMax) as InventSlot
DIM gold as integer

'Hero walkabout (caterpillar) data
'Noninterpolated
REDIM herow(3) as HeroWalkabout
'Interpolated
'The cats array store a history of recent leader positions.
'The size is: (max_number_of_heroes - 1) * (tile_size / leader_speed) + 1
'but for simplicity we just dim it for the slowest possible leader speed of 1, so:
'(4 - 1) * (20 / 1) + 1 = 61
' so 61 elements is 0-60
REDIM cats(60) as CaterpillarHistory

REDIM npcs(0) as NPCType
REDIM npc(299) as NPCInst

DIM vstate as VehicleState

DIM mapx as integer
DIM mapy as integer
DIM mapsizetiles as XYPair  'Size of the map in tiles

'Map
REDIM gmap(0) as integer  'sized later
REDIM maptiles(0) as TileMap
DIM pass as TileMap
DIM foemap as TileMap
DIM zmap as ZoneMap
REDIM tilesets(maplayerMax) as TilesetData ptr  'tilesets is fixed size at the moment. It must always be at least as large as the number of layers on a map

'Graphics
DIM vpage as integer
DIM dpage as integer
REDIM master(255) as RGBcolor
REDIM uilook(uiColorLast) as integer
REDIM boxlook(uiBoxLast) as BoxStyle
REDIM current_font(1023) as integer

REDIM buffer(16384) as integer 'FIXME: when can we get rid of this?

DIM fadestate as bool
DIM presentsong as integer
DIM backcompat_sound_slot_mode as bool
REDIM backcompat_sound_slots(7) as integer

DIM fatal as bool
DIM checkfatal as bool
DIM lastformation as integer
DIM lastsaveslot as integer

DIM usepreunlump as bool
DIM exename as string
DIM game as string
DIM sourcerpg as string
DIM savefile as string
DIM workingdir as string
DIM documents_dir as string
DIM prefsdir as string
DIM config_file as string
DIM app_dir as string

DIM lump_reloading as LumpReloadOptions
lump_reloading.gmap.mode = loadmodeAlways
lump_reloading.maptiles.mode = loadmodeAlways
lump_reloading.passmap.mode = loadmodeAlways
lump_reloading.foemap.mode = loadmodeAlways
lump_reloading.zonemap.mode = loadmodeAlways
lump_reloading.npcl.mode = loadmodeMerge
lump_reloading.npcd.mode = loadmodeAlways
lump_reloading.hsp.mode = loadmodeNever

'Menu Data
DIM menu_set as MenuSet
REDIM menus(0) as MenuDef 'This is an array because it holds a stack of heirarchial menus (resized as required)
REDIM mstates(0) as MenuState
DIM topmenu as integer = -1

REDIM csetup(12) as integer
REDIM carray(13) as integer
REDIM joy(14) as integer
REDIM gotj(7) as bool

'Script interpreter
DIM nowscript as integer = -1
DIM scriptret as integer
REDIM retvals(32) as integer
DIM scriptctr as uinteger
DIM numloadedscr as integer    'Number of loaded script headers in script cache (some may not have data loaded)
DIM totalscrmem as integer     'Total memory used by all loaded scripts, in int32s
DIM unused_script_cache_mem as integer  'Memory used by scripts in cache which are unused, int32s
DIM err_suppress_lvl as scriptErrEnum
DIM scrwatch as integer
DIM next_interpreter_check_time as double
DIM interruption_grace_period as integer
REDIM global(maxScriptGlobals) as integer
DIM mainFibreGroup as ScriptFibre ptr vector
REDIM plotstr(maxScriptStrings) as Plotstring
DIM insideinterpreter as bool
DIM timing_fibre as bool
DIM scriptprofiling as bool
DIM wantimmediate as integer  'Equal to 0, -1 or -2

'incredibly frustratingly fbc doesn't export global array debugging symbols
DIM globalp as integer ptr
DIM heapp as integer ptr
DIM scratp as OldScriptState ptr
DIM scriptp as ScriptData ptr ptr
DIM retvalsp as integer ptr
DIM plotslicesp as slice ptr ptr
globalp = @global(0)
heapp = @heap(0)
scratp = @scrat(0)
scriptp = @script(0)
retvalsp = @retvals(0)


'======================== Setup directories & debug log =======================
' This is almost identical to startup code in Custom; please don't unnecessarily diverge.

'Note: On Android exename is "sdl" and exepath is "" (currently unimplemented in FB and meaningless for an app anyway)

orig_dir = CURDIR
'Note: debug log messages go in CURDIR until log_dir set below

app_dir = EXEPATH  'FreeBasic builtin

#IFDEF __FB_DARWIN__
 'Bundled apps have starting current directory equal to the location of the bundle, but exepath points inside
 IF RIGHT(exepath, 19) = ".app/Contents/MacOS" THEN
  app_resources_dir = parentdir(exepath, 1) + "Resources"
  app_dir = parentdir(exepath, 3)
 END IF
 'FIXME: why are we changing app_dir??
 IF app_dir = "/Applications/" THEN
  'Equal to documents_dir (not set yet)
  app_dir = ENVIRON("HOME") & SLASH & "Documents"
  CHDIR app_dir
 END IF
#ENDIF

#IFDEF __FB_ANDROID__
 'Prevent log_dir from being changed to the .rpg directory
 '(But why? If it's on external storage, that seems like great place to put it)
 log_dir = orig_dir & SLASH
 overrode_log_dir = YES
#ELSE
 log_dir = CURDIR & SLASH
#ENDIF

'Once log_dir is set, can create debug log.
external_log "main() started; starting debug log..."
start_new_debug "Starting OHRRPGCE Game"
debuginfo DATE & " " & TIME
debuginfo long_version & build_info
debuginfo "exepath: " & EXEPATH & ", exe: " & COMMAND(0)
' Load these three strings with info collectable before backend initialisation
read_backend_info()
debuginfo "Runtime info: " & gfxbackendinfo & "  " & musicbackendinfo & "  " & systeminfo

settings_dir = get_settings_dir()
documents_dir = get_documents_dir()  'may depend on app_dir
tmpdir = get_tmpdir()
'As soon as we create the tmpdir, we want to put a keepalive file in it
refresh_keepalive_file


'========================== Process commandline flags =========================

'Global variables which are affected by processcommandline (specifically, game_setoption)
DIM autotestmode as bool = NO
DIM always_enable_debug_keys as bool = NO
DIM speedcontrol as double = 55
DIM autosnap as integer = 0   'Number of ticks
DIM running_as_slave as bool = NO
DIM custom_version as string  'when running as slave
DIM master_channel as IPCChannel = NULL_CHANNEL  'when running as slave
DIM modified_lumps as string vector  'when running as slave
v_new modified_lumps
DIM force_prefsdir_save as bool = NO  'Whether to put save files in prefsdir rather than next to .rpg

REDIM cmdline_args() as string
' This can modify log_dir and restart the debug log
' Also, this (game_setoptions) opens a channel with Custom as soon as it processes the --slave option
processcommandline cmdline_args(), @gamecustom_setoption, orig_dir & SLASH & "ohrrpgce_arguments.txt"

IF running_as_slave THEN debuginfo "Spawned from Custom (" & custom_version & ")"


'============================== Initialise backends ===========================

'DEBUG debug "set mode-X"
setmodex
dpage = 1: vpage = 0

'DEBUG debug "init sound"
setupmusic

'seed the random number generator
mersenne_twister TIMER


'==============================================================================

'DEBUG debug "Thestart"
DO
' This is a big loop that encloses the entire program (more than it should).
' The loop is only reached when resetting the program (quitting out of a game).

'====================== (Re)initialise gfx/window/IO options ==================

presentsong = -1

gam.current_master_palette = -1
load_default_master_palette master()
setpal master()
DefaultUIColors uilook(), boxlook()
getdefaultfont current_font()
setfont current_font()

' Remove junk when using "run game"
clearpage vpage
setvispage vpage, NO

'-- Init joysticks
'-- Find which joysticks are present (this is a DOS-ism, the active joysticks are probably
'-- numbered 0 through n-1).
'-- FIXME: Also, this is definitely wrong for gfx_directx, which removes a joystick, renumbering the
'-- others, if it can't read it.
FOR i as integer = 0 TO UBOUND(gotj)
 gotj(i) = readjoy(joy(), i)
NEXT i

gen(genJoy) = 0  'joystick disabled by default
defaultc  'set up default controls

'Read joyset.ini
readjoysettings

DIM gp as GamePadMap
gp.A = scEnter
gp.B = scESC
gp.X = scESC
gp.Y = scESC
gp.L1 = scPageUp
gp.R1 = scPageDown
gp.L2 = scHome
gp.R2 = scEnd
remap_android_gamepad 0, gp
'Make all four gamepads use the same keys by default
FOR i as integer = 1 to 3
 remap_android_gamepad i, gp
NEXT i

'virtual gamepad stuff only has effect on platforms that actually allow
' a virtual gamepad (currently all Android except for OUYA)
hide_virtual_gamepad()
remap_touchscreen_button 0, scEnter
remap_touchscreen_button 1, scESC
remap_touchscreen_button 2, 0
remap_touchscreen_button 3, 0
remap_touchscreen_button 4, 0
remap_touchscreen_button 5, 0

IF LEN(gam.want.rungame) = 0 THEN
 ' We can skip this, to reduce flicker

 setwindowtitle "O.H.R.RPG.C.E"
 defaultmousecursor  'init mouse state
 mouserect -1, -1, -1, -1

 debuginfo "Setting default window settings..."
 set_safe_zone_margin default_margin()
 IF overrode_default_fullscreen = NO AND supports_fullscreen_well() THEN
  gfx_setwindowed(YES)
 END IF
 set_resolution 320, 200
 IF overrode_default_zoom = NO THEN
  'If it was set on the commandline, then it should still be set to that; game didn't change it
  set_scale_factor 2
 END IF
END IF

'=============================== Select a game ================================

gam.autorungame = NO
gam.started_by_run_game = NO
usepreunlump = NO
DIM rpg_browse_default as string = ""  'local variable

exename = trimextension(trimpath(COMMAND(0)))

IF running_as_slave THEN

 'Check for version compatibility, and get told sourcerpg & workingdir
 'NOTE: normally sourcedir == workingdir if running a preunlumped game, but not in this case!
 handshake_with_master
 gam.autorungame = YES
 usepreunlump = YES

ELSE  'NOT running_as_slave

 workingdir = tmpdir + "playing.tmp"

 'DEBUG debug "create playing.tmp"
 IF isdir(workingdir) THEN
  ' This should not happen, because tmpdir is unique and playing.tmp gets deleted after exiting a previous game!
  debug workingdir + " already exists!"
  killdir workingdir
 END IF
 IF makedir(workingdir) THEN fatalerror "Couldn't create " & workingdir

 IF LEN(gam.want.rungame) THEN

  IF select_rpg_or_rpgdir(gam.want.rungame) = NO THEN
   ' We already checked this was valid!
   fatalerror gam.want.rungame + " disappeared!"
  END IF

  gam.started_by_run_game = YES
  gam.want.rungame = ""

 ELSE

  '---IF A VALID RPG FILE WAS SPECIFIED ON THE COMMAND LINE, RUN IT, ELSE BROWSE---
  '---ALSO CHECKS FOR GAME.EXE RENAMING

  'DEBUG debug "searching commandline for game"
  FOR i as integer = 0 TO UBOUND(cmdline_args)
   DIM arg as string = cmdline_args(i)

   ' On success sets sourcerpg, gam.autorungame, usepreunlump and possibly workingdir
   IF select_rpg_or_rpgdir(arg) THEN
    EXIT FOR
   ELSEIF isdir(arg) THEN
    rpg_browse_default = absolute_path(arg)
   ELSE
    visible_debug "Unrecognised commandline argument " & arg & " ignored"
   END IF
  NEXT
 END IF

END IF  'NOT running_as_slave

#IFDEF __FB_UNIX__
IF gam.autorungame = NO THEN
 IF exename <> "ohrrpgce-game" THEN
  IF starts_with(exepath, "/usr/games") ORELSE starts_with(exepath, "/usr/bin") THEN
   seek_rpg_or_rpgdir_and_select_it("/usr/share/" & exename, exename)
   seek_rpg_or_rpgdir_and_select_it("/usr/share/games/" & exename, exename)
  END IF
  IF starts_with(exepath, "/usr/local") THEN
   seek_rpg_or_rpgdir_and_select_it("/usr/local/share/" & exename, exename)
   seek_rpg_or_rpgdir_and_select_it("/usr/local/share/games/" & exename, exename)
  END IF
 END IF
END IF
#ENDIF

#IFDEF __FB_DARWIN__
IF gam.autorungame = NO THEN
 IF ends_with(exepath, ".app/Contents/MacOS") THEN
  IF isfile(app_resources_dir & "/bundledgame") THEN
   DIM bundledname as string
   bundledname = TRIM(string_from_first_line_of_file(app_resources_dir & "/bundledgame"), ANY !" \t\r\n")
   IF seek_rpg_or_rpgdir_and_select_it(app_resources_dir, bundledname) THEN
    force_prefsdir_save = YES
   END IF
  END IF
 END IF
END IF
#ENDIF

IF gam.autorungame = NO THEN
 IF LCASE(exename) <> "game" ANDALSO exename <> "ohrrpgce-game" THEN
  seek_rpg_or_rpgdir_and_select_it exepath, exename
 END IF
END IF

IF gam.autorungame = NO THEN
 'DEBUG debug "browse for RPG"
 ' If we've shown the browser once, that means we should return to it when quitting
 ' (Can't use gam.autorungame to make that decision due to "run game")
 gam.return_to_browser = YES
 show_virtual_gamepad()
 sourcerpg = browse(7, rpg_browse_default, "*.rpg", "game_browse_rpg", YES)  'fades in
 hide_virtual_gamepad()
 IF sourcerpg = "" THEN exit_gracefully NO
 IF isdir(sourcerpg) THEN
  usepreunlump = YES
  workingdir = sourcerpg
 END IF
END IF


'================= Setup game-specific directories & debug log ================

'-- set up prefs dir
prefsdir = settings_dir & SLASH & trimextension(trimpath(sourcerpg))
IF NOT isdir(prefsdir) THEN makedir prefsdir
config_file = prefsdir & SLASH & "gameconfig.ini"

'-- change current directory, where g_debug will be put; mainly for drag-dropping onto Game in Windows which defaults to $HOME
DIM newcwd as string = trimfilename(sourcerpg)
IF newcwd <> "" ANDALSO diriswriteable(newcwd) THEN
 'first choice is game directory
ELSEIF diriswriteable(app_dir) THEN
 newcwd = app_dir
ELSE
 newcwd = prefsdir
END IF

end_debug 'delete unimportant messages generated before this point, or from previous game

CHDIR newcwd

IF overrode_log_dir = NO THEN log_dir = CURDIR & SLASH
start_new_debug "Loading " & sourcerpg
' Initialisation is over, don't store any further debug messages in memory.
remember_debug_messages = NO
debuginfo "curdir: " & CURDIR
debuginfo "tmpdir: " & tmpdir
debuginfo "settings_dir: " & settings_dir

init_save_system
gam.script_log.filename = log_dir & "script_log.txt"

#IFDEF __FB_ANDROID__
cleanup_other_temp_files
#ENDIF


'==================================== Unlump ==================================

' If coming from the browser, this is drawn on top of the file path at the top.
rectangle 0, 0, rWidth, 17, uilook(uiBackground), vpage
'edgeboxstyle pCentered, 3, rWidth - 8, 14, 0, vpage  'Rectangle behind "Loading"
edgeprint "Loading...", pCentered, 6, uilook(uiText), vpage
setvispage vpage, NO

DIM archinym as string

'--pre-extract (if needed) .gen and load it
IF usepreunlump THEN
 archinym = readarchinym(workingdir, sourcerpg)
 xbload workingdir & SLASH & archinym & ".gen", gen(), "general game data missing from " + sourcerpg
ELSE
 copylump sourcerpg, "archinym.lmp", tmpdir, YES
 archinym = readarchinym(tmpdir, sourcerpg)
 copylump sourcerpg, archinym + ".gen", tmpdir, YES
 xbload tmpdir + archinym + ".gen", gen(), "general game data missing from " + sourcerpg
END IF

DIM forcerpgcopy as integer = NO
IF gen(genVersion) > CURRENT_RPG_VERSION THEN
 debug "genVersion = " & gen(genVersion)
 future_rpg_warning  '(fatal error is running_as_slave)
 forcerpgcopy = YES  'If we upgraded an .rpgdir in-place, we would probably damage it
END IF

IF usepreunlump = NO THEN
 unlump sourcerpg, workingdir
ELSEIF NOT running_as_slave THEN  'Won't unlump or upgrade if running as slave
 IF NOT diriswriteable(workingdir) THEN
  'We have to copy the game, otherwise we won't be able to upgrade it
  '(it's too much trouble to properly check whether the game is already
  'fully up to date, which is unlikely anyway): change workingdir!
  debuginfo workingdir + " not writeable"
  forcerpgcopy = YES
 END IF
 IF forcerpgcopy THEN
  workingdir = tmpdir + "playing.tmp"
  copyfiles sourcerpg, workingdir + SLASH
  usepreunlump = NO
 END IF
END IF

'--set game
game = workingdir + SLASH + archinym
game_unique_id = STR(randint(INT_MAX))


'============================== Upgrade the game ==============================

'Delete general.reld cache in case it was automatically created by something
close_general_reld()

debuginfo "Name: " & getdisplayname("")
DIM wintitle as string = getdisplayname(trimpath(sourcerpg))
IF running_as_slave THEN wintitle = "Testing " + wintitle
setwindowtitle wintitle

'Show a warning if the versions aren't identical
IF running_as_slave THEN check_game_custom_versions_match

'Perform additional checks for future rpg files or corruption
'FIXME: if a problem was detected, we don't force copy of an .rpgdir
rpg_sanity_checks

xbload game + ".fnt", current_font(), "font missing from " + sourcerpg

'--upgrade obsolete RPG files (if possible)
IF NOT running_as_slave THEN upgrade gam.started_by_run_game = NO


'======================== Stuff initialised once per .RPG =====================

set_music_volume 0.01 * gen(genMusicVolume)
set_global_sfx_volume 0.01 * gen(genSFXVolume)

REDIM gmap(dimbinsize(binMAP)) 'this must be sized here, after the binsize file exists!

'Unload any default graphics (from data/defaultgfx) that might have been cached
sprite_empty_cache
palette16_empty_cache

setfont current_font()
loadglobalstrings
getstatnames statnames()

IF isfile(game + ".hsp") THEN unlump game + ".hsp", tmpdir
'Might be changed by --errlvl commandline option
'Default to showing all errors. genErrorLevel is no longer used (but might be again in future)
IF err_suppress_lvl = 0 THEN err_suppress_lvl = serrIgnore
nowscript = -1
numloadedscr = 0
totalscrmem = 0
resetinterpreter
IF gam.script_log.enabled THEN start_script_trigger_log
'the old stack used only inbattle
releasestack
setupstack
v_new mainFibreGroup

SetupGameSlices
'beginplay

'This is called BEFORE the loop, because when the game is quit or a save is loaded, this will be called again there
reset_game_state

'Fade out before resizing the window
fadeout 0, 0, 0

'Recreate/resize/reposition the window as needed
apply_game_window_settings NO
set_safe_zone_margin read_ini_int(config_file, "gfx.margin", default_margin_for_game())


'===================== Stuff reinitialised each new/load-game ==================

DO' This loop encloses the playable game for a specific RPG file


gam.current_master_palette = gen(genMasterPal)
loadpalette master(), gam.current_master_palette
LoadUIColors uilook(), boxlook(), gam.current_master_palette
set_speedcontrol
set_animation_framerate gen(genMillisecPerFrame)

initgamedefaults
fatal = NO
checkfatal = NO
gam.quit = NO
lastformation = -1
scrwatch = 0
menu_set.menufile = workingdir & SLASH & "menus.bin"
menu_set.itemfile = workingdir & SLASH & "menuitem.bin"
load_script_triggers_and_names

makebackups 'make a few backup lumps

gam.want.box = 0
gam.want.door = 0
gam.want.battle = 0
gam.want.teleport = NO
gam.want.usenpc = 0
gam.want.loadgame = 0
gam.want.dont_quit_to_loadmenu = NO
'gam.want.resetgame reset after title/loadmenu
load_non_elemental_elements gam.non_elemental_elements()

txt.showing = NO
txt.fully_shown = NO
txt.show_lines = 0
txt.sayer = -1
txt.id = -1

'--Reset some stuff related to debug keys
gam.showtext_ticks = 0
gam.debug_showtags = 0
gam.debug_npc_info = NO
gam.walk_through_walls = NO

reset_vehicle vstate

'========================== Title and loadgame menu ============================

gam.ingame = YES
IF get_gen_bool("/mouse/show_cursor") THEN showmousecursor 'Without this, the default cursor visibility depends on window state

DIM load_slot as integer = -1
'.resetgame is YES when resetgame was called so we are skipping straight to launching the game
IF gam.want.resetgame = NO THEN
 queue_fade_in
 IF readbit(gen(), genBits, 11) = 0 THEN
  '"Skip title screen" is off
  IF titlescreen() = NO THEN EXIT DO
  IF readbit(gen(), genBits, 12) = 0 THEN load_slot = pickload()
 ELSEIF readbit(gen(), genBits, 12) = 0 THEN
  '"Skip load screen" is off
  IF gen(genTitleMus) > 0 THEN wrappedsong gen(genTitleMus) - 1
  ' Show a black background beneath the load menu
  clearpage vpage
  load_slot = pickload()
 END IF
END IF
gam.want.resetgame = NO
'DEBUG debug "picked save slot " & load_slot

IF readbit(gen(), genBits2, 24) = 0 THEN  '"Don't stop music when starting/loading game"
 queue_music_change -1  'stop music (unless initial map has same music)
END IF
IF load_slot = -2 THEN
 fadeout 0, 0, 0
 EXIT DO
ELSEIF load_slot >= 0 THEN
 fadeout 0, 0, 0
 doloadgame load_slot
ELSE
 'New game
 refresh_purchases()
 'This fadeout means that resetgame fades out the screen although gameover doesn't
 fadeout 0, 0, 0
 'Clear the screen so that there's no garbage shown behind the prompt to rename the starting hero
 clearpage dpage
 clearpage vpage
 'Add initial hero to party (slot 0)
 addhero 1 + gen(genStartHero), 0
 'Trigger textbox and/or script
 gam.want.box = gen(genStartTextbox)  '0 for no textbox
 IF gen(genNewGameScript) > 0 THEN
  trigger_script gen(genNewGameScript), UBOUND(gam.want.script_args) + 1, YES, "newgame", "", mainFibreGroup
  FOR idx as integer = 0 TO UBOUND(gam.want.script_args)
   trigger_script_arg idx, gam.want.script_args(idx), "custom arg"
  NEXT
  REDIM gam.want.script_args(-1 TO -1)
 END IF
 prepare_map
END IF

load_special_tag_caches
evalherotags


'================================= Main loop ==================================
'==============================================================================

queue_fade_in
'DEBUG debug "pre-call update_heroes"
update_heroes(YES)
setkeys

DIM tog as integer
DO
 'DEBUG debug "top of master loop"
 setwait speedcontrol
 IF running_as_slave THEN try_to_reload_lumps_onmap
 tog = tog XOR 1
 'DEBUG debug "increment play timers"
 IF gam.paused = NO THEN playtimer

 'DEBUG debug "read controls"
 update_virtual_gamepad_display()
 setkeys gam.getinputtext_enabled
 'debug_mouse_state()
 control

 '--Debug keys
 IF always_enable_debug_keys OR readbit(gen(), genBits, 8) = 0 THEN check_debug_keys()

 IF gam.paused = NO THEN

 'debug "menu key handling:"
 check_menu_tags
 player_menu_keys()
 'debug "after menu key handling:"

 IF menus_allow_gameplay() THEN

 '--Scripts
 trigger_onkeypress_script
 'breakpoint : called after keypress script is run, but don't get called by wantimmediate
 IF scrwatch > 1 THEN breakpoint scrwatch, 4
 'DEBUG debug "enter script interpreter"
 interpret_scripts
 'DEBUG debug "increment script timers"
 dotimer(TIMER_NORMAL)

 'DEBUG debug "keyboard handling"
 IF txt.showing = NO AND gam.need_fade_in = NO AND readbit(gen(), genSuspendBits, suspendplayer) = 0 AND vstate.active = NO THEN
  'Menu key is enabled (provided you're stationary)
  update_hero_pathfinding_menu_queue()
  IF (user_triggered_main_menu() ORELSE gam.hero_pathing.queued_menu) AND herow(0).xgo = 0 AND herow(0).ygo = 0 THEN
   gam.hero_pathing.queued_menu = NO
   IF gen(genEscMenuScript) > 0 THEN
    trigger_script gen(genEscMenuScript), 0, NO, "", "", mainFibreGroup
   ELSEIF allowed_to_open_main_menu() THEN
    add_menu 0
    menusound gen(genAcceptSFX)
   END IF
  END IF
 ELSE
  'Edge case: don't allow a queued menu to be delayed indefinitely
  gam.hero_pathing.queued_menu = NO
 END IF
 IF txt.showing = NO AND gam.need_fade_in = NO AND gam.debug_camera_pan = NO _
    AND readbit(gen(), genSuspendBits, suspendplayer) = 0 AND vehicle_is_animating() = NO _
    AND menus_allow_player() THEN
  IF get_gen_bool("/mouse/move_hero") THEN
   IF readmouse().buttons AND mouseLeft THEN
    cancel_hero_pathfinding()
    trigger_hero_pathfinding()
   END IF
  END IF
  IF herow(0).xgo = 0 AND herow(0).ygo = 0 THEN
   DO
    IF carray(ccUp) > 0 THEN herow(0).ygo = 20: (herodir(0)) = 0    : cancel_hero_pathfinding() : EXIT DO
    IF carray(ccDown) > 0 THEN herow(0).ygo = -20: (herodir(0)) = 2 : cancel_hero_pathfinding() : EXIT DO
    IF carray(ccLeft) > 0 THEN herow(0).xgo = 20: (herodir(0)) = 3  : cancel_hero_pathfinding() : EXIT DO
    IF carray(ccRight) > 0 THEN herow(0).xgo = -20: (herodir(0)) = 1: cancel_hero_pathfinding() : EXIT DO
    IF carray(ccUse) > 1 AND vstate.active = NO THEN
     cancel_hero_pathfinding()
     usenpc 0, find_useable_npc()
    END IF
    update_hero_pathfinding(0)
    EXIT DO
   LOOP
  END IF
 END IF
 IF txt.fully_shown = YES ANDALSO readbit(gen(), genSuspendBits, suspendboxadvance) = 0 THEN
  IF use_touch_textboxes() THEN
   IF readmouse().release AND mouseLeft THEN
    advance_text_box
   END IF
  END IF
  IF carray(ccUse) > 1 THEN
   advance_text_box
  END IF
 END IF
 'debug "after advance_text_box:"
 IF vstate.active THEN
  'DEBUG debug "evaluate vehicles"
  update_vehicle_state()
 END IF
 'You can still move the cursor of a textbox choice box when box advance is suspended
 IF txt.fully_shown = YES AND txt.box.choice_enabled THEN
  usemenusounds
  usemenu txt.choicestate
 END IF
 'DEBUG debug "hero movement"
 update_heroes()
 'DEBUG debug "NPC movement"
 update_npcs()

 AdvanceSlice SliceTable.root
 ELSE
  dotimer(TIMER_BLOCKINGMENUS)
 END IF' end menus_allow_gameplay
 END IF' end gam.paused = NO

 IF gam.want.loadgame > 0 THEN
  'DEBUG debug "loading game slot " & (gam.want.loadgame - 1)
  load_slot = gam.want.loadgame - 1
  gam.want.loadgame = 0
  resetgame
  initgamedefaults
  IF readbit(gen(), genBits2, 24) = 0 THEN  '"Don't stop music when starting/loading game"
   queue_music_change -1  'stop music (unless new map has same music)
  END IF
  ' Don't stop sound effects, because if used from the Load menu this would cut off
  ' the Accept sfx unplesantly. (However, would be ideal to stop longer ones)
  'resetsfx
  fadeout 0, 0, 0
  queue_fade_in 1, YES
  doloadgame load_slot
 END IF

 'Death handling
 IF checkfatal THEN
  'Note that we only check for death if requested because setting hero HP to zero with a script
  'doesn't end the game, for back-compat.
  'Also, battles set the 'fatal' global directly, because they use a different death condition
  '(a hero with zero max HP counts as dead, while OOB they count as alive)
  fatal OR= checkfordeath
  checkfatal = NO
 END IF
 IF fatal THEN
  '--this is what happens when you die
  txt.showing = NO
  txt.fully_shown = NO
  IF gen(genGameoverScript) > 0 THEN
   trigger_script gen(genGameoverScript), 0, NO, "death", "", mainFibreGroup
   fatal = NO
   queue_fade_in 1
  ELSE
   fadeout 255, 0, 0
   gam.quit = YES
  END IF
 END IF

 'Draw screen
 displayall()

 'Main loop exit test (does this need to be here?)
 IF gam.quit OR gam.want.resetgame OR LEN(gam.want.rungame) THEN
  resetgame
  'Stop sounds but not music; the title screen might not have any music set, or be set to the same music
  resetsfx
  IF LEN(gam.want.rungame) THEN EXIT DO, DO  'Quit out of game
  IF gam.want.resetgame THEN EXIT DO  'skip to new game
  DIM skip_load_menu as bool = readbit(gen(), genBits, 12)
  skip_load_menu OR= (count_used_save_slots() = 0)
  skip_load_menu OR= gam.want.dont_quit_to_loadmenu
  'if skipping title and loadmenu, quit
  IF readbit(gen(), genBits, 11) AND skip_load_menu THEN
   EXIT DO, DO ' To game select screen (quit the gameplay and RPG file loops, allowing the program loop to cycle)
  ELSE
   EXIT DO ' To title screen (quit the gameplay loop and allow the RPG file loop to cycle)
  END IF
 END IF

 'DEBUG debug "swap video pages"
 SWAP vpage, dpage
 setvispage vpage

 IF gam.paused = NO THEN
  'DEBUG debug "fade in"
  check_for_queued_music_change
  check_for_queued_fade_in
 END IF
 'DEBUG debug "tail of main loop"
 dowait
LOOP

' Loop back to the titlescreen
LOOP ' This is the end of the DO that encloses a specific RPG file

' Start storing debug messages again when we're in-between games, so messages aren't missed
remember_debug_messages = YES
debuginfo "...Quit the game." LINE_END

' Exit the game
reset_game_final_cleanup  'This may call exitprogram

LOOP ' This is the end of the DO that encloses the entire program.


'==========================================================================================
'==========================================================================================

' Save config changes to gameconfig.ini
SUB save_game_config()
 ' Save the fullscreen/windowed state, if the player customised it.
 IF user_toggled_fullscreen THEN
  DIM fullscreen as bool
  IF try_check_fullscreen(fullscreen) THEN
   debuginfo "write " & gam.fullscreen_config_file & " : gfx.fullscreen = " & fullscreen
   write_ini_value gam.fullscreen_config_file, "gfx.fullscreen", fullscreen
  END IF
 END IF
END SUB

' Unload all data for the current game and either quit, or return if we're going
' back to the file browser or loading another game (with rungame).
SUB reset_game_final_cleanup()
 'WARNING: It's a bug to call anything in here that causes something to be cached after
 'the cache has been emptied (such as anything that calls getbinsize after clear_binsize_cache)
 gam.ingame = NO
 save_game_config 'Call before cleaning up everything.
 ' This sticky bit is cleared when returning to the file browser
 IF LEN(gam.want.rungame) = 0 THEN gam.shared_fullscreen_setting = NO
 ' OK to reset this even after "run game", because we already
 ' called save_game_config to save "gfx.fullscreen"
 user_toggled_fullscreen = NO
 cleanup_text_box
 resetinterpreter 'unload scripts
 unloadmaptilesets tilesets()
 refresh_map_slice_tilesets '--zeroes out now-invalid pointers
 unloadtilemaps maptiles()
 unloadtilemap pass
 unloadtilemap foemap
 DeleteZonemap zmap
 'checks for leaks and deallocates them
 sprite_empty_cache
 palette16_empty_cache
 cleanup_game_slices
 SliceDebugDump YES
 cleanup_global_reload_doc
 close_general_reld
 clear_binsize_cache
 stopsong
 resetsfx
 cleanup_other_temp_files
 'We bypass exit_gracefully() because we already called save_game_config
 IF gam.return_to_browser = NO AND LEN(gam.want.rungame) = 0 THEN exitprogram YES
 debuginfo "Recreating " & tmpdir
 killdir tmpdir, YES  'recursively deletes playing.tmp if it exists
 makedir tmpdir
 'killdir and thus makedir would fail if some in-use file can't be deleted
 IF NOT isdir(tmpdir) THEN fatalerror "Can't recreate temp directory " & tmpdir
 fadeout 0, 0, 0
 sourcerpg = ""
END SUB

' Call this instead of exitprogram when not quitting due to an error.
' This assumes no cleanup has been performed;
SUB exit_gracefully(need_fade_out as bool = NO)
 IF LEN(sourcerpg) THEN save_game_config
 exitprogram need_fade_out, 0
END SUB

SUB cleanup_game_slices ()
 FOR i as integer = 0 TO UBOUND(herow)
  DeleteSlice @herow(i).sl
 NEXT i
 FOR i as integer = 0 TO UBOUND(npc)
  DeleteSlice @npc(i).sl
 NEXT i
 DestroyGameSlices
END SUB

SUB doloadgame(byval load_slot as integer)
 loadgame load_slot
 interpolatecat()
 IF gen(genLoadGameScript) > 0 THEN
  DIM nargs as integer = UBOUND(gam.want.script_args) + 2
  trigger_script gen(genLoadGameScript), nargs, YES, "loadgame", "", mainFibreGroup
  '--pass save slot as argument
  IF load_slot = 32 THEN
   trigger_script_arg 0, -1, "slot"  'quickload slot
  ELSE
   trigger_script_arg 0, load_slot, "slot"
  END IF
  '--pass more args, if provided to "load from slot"
  FOR idx as integer = 1 TO nargs - 1
   trigger_script_arg idx, gam.want.script_args(idx - 1), "custom arg"
  NEXT
  REDIM gam.want.script_args(-1 TO -1)
 END IF
 gam.map.same = YES

 prepare_map NO, YES
 'FIXME: clean this up: setting vstate.id is only backcompat for loading from the old SAV format;
 ' ideally this would be in old_loadgame, but we need to load NPCs in prepare_map
 IF vstate.active THEN
  SELECT CASE npc(vstate.npc).id
   CASE 0:
    debug "Vehicle NPC ref " & vstate.npc - 1 & " in save state does not exist in game anymore"
    vehicle_graceful_dismount
   CASE IS < 0:
    debug "Vehicle NPC ref " & vstate.npc - 1 & " in save state is now disabled by tags"
    vehicle_graceful_dismount
   CASE ELSE
    vstate.id = npcs(npc(vstate.npc).id - 1).vehicle - 1
    create_walkabout_shadow npc(vstate.npc).sl
  END SELECT
 END IF

 party_change_updates
 refresh_purchases()
 
END SUB

'==========================================================================================

SUB displayall()
 ' We need to update walkabout slice positions before calling
 ' setmapxy, in the case where the camera is following a hero
 ' or NPC, but this is pretty wasteful. One alternative
 ' is to only update a single slice as required from setmapxy,
 ' or to stop using walkabout slices there.
 update_walkabout_slices()

 ' Update camera position
 setmapxy
 SliceTable.MapRoot->Pos = XY(-mapx, -mapy)

 ' Walkabout slice positions (other than the hero/NPC being
 ' followed) also depend on the camera position, so need to be
 ' repositioned after the camera is updated.
 ' TODO: I think that ideally slices could be set to wrap their children,
 ' that way slices manually parented to a map layer will always
 ' draw in the correct position, whereas currently this breaks on wrapping
 ' maps. This would also remove the need for this
 ' second update_walkabout_slices call.
 update_walkabout_slices()

 ' Beware that map slices behave in unique ways; see comments in DrawMapSlice.
 ' 
 ' Map layers edge handling.
 ' (backcompat bit: 'Wrap map layers over edge of Crop maps')
 set_map_edge_draw_mode gmap(), readbit(gen(), genBits2, 21)

 IF readbit(gen(), genSuspendBits, suspendoverlay) THEN
  ChangeMapSlice SliceTable.MapLayer(0), , , , 0   'draw all
  SliceTable.ObsoleteOverhead->Visible = NO
 ELSE
  ChangeMapSlice SliceTable.MapLayer(0), , , , 1   'draw non-overhead only
  SliceTable.ObsoleteOverhead->Visible = YES
 END IF

 update_backdrop_slice

 NumDrawnSlices = 0
 DIM drawtime as double = TIMER
 DrawSlice(SliceTable.Root, dpage)
 drawtime = TIMER - drawtime
 'debuginfo "Drew " & NumDrawnSlices & " slices in " & CINT(drawtime * 1e6) & "us; " & CINT(drawtime * 1e9 / NumDrawnSlices) & "ns/slice average"

 'The order in which we update and draw things is a little strange; I'm just preserving what it was
 animatetilesets tilesets()
 IF harmtileflash = YES THEN
  rectangle 0, 0, rWidth, rHeight, gmap(10), dpage
  harmtileflash = NO
 END IF
 IF txt.showing = YES THEN update_textbox

 'FIXME: Eventually we want to draw the rest of this stuff using slices, but for now draw it on top
 'Note: this updates .pt and .top etc for each menu, but doesn't update item visibility.
 'That happens on check_menu_tags, next tick
 update_menu_states
 FOR i as integer = 0 TO topmenu
  draw_menu menus(i), mstates(i), dpage
 NEXT i
 wrapprint gam.showstring, 0, pBottom, uilook(uiText), dpage
 showplotstrings
 IF gam.showtext_ticks > 0 THEN
  gam.showtext_ticks -= 1
  wrapprint gam.showtext, pCentered, pBottom - 10, uilook(uiText), dpage
 END IF
 IF gam.debug_npc_info THEN npc_debug_display
 IF gam.debug_showtags THEN tagdisplay
 IF scrwatch THEN scriptwatcher scrwatch, -1
END SUB


'==========================================================================================
'                                      Hero movement
'==========================================================================================

FUNCTION catleaderspeed() as integer
 IF readbit(gen(), genBits2, 25) = 0 THEN
  '"Keep caterpillar length the same when speed changes" bitset is off
  'so treat the caterpillar leader speed as if it is hard-coded to 4
  RETURN 4
 END IF

 DIM speed as integer = herow(0).speed
 IF speed <= 0 THEN
  'If leader speed is zero or negative, treat the caterpillar as if speed is 1
  speed = 1
 END IF
 IF speed > 20 THEN
  'If speed is bigger than tile size, clamp it. That will cause the caterpillar to stretch
  'but if you speed is bigger than your tilesize, that is probably the least of your problems ;)
  speed = 20
 END IF
 RETURN speed
END FUNCTION

FUNCTION catindex(byval rank as integer) as integer
 RETURN rank * (20 \ catleaderspeed())
END FUNCTION

FUNCTION heropos(byval rank as integer) byref as XYPair
 RETURN cats(catindex(rank)).pos
END FUNCTION

FUNCTION herox(byval rank as integer) byref as integer
 RETURN cats(catindex(rank)).x
END FUNCTION

FUNCTION heroy(byval rank as integer) byref as integer
 RETURN cats(catindex(rank)).y
END FUNCTION

FUNCTION heroz(byval rank as integer) byref as integer
 RETURN cats(catindex(rank)).z
END FUNCTION

FUNCTION herodir(byval rank as integer) byref as integer
 RETURN cats(catindex(rank)).d
END FUNCTION

FUNCTION herotpos(byval rank as integer) as XYPair
 RETURN heropos(rank) \ 20
END FUNCTION

FUNCTION herotx(byval rank as integer) as integer
 RETURN herox(rank) \ 20
END FUNCTION

FUNCTION heroty(byval rank as integer) as integer
 RETURN heroy(rank) \ 20
END FUNCTION

SUB resetcaterpillar_for_one_hero (byval rank as integer, byval newx as integer, byval newy as integer)
 'FIXME: this is still hardcoded for leader speed 4
 DIM sp as integer = catleaderspeed()
 DIM gap as integer = 20 / sp
 FOR i as integer = 0 TO gap - 1
  DIM index as integer = small(rank * gap + i, UBOUND(cats))
  cats(index).x = newx
  cats(index).y = newy
 NEXT i
END SUB

SUB resetcaterpillar ()
 FOR i as integer = 1 TO UBOUND(cats)
  cats(i).x = cats(0).x
  cats(i).y = cats(0).y
  cats(i).d = cats(0).d
  cats(i).z = 0
 NEXT i
END SUB

SUB change_hero_speed(byval rank as integer, byval new_speed as integer)
 DIM old_speed as integer = herow(rank).speed
 herow(rank).speed = new_speed
 IF rank = 0 ANDALSO old_speed <> new_speed THEN
  interpolatecat (old_speed)
 END IF
END SUB

SUB interpolatecat (byval old_speed as integer = -1)
 'given the current positions of the caterpillar party, interpolate their inbetween frames
 'This is used when caterpillar party is re-enabled after being disabled
 'This should be called any time the leader's speed changes!
 
 DIM sp as integer = catleaderspeed()

 IF old_speed = -1 THEN old_speed = sp
 
 IF readbit(gen(), genBits2, 25) = 0 THEN
  '"Keep caterpillar length the same when speed changes" bitset is off
  'so we never actually remap hero indexes when speed changes
  old_speed = 4
 END IF
 
 IF old_speed <> sp THEN
  'Remap the hero positions from the old speed to the new speed
  DIM cattemp(3) as CaterpillarHistory
  FOR i as integer = 0 to 3
   cattemp(i) = cats(i * (20 / old_speed))
  NEXT i
  FOR i as integer = 0 to 3
   cats(i * (20 / sp)) = cattemp(i)
  NEXT i
 END IF

 DIM gap as integer = 20 / sp
 FOR o as integer = 0 TO UBOUND(cats) - gap STEP gap
  FOR i as integer = o + 1 TO o + gap - 1
   cats(i).pos = cats(i - 1).pos + ((cats(o + gap).pos - cats(o).pos) / gap)
   cats(i).d = cats(o).d
  NEXT i
 NEXT o
END SUB

SUB updatecaterpillarhistory ()
 'This happens when a hero is about to move and caterpillar party is enabled
 FOR i as integer = UBOUND(cats) TO 1 STEP -1
  cats(i).x = cats(i - 1).x
  cats(i).y = cats(i - 1).y
  cats(i).d = cats(i - 1).d
 NEXT i
END SUB

SUB update_heroes(force_step_check as bool=NO)
 'note: xgo and ygo are offset of current position from destination, eg +ve xgo means go left
 FOR whoi as integer = 0 TO sizeActiveParty - 1
  IF herow(whoi).speed = 0 THEN
   '--cancel movement, or some of the following code misbehaves
   herow(whoi).xgo = 0
   herow(whoi).ygo = 0
  END IF
  '--if starting movement to a new tile and passibility is enabled ... and some vehicle stuff ...
  IF want_to_check_for_walls(whoi) THEN
   IF readbit(gen(), genSuspendBits, suspendherowalls) = 0 AND vehicle_is_animating() = NO THEN
    '--this only happens if herowalls is on
    '--wrapping passability
    DIM herotile as XYPair = herotpos(whoi)
    wrappass herotile.x, herotile.y, herow(whoi).xgo, herow(whoi).ygo, vstate.active
   END IF
   IF readbit(gen(), genSuspendBits, suspendobstruction) = 0 AND vehicle_is_animating() = NO THEN
    '--this only happens if obstruction is on
    FOR i as integer = 0 TO UBOUND(npc)
     WITH npc(i)
      IF .id > 0 THEN '---NPC EXISTS---
       DIM id as integer
       id = .id - 1
       IF npcs(id).activation <> 2 THEN '---NPC is not step-on
        IF wrapcollision (.pos, .xygo, heropos(whoi), herow(whoi).xygo) THEN
         IF .not_obstruction = 0 THEN
          herow(whoi).xygo = 0
          '--push the NPC
          DIM push as integer = npcs(id).pushtype
          IF push > 0 AND .xgo = 0 AND .ygo = 0 THEN
           IF herodir(whoi) = 0 AND (push = 1 OR push = 2 OR push = 4) THEN .ygo = 20
           IF herodir(whoi) = 2 AND (push = 1 OR push = 2 OR push = 6) THEN .ygo = -20
           IF herodir(whoi) = 3 AND (push = 1 OR push = 3 OR push = 7) THEN .xgo = 20
           IF herodir(whoi) = 1 AND (push = 1 OR push = 3 OR push = 5) THEN .xgo = -20
           IF readbit(gen(), genBits2, 0) = 0 THEN ' Only do this if the backcompat bitset is off
            FOR o as integer = 0 TO UBOUND(npc) ' check to make sure no other NPCs are blocking this one
             IF npc(o).id <= 0 THEN CONTINUE FOR 'Ignore empty NPC slots and negative (tag-disabled) NPCs
             IF i = o THEN CONTINUE FOR
             IF npc(o).not_obstruction THEN CONTINUE FOR
             IF wrapcollision (.pos, .xygo, npc(o).pos, npc(o).xygo) THEN
              .xgo = 0
              .ygo = 0
              EXIT FOR
             END IF
            NEXT o
           END IF
          END IF
         END IF
         IF npcs(id).activation = 1 AND whoi = 0 THEN '--NPC is touch-activated
          IF wraptouch(.pos, heropos(0), 20) THEN
           usenpc 1, i
          END IF
         END IF '---touch-activate
        END IF ' ---NPC IS IN THE WAY
       END IF ' ---NPC is not step-on
      END IF '---NPC EXISTS
     END WITH
    NEXT i
   END IF
  END IF'--this only gets run when starting a movement to a new tile
 NEXT whoi

 'Caterpillar hero movement: if enabled and the leader is about to move
 ' then make other heroes trail along by updating the caterpillar history
 IF readbit(gen(), genSuspendBits, suspendcaterpillar) = 0 THEN
  'Normal caterpillar
  IF herow(0).xgo ORELSE herow(0).ygo THEN
   updatecaterpillarhistory
  END IF
  IF herow(0).xgo ORELSE herow(0).ygo ORELSE readbit(gen(), genBits2, 26) THEN
   FOR whoi as integer = 0 TO sizeActiveParty - 1
    herow(whoi).wtog = loopvar(herow(whoi).wtog, 0, 3, 1)
   NEXT whoi
  END IF
 ELSE
  'Suspended caterpillar
  FOR whoi as integer = 0 TO sizeActiveParty - 1
   IF herow(whoi).xgo ORELSE herow(whoi).ygo ORELSE readbit(gen(), genBits2, 26) THEN
    herow(whoi).wtog = loopvar(herow(whoi).wtog, 0, 3, 1)
   END IF
  NEXT whoi
 END IF

 'Non-caterpillar (normal [xy]go-based) hero movement
 DIM didgo(0 TO sizeActiveParty - 1) as bool
 FOR whoi as integer = 0 TO sizeActiveParty - 1
  'NOTE: this loop covers the max caterpillar size, and not the current
  ' return value of caterpillar_size() because empty hero slots still
  ' need to be movable on the map. Scripts sometimes want to move a hero
  ' and wait for that hero without first checking if the slot is occupied
  didgo(whoi) = NO
  IF herow(whoi).xgo OR herow(whoi).ygo THEN
   '--this actually updates the hero's coordinates
   'NOTE: if the caterpillar is enabled, then only the leader has nonzero xgo, ygo
   IF herow(whoi).xgo > 0 THEN herow(whoi).xgo -= herow(whoi).speed: herox(whoi) -= herow(whoi).speed
   IF herow(whoi).xgo < 0 THEN herow(whoi).xgo += herow(whoi).speed: herox(whoi) += herow(whoi).speed
   IF herow(whoi).ygo > 0 THEN herow(whoi).ygo -= herow(whoi).speed: heroy(whoi) -= herow(whoi).speed
   IF herow(whoi).ygo < 0 THEN herow(whoi).ygo += herow(whoi).speed: heroy(whoi) += herow(whoi).speed
   didgo(whoi) = YES
  END IF
  cropmovement heropos(whoi), herow(whoi).xygo
 NEXT whoi

 'Update lists of current zones and run zone entry+exit triggers
 'We do this each tick instead of only when completing a step because they need to be
 'rechecked when the hero position changes for any reason (eg. script commands), or when
 'the zone map changes (eg. loading map state), and hooking into all those places is too
 'much of a maintenance burden. Plus also each-step detection sucks.
 FOR whoi as integer = 0 TO caterpillar_size() - 1
  update_hero_zones whoi
 NEXT
 
 FOR whoi as integer = 0 TO caterpillar_size() - 1

  DIM steppingslot as integer = whoi
  '--If caterpillar is not suspended, only the leader's motion determines a step
  '--(a limitation of the caterpillar party.)
  '--BUG: if the caterpillar isn't properly interpolated, will get weird results like
  '--jumping over tiles without damage.
  IF readbit(gen(), genSuspendBits, suspendcaterpillar) = 0 THEN steppingslot = 0

  IF didgo(steppingslot) = YES AND (herow(steppingslot).xgo MOD 20) = 0 AND (herow(steppingslot).ygo MOD 20) = 0 THEN
   '--Stuff that should only happen when a hero finishs a step

   '--Run each-step zone triggers
   process_zone_eachstep_triggers "hero" & whoi, herow(whoi).curzones

   '--Check for harm tile
   DIM p as integer = readblock(pass, herotx(whoi), heroty(whoi))
   IF p AND passHarm THEN

    DIM harm_whole_party as bool = NO

    IF whoi = 0 AND readbit(gen(), genBits, 1) = 0 THEN
     'The caterpillar is disabled, so maybe harm the whole party when the leader steps on a harm tile
     'if backcompat sit, otherwise old buggy behaviour: just the leader
     IF readbit(gen(), genBits2, 12) THEN  'Harm tiles harm non-caterpillar heroes
      harm_whole_party = YES
     END IF
    END IF

    IF harm_whole_party THEN
     FOR party_slot as integer = 0 TO sizeActiveParty - 1
      IF gam.hero(party_slot).id >= 0 THEN
       gam.hero(party_slot).stat.cur.hp = large(gam.hero(party_slot).stat.cur.hp - gmap(9), 0)
      END IF
     NEXT
    ELSE
     '--harm single hero
     DIM party_slot as integer = rank_to_party_slot(whoi)
     gam.hero(party_slot).stat.cur.hp = large(gam.hero(party_slot).stat.cur.hp - gmap(9), 0)
    END IF

    IF gmap(10) THEN
     harmtileflash = YES
    END IF
    checkfatal = YES
   END IF

  END IF  'End of harm tile checking
 NEXT whoi

 'If the leader finished a step, check triggers
 IF (herow(0).xgo MOD 20 = 0) AND (herow(0).ygo MOD 20 = 0) AND (didgo(0) = YES OR force_step_check = YES) THEN

  'Trigger step-on NPCs
  IF readbit(gen(), genSuspendBits, suspendobstruction) = 0 THEN
   '--check for step-on NPCS
   FOR i as integer = 0 TO UBOUND(npc)
    WITH npc(i)
     IF .id > 0 THEN '---NPC EXISTS---
      IF vstate.active = NO OR (vstate.dat.enable_npc_activation = YES AND vstate.npc <> i) THEN
       IF npcs(.id - 1).activation = 2 THEN '---NPC is step-on activated
        IF .pos = heropos(0) THEN '---YOU ARE ON NPC---
         usenpc 1, i
        END IF '---YOU ARE ON NPC---
       END IF '---NPC IS PASSABLE---
      END IF '--vehicle okay
     END IF '---NPC EXISTS
    END WITH
   NEXT i
  END IF

  'Trigger doors (only if the hero really moved, not just if force_step_check = YES)
  IF didgo(0) = YES THEN
   checkdoors
  END IF

  'Trigger battles
  'No random battle allowed on the first tick before fade-in (?)
  IF gam.need_fade_in = NO AND readbit(gen(), genSuspendBits, suspendrandomenemies) = 0 THEN
   DIM battle_formation_set as integer
   battle_formation_set = readblock(foemap, herotx(0), heroty(0))
   IF vstate.active = YES THEN
    '--Riding a vehicle
    IF vstate.dat.random_battles > 0 THEN
     '--This vehicle overrides the random battle formation set
     battle_formation_set = vstate.dat.random_battles
    ELSEIF vstate.dat.random_battles = -1 THEN
     '--This vehicle disables random battles
     battle_formation_set = 0
    END IF
   END IF
   IF battle_formation_set > 0 THEN
    DIM formset as FormationSet
    LoadFormationSet formset, battle_formation_set
    IF istag(formset.tag, YES) THEN
     gam.random_battle_countdown = gam.random_battle_countdown - formset.frequency

     IF gam.random_battle_countdown <= 0 THEN
      gam.random_battle_countdown = range(100, 60)
      DIM battle_formation as integer = random_formation(battle_formation_set)
      IF gmap(13) <= 0 THEN 'if no random battle script is defined
       IF battle_formation >= 0 THEN 'and if the randomly selected battle is valid
        'trigger a normal random battle
        fatal = NO
        gam.wonbattle = battle(battle_formation)
        prepare_map YES
        queue_fade_in 1
       END IF
      ELSE
       'trigger the instead-of-battle script
       trigger_script gmap(13), 2, YES, "instead-of-battle", "triggered at " & herotx(0) & "," & heroty(0), mainFibreGroup
       trigger_script_arg 0, battle_formation, "formation"
       trigger_script_arg 1, battle_formation_set, "formation set"
      END IF
     END IF
    END IF
   END IF
  END IF

  'Each step trigger
  IF gmap(14) > 0 THEN
   trigger_script gmap(14), 3, YES, "eachstep", "map " & gam.map.id, mainFibreGroup
   trigger_script_arg 0, herotx(0), "tile x"
   trigger_script_arg 1, heroty(0), "tile y"
   trigger_script_arg 2, herodir(0), "direction"
  END IF

 END IF '--End of on-step triggers
END SUB


'==========================================================================================
'                                       Zone triggers
'==========================================================================================


SUB process_zone_eachstep_triggers(who as string, byval zones as integer vector)
 FOR i as integer = 0 TO v_len(zones) - 1
  'debuginfo who & " step in zone " & zones[i]
 NEXT
END SUB

SUB process_zone_entry_triggers(who as string, byval oldzones as integer vector, byval newzones as integer vector)
 'Check for differences between two sorted lists of zone IDs, and run entry and exit triggers

 DIM oldi as integer = 0  'index in oldzones()
 DIM newi as integer = 0  'index in newzones()
 DO
  DIM oldzone as integer = IIF(oldi < v_len(oldzones), oldzones[oldi], 999999)
  DIM newzone as integer = IIF(newi < v_len(newzones), newzones[newi], 999999)

  IF oldzone = 999999 AND newzone = 999999 THEN EXIT DO

  IF oldzone > newzone THEN
   'Found newly entered zone
   '(add triggers here)
   'debuginfo who & " entered " & newzone
   newi += 1
  ELSEIF oldzone < newzone THEN
   'Left a zone
   'debuginfo who & " left " & oldzone
   oldi += 1
  ELSE
   'Same zone appears in both lists
   newi += 1
   oldi += 1
  END IF
 LOOP
END SUB

SUB update_hero_zones(byval who as integer)
 DIM newzones as integer vector
 v_move newzones, GetZonesAtTile(zmap, herotx(who), heroty(who))
 process_zone_entry_triggers "hero" & who, herow(who).curzones, newzones
 v_move herow(who).curzones, newzones
END SUB

SUB update_npc_zones(byval npcref as integer)
 DIM newzones as integer vector
 v_move newzones, GetZonesAtTile(zmap, npc(npcref).x \ 20, npc(npcref).y \ 20)
 process_zone_entry_triggers "npc" & npcref, npc(npcref).curzones, newzones
 v_move npc(npcref).curzones, newzones
END SUB


'==========================================================================================
'                                      NPC movement
'==========================================================================================


'NPC movement
'Note that NPC xgo and ygo can also be set from elsewhere, eg. being pushed
SUB update_npcs ()
 FOR o as integer = 0 TO UBOUND(npc)
  IF npc(o).id > 0 THEN
   DIM as integer id = (npc(o).id - 1)

   '--if this is the active vehicle
   IF vstate.active = YES AND vstate.npc = o THEN
    '--if we are not scrambling clearing or aheading
    IF vstate.mounting = NO AND vstate.trigger_cleanup = NO AND vstate.ahead = NO THEN
     '--match vehicle to main hero
     npc(o).x = herox(0)
     npc(o).y = heroy(0)
     npc(o).z = heroz(0) 'NPC Z value is matched to the hero in update_vehicle_state for simplicity, but
                         'this is here in case of setheroz or setnpcz or loaded map state or other funkiness happens
     npc(o).dir = herodir(0)
     npc(o).frame = herow(0).wtog
    END IF
   ELSE
    '--For all NPCs except the active vehicle
    IF (txt.sayer <> o ANDALSO readbit(gen(), genSuspendBits, suspendnpcs) = 0 ANDALSO npc(o).suspend_ai = 0) ORELSE npc(o).pathover.override THEN
     IF npc(o).xgo = 0 AND npc(o).ygo = 0 THEN
      pick_npc_action npc(o), npcs(id)
     END IF
    END IF

   END IF

   DIM oldpos as XYPair = npc(o).pos

   DIM finished_step as bool = NO
   IF npc(o).xgo <> 0 OR npc(o).ygo <> 0 THEN finished_step = perform_npc_move(o, npc(o), npcs(id))

   IF oldpos = npc(o).pos THEN
    npc(o).stillticks += 1
   ELSE
    npc(o).stillticks = 0
   END IF

   'Recalculate current zones every tick (see update_heroes for rationale)
   update_npc_zones o

   IF finished_step THEN
    process_zone_eachstep_triggers "npc" & o, npc(o).curzones
   END IF

  END IF
 NEXT o
END SUB

SUB npcmove_random_wander(npci as NPCInst)
 DIM percent_chance_to_move as integer = 25
 IF wraptouch(npci.pos, heropos(0), 20) THEN
  'Far more likely to hold still while touching the hero
  percent_chance_to_move = 5
 END IF
 IF randint(100) < percent_chance_to_move THEN
  DIM dir_to_go as integer = randint(4)
  npci.dir = dir_to_go
  IF dir_to_go = 0 THEN npci.ygo = 20
  IF dir_to_go = 2 THEN npci.ygo = -20
  IF dir_to_go = 3 THEN npci.xgo = 20
  IF dir_to_go = 1 THEN npci.xgo = -20
 END IF
END SUB

SUB npcmove_walk_ahead(npci as NPCInst)
 IF npci.dir = 0 THEN npci.ygo = 20
 IF npci.dir = 2 THEN npci.ygo = -20
 IF npci.dir = 3 THEN npci.xgo = 20
 IF npci.dir = 1 THEN npci.xgo = -20
END SUB

SUB npcmove_meandering_chase(npci as NPCInst, byval avoid_instead as bool = NO)
 DIM d as integer
 IF randint(100) < 50 THEN
  'Vertical movement
  IF heroy(0) < npci.y THEN d = 0
  IF heroy(0) > npci.y THEN d = 2
  IF gmap(5) = 1 THEN
   'Special handling for wraparound maps
   IF heroy(0) - mapsizetiles.y * 10 > npci.y THEN d = 0
   IF heroy(0) + mapsizetiles.y * 10 < npci.y THEN d = 2
  END IF
  IF heroy(0) = npci.y THEN d = randint(4)
 ELSE
  'Horizontal movement
  IF herox(0) < npci.x THEN d = 3
  IF herox(0) > npci.x THEN d = 1
  IF gmap(5) = 1 THEN
   'Special handling for wraparound maps
   IF herox(0) - mapsizetiles.x * 10 > npci.x THEN d = 3
   IF herox(0) + mapsizetiles.x * 10 < npci.x THEN d = 1
  END IF
  IF herox(0) = npci.x THEN d = randint(4)
 END IF
 IF avoid_instead THEN d = loopvar(d, 0, 3, 2) 'invert the direction
 npci.dir = d
 npcmove_walk_ahead(npci)
END SUB

SUB npcmove_meandering_avoid(npci as NPCInst)
 npcmove_meandering_chase(npci, YES)
END SUB

SUB npcmove_walk_in_place(npci as NPCInst)
 npci.frame = loopvar(npci.frame, 0, 3, 1)
END SUB

SUB npcmove_direct_chase(npci as NPCInst, npcdata as NPCType)
 DIM t1 as XYPair = npci.pos / 20
 DIM t2 as XYPair = herotpos(0)
 DIM dist as XYPair = t2 - t1
 DIM axis as integer '0=horizontal, 1=vertical
 IF dist.x = 0 THEN
  'Lined up horizontally
  axis = 1
 ELSEIF dist.y = 0 THEN
  'Lined up vertically
  axis = 0
 ELSE
  'All diagonals
  IF ABS(dist.x) < ABS(dist.y) THEN
   'Horizontal first
   'Prefers closing the shortest distance first
   axis = 0
  ELSEIF ABS(dist.y) < ABS(dist.x) THEN
   'Vertical first
   'Prefers closing the shortest distance first
   axis = 1
  ELSE
   'Exactly diagonal, use manhattan distance modulo 1 as a non-random tiebreaker
   axis = (ABS(dist.x) + ABS(dist.y)) MOD 1
  END IF
  'Check for walls
  DIM obstructed(1) as bool
  FOR i as integer = 0 TO 1
   obstructed(i) = npc_collision_check(npci, npcdata, xypair_direction(dist, i, npci.dir))
  NEXT i
  'There is a wall in the preferred direction, go the other way
  IF obstructed(axis) THEN axis = axis XOR 1
 END IF
 npci.dir = xypair_direction(dist, axis, npci.dir)
 npcmove_walk_ahead(npci)
END SUB

SUB npcmove_direct_avoid(npci as NPCInst, npcdata as NPCType)
 DIM t1 as XYPair = npci.pos / 20
 DIM t2 as XYPair = herotpos(0)
 DIM dist as XYPair = t2 - t1
 DIM axis as integer '0=horizontal, 1=vertical
 IF dist.x = 0 THEN
  'Lined up horizontally
  axis = 1
 ELSEIF dist.y = 0 THEN
  'Lined up vertically
  axis = 0
 ELSE
  'All diagonals
  IF ABS(dist.x) > ABS(dist.y) THEN
   'Horizontal first
   'Prefers fleeing in the longest distance first
   axis = 0
  ELSEIF ABS(dist.y) > ABS(dist.x) THEN
   'Vertical first
   'Prefers fleeing the longest distance first
   axis = 1
  ELSE
   'Exactly diagonal, use manhattan distance modulo 1 as a non-random tiebreaker
   axis = (ABS(dist.x) + ABS(dist.y)) MOD 1
  END IF
  'Check for walls
  DIM obstructed(1) as bool
  FOR i as integer = 0 TO 1
   obstructed(i) = npc_collision_check(npci, npcdata, xypair_direction(dist * -1, i, npci.dir))
  NEXT i
  'There is a wall in the preferred direction, go the other way
  IF obstructed(axis) THEN axis = axis XOR 1
 END IF
 npci.dir = xypair_direction(dist * -1, axis, npci.dir)
 npcmove_walk_ahead(npci)
END SUB

SUB npcmove_change_dir_and_walk_ahead(npci as NPCInst, byval new_dir as integer)
 npci.dir = new_dir
 npcmove_walk_ahead(npci)
END SUB

SUB npcmove_rotate_and_walk_ahead(npci as NPCInst, byval rota as integer, byval amount as integer = 1)
 'rota 1=clockwise -1=counterclockwise
 npcmove_change_dir_and_walk_ahead(npci, walkrotate(npci.dir, rota, amount))
END SUB

SUB npcmove_follow_walls(npci as NPCInst, npcdata as NPCType, byval side as integer)
 'side is 1 for right-hand walls and -1 for left-hand walls
 DIM d as integer = npci.dir
 d = walkrotate(d, side)
 IF NOT npc_collision_check(npci, npcdata, d) THEN
  'No side-wall present, we might want to turn
  DIM tile as XYPair = npci.pos / 20
  xypair_move tile, d
  IF npc_collision_check_at(npci, tile, walkrotate(d, side)) THEN
   'A wall is present in this direction for us to follow
   npcmove_change_dir_and_walk_ahead(npci, d)
   EXIT SUB
  END IF
  'Look to see if a narrow wall is present to do a u-turn around
  d = walkrotate(d, side)
  xypair_move tile, d
  IF npc_collision_check_at(npci, tile, walkrotate(d, side)) THEN
   'A wall is present for us to u-turn around, so start the first half of the u-turn
   npcmove_change_dir_and_walk_ahead(npci, walkrotate(d, side * -1))
   EXIT SUB
  END IF
 END IF
 d = npci.dir
 IF npc_collision_check(npci, npcdata, d) THEN
  'Blocked ahead, turn.
  npcmove_change_dir_and_walk_ahead(npci, walkrotate(d, side * -1))
  EXIT SUB
 END IF
 'No walls present that would motivate us to turn, so just keep going forward
 npcmove_walk_ahead(npci)
END SUB

SUB npcmove_follow_walls_stop_for_others(npci as NPCInst, npcdata as NPCType, byval side as integer)
 'side is 1 for right-hand walls and -1 for left-hand walls
 DIM d as integer = npci.dir
 d = walkrotate(d, side)
 IF NOT npc_collision_check_walls_and_zones(npci, d) THEN
  'No side-wall present, we might want to turn
  DIM tile as XYPair = npci.pos / 20
  xypair_move tile, d
  IF npc_collision_check_at_walls_and_zones(npci, tile, walkrotate(d, side)) THEN
   'A wall is present in this direction for us to follow
   npcmove_change_dir_and_walk_ahead(npci, d)
   EXIT SUB
  END IF
  'Look to see if a narrow wall is present to do a u-turn around
  d = walkrotate(d, side)
  xypair_move tile, d
  IF npc_collision_check_at_walls_and_zones(npci, tile, walkrotate(d, side)) THEN
   'A wall is present for us to u-turn around, so start the first half of the u-turn
   npcmove_change_dir_and_walk_ahead(npci, walkrotate(d, side * -1))
   EXIT SUB
  END IF
 END IF
 d = npci.dir
 IF npc_collision_check_walls_and_zones(npci, d) THEN
  'Blocked ahead, turn.
  npcmove_change_dir_and_walk_ahead(npci, walkrotate(d, side * -1))
  EXIT SUB
 END IF
 'No walls present that would motivate us to turn, so just keep going forward
 npcmove_walk_ahead(npci)
END SUB

SUB npcmove_pathfinding_chase(npci as NPCInst, npcdata as NPCType)
 if npci.pathover.stop_after_stillticks > 0 andalso npci.stillticks > npci.pathover.stop_after_stillticks then
  cancel_npc_movement_override (npci)
  return
 end if
 if npci.pathover.cooldown > 0 then
  npci.pathover.cooldown -= 1
  return
 end if

 dim should_collide_with_hero as bool = NO
 
 dim t1 as XYPair = npci.pos / 20
 dim t2 as XYPair
 select case npci.pathover.override
  case NPCOverrideMove.NONE
   'No override is currently happening, default to chasing the leader hero
   t2 = herotpos(0)
   should_collide_with_hero = NO
  case NPCOverrideMove.NPC
   if npc(npci.pathover.dest_npc).id = 0 then
    'NPC must have been deleted
    cancel_npc_movement_override (npci)
    return
   end if
   t2 = npc(npci.pathover.dest_npc).pos / 20
   if npci.pathover.stop_when_npc_reached andalso xypair_wrapped_distance(t1, t2) <= 1 then
    'Within 1 tile of destination
    cancel_npc_movement_override (npci)
    return
   end if
   should_collide_with_hero = YES
  case NPCOverrideMove.POS
   t2 = npci.pathover.dest_pos
   if t1 = t2 then
    'Already at destination
    cancel_npc_movement_override (npci)
    return
   end if
   should_collide_with_hero = YES
 end select

 dim pf as AStarPathfinder = AStarPathfinder(t1, t2, 1000)
 pf.calculate(@npci, should_collide_with_hero)
 'pf.debug_path()
 if v_len(pf.path) > 1 then
  'Don't move unless a path is found that is longer than one tile
  
  npci.dir = xypair_direction_to(pf.path[0], pf.path[1], npci.dir)
  npcmove_walk_ahead(npci)
 else
  'Don't try again for 10 ticks
  npci.pathover.cooldown = 10
 end if
END SUB

SUB cancel_npc_movement_override (npci as NPCInst)
 npci.pathover.override = NPCOverrideMove.NONE
 npci.pathover.dest_pos = XY(-1, -1)
 npci.pathover.dest_npc = 0
 npci.pathover.stop_when_npc_reached = NO
 npci.pathover.stop_after_stillticks = 0
 npci.pathover.cooldown = 0
END SUB

'A currently stationary NPC decides what to do.
'Most move types are implemented here, but some are handled upon collision in npchitwall()
SUB pick_npc_action(npci as NPCInst, npcdata as NPCType)
 
 IF npcdata.movetype <> 8 ANDALSO npcdata.speed = 0 THEN
  ' Do nothing for most movetypes when walking speed is 0
  EXIT SUB
 END IF

 IF npci.pathover.override THEN 
  npcmove_pathfinding_chase(npci, npcdata)
  EXIT SUB
 END IF
 
 SELECT CASE npcdata.movetype
  CASE 1:
   npcmove_random_wander(npci)
  CASE 2,3,4,5:
   'This handles the movement part of pacing.
   'See also the collision detection in perform_npc_move()
   npcmove_walk_ahead(npci)
  CASE 6:
   npcmove_meandering_chase(npci)
  CASE 7:
   npcmove_meandering_avoid(npci)
  CASE 8:
   npcmove_walk_in_place(npci)
  CASE 9:
   npcmove_direct_chase(npci, npcdata)
  CASE 10:
   npcmove_direct_avoid(npci, npcdata)
  CASE 11:
   npcmove_follow_walls(npci, npcdata, 1)
  CASE 12:
   npcmove_follow_walls(npci, npcdata, -1)
  CASE 13:
   npcmove_follow_walls_stop_for_others(npci, npcdata, 1)
  CASE 14:
   npcmove_follow_walls_stop_for_others(npci, npcdata, -1)
  CASE 15:
   npcmove_pathfinding_chase(npci, npcdata)
 END SELECT

END SUB

FUNCTION perform_npc_move(byval npcnum as integer, npci as NPCInst, npcdata as NPCType) as bool
 '--npcnum is the npc() index of npci.
 '--Here we attempt to actually update the coordinates for this NPC, checking obstructions
 '--Return true if we finished a step (didgo)
 DIM didgo as bool = NO
 npci.frame = loopvar(npci.frame, 0, 3, 1)
 DIM hit_something as bool = NO
 IF movdivis(npci.xgo) OR movdivis(npci.ygo) THEN
  'This check only happens when the NPC is about to start moving to a new tile
  DIM collision_type as WalkaboutCollisionType
  IF npc_collision_check(npci, npcdata, npci.xgo, npci.ygo, collision_type) THEN
   npci.xgo = 0
   npci.ygo = 0
   IF collision_type = collideHero THEN
    '--a 0-3 tick delay before pacing enemies bounce off hero
    'James: "This delay feels like something I must have done by mistake in the late 90's"
    IF npci.frame = 3 THEN
     npchitwall(npci, npcdata)
     hit_something = YES
    END IF
   ELSE
    npchitwall(npci, npcdata)
    hit_something = YES
   END IF
  END IF
 END IF

 IF NOT hit_something THEN
  'If we didn't hit any obstacle, actually move
  IF npcdata.speed THEN
   '--change x,y and decrement wantgo by speed
   IF npci.xgo OR npci.ygo THEN
    IF npci.xgo > 0 THEN npci.xgo -= npcdata.speed: npci.x -= npcdata.speed
    IF npci.xgo < 0 THEN npci.xgo += npcdata.speed: npci.x += npcdata.speed
    IF npci.ygo > 0 THEN npci.ygo -= npcdata.speed: npci.y -= npcdata.speed
    IF npci.ygo < 0 THEN npci.ygo += npcdata.speed: npci.y += npcdata.speed
    IF (npci.xgo MOD 20) = 0 AND (npci.ygo MOD 20) = 0 THEN didgo = YES
   END IF
  ELSE
   '--no speed, kill wantgo
   npci.xgo = 0
   npci.ygo = 0
   '--also kill pathfinding override
   cancel_npc_movement_override (npci)
  END IF
  IF cropmovement(npci.pos, npci.xygo) THEN npchitwall(npci, npcdata)
 END IF

 '--Check touch activation (always happens). I have no idea why this is here!
 IF npcdata.activation = 1 AND txt.showing = NO THEN
  IF wraptouch(npci.pos, heropos(0), 20) THEN
   usenpc 1, npcnum
  END IF
 END IF

 RETURN didgo
END FUNCTION

FUNCTION npc_collision_check_walls_and_zones(npci as NPCInst, byval direction as integer) as bool
 DIM collide_type as WalkaboutCollisionType
 DIM result as bool = npc_collision_check(npci, direction, collide_type)
 IF collide_type = collideNPC ORELSE collide_type = collideHero THEN RETURN NO
 RETURN result
END FUNCTION

FUNCTION npc_collision_check_at_walls_and_zones(npci as NPCInst, tile as XYPair, byval direction as integer) as bool
 DIM collide_type as WalkaboutCollisionType
 DIM result as bool = npc_collision_check_at(npci, tile, direction, collide_type)
 IF collide_type = collideNPC ORELSE collide_type = collideHero THEN RETURN NO
 RETURN result
END FUNCTION

FUNCTION npc_collision_check_at(npci as NPCInst, tile as XYPair, byval direction as integer, byref collision_type as WalkaboutCollisionType=collideNone, byval npc_ccache as NPCCollisionCache Ptr=0) as bool
 'Returns an NPC collision check as if the NPC was at a different location than it really is
 DIM savepos as XYPair = npci.pos
 DIM savego as XYPair = npci.xygo
 'Temporarily override NPC position and movement
 npci.pos = tile * 20
 npci.xygo = 0
 DIM result as bool
 result = npc_collision_check(npci, direction, collision_type, npc_ccache)
 'Restore real NPC position and movement
 npci.pos = savepos
 npci.xygo = savego
 RETURN result
END FUNCTION

FUNCTION hero_collision_check_at(byval rank as integer, tile as XYPair, byval direction as integer, byref collision_type as WalkaboutCollisionType=collideNone, byval npc_ccache as NPCCollisionCache Ptr=0) as bool
 'Returns an Hero collision check as if the Hero was at a different location than it really is
 DIM savepos as XYPair = heropos(rank)
 DIM savego as XYPair = herow(rank).xygo
 'Temporarily override hero position and movement
 (heropos(rank)) = tile * 20
 herow(rank).xygo = 0
 DIM result as bool
 result = hero_collision_check(rank, direction, collision_type, npc_ccache)
 'Restore real hero position and movement
 (heropos(rank)) = savepos
 herow(rank).xygo = savego
 RETURN result
END FUNCTION

FUNCTION npc_collision_check(npci as NPCInst, byval direction as integer, byref collision_type as WalkaboutCollisionType=collideNone, byval npc_ccache as NPCCollisionCache Ptr=0) as bool
 RETURN npc_collision_check(npci, npcs(ABS(npci.id) - 1), direction, collision_type, npc_ccache)
END FUNCTION

FUNCTION npc_collision_check(npci as NPCInst, npcdata as NPCType, byval direction as integer, byref collision_type as WalkaboutCollisionType=collideNone, byval npc_ccache as NPCCollisionCache Ptr=0) as bool
 DIM go as XYPair
 xypair_move go, direction, 20
 'NPC xgo and ygo are backwards, so we invert the value we got from xypair_move()
 RETURN npc_collision_check(npci, npcdata, go.x * -1, go.y * -1, collision_type, npc_ccache)
END FUNCTION

FUNCTION hero_collision_check(byval rank as integer, byval direction as integer, byref collision_type as WalkaboutCollisionType=collideNone, byval npc_ccache as NPCCollisionCache Ptr=0) as bool
 DIM go as XYPair
 xypair_move go, direction, 20
 'Hero xgo and ygo are backwards, so we invert the value we got from xypair_move()
 RETURN hero_collision_check(rank, go.x * -1, go.y * -1, collision_type, npc_ccache)
END FUNCTION

FUNCTION npc_collision_check(npci as NPCInst, npcdata as NPCType, byval xgo as integer, byval ygo as integer, byref collision_type as WalkaboutCollisionType=collideNone, byval npc_ccache as NPCCollisionCache Ptr=0) as bool
 'Returns true if the NPC would collide with a wall, zone, npc, hero, etc
 
 'This function works with local copies of xgo and ygo because it calls functions that modify
 'the xgo and ygo passed in, but we don't want to alter npci.xgo and npci.ygo if we are just
 'checking whether collision could possibly happen.

 'NPC xgo and ygo are backwards from what you might expect! xgo=-1 means the hero wants to 1 pixel right

 'Collision type optionally communicates which type of collision was detected first.
 'If two types of collision are possible for a single move, only the first will ever be indicated 

 DIM tilepos as XYPair 'Which tile is the center of the NPC on?
 tilepos.x = (npci.x + 10) \ 20
 tilepos.y = (npci.y + 10) \ 20
 DIM pixelpos as XYPair 'Tile top left corner pixel pos for passing to wrapzonecheck
 pixelpos = tilepos * 20

 IF readbit(gen(), genSuspendBits, suspendnpcwalls) = 0 AND npci.ignore_walls = 0 THEN
  '--this only happens if NPC walls on
  IF wrappass(tilepos.x, tilepos.y, xgo, ygo, NO, npcdata.ignore_passmap) THEN
   collision_type = collideWall
   RETURN YES
  END IF
  '--Check for movement zones (treat the edges as walls)
  DIM zone as integer = npcdata.defaultzone
  IF zone = 0 THEN zone = gmap(32)  'fallback to default
  IF zone > 0 ANDALSO wrapzonecheck(zone, pixelpos, XY(xgo, ygo)) = 0 THEN
   collision_type = collideMoveZone
   RETURN YES
  END IF
  '--Check for avoidance zones (treat as walls)
  zone = npcdata.defaultwallzone
  IF zone = 0 THEN zone = gmap(33)  'fallback to default
  IF zone > 0 ANDALSO wrapzonecheck(zone, pixelpos, XY(xgo, ygo)) THEN
   collision_type = collideAvoidZone
   RETURN YES
  END IF
 END IF
 IF readbit(gen(), genSuspendBits, suspendobstruction) = 0 AND npci.not_obstruction = 0 THEN
  '--this only happens if obstruction is on
  '---Check for NPC-NPC collision
  IF npc_ccache <> 0 THEN
   'An NPC collision cache is available, check it
   DIM tpos as XYPair = XY((npci.x - xgo) / 20, (npci.y - ygo) / 20)
   wrapxy tpos
   IF npc_ccache->obstruct(tpos.x, tpos.y) THEN
    collision_type = collideNPC
    RETURN YES
   END IF
  ELSE
   'Loop through all the NPCs and check them
   FOR i as integer = 0 TO UBOUND(npc)
    IF npc(i).id > 0 AND @npci <> @npc(i) AND npc(i).not_obstruction = 0 THEN
     IF wrapcollision (npc(i).pos, npc(i).xygo, npci.pos, XY(xgo, ygo)) THEN
      collision_type = collideNPC
      RETURN YES
     END IF
    END IF
   NEXT i
  END IF
  '---Check for hero-NPC collision
  IF npcdata.activation <> 2 THEN  'Not step-on activated
   IF wrapcollision (npci.pos, XY(xgo, ygo), heropos(0), herow(0).xygo) THEN
    collision_type = collideHero
    RETURN YES
   END IF
  END IF
 END IF
 
 'Did not collide with anything
 collision_type = collideNone
 RETURN NO
END FUNCTION

FUNCTION hero_collision_check(byval rank as integer, byval xgo as integer, byval ygo as integer, byref collision_type as WalkaboutCollisionType=collideNone, byval npc_ccache as NPCCollisionCache Ptr=0) as bool
 'Returns true if the hero would collide with a wall, zone, npc, hero, etc
 
 'This function works with local copies of xgo and ygo because it calls functions that modify
 'the xgo and ygo passed in, but we don't want to alter herow().xgo and herow().ygo if we are just
 'checking whether collision could possibly happen.

 'Hero xgo and ygo are backwards from what you might expect! xgo=-1 means the hero wants to 1 pixel right

 'Collision type optionally communicates which type of collision was detected first.
 'If two types of collision are possible for a single move, only the first will ever be indicated 

 DIM tilepos as XYPair 'Which tile is the center of the hero on?
 tilepos = herotpos(rank)

 IF readbit(gen(), genSuspendBits, suspendherowalls) = 0 THEN
  '--this only happens if hero walls are on
  IF wrappass(tilepos.x, tilepos.y, xgo, ygo, NO, NO) THEN
   IF NOT hero_should_ignore_walls(rank) THEN
    collision_type = collideWall
    RETURN YES
   END IF
  END IF
  '--If heroes had zone restrictions like NPCs, this would be the place to check them (But they don't!)
 END IF
 IF readbit(gen(), genSuspendBits, suspendobstruction) = 0 THEN
  '--this only happens if obstruction is on
  '---Check for hero-NPC collision
  IF npc_ccache <> 0 THEN
   'An NPC collision cache is available, check it
   DIM tpos as XYPair = XY((herox(rank) - xgo) / 20, (heroy(rank) - ygo) / 20)
   wrapxy tpos
   IF npc_ccache->obstruct(tpos.x, tpos.y) THEN
    collision_type = collideNPC
    RETURN YES
   END IF
  ELSE
   'Loop through all the NPCs and check them
   FOR i as integer = 0 TO UBOUND(npc)
    IF npc(i).id > 0 ANDALSO npc(i).not_obstruction = 0 THEN
     IF npcs(npc(i).id - 1).activation <> 2 THEN ' Only for NPCs that are not step-on activated
      IF wrapcollision (npc(i).pos, npc(i).xygo, heropos(i), XY(xgo, ygo)) THEN
       collision_type = collideNPC
       RETURN YES
      END IF
     END IF
    END IF
   NEXT i
  END IF
  '---Do Not Check for hero-hero collision (but if we did, it would go here)
 END IF
 
 'Did not collide with anything
 collision_type = collideNone
 RETURN NO
END FUNCTION

SUB npchitwall(npci as NPCInst, npcdata as NPCType)
 IF npci.suspend_ai = 0 THEN
  IF npci.pathover.override THEN
   'Don't do any of this if normal movement has been temporarily overridden by pathfinding
   EXIT SUB
  END IF
  IF npcdata.movetype = 2 THEN npci.dir = loopvar(npci.dir, 0, 3, 2)  'Pace
  IF npcdata.movetype = 3 THEN npci.dir = loopvar(npci.dir, 0, 3, 1)  'Right Turns
  IF npcdata.movetype = 4 THEN npci.dir = loopvar(npci.dir, 0, 3, -1) 'Left Turns
  IF npcdata.movetype = 5 THEN npci.dir = randint(4)                'Random Turns
 END IF
END SUB


'==========================================================================================
'                                         Scripts
'==========================================================================================


SUB execute_script_fibres
 WHILE nowscript >= 0
  WITH scriptinsts(nowscript)
   IF .waiting THEN
    process_wait_conditions
   END IF
   IF .waiting THEN
    EXIT WHILE
   END IF

   '--interpret script
   insideinterpreter = YES
   wantimmediate = 0
   'May set wantimmediate to -1 to indicate fibre finished, or -2 to indicate fibre
   'finished in way that triggered bug 430
   scriptinterpreter
   insideinterpreter = NO

   IF wantimmediate = -2 THEN
    'IF nowscript < 0 THEN
    ' debug "wantimmediate ended on nowscript = -1"
    'ELSE
    ' debug "wantimmediate would have skipped wait on command " & commandname(scrat(nowscript).curvalue) _
    '       & " in " & scriptname(scrat(nowscript).id) & ", state = " & scrat(nowscript).state
    'END IF
    IF readbit(gen(), genBits2, 17) THEN
     'Reenable bug 430 (see also bug 550), where if two scripts were triggered at once then
     'when the top script ended it would cause the one below it to run for two ticks.
     wantimmediate = -1
    ELSE
     wantimmediate = 0
    END IF
   END IF

   IF wantimmediate = 0 THEN EXIT WHILE
  END WITH
 WEND
END SUB

SUB interpret_scripts()
 'It seems like it would be good to call this immediately before scriptinterpreter so that
 'the return values of fightformation and waitforkey are correct, however doing so might
 'break something?
 run_queued_scripts

 execute_script_fibres

 script_log_tick
 gam.script_log.tick += 1

 'Do spawned text boxes, battles, etc.
 'The actual need for these gam.want.* variables is now gone, but they are kept around for backcompat.
 'They could be removed and the implementations moved straight into the command handlers,
 '(and the implicit waits made optional at the same time), but this makes things especially tricky
 'for concurrent fibres.
 'For example if a script changes the map (whether through a textbox, teleporttomap, or door use)
 'it currently prevents any other script from running for the rest of the tick, preventing the potentially
 'disasterous (for scripted games) situation where the map changes and other scripts run before the
 'map autorun script (which might contain important initialisation). 

 'Also note that now if two fibres run two commands like fightformation and usedoor the order in which
 'they occur is independent of the order in which they were called.

 'FIXME: 
 'Currently if a map changes (or even is a game is loaded) there is one tick on the new map
 'before the map autorun or any other scripts can make changes. This transition is hidden by screen fades
 'and now by the delayed music change. But if the map change happens without a fade (teleporttomap, or
 'if we make fades customisable) that one tick delay is undesired.
 'So consider delaying all calls to prepare_map (and doloadgame) until the start of the next tick.

 IF gam.want.box > 0 THEN
  loadsay gam.want.box
 END IF
 gam.want.box = 0
 IF gam.want.door > 0 THEN
  usedoor gam.want.door - 1
  gam.want.door = 0
 END IF
 IF gam.want.battle > 0 THEN
  fatal = NO
  gam.wonbattle = battle(gam.want.battle - 1)
  gam.want.battle = 0
  prepare_map YES
  gam.random_battle_countdown = range(100, 60)
  queue_fade_in 2 'FIXME: why 2 ticks?
  setkeys
 END IF
 IF gam.want.teleport THEN
  gam.want.teleport = NO
  prepare_map
  gam.random_battle_countdown = range(100, 60)
 END IF
 IF gam.want.usenpc > 0 THEN
  usenpc 2, gam.want.usenpc - 1
  gam.want.usenpc = 0
 END IF
 'ALSO gam.want.loadgame, gam.want.rungame
END SUB


'==========================================================================================
'                                   Loading map lumps
'==========================================================================================


'Call after loading gmap()
SUB gmap_updates
 IF gmap(31) = 0 THEN gmap(31) = 2  'Number of layers beneath walkabouts.
 refresh_map_slice  'Because map layer and walkabout sorting may have changed.

 loadmaptilesets tilesets(), gmap()
 refresh_map_slice_tilesets
END SUB

'The following functions can get called from "reset map state", so have to do
'things like sice refreshing that are redundant from within preparemap().

SUB loadmap_gmap(byval mapnum as integer)
 lump_reloading.gmap.dirty = NO
 lump_reloading.gmap.changed = NO
 loadrecord gmap(), game & ".map", getbinsize(binMAP) / 2, mapnum
 gmap_updates
END SUB

SUB loadmap_npcl(byval mapnum as integer)
 lump_reloading.npcl.changed = NO
 lump_reloading.npcl.hash = hash_file(maplumpname(mapnum, "l"))
 LoadNPCL maplumpname(mapnum, "l"), npc()

 'Evaluate whether NPCs should appear or disappear based on tags
 visnpc
END SUB

SUB loadmap_npcd(byval mapnum as integer)
 lump_reloading.npcd.dirty = NO
 lump_reloading.npcd.changed = NO
 lump_reloading.npcd.hash = hash_file(maplumpname(mapnum, "n"))
 LoadNPCD maplumpname(mapnum, "n"), npcs()

 'Evaluate whether NPCs should appear or disappear based on tags
 visnpc
 'load NPC graphics
 reset_npc_graphics
END SUB

'Load all map layers
SUB loadmap_tilemap(byval mapnum as integer)
 lump_reloading.maptiles.dirty = NO
 lump_reloading.maptiles.changed = NO
 lump_reloading.maptiles.hash = hash_file(maplumpname(mapnum, "t"))
 LoadTileMaps maptiles(), maplumpname(mapnum, "t")
 mapsizetiles.w = maptiles(0).wide
 mapsizetiles.h = maptiles(0).high
 update_map_slices_for_new_tilemap

 '--as soon as we know the dimensions of the map, enforce hero position boundaries
 cropposition herox(0), heroy(0), 20
END SUB

SUB loadmap_passmap(byval mapnum as integer)
 lump_reloading.passmap.dirty = NO
 lump_reloading.passmap.changed = NO
 lump_reloading.passmap.hash = hash_file(maplumpname(mapnum, "p"))
 LoadTileMap pass, maplumpname(mapnum, "p")
END SUB

SUB loadmap_foemap(byval mapnum as integer)
 lump_reloading.foemap.dirty = NO
 lump_reloading.foemap.changed = NO
 lump_reloading.foemap.hash = hash_file(maplumpname(mapnum, "e"))
 LoadTileMap foemap, maplumpname(mapnum, "e")
END SUB

SUB loadmap_zonemap(byval mapnum as integer)
 lump_reloading.zonemap.dirty = NO
 lump_reloading.zonemap.changed = NO
 '.Z is the only one of the map lumps that has been added in about the last decade
 DIM filename as string = maplumpname(mapnum, "z")
 IF isfile(filename) THEN
  LoadZoneMap zmap, filename
  lump_reloading.zonemap.hash = hash_file(filename)
 ELSE
  CleanZoneMap zmap, mapsizetiles.x, mapsizetiles.y
  lump_reloading.zonemap.hash = 0
 END IF
END SUB

'This sub is only used by "reset map state" command
SUB loadmap_bitmask (byval mapnum as integer, byval loadmask as integer)
 'loads some, but not all the lumps needed for each map
 IF loadmask AND 1 THEN
  loadmap_gmap mapnum
 END IF
 IF loadmask AND 2 THEN
  loadmap_npcl mapnum
 END IF
 IF loadmask AND 4 THEN
  loadmap_npcd mapnum
 END IF
 IF loadmask AND 8 THEN
  loadmap_tilemap mapnum
 END IF
 IF loadmask AND 16 THEN
  loadmap_passmap mapnum
 END IF
 IF loadmask AND 32 THEN
  loadmap_zonemap mapnum
 END IF
END SUB

'==========================================================================================

SUB MenuSound(byval s as integer)
  IF s THEN
    stopsfx s-1
    playsfx s-1, 0
  END IF
END SUB

SUB usemenusounds (byval deckey as integer = scUp, byval inckey as integer = scDown)
  IF keyval(deckey) > 1 ORELSE keyval(inckey) > 1 ORELSE keyval(scPageup) > 1 _
       ORELSE keyval(scPagedown) > 1 ORELSE keyval(scHome) > 1 ORELSE keyval(scEnd) > 1 THEN
    menusound gen(genCursorSFX)
  END IF
END SUB


'==========================================================================================
'                                         Timers
'==========================================================================================


FUNCTION should_skip_this_timer(timercontext as TimerContextEnum, tmr as PlotTimer) as bool
 IF timercontext = TIMER_BATTLE THEN
  'This is happening in battle!
  IF (tmr.flags AND TIMERFLAG_BATTLE) = 0 THEN
   RETURN YES
  END IF
 ELSEIF timercontext = TIMER_BLOCKINGMENUS THEN
  'This is happening in a menu!
  IF (tmr.flags AND TIMERFLAG_MENU) = 0 THEN
   RETURN YES
  END IF
 END IF
 RETURN NO
END FUNCTION

' Countdown timers, applying effects (except TIMERFLAG_CRITICAL)
SUB dotimer(timercontext as TimerContextEnum)
  if readbit(gen(), genSuspendBits, suspendtimers) <> 0 then exit sub
  dim i as integer
  for i = 0 to ubound(timers)
    with timers(i)
      if .speed > 0 then
        if should_skip_this_timer(timercontext, timers(i)) then continue for  'not supposed to run here
        'debug "i=" & i & " timercontext=" & timercontext & " .speed=" & .speed & " .ticks=" & .ticks & " .count=" & .count & " .flags=" & .flags & " .trigger=" & .trigger

        if .st > 0 then
          if plotstr(.st - 1).s = "" then plotstr(.st - 1).s = seconds2str(.count)
        end if

        .ticks += 1
        if .ticks >= .speed then
          .count -= 1
          .ticks = 0
          if .st > 0 and .count >= 0 then plotstr(.st - 1).s = seconds2str(.count)
          if .count < 0 then
            .finished_tick = gam.script_log.tick
            .speed *= -1
            .speed -= 1
            'do something
            if .trigger = TIMERTRIGGER_GAMEOVER then
              'Fadeout due to death
              fadeout 255, 0, 0
              gam.quit = YES

              exit sub
            end if

            if .trigger = TIMERTRIGGER_DEFAULT then
              'undefined, shouldn't happen
            end if

            if .trigger >= 0 then  'a plotscript
              ' NOTE: this doesn't run until the next tick (a design flaw)
              trigger_script .trigger, 1, NO, "timer", "", mainFibreGroup
              trigger_script_arg 0, i, "id"
            end if
          end if
        end if
      end if
    end with
  next
end sub

'Update timers from within a battle
'Returns true if the battle should be exited immediately
function dotimerbattle() as bool
  dotimer TIMER_BATTLE  'no sense duplicating code

  dim i as integer
  for i = 0 to ubound(timers)
    with timers(i)
      if .speed < 0 then 'normally, not valid. but, if a timer expired in battle, this will be -ve, -1
        if .flags AND TIMERFLAG_CRITICAL then return YES
      end if
    end with
  next
  return NO
end function


'==========================================================================================
'                                          Menus
'==========================================================================================


'Returns the menu handle
FUNCTION add_menu (byval record as integer, byval allow_duplicate as bool=NO) as integer
 IF record >= 0 AND allow_duplicate = NO THEN
  'If adding a non-blank menu, first check if the requested menu is already open
  DIM menuslot as integer
  menuslot = find_menu_id(record)
  IF menuslot >= 0 THEN
   'the requested menu is already open, just bring it to the top
   bring_menu_forward menuslot
   RETURN menus(topmenu).handle
  END IF
 END IF
 'Load the menu into a new menu slot
 topmenu += 1
 IF topmenu > UBOUND(menus) THEN
  REDIM PRESERVE menus(topmenu) as MenuDef
  REDIM PRESERVE mstates(topmenu) as MenuState
 END IF
 mstates(topmenu).pt = 0
 mstates(topmenu).top = 0
 IF record = -1 THEN
  ClearMenuData menus(topmenu)
 ELSE
  LoadMenuData menu_set, menus(topmenu), record
 END IF
 init_menu_state mstates(topmenu), menus(topmenu)
 IF topmenu > 0 THEN mstates(topmenu - 1).active = NO
 mstates(topmenu).active = YES
 check_menu_tags
 IF get_gen_bool("/mouse/move_hero/cancel_on_menu") THEN
  cancel_hero_pathfinding()
 END IF
 RETURN assign_menu_handles(menus(topmenu))
END FUNCTION

SUB remove_menu (byval slot as integer, byval run_on_close as bool=YES)
 IF slot < 0 OR slot > UBOUND(menus) THEN
  debugc errBug, "remove_menu: invalid slot " & slot
  EXIT SUB
 END IF
 bring_menu_forward slot
 IF menus(topmenu).advance_textbox = YES THEN
  'Advance an open text box.
  'Because this could open other menus, take care to remember this menu's handle
  '(Isn't it impossible for slot to change though?)
  DIM remember_handle as integer = menus(topmenu).handle
  advance_text_box
  slot = find_menu_handle(remember_handle)
  bring_menu_forward slot
 END IF
 IF menus(topmenu).on_close <> 0 AND run_on_close THEN
  trigger_script menus(topmenu).on_close, 0, YES, "menu on-close", "menu " & menus(topmenu).record, mainFibreGroup
 END IF
 ClearMenuData menus(topmenu)
 topmenu = topmenu - 1
 IF topmenu >= 0 THEN
  REDIM PRESERVE menus(topmenu) as MenuDef
  REDIM PRESERVE mstates(topmenu) as MenuState
  mstates(topmenu).active = YES
 END IF
END SUB

SUB bring_menu_forward (byval slot as integer)
 IF slot < 0 OR slot > UBOUND(menus) OR slot > topmenu THEN
  scripterr "bring_menu_forward: invalid slot " & slot, serrBound
  EXIT SUB
 END IF
 mstates(topmenu).active = NO
 FOR i as integer = slot TO topmenu - 1
  SWAP menus(i), menus(i + 1)
  SWAP mstates(i), mstates(i + 1)
 NEXT i
 mstates(topmenu).active = YES
END SUB

FUNCTION menus_allow_gameplay () as bool
 IF topmenu < 0 THEN RETURN YES
 RETURN menus(topmenu).allow_gameplay
END FUNCTION

FUNCTION menus_allow_player () as bool
 IF topmenu < 0 THEN RETURN YES
 RETURN menus(topmenu).suspend_player = NO
END FUNCTION

SUB update_menu_states ()
 FOR i as integer = 0 TO topmenu
  IF mstates(i).need_update THEN
   mstates(i).need_update = NO
   init_menu_state mstates(i), menus(i)
  END IF
 NEXT i
END SUB

FUNCTION player_menu_should_close() as bool
 IF menus(topmenu).no_close THEN RETURN NO
 IF carray(ccMenu) > 1 THEN RETURN YES
 IF menu_click_outside(menus(topmenu)) THEN
  'Clicked while the mouse was outside the menu
  RETURN YES
 END IF
 RETURN NO
END FUNCTION

SUB player_menu_keys ()
 IF topmenu >= 0 THEN
  IF menus(topmenu).no_controls = YES THEN EXIT SUB
  IF gam.debug_camera_pan THEN EXIT SUB
  'Following controls useable on empty menus too

  IF player_menu_should_close() THEN
   carray(ccMenu) = 0
   setkeys ' Forget keypress that closed the menu
   DIM esc_menu as integer = menus(topmenu).esc_menu - 1
   remove_menu topmenu
   menusound gen(genCancelSFX)
   IF esc_menu >= 0 THEN
    add_menu esc_menu
   END IF
   EXIT SUB
  END IF

  'Following controls are for non-empty menus only
  IF mstates(topmenu).last = -1 THEN EXIT SUB

  IF game_usemenu(mstates(topmenu)) THEN
   menusound gen(genCursorSFX)
  END IF
  DIM mi as MenuDefItem '--using a copy of the menu item here is safer (in future) because activate_menu_item() can deallocate it
  mi = *menus(topmenu).items[mstates(topmenu).pt]
  IF mi.disabled THEN EXIT SUB
  ' This is also duplicated in Custom_volume_menu in Custom
  IF mi.t = mtypeSpecial AND (mi.sub_t = spMusicVolume OR mi.sub_t = spVolumeMenu) THEN
   IF carray(ccLeft) > 1 THEN set_music_volume large(get_music_volume - 1/16, 0.0)
   IF carray(ccRight) > 1 THEN set_music_volume small(get_music_volume + 1/16, 1.0)
  END IF
  IF mi.t = mtypeSpecial AND mi.sub_t = spSoundVolume THEN
   IF carray(ccLeft) > 1 THEN set_global_sfx_volume large(get_global_sfx_volume - 1/16, 0.0)
   IF carray(ccRight) > 1 THEN set_global_sfx_volume small(get_global_sfx_volume + 1/16, 1.0)
  END IF
  IF mi.t = mtypeSpecial AND mi.sub_t = spMargins THEN '--TV safe margin
   DIM save_margin as bool = NO
   IF carray(ccLeft) > 1 THEN
    set_safe_zone_margin large(get_safe_zone_margin() - 1, 0)
    save_margin = YES
   END IF
   IF carray(ccRight) > 1 THEN
    set_safe_zone_margin small(get_safe_zone_margin() + 1, 10)
    save_margin = YES
   END IF
   IF save_margin THEN
    save_margin = NO
    write_ini_value config_file, "gfx.margin", get_safe_zone_margin()
   END IF
  END IF
  IF carray(ccUse) > 1 ORELSE menu_click(mstates(topmenu)) THEN
   activate_menu_item mi, topmenu
  END IF
 END IF
END SUB

FUNCTION activate_menu_item(mi as MenuDefItem, byval menuslot as integer) as bool
 DIM open_other_menu as integer = -1 'Menu ID to open
 DIM menu_text_box as integer = 0    'Textbox to open
 DIM updatetags as bool = NO         'Whether to do tag updates
 DIM slot as integer   'Party slot (temp)
 DIM activated as bool = YES
 WITH mi
  SELECT CASE .t
   CASE mtypeCaption
    SELECT CASE .sub_t
     CASE 0 'Selectable
     CASE 1 'Unselectable
      activated = NO
    END SELECT
   CASE mtypeSpecial
    SELECT CASE .sub_t
     CASE spItems
      menu_text_box = item_screen()
      IF menu_text_box > 0 THEN
       IF mi.close_if_selected = NO THEN
        remove_menu menuslot, (mi.skip_close_script = NO)
       END IF
      END IF
     CASE spSpells
      slot = onwho(readglobalstring(106, "Whose Spells?", 20), NO)
      IF slot >= 0 THEN old_spells_menu slot
     CASE spStatus
      slot = onwho(readglobalstring(104, "Whose Status?", 20), NO)
      IF slot >= 0 THEN status_screen slot
     CASE spEquip
      slot = onwho(readglobalstring(108, "Equip Whom?", 20), NO)
      IF slot >= 0 THEN equip_menu slot
     CASE spOrder
      hero_swap_menu 0
     CASE spTeam
      hero_swap_menu 1
     CASE spTeamOrOrder
      hero_swap_menu readbit(gen(), genBits, 5)
     CASE spMap, spMapMaybe
      minimap herox(0), heroy(0)
     CASE spSave, spSaveMaybe
      slot = picksave()
      IF slot >= 0 THEN savegame slot
     CASE spLoad
      slot = pickload(NO, YES)  'No New Game option, beep if the menu doesn't display
      '(Maybe it would be better to display the load menu even if there are no saves)
      IF slot >= 0 THEN
       gam.want.loadgame = slot + 1
      END IF
     CASE spQuit
      menusound gen(genAcceptSFX)
      verify_quit
     CASE spVolumeMenu
      add_menu -1
      create_volume_menu menus(topmenu)
      init_menu_state mstates(topmenu), menus(topmenu)
     CASE spMusicVolume, spSoundVolume
      activated = NO
     CASE spPurchases
      purchases_menu()
     CASE spWindowed
      IF running_on_desktop() THEN
       gfx_setwindowed(YES)
       user_toggled_fullscreen = YES
      END IF
     CASE spFullscreen
      IF running_on_desktop() THEN
       gfx_setwindowed(NO)
       user_toggled_fullscreen = YES
      END IF
    END SELECT
   CASE mtypeMenu
    open_other_menu = .sub_t
   CASE mtypeTextBox
    menu_text_box = .sub_t
   CASE mtypeScript
    DIM numargs as integer = IIF(menus(topmenu).allow_gameplay, 4, 3)
    trigger_script .sub_t, numargs, YES, "menuitem", _
                   "item '" & get_menu_item_caption(mi, menus(menuslot)) _
                   & "' in menu " & menus(menuslot).record, mainFibreGroup
    IF menus(topmenu).allow_gameplay THEN
     '0 is passed instead of the menu item handle if it would be invalid
     trigger_script_arg 0, IIF(mi.close_if_selected, 0, .handle), "item handle"
     trigger_script_arg 1, .extra(0), "extra0"
     trigger_script_arg 2, .extra(1), "extra1"
     trigger_script_arg 3, .extra(2), "extra2"
    ELSE
     'but if the topmost menu suspends gameplay, then a handle will always be invalid
     'by the time the script runs, so pass the extra values instead.
     'Sadly, for back-compatibility, leave out the handle instead of passing zero.
     trigger_script_arg 0, .extra(0), "extra0"
     trigger_script_arg 1, .extra(1), "extra1"
     trigger_script_arg 2, .extra(2), "extra2"
    END IF
  END SELECT
 END WITH
 IF activated THEN
  IF ABS(mi.settag) > 1 THEN settag mi.settag : updatetags = YES
  IF mi.togtag > 1 THEN settag mi.togtag, NOT istag(mi.togtag, 0) : updatetags = YES
  IF mi.close_if_selected THEN
   remove_menu menuslot, (mi.skip_close_script = NO)

   'WARNING: below this point, mi is invalid

   IF insideinterpreter = NO THEN '--Not inside a script
    carray(ccUse) = 0
    setkeys '--Discard the keypress that triggered the menu item that closed the menu
   END IF
  END IF
 END IF
 IF open_other_menu >= 0 THEN
  add_menu open_other_menu
 END IF
 IF menu_text_box > 0 THEN
  '--player has triggered a text box from the menu--
  loadsay menu_text_box
 END IF
 IF updatetags THEN
  evalherotags
  evalitemtags
  tag_updates
 END IF
 RETURN activated
END FUNCTION

'Call this any time a tag is changed!
SUB tag_updates (npc_visibility as bool=YES)
 IF npc_visibility THEN visnpc
 check_menu_tags
END SUB

' Updates which menu items are enabled (for any reason, not just tags)
SUB check_menu_tags ()
 FOR menunum as integer = 0 TO topmenu
  WITH menus(menunum)
   DIM changed as bool = NO
   FOR idx as integer = 0 TO .numitems - 1
    WITH *.items[idx]
     DIM old as bool = .disabled
     .disabled = NO
     IF NOT (istag(.tag1, YES) AND istag(.tag2, YES)) THEN .disabled = YES
     IF .t = mtypeCaption AND .sub_t = 1 THEN .disabled = YES
     IF .t = mtypeSpecial THEN
      ' Minimap and Save may be disabled on this map
      IF .sub_t = spMapMaybe AND gmap(2) = 0 THEN .disabled = YES
      IF .sub_t = spSaveMaybe AND gmap(3) = 0 THEN .disabled = YES
      ' TV Safe Margin disabled on backends that don't support it
      IF .sub_t = spMargins AND NOT supports_safe_zone_margin() THEN .disabled = YES
      ' Purchases disabled on platforms that don't have a supported store
      IF .sub_t = spPurchases AND NOT supports_in_app_purchases() THEN .disabled = YES
      IF .sub_t = spWindowed OR .sub_t = spFullscreen THEN
       .disabled = YES
       IF supports_fullscreen_well() THEN
        DIM fullscreen as bool
        IF try_check_fullscreen(fullscreen) THEN
         IF fullscreen ANDALSO .sub_t = spWindowed THEN .disabled = NO
         IF fullscreen = NO ANDALSO .sub_t = spFullscreen THEN .disabled = NO
        END IF
       END IF
      END IF
     END IF
     IF old <> .disabled THEN changed = YES
    END WITH
   NEXT idx
   IF changed = YES THEN
    ' Update .pt, .top, etc
    init_menu_state mstates(menunum), menus(menunum)
   END IF
  END WITH
 NEXT menunum
 update_menu_states
END SUB

FUNCTION game_usemenu (state as MenuState) as bool
 RETURN usemenu(state, csetup(ccUp), csetup(ccDown))
END FUNCTION

FUNCTION allowed_to_open_main_menu () as bool
 DIM i as integer
 IF find_menu_id(0) >= 0 THEN RETURN NO 'Already open
 FOR i = topmenu TO 0 STEP -1
  IF menus(i).prevent_main_menu = YES THEN RETURN NO
 NEXT i
 RETURN YES
END FUNCTION

'==========================================================================================

FUNCTION random_formation (byval set as integer) as integer
 DIM formset as FormationSet
 DIM as integer i, num
 STATIC foenext as integer = 0
 LoadFormationSet formset, set
 FOR i = 0 TO UBOUND(formset.formations)
  IF formset.formations(i) >= 0 THEN num += 1
 NEXT
 IF num = 0 THEN RETURN -1

 'surprisingly, this is actually slightly effective at reducing the rate of the
 'same slot being picked consecutively, so I'll leave it be for now
 'FIXME: When this was written, I confused the meaning of range; should improve this
 FOR i = 0 TO randint(range(19, 27))
  DO
   foenext = loopvar(foenext, 0, UBOUND(formset.formations), 1)
  LOOP WHILE formset.formations(foenext) = -1
 NEXT
 RETURN formset.formations(foenext)
END FUNCTION


'==========================================================================================
'                                        Map setup
'==========================================================================================


SUB prepare_map (byval afterbat as bool=NO, byval afterload as bool=NO)
 'DEBUG debug "in preparemap"

 script_log_out !"\nLoading map " & gam.map.id & IIF(afterbat, " (reloading after a battle)", "")

 'save data from old map
 IF gam.map.lastmap > -1 THEN
  'NPC Data: Remember state when leaving
  IF gmap(17) = 1 THEN
   savemapstate_npcd gam.map.lastmap, "map"
   savemapstate_npcl gam.map.lastmap, "map"
  END IF
  'Tile Data: Remember state when leaving
  IF gmap(18) = 1 THEN
   savemapstate_tilemap gam.map.lastmap, "map"
   savemapstate_passmap gam.map.lastmap, "map"
   savemapstate_zonemap gam.map.lastmap, "map"
  END IF
 END IF
 IF running_as_slave THEN make_map_backups

 gam.map.lastmap = gam.map.id

 '--- Load new map's data

 'load gmap
 loadmapstate_gmap gam.map.id, "map"

 'Play map music
 IF readbit(gen(), genSuspendBits, suspendambientmusic) = 0 THEN
  IF gmap(1) >= 0 THEN
   queue_music_change gmap(1) - 1
  ELSEIF gmap(1) = -1 AND afterbat = YES THEN
   queue_music_change gam.remembermusic
  END IF
 END IF

 gam.map.name = getmapname(gam.map.id)

 IF gmap(18) < 2 THEN
  'Tile Data: Don't save state when leaving or Remember state when leaving
  loadmapstate_tilemap gam.map.id, "map"
  loadmapstate_passmap gam.map.id, "map"
  loadmapstate_zonemap gam.map.id, "map"
 ELSE
  'Tile Data: Ignore saved state, load anew
  loadmap_tilemap gam.map.id
  loadmap_passmap gam.map.id
  loadmap_zonemap gam.map.id
 END IF
 loadmap_foemap gam.map.id

 'Cancel any pending hero pathing
 IF afterbat ANDALSO NOT get_gen_bool("/mouse/move_hero/cancel_on_battle") THEN
  'Don't cancel
 ELSE
  cancel_hero_pathfinding()
 END IF

 IF afterbat = NO THEN
  recreate_map_slices
 END IF

 IF afterbat = NO THEN
  gam.showtext = gam.map.name
  embedtext gam.showtext
  gam.showtext_ticks = gmap(4)
  IF gmap(17) < 2 THEN
   loadmapstate_npcd gam.map.id, "map"
   loadmapstate_npcl gam.map.id, "map"
  ELSE
   loadmap_npcd gam.map.id
   loadmap_npcl gam.map.id
  END IF
 END IF

 'Load door locations
 DeSerDoors(game + ".dox", gam.map.door(), gam.map.id)

 '--- Update/clean up various state

 'Hero/caterpillar party and vehicle
 IF afterbat = NO AND gam.map.same = NO THEN
  forcedismount
 END IF
 IF afterbat = NO AND afterload = NO THEN
  resetcaterpillar
 END IF
 IF afterload = YES THEN
  herow(0).xgo = 0
  herow(0).ygo = 0
  herow(0).speed = 4
  change_hero_speed(0, 4)
 END IF
 IF vstate.active = YES AND gam.map.same = YES THEN
  FOR i as integer = 0 TO 3
   (heroz(i)) = vstate.dat.elevation
  NEXT i
  npc(vstate.npc).z = vstate.dat.elevation
  IF vstate.dat.speed = 3 THEN
   change_hero_speed(0, 10)
  ELSE
   change_hero_speed(0, vstate.dat.speed)
  END IF
 END IF

 txt.sayer = -1

 'If following NPC or slice on old map, reset camera
 IF afterbat = NO THEN
  IF gen(genCameraMode) = slicecam ANDALSO valid_plotslice(gen(genCameraArg1), serrIgnore) = NO  _
     OR gen(genCameraMode) = npccam THEN
   '(Note that normally when following an invalid slice we stop the camera instead)
   gen(genCameraMode) = herocam
   gen(genCameraArg1) = 0
  END IF
 END IF

 IF afterbat = NO THEN
  IF gmap(7) > 0 THEN
   trigger_script gmap(7), 1, YES, "map autorun", "map " & gam.map.id, mainFibreGroup
   trigger_script_arg 0, gmap(8), "arg"
  END IF
 ELSE
  IF gmap(12) > 0 THEN
   trigger_script gmap(12), 1, NO, "afterbattle", "", mainFibreGroup
   '--afterbattle script gets one arg telling if you won or ran
   trigger_script_arg 0, IIF(gam.wonbattle, 1, 0), "wonbattle"
  END IF
 END IF
 gam.map.same = NO

 'For heroes, we trigger zone exit scripts for the zones the hero was inside
 'on the previous map, and zone entry scripts for the new zones
 FOR whoi as integer = 0 TO caterpillar_size() - 1
  update_hero_zones whoi
 NEXT

 'For NPCs, we don't run zone exit scripts (because the NPCs no longer exist)
 'for the previous map, but we do run the entry scripts for the new map
 'UNLESS (unimplemented, FIXME) restoring a saved map state
 FOR npcref as integer = 0 TO UBOUND(npc)
  IF npc(npcref).id > 0 THEN
   update_npc_zones npcref
  END IF
 NEXT
 
 'DEBUG debug "end of preparemap"
END SUB


'==========================================================================================
'                                          Doors
'==========================================================================================


'Return the ID of a door at a tile, or -1 for none
'(There should only be one door on each tile, because the editor doesn't let you place more)
FUNCTION find_door (byval tilex as integer, byval tiley as integer) as integer
 FOR door_id as integer = 0 TO maxDoorsPerMap
  IF readbit(gam.map.door(door_id).bits(), 0, 0) THEN  'Door exists
   IF gam.map.door(door_id).x = tilex AND gam.map.door(door_id).y = tiley + 1 THEN
    RETURN door_id
   END IF
  END IF
 NEXT door_id
 RETURN -1
END FUNCTION

SUB checkdoors ()
 'If the leader is standing on a door, use it.
 IF vstate.active = YES AND vstate.dat.enable_door_use = NO THEN EXIT SUB 'Doors are disabled by a vehicle
 IF readbit(gen(), genSuspendBits, suspenddoors) = 1 THEN EXIT SUB

 DIM door_id as integer
 door_id = find_door(herotx(0), heroty(0))
 IF door_id >= 0 THEN usedoor door_id
END SUB

FUNCTION find_doorlink (byref thisdoorlink as doorlink, byval door_id as integer, byval map_id as integer=-1) as bool
 'populates the thisdoorlink object
 'returns YES on success, or NO if no links were found or the door doesn't exist
 'If map_id is -1 then use the current map
 DIM thisdoor as door
 IF map_id = -1 THEN map_id = gam.map.id
 IF map_id = gam.map.id THEN
  thisdoor = gam.map.door(door_id)
 ELSE
  IF read_one_door(thisdoor, map_id, door_id) = NO THEN RETURN NO
 END IF

 IF readbit(thisdoor.bits(), 0, 0) = 0 THEN RETURN NO

 DIM door_links(199) as DoorLink
 deserdoorlinks maplumpname(map_id,"d"), door_links()
 DIM index as integer = find_doorlink_id(door_id, thisdoor, door_links())
 IF index >= 0 THEN
  thisdoorlink = door_links(index)
  RETURN YES
 END IF
 RETURN NO
END FUNCTION

FUNCTION find_doorlink_id (byval door_id as integer, thisdoor as door, door_links() as Doorlink) as integer
 'Returns the index in door_links() which is active for door_id,
 'or -1 if none are, or if the door does not even exist.
 'Assumes that the door_id and the doorlinks() array belong to the same map
 'If multiple matches exist, only the first one that passes the tag tests will be returned.

 IF readbit(thisdoor.bits(), 0, 0) = 0 THEN RETURN -1

 FOR i as integer = 0 TO UBOUND(door_links)
  WITH door_links(i)
   IF door_id = .source THEN
    IF istag(.tag1, YES) AND istag(.tag2, YES) THEN 'Check tags to make sure this door is okay
     RETURN i
    END IF
   END IF
  END WITH
 NEXT i
 RETURN -1
END FUNCTION

SUB usedoor (byval door_id as integer)
 DIM dlink as doorlink
 IF find_doorlink(dlink, door_id) = NO THEN EXIT SUB

 WITH dlink
  gam.map.same = (.dest_map = gam.map.id)
  gam.map.id = .dest_map
  deserdoors game + ".dox", gam.map.door(), gam.map.id
  (herox(0)) = gam.map.door(.dest).x * 20
  (heroy(0)) = (gam.map.door(.dest).y - 1) * 20
  fadeout 0, 0, 0
  queue_fade_in 1
  prepare_map
  gam.random_battle_countdown = range(100, 60)
 END WITH
END SUB


'==========================================================================================
'                                        Textboxes
'==========================================================================================


FUNCTION immediate_showtextbox() as bool
 RETURN xreadbit(gen(), 18, genBits2)
END FUNCTION

'Load a textbox and process conditionals that happen immediately, including
'the "instead" conditionals to pick a different box.
SUB loadsay (byval box_id as integer)
 DO '--This loop is where we find which box will be displayed right now
  '--load data from the textbox lump
  LoadTextBox txt.box, box_id

  '-- evaluate "instead" conditionals
  IF istag(txt.box.instead_tag, 0) THEN
   '--do something else instead
   IF txt.box.instead < 0 THEN
    trigger_script -txt.box.instead, 0, YES, "textbox instead", "box " & box_id, mainFibreGroup
    txt.sayer = -1
    EXIT SUB
   ELSE
    IF box_id <> txt.box.instead THEN
     box_id = txt.box.instead
     CONTINUE DO' Skip back to the top of the loop and get another box
    END IF
   END IF
  END IF

  EXIT DO'--We have the box we want to display, proceed
 LOOP

 '--Store box ID number for later reference
 txt.id = box_id

 gen(genTextboxBackdrop) = 0
 WITH txt.choicestate
  .pt = 0
  .size = 2
  .last = 1
 END WITH

 FOR j as integer = 0 TO 7
  embedtext txt.box.text(j), 38
 NEXT j

 '-- set tags indicating the text box has been seen.
 IF istag(txt.box.settag_tag, 0) THEN
  settag txt.box.settag1
  settag txt.box.settag2
  'NOTE: We just changed tags, but we do not want tag_updates to update
  '  NPC visibility until after the box adances. We do however update
  '  menu tags right away.
  tag_updates NO
 END IF

 '--make a sound if the choicebox is enabled
 IF txt.box.choice_enabled THEN MenuSound gen(genAcceptSFX)

 '-- update backdrop if necessary
 IF txt.box.backdrop > 0 THEN
  gen(genTextboxBackdrop) = txt.box.backdrop
 END IF

 '-- change music if necessary
 IF txt.box.music > 0 THEN
  txt.remember_music = presentsong
  wrappedsong txt.box.music - 1
 ELSEIF txt.box.music < 0 THEN
  ' Silence
  txt.remember_music = presentsong
  stopsong
 END IF

 '--play a sound effect
 IF txt.box.sound_effect > 0 THEN
  playsfx txt.box.sound_effect - 1
 END IF

 '-- evaluate menu conditionals
 IF istag(txt.box.menu_tag, 0) THEN
  add_menu txt.box.menu
 END IF

 txt.showing = YES
 txt.fully_shown = NO
 txt.show_lines = 0

 '--Create a set of slices to display the text box
 init_text_box_slices txt
 
 '--Cancel hero pathfinding
 IF get_gen_bool("/mouse/move_hero/cancel_on_textbox") THEN
  cancel_hero_pathfinding()
 END IF
END SUB

SUB advance_text_box ()
 IF txt.box.backdrop > 0 THEN
  '--backdrop needs resetting
  gen(genTextboxBackdrop) = 0
 END IF
 '---IF MADE A CHOICE---
 IF txt.box.choice_enabled THEN
  MenuSound gen(genAcceptSFX)
  settag txt.box.choice_tag(txt.choicestate.pt)
 END IF
 '---RESET MUSIC----
 IF txt.box.restore_music THEN
  IF gmap(1) > 0 THEN
   wrappedsong gmap(1) - 1
  ELSEIF gmap(1) = 0 THEN
   stopsong
  ELSE
   ' Map music is set to "same as previous map".
   ' It is not a bug that we only restore the actual previously playing music in
   ' this case and otherwise use the map setting, because a chain of textboxes
   ' might play some music and then want to restore the map music at the end.
   ' It's even documented that way.
   IF txt.remember_music > -1 THEN
    wrappedsong txt.remember_music
   ELSE
    stopsong
   END IF
  END IF
 END IF
 '---STOP SOUND EFFECT----
 IF txt.box.sound_effect > 0 AND txt.box.stop_sound_after THEN
  stopsfx txt.box.sound_effect - 1
 END IF
 '---GAIN/LOSE CASH-----
 IF istag(txt.box.money_tag, 0) THEN
  gold = gold + txt.box.money
  IF gold > 2000000000 THEN gold = 2000000000
  IF gold < 0 THEN gold = 0
 END IF
 '---SPAWN BATTLE--------
 IF istag(txt.box.battle_tag, 0) THEN
  fatal = NO
  gam.wonbattle = battle(txt.box.battle)
  prepare_map YES
  gam.random_battle_countdown = range(100, 60)
  queue_fade_in 1, YES
 END IF
 '---GAIN/LOSE ITEM--------
 IF istag(txt.box.item_tag, 0) THEN
  IF txt.box.item > 0 THEN getitem txt.box.item - 1
  IF txt.box.item < 0 THEN delitem (-txt.box.item) - 1
 END IF
 '---SHOP/INN/SAVE/ETC------------
 IF istag(txt.box.shop_tag, 0) THEN
  IF txt.box.shop > 0 THEN
   shop txt.box.shop - 1
  ELSEIF txt.box.shop < 0 THEN
   '--Preserve background for display beneath the top-level shop menu
   DIM holdscreen as integer = duplicatepage(vpage)
   IF useinn(-txt.box.shop, holdscreen) THEN
    innRestore
    fadeout 0, 0, 80
    queue_fade_in 1, YES
   END IF
   freepage holdscreen
  ELSEIF txt.box.shop = 0 THEN
   innRestore
  END IF
 END IF
 '---ADD/REMOVE/SWAP/LOCK HERO-----------------
 IF istag(txt.box.hero_tag, 0) THEN add_rem_swap_lock_hero txt.box
 '---FORCE DOOR------
 IF istag(txt.box.door_tag, 0) THEN
  usedoor txt.box.door
 END IF
 '---JUMP TO NEXT TEXT BOX--------
 IF istag(txt.box.after_tag, 0) THEN
  IF txt.box.after < 0 THEN
   trigger_script -txt.box.after, 0, YES, "textbox", "box " & txt.id, mainFibreGroup
  ELSE
   loadsay txt.box.after
   EXIT SUB
  END IF
 END IF
 '---DONE EVALUATING CONDITIONALS--------
 'Lots of things in this sub directly or indirectly affects tags. Many of the functions
 'called make sure the proper effects occur themselves, but we do it all again for simplicity
 evalitemtags
 evalherotags
 tag_updates
 IF txt.sayer >= 0 AND txt.old_dir <> -1 THEN
  IF npc(txt.sayer).id > 0 THEN
   IF npcs(npc(txt.sayer).id - 1).facetype = 1 THEN  '"Face Player"
    npc(txt.sayer).dir = txt.old_dir
   END IF
  END IF
 END IF
 IF txt.box.backdrop > 0 THEN
  gen(genTextboxBackdrop) = 0
 END IF
 txt.showing = NO
 txt.fully_shown = NO
 txt.sayer = -1
 txt.id = -1
 IF txt.sl THEN DeleteSlice @(txt.sl)
 ClearTextBox txt.box
 setkeys
 flusharray carray(), 7, 0
END SUB

SUB add_rem_swap_lock_hero (byref box as TextBox)
 '---ADD/REMOVE/SWAP/LOCK
 '---ADD---
 DIM i as integer
 IF box.hero_addrem > 0 THEN
  i = first_free_slot_in_party()
  IF i > -1 THEN
   addhero box.hero_addrem, i
  END IF
 END IF '---end if > 0
 '---REMOVE---
 IF box.hero_addrem < 0 THEN
  IF herocount(40) > 1 THEN
   i = findhero(-box.hero_addrem, 0, 40, 1, serrWarn)
   IF i > -1 THEN gam.hero(i).id = -1
   IF herocount(3) = 0 THEN forceparty
  END IF
 END IF '---end if < 0
 '---SWAP-IN---
 IF box.hero_swap > 0 THEN
  i = findhero(box.hero_swap, 40, 0, -1, serrWarn)
  IF i > -1 THEN
   FOR o as integer = 0 TO 3
    IF gam.hero(o).id = -1 THEN
     doswap i, o
     EXIT FOR
    END IF
   NEXT o
  END IF
 END IF '---end if > 0
 '---SWAP-OUT---
 IF box.hero_swap < 0 THEN
  i = findhero(-box.hero_swap, 0, 40, 1, serrWarn)
  IF i > -1 THEN
   FOR o as integer = 40 TO 4 STEP -1
    IF gam.hero(o).id = -1 THEN
     doswap i, o
     IF herocount(3) = 0 THEN forceparty
     EXIT FOR
    END IF
   NEXT o
  END IF
 END IF '---end if < 0
 '---UNLOCK HERO---
 IF box.hero_lock > 0 THEN
  DIM heroat as integer = findhero(box.hero_lock, 0, 40, 1, serrWarn)
  IF heroat > -1 THEN gam.hero(heroat).locked = NO
 END IF '---end if > 0
 '---LOCK HERO---
 IF box.hero_lock < 0 THEN
  DIM heroat as integer = findhero(-box.hero_lock, 0, 40, 1, serrWarn)
  IF heroat > -1 THEN gam.hero(heroat).locked = YES
 END IF '---end if > 0

 '--indirect effects
 party_change_updates
END SUB

SUB init_text_box_slices(txt as TextBoxState)
 IF txt.sl THEN
  '--free any already-loaded textbox
  DeleteSlice @(txt.sl)
 END IF

 'The textbox root slice is parent to the box and choicebox
 txt.sl = NewSliceOfType(slContainer, SliceTable.TextBox, SL_TEXTBOX_ROOT)
 WITH *txt.sl
  'Should not be set to fill, as scripts may expect to be able to move it around.
  'Set the width and height according to SliceTable.TextBox's size and padding.
  .Fill = YES
  .Parent->ChildRefresh(.Parent, txt.sl)
  .Fill = NO
 END WITH

 '--Create a new slice for the text box
 DIM text_box as Slice Ptr

 '--set up box style
 text_box = NewSliceOfType(slRectangle, txt.sl, SL_TEXTBOX_BOX)
 IF txt.box.no_box THEN
  'Invisible box (for the benefit of scripts)
  ChangeRectangleSlice text_box, , , , -2, transHollow
 ELSE
  ChangeRectangleSlice text_box, txt.box.boxstyle, , , , iif(txt.box.opaque, transOpaque, transFuzzy)
 END IF

 '--position and size the text box
 WITH *text_box
  .X = 0
  .Y = 4 + txt.box.vertical_offset * 4
  .Width = 312
  .Height = get_text_box_height(txt.box)
  .PaddingLeft = 4
  .PaddingRight = 4
  .PaddingTop = 3
  .PaddingBottom = 3
  'Horizontal centering
  .AlignHoriz = 1
  .AnchorHoriz = 1
  .AnchorVert = 0
  .AlignVert = 0
 END WITH

 '--Set up the actual text
 DIM col as integer
 col = uilook(uiText)
 IF txt.box.textcolor > 0 THEN col = txt.box.textcolor

 DIM s as string = ""
 FOR i as integer = 0 TO 7
  s &= txt.box.text(i) & CHR(10)
 NEXT i

 DIM text_sl as Slice Ptr
 text_sl = NewSliceOfType(slText, text_box, SL_TEXTBOX_TEXT)
 text_sl->Fill = YES
 ChangeTextSlice text_sl, s, col, YES, NO

 '--start the displayed lines as all hidden. They will be revealed in drawsay
 DIM dat as TextSliceData Ptr
 dat = text_sl->SliceData
 IF dat THEN
  dat->line_limit = -1
 END IF

 '--figure out which portrait to load
 'NOTE: Compare this to customsubs.rbas:load_text_box_portrait()
 'If you update this code, you might need to update that too.
 DIM img_id as integer = -1
 DIM pal_id as integer = -1
 DIM hero_slot as integer = -1
 SELECT CASE txt.box.portrait_type
  CASE 1' Fixed ID number
   img_id = txt.box.portrait_id
   pal_id = txt.box.portrait_pal
  CASE 2' Hero by caterpillar
   hero_slot = rank_to_party_slot(txt.box.portrait_id)
  CASE 3' Hero by party slot
   hero_slot = txt.box.portrait_id
  CASE 4' Hero by ID
   'If the hero is in the party, use their current state.
   'if there are multiple copies, use the first.
   hero_slot = findhero(txt.box.portrait_id + 1, 0, 40, 1)
   IF hero_slot = -1 THEN
    'The hero is not in the party right now, use their default
    DIM her as HeroDef
    loadherodata her, txt.box.portrait_id
    img_id = her.portrait
    pal_id = her.portrait_pal
   END IF
 END SELECT
 IF hero_slot >= 0 ANDALSO hero_slot <= UBOUND(gam.hero) THEN
  IF gam.hero(hero_slot).id >= 0 THEN
   img_id = gam.hero(hero_slot).portrait_pic
   pal_id = gam.hero(hero_slot).portrait_pal
  END IF
 END IF

 IF img_id >= 0 THEN
  '--First set up the box that holds the portrait
  DIM img_box as Slice Ptr
  img_box = NewSliceOfType(slRectangle, text_box, SL_TEXTBOX_PORTRAIT_BOX)
  IF txt.box.portrait_box THEN
   ChangeRectangleSlice img_box, txt.box.boxstyle, , , , transFuzzy
  ELSE
   'Invisible box
   ChangeRectangleSlice img_box, , , , -2, transHollow
  END IF
  img_box->Width = 50
  img_box->Height = 50
  img_box->X = txt.box.portrait_pos.x - 4
  img_box->Y = txt.box.portrait_pos.y - 3
  '--Then load the portrait
  DIM img_sl as Slice Ptr
  img_sl = NewSliceOfType(slSprite, img_box, SL_TEXTBOX_PORTRAIT)
  ChangeSpriteSlice img_sl, 8, img_id, pal_id
 END IF

 '--set up the choice-box (if any)
 IF txt.box.choice_enabled THEN
  'tempy = 100 + (txt.box.vertical_offset * 4) - (txt.box.shrink * 4)
  'IF tempy > 160 THEN tempy = 20
  'centerbox 160, tempy + 12, 10 + large(LEN(txt.box.choice(0)) * 8, LEN(txt.box.choice(1)) * 8), 24, txt.box.boxstyle + 1, dpage
  DIM choice_box as Slice Ptr
  choice_box = NewSliceOfType(slRectangle, txt.sl, SL_TEXTBOX_CHOICE_BOX)
  WITH *choice_box
   '--center the box
   .AnchorHoriz = 1
   .AlignHoriz = 1
   .AnchorVert = 0
   .AlignVert = 0
   '--set box size
   .Width = 10 + large(LEN(txt.box.choice(0)) * 8, LEN(txt.box.choice(1)) * 8)
   .Height = 24
   '--FIXME: This hackyness just reproduces the old method of positioning the choicebox.
   '--FIXME: eventually the game author should have control over this.
   .Y = text_box->Y + text_box->Height + 12
   IF .Y > txt.sl->Height - (.Height + 4) THEN .Y = 32
  END WITH
  ChangeRectangleSlice choice_box, txt.box.boxstyle
  REDIM choice_sl(1) as Slice Ptr
  FOR i as integer = 0 TO 1
   choice_sl(i) = NewSliceOfType(slText, choice_box)
   ChangeTextSlice choice_sl(i), txt.box.choice(i), uilook(uiMenuItem), YES
   WITH *(choice_sl(i))
    .AnchorHoriz = 1
    .AlignHoriz = 1
    .Y = 2 + i * 10
   END WITH
  NEXT i
  choice_sl(0)->Lookup = SL_TEXTBOX_CHOICE0
  choice_sl(1)->Lookup = SL_TEXTBOX_CHOICE1
 END IF
END SUB

'This is used for resetting game state. But only a few of the txt members
'actually need to be cleaned up; most aren't used when no box is up
SUB cleanup_text_box ()
 ClearTextBox txt.box
 WITH txt
  .id = -1
  .showing = NO
  .fully_shown = NO
  .choicestate.pt = 0
  .remember_music = NO
  .show_lines = 0
  .sayer = -1
  .old_dir = 0
 END WITH
 IF txt.sl THEN DeleteSlice @(txt.sl)
END SUB


'==========================================================================================
'                                        Map slices
'==========================================================================================


''''Updating map slices:
'*If changing map, call recreate_map_slices() to possibly recreate everything.
'  This also calls refresh_map_slice() and refresh_map_slice_tilesets().
'*If the tilemap changed then the number of map layers may have changed, so call
'  update_map_slices_for_new_tilemap()
'  This also calls refresh_map_slice().
'  If the number of map layers is the same you can call refresh_map_slice() to update tilemap data.
'*If the passmap changed no need to do anything, because 'pass' is a global so
'  map layer slices already have the correct pointer.
'*If gmap changed, call update_gmap().
'  This calls refresh_map_slice() to change map and walkabout layer ordering and visibility,
'  and handles the possible change to tilesets (see next item).
'*If tilesets changed, call loadmaptilesets() and then refresh_map_slice_tilesets().
'  Can be called before/after/separately from refresh_map_slice().

SUB recreate_map_slices()
 'this destroys and re-creates the map slices. it should only happen when
 'moving from one map to another, but not when a battle ends. (same as when
 'the map autorun script is triggered)

 'First free all NPC slices because we need to make sure the npc(i).sl's
 'don't point to deleted memory, though they would all be deleted anyway,
 'but not soon enough. (and we must do this unconditionally, even if
 'the preference for recreating map slices is turned OFF)
 FOR i as integer = 0 TO UBOUND(npc)
  DeleteSlice @npc(i).sl
 NEXT i

 IF readbit(gen(), genBits2, 11) <> 0 THEN
  '"Recreate map slices when changing maps" = ON

  'Orphan the hero slices to prevent them from being destroyed when we
  'destroy the map layers
  orphan_hero_slices

  'Free the map slices
  FOR i as integer = 0 TO UBOUND(SliceTable.MapLayer)
   DeleteSlice @SliceTable.MapLayer(i)
  NEXT i
  DeleteSlice @SliceTable.ObsoleteOverhead
  DeleteSlice @SliceTable.MapOverlay
  DeleteSlice @SliceTable.HeroLayer
  DeleteSlice @SliceTable.NPCLayer
  DeleteSlice @SliceTable.Walkabout

  'Anything else attached to the map
  DeleteSliceChildren SliceTable.MapRoot

  'And then create new ones
  SetupMapSlices UBOUND(maptiles)

  'Reparent the hero slices to the new map
  reparent_hero_slices
 END IF
 refresh_map_slice_tilesets
 'Recreate all NPC slices
 visnpc
 'Update everything else.
 refresh_map_slice
END SUB

SUB update_map_slices_for_new_tilemap()
 'Call this if the number of map layers may have changed (by loading maptiles()) for a reason other
 'than a map change, so you don't want to destroy and recreate everything by calling recreate_map_slices

 IF readbit(gen(), genBits2, 11) <> 0 THEN
  'When "Recreate map slices when changing maps" = ON then number of map layer slices is variable.
  FOR idx as integer = 0 TO mapLayerMax
   IF idx > UBOUND(maptiles) THEN
    DeleteSlice @SliceTable.MapLayer(idx)
   ELSE
    IF SliceTable.MapLayer(idx) = NULL THEN
     SliceTable.MapLayer(idx) = NewSliceOfType(slMap, SliceTable.MapRoot, SL_MAP_LAYER0 - idx)
     ChangeMapSlice SliceTable.MapLayer(idx), , , (idx > 0), 0   'maybe transparent, not overhead
     ChangeMapSliceTileset SliceTable.MapLayer(idx), tilesets(idx)
    END IF
   END IF
  NEXT
 END IF

 'Set visibility, tilemaps, sort order
 refresh_map_slice
END SUB

SUB refresh_map_slice()
 'This updates the size, tilemaps, sort order, and visibility of the map slices
 'and the sorting of walkabout layers and slices,
 'but does NOT update tilesets or recreate map slices - that's done by recreate_map_slices.

 'debuginfo "refresh_map_slice() there are " & UBOUND(maptiles) + 1 & " map layers on map " & gam.map.id

 '--Store info about the map in the map slices
 WITH *(SliceTable.MapRoot)
  .Width = mapsizetiles.x * 20
  .Height = mapsizetiles.y * 20
 END WITH
 FOR i as integer = 0 TO UBOUND(SliceTable.MapLayer)
  IF SliceTable.MapLayer(i) THEN
   SliceTable.MapLayer(i)->Size = mapsizetiles * 20
  END IF
 NEXT
 SliceTable.ObsoleteOverhead->Size = mapsizetiles * 20
 SliceTable.MapOverlay->Size = mapsizetiles * 20

 FOR i as integer = 0 TO UBOUND(maptiles)
  '--reset each layer (the tileset ptr is set in refresh_map_slice_tilesets
  IF SliceTable.MapLayer(i) = 0 THEN
   debug "NULL SliceTable.MapLayer(" & i & ") when resetting tilesets in refresh_map_slice()"
  ELSE
   ChangeMapSlice SliceTable.MapLayer(i), @maptiles(i), @pass
   SliceTable.MapLayer(i)->Visible = IIF(i = 0, YES, readbit(gmap(), 19, i - 1))
  END IF
 NEXT i
 FOR i as integer = UBOUND(maptiles) + 1 TO UBOUND(SliceTable.MapLayer)
  '--if slices exist for the unused layers that this map doesn't have
  '--(which occurs when "recreate map slices" is off),
  '--we should make them display no tiles
  IF Slicetable.MapLayer(i) <> 0 THEN
   ChangeMapSlice SliceTable.MapLayer(i), NULL, NULL
   SliceTable.MapLayer(i)->Visible = NO
  END IF
 NEXT i
 ChangeMapSlice SliceTable.ObsoleteOverhead, @maptiles(0), @pass

 '--now fix up the order of the slices
 DIM num_layers_under_walkabouts as integer
 '--It's possible for gmap(31) to be larger than the number of map layers
 num_layers_under_walkabouts = bound(gmap(31), 1, UBOUND(maptiles) + 1)
 FOR i as integer = 0 TO UBOUND(maptiles)
  IF SliceTable.Maplayer(i) = 0 THEN
   debug "Null map layer " & i & " when sorting in refresh_map_slice"
  ELSE
   SliceTable.MapLayer(i)->Sorter = IIF(i < num_layers_under_walkabouts, i, i + 1)
  END IF
 NEXT
 FOR i as integer = UBOUND(maptiles) + 1 TO UBOUND(SliceTable.MapLayer)
  'Slices for layers that do not exist on the current map...
  IF SliceTable.MapLayer(i) <> 0 THEN
   '...should be sorted too, if they exist.
   SliceTable.MapLayer(i)->Sorter = i
  END IF
 NEXT i

 SliceTable.Walkabout->Sorter = num_layers_under_walkabouts
 SliceTable.ObsoleteOverhead->Sorter = UBOUND(maptiles) + 2
 SliceTable.MapOverlay->Sorter = UBOUND(maptiles) + 3

 CustomSortChildSlices SliceTable.MapRoot, YES
 'Delete/recreate walkabout layers if needed.
 refresh_walkabout_layer_sort()
END SUB

SUB refresh_map_slice_tilesets()
 FOR i as integer = 0 TO maplayerMax
  '--reset map layer tileset ptrs
  IF SliceTable.MapLayer(i) <> 0 THEN
   ChangeMapSliceTileset SliceTable.MapLayer(i), tilesets(i)
  END IF
 NEXT i
 ChangeMapSliceTileset SliceTable.ObsoleteOverhead, tilesets(0)
END SUB


'==========================================================================================
'                                         usenpc
'==========================================================================================


'--Look in front of the leader for an activatable NPC.
'--WARNING: has side-effects: assumes result is passed to usenpc
FUNCTION find_useable_npc() as integer
 DIM ux as integer = herox(0)
 DIM uy as integer = heroy(0)
 wrapaheadxy ux, uy, herodir(0), 20, 20

 FOR j as integer = 0 TO 299
  WITH npc(j)
   IF .id > 0 AND (j <> vstate.npc OR vstate.active = NO) THEN
    '--Step-on NPCs cannot be used
    IF npcs(.id - 1).activation = 2 THEN CONTINUE FOR
    IF .suspend_use THEN CONTINUE FOR
    DIM nx as integer = .x
    DIM ny as integer = .y
    IF (nx = ux AND ny = uy) THEN 'not moving NPCs
     RETURN j
    ELSEIF nx MOD 20 <> 0 XOR ny mod 20 <> 0 THEN 'they're moving (i.e. misaligned)
     '--first check the tile the NPC is stepping into
     nx -= .xgo
     ny -= .ygo
     cropposition nx, ny, 20
     '--uncommenting the line below provides a helpful rectangle that shows the activation tile of an NPC
     'rectangle nx - mapx, ny - mapy, 20,20, 1, vpage : setvispage vpage, NO
     IF (nx = ux AND ny = uy) THEN 'check for activation
      RETURN j
     END IF
     '--also check the tile the NPC is leaving
     nx = nx + SGN(.xgo) * 20
     ny = ny + SGN(.ygo) * 20
     '--uncommenting the line below provides a helpful rectangle that shows the activation tile of an NPC
     'rectangle nx - mapx, ny - mapy, 20,20, 4, vpage : setvispage vpage, NO
     IF (nx = ux AND ny = uy) THEN 'check for activation
      '--if activating an NPC that has just walked past us, cause it to back up
      .xgo = SGN(.xgo * -1) * (20 - ABS(.xgo))
      .ygo = SGN(.ygo * -1) * (20 - ABS(.ygo))
      RETURN j
     END IF
    END IF
   END IF
  END WITH
 NEXT
 RETURN -1
END FUNCTION

'Activate npc(npcnum)
SUB usenpc(byval cause as integer, byval npcnum as integer)
 'cause = 0: normal use key
 'cause = 1: touch and step-on
 'cause = 2: scripted
 IF npcnum < 0 THEN EXIT SUB
 IF npc(npcnum).suspend_use ANDALSO cause <> 2 THEN EXIT SUB
 DIM id as integer = npc(npcnum).id - 1

 '---Item from NPC---
 DIM getit as integer = npcs(id).item
 IF getit THEN
  getitem getit - 1
  evalitemtags
  'Delay tag_updates
 END IF
 '---DIRECTION CHANGING-----------------------
 txt.old_dir = -1
 IF cause <> 2 AND npcs(id).facetype <> 2 THEN  'not "Do not face player"
  txt.old_dir = npc(npcnum).dir
  npc(npcnum).dir = herodir(0)
  npc(npcnum).dir = loopvar(npc(npcnum).dir, 0, 3, 2)
 END IF
 IF npcs(id).usetag > 0 THEN
  '--One-time-use tag
  settag onetime(), npcs(id).usetag, YES
  'Delay tag_updates
 END IF
 IF npcs(id).script > 0 THEN
  '--summon a script directly from an NPC
  trigger_script npcs(id).script, 2, YES, "NPC", "NPC ID " & id & " at " & npc(npcnum).x & "," & npc(npcnum).y, mainFibreGroup
  trigger_script_arg 0, npcs(id).scriptarg, "arg"
  trigger_script_arg 1, (npcnum + 1) * -1, "npcref"
 END IF
 DIM vehuse as integer = npcs(id).vehicle
 IF vehuse THEN '---activate a vehicle---
  reset_vehicle vstate
  vstate.id = vehuse - 1
  LoadVehicle game & ".veh", vstate.dat, vstate.id
  '--check mounting permissions first
  IF vehpass(vstate.dat.mount_from, readblock(pass, herotx(0), heroty(0)), -1) THEN
   vstate.active = YES
   vstate.npc = npcnum
   vstate.old_speed = herow(0).speed
   change_hero_speed(0, 10)
   vstate.mounting = YES '--trigger mounting sequence
   settag vstate.dat.riding_tag, YES
   create_walkabout_shadow npc(vstate.npc).sl
  END IF
 END IF
 IF npcs(id).textbox > 0 THEN
  txt.sayer = npcnum
  loadsay npcs(id).textbox
  'NOTE: don't force NPC tag visibility to be updated after a text box
  '  is displayed because that could cause premature NPC disappearance,
  '  and because tag_updates will always be called when the box advances
  tag_updates NO
 ELSE
  'Several different ways to modify tags in this sub
  tag_updates
 END IF
END SUB

FUNCTION want_to_check_for_walls(byval who as integer) as bool
 'Check hero is at beginning of a movement to a new tile (aligned in at least one direction)...
 IF movdivis(herow(who).xgo) = NO AND movdivis(herow(who).ygo) = NO THEN RETURN NO
 '...and certain conditions aren't met
 IF hero_should_ignore_walls(who) THEN RETURN NO
 RETURN YES
END FUNCTION

FUNCTION hero_should_ignore_walls(byval who as integer) as bool
 IF gam.walk_through_walls THEN RETURN YES
 IF vstate.dat.pass_walls THEN RETURN YES
 IF vstate.active THEN
  IF vehpass(vstate.dat.override_walls, readblock(pass, herotx(who), heroty(who)), 0) <> 0 THEN RETURN YES
 END IF
 RETURN NO
END FUNCTION

'==========================================================================================
'                                      Party slots
'==========================================================================================


SUB forceparty ()
 '---MAKE SURE YOU HAVE AN ACTIVE PARTY---
 DIM fpi as integer = findhero(-1, 0, 40, 1)
 IF fpi > -1 THEN
  FOR fpo as integer = 0 TO 3
   IF gam.hero(fpo).id = -1 THEN
    doswap fpi, fpo
    EXIT FOR
   END IF
  NEXT fpo
 END IF
END SUB

FUNCTION first_free_slot_in_party() as integer
 DIM slot as integer = -1
 IF free_slots_in_party() > 0 THEN
  slot = first_free_slot_in_active_party()
  IF slot = -1 THEN
   slot = first_free_slot_in_reserve_party()
  END IF
 END IF
 RETURN slot
END FUNCTION

FUNCTION first_free_slot_in_active_party() as integer
 '--returns the first free slot, or -1 if all slots are full
 FOR i as integer = 0 TO 3
  IF gam.hero(i).id = -1 THEN RETURN i
 NEXT i
 RETURN -1
END FUNCTION

FUNCTION first_free_slot_in_reserve_party() as integer
 '--returns the first free slot, or -1 if all slots are full
 IF free_slots_in_party() > 0 THEN
  FOR i as integer = 4 TO 40
   IF gam.hero(i).id = -1 THEN RETURN i
  NEXT i
 END IF
 RETURN -1
END FUNCTION

FUNCTION free_slots_in_party() as integer
 '--Returns the number of free slots in the active+reserve party
 'Note that there can only be 38 heroes total even though there are 41
 'hero slots. This is because 3 reserve slots have to be saved to
 'allow active party members to be swapped out.
 'FIXME: the above would be true except that it has been broken so
 'very long that games could already exist that rely on having 41 heroes

 '--This is the "correct" intended limit that has never been enforced right.
 'RETURN 38 - herocount(40)

 RETURN 41 - herocount(40)

END FUNCTION

FUNCTION last_active_party_slot() as integer
 RETURN 3
END FUNCTION

FUNCTION is_active_party_slot(byval slot as integer) as integer
 RETURN slot >=0 ANDALSO slot <= last_active_party_slot()
END FUNCTION

FUNCTION active_party_size() as integer
 RETURN last_active_party_slot() + 1
END FUNCTION

FUNCTION loop_active_party_slot(byval slot as integer, byval direction as integer=1) as integer
 'Given a slot number in the active party, return the next or previous occupied slot
 IF direction <> 1 ANDALSO direction <> -1 THEN
  RETURN slot
 END IF
 IF herocount() = 0 THEN
  'If the party is somehow empty, return the original slot
  RETURN slot
 END IF
 DO
  slot = loopvar(slot, 0, last_active_party_slot(), direction)
  IF gam.hero(slot).id >= 0 THEN RETURN slot
 LOOP
END FUNCTION


'==========================================================================================

SUB queue_music_change (byval song as integer)
 'Delay map ambient music to give scripts a chance to override it.
 'Use song = -1 to queue stopping the music.
 'A delay of two is actually a single tick delay, because it will be decremented
 'the same tick that this is called, at the bottom of the main loop.
 gam.music_change_delay = 2
 gam.delayed_music = song
END SUB

SUB check_for_queued_music_change ()
 IF gam.music_change_delay = 1 THEN
  IF gam.delayed_music >= 0 THEN
   wrappedsong gam.delayed_music
  ELSE
   stopsong
  END IF
 END IF
 gam.music_change_delay = large(0, gam.music_change_delay - 1)
END SUB

'Cause a screen fade in some number of ticks from now.
'script_overridable allows the fade in to be cancelled by a fadescreenout command,
'and is for backcompatibility. See fadescreenout. If you need to increase
'any fade in delays, normally you should set script_overridable = YES
SUB queue_fade_in (delay as integer = 0, script_overridable as bool = NO)
 gam.need_fade_in = YES
 gam.fade_in_delay = delay
 gam.fade_in_script_overridable = script_overridable
END SUB

SUB check_for_queued_fade_in ()
 IF gam.need_fade_in THEN
  IF gam.fade_in_delay <= 0 THEN
   gam.need_fade_in = 0
   script_log_out !"\nFading in the screen"
   fadein
   setkeys
  ELSE
   gam.fade_in_delay -= 1
  END IF
 END IF
END SUB

'==========================================================================================

' Check if the given path is an rpg file
FUNCTION is_rpg(path as string) as bool
 RETURN (LCASE(RIGHT(path, 4)) = ".rpg" ANDALSO isfile(path))
END FUNCTION

' Check if the given path is an rpgdir
FUNCTION is_rpgdir(path as string) as bool
 'Perhaps it's an unlumped folder?
 'Check for essentials (archinym.lmp was added long before .rpgdir support)
 RETURN (isdir(path) ANDALSO isfile(path & SLASH & "archinym.lmp"))
END FUNCTION

' Check if the given path/string is an rpg file or an rpgdir
' and if so, select it for playing (the browse screen will not appear).
' Returns YES if found, NO if not found.
FUNCTION select_rpg_or_rpgdir(path as string) as bool
 IF is_rpg(path) THEN
  sourcerpg = absolute_path(path)
  gam.autorungame = YES
  usepreunlump = NO
  RETURN YES
 ELSEIF is_rpgdir(path) THEN
  sourcerpg = trim_trailing_slashes(absolute_path(path))
  workingdir = sourcerpg
  gam.autorungame = YES
  usepreunlump = YES
  RETURN YES
 END IF
 RETURN NO
END FUNCTION

' Search to see if a rpg file or an rpgdir of a given name exists
' and if so, select it for playing (the browse screen will not appear).
' Returns YES if found, NO if not found.
FUNCTION seek_rpg_or_rpgdir_and_select_it(where as string, gamename as string) as bool
 RETURN select_rpg_or_rpgdir(where & SLASH & gamename & ".rpg") ORELSE _
        select_rpg_or_rpgdir(where & SLASH & gamename & ".rpgdir")
END FUNCTION

'==========================================================================================
'                                      Debug menus
'==========================================================================================


SUB DebugMenuDef.start_building_menu()
 v_new menu
END SUB

DESTRUCTOR DebugMenuDef()
 v_free menu
END DESTRUCTOR

' This does one of three different things; see debug_menu_functions() for that explanation.
' Returns whether to execute the definition of this debug function.
' combining_scancode: either check for keyval(combining_scancode) > 1, or if 0, check keyval(scCtrl) = 0.
' scancode: check for keyval(scancode) > 1, or no key combination if 0.
' menuitem: name of the menu item to add to the debug menu, or "" for none.
FUNCTION DebugMenuDef.def(combining_scancode as integer = 0, scancode as integer = 0, menuitem as string = "") as bool
 IF menu = NULL THEN
  'Only check keys
  IF combining_scancode THEN
   IF keyval(combining_scancode) = 0 THEN RETURN NO
  ELSE
   IF keyval(scCtrl) > 0 THEN RETURN NO
  END IF
  IF scancode = 0 THEN RETURN NO
  RETURN keyval(scancode) > 1
 ELSEIF LEN(selected_item) THEN
  RETURN menuitem = selected_item
 ELSEIF LEN(menuitem) THEN
  v_append menu, menuitem
  RETURN NO
 END IF
END FUNCTION

' This sub does three different things, depending on the state of the DebugMenuDef:
' - Checks for debug key combos. dbg.def() returns true if that key is pressed.
' - Builds a list of available debug menu items. dbg.def() returns false.
' - Performs an action selected in the debug menu. dbg.def() returns true if selected.
SUB debug_menu_functions(dbg as DebugMenuDef)

 ' If you don't want a debug function to appear in the debug menu, don't
 ' give it a description (menuitem) string.
 ' If you don't want a debug function to have a shortcut key, leave the key blank.
 ' To give it multiple keys, write "dbg.def() OR dbg.def()" (not ORELSE!) with at
 ' most one description string between them.
 ' If you want to give extra requirements, write "may_frobnicate() ANDALSO dbg.def()"
 ' (not AND, unless you want it to always appear in the menu!)

 IF txt.showing = NO THEN
  IF dbg.def(      , scF1, "Minimap (F1)") THEN minimap herox(0), heroy(0)

  IF dbg.def(scCtrl, scF1, "Teleport tool (Ctrl-F1)") THEN
   IF teleporttool() THEN 'CTRL + F1
    prepare_map
   END IF
  END IF

  IF dbg.def(      , scF2, "Quick-save (F2)") THEN
   savegame 32
   gam.showtext = "Quick-saved. Press F3 to quick-load"
   gam.showtext_ticks = 20
  END IF

  IF dbg.def(      , scF3, "Quick-load (F3)") THEN
   IF yesno("Load quick-saved game?") THEN gam.want.loadgame = 33
  END IF
 END IF

 IF dbg.def(      , scF4, "Tag debugger (F4)") THEN
  gam.debug_showtags = (gam.debug_showtags + 1) MOD 3
  scrwatch = 0
 END IF

 IF dbg.def(scCtrl, scF4, "View/edit slice tree (Ctrl-F4)") THEN
  slice_editor SliceTable.Root
 END IF

 IF dbg.def(      , scF5, "Data reload menu (F5)") THEN live_preview_menu

 DIM showhide as string = IIF(gam.debug_npc_info, "Hide", "Show")
 IF dbg.def(      , scF6, showhide & " NPC info overlay (F6)") THEN gam.debug_npc_info XOR= YES

 IF dbg.def(      , scF7, "Move the camera (F7)") THEN
  IF gam.debug_camera_pan THEN
   gam.showtext = "Normal camera restored"
  ELSE
   gam.showtext = "Press arrow keys to pan the camera, SHIFT to go faster, F7 to stop"
  END IF
  gam.showtext_ticks = 45
  gam.debug_camera_pan XOR= YES
 END IF

 IF dbg.def(      , scF8) THEN debug_menu
 dbg.def(      ,     , "Debug menu (F8)")  'Does nothing, but document F8.


 IF dbg.def(scCtrl, scF9, IIF(scriptprofiling, "Stop", "Start") & " script profiling (Ctrl-F9)") THEN
  scriptprofiling XOR= YES
  IF scriptprofiling THEN
   gam.showtext = "Timings will be printed to g_debug.txt"
  ELSE
   print_script_profiling
   clear_profiling_stats
   gam.showtext = "Script timings printed to g_debug.txt"
  END IF
  gam.showtext_ticks = 36
 END IF

 IF dbg.def(      , scF10) THEN
  scrwatch = loopvar(scrwatch, 0, 2, 1)
  gam.debug_showtags = 0
 END IF
 IF dbg.def(      ,      , "Script debugger (F10)") THEN
  scrwatch = 2  'Go straight in instead of showing the memory usage bars
  gam.debug_showtags = 0
 END IF

 IF dbg.def(scCtrl, scF10, "Toggle script logging (Ctrl-F10)") THEN
  IF gam.script_log.enabled THEN
   gam.script_log.enabled = NO
   gam.showtext = "Script logging disabled."
  ELSE
   gam.showtext = "Logging to " & trimpath(gam.script_log.filename)
   start_script_trigger_log
  END IF
  gam.showtext_ticks = 36
 END IF

 IF dbg.def(      , scF11, "Walk through walls (F11)") THEN
  gam.walk_through_walls XOR= YES
  gam.showtext = "Walk through walls: " & yesorno(gam.walk_through_walls)
  gam.showtext_ticks = 36
 END IF

 'Ctrl+F11 is handled in allmodex
 IF dbg.def( , , "Macro record/replay menu (Ctrl-F11)") THEN macro_controls

 'Screenshotting with F12 is handled in allmodex
 IF dbg.def( , , "Screenshot (F12)") THEN screenshot

 'This is also handled in allmodex
 IF dbg.def( , , "Record .gif video (Ctrl-F12)") THEN toggle_recording_gif

 IF dbg.def(, scPause, "Pause game (Pause)") THEN
  gam.paused XOR= YES
  IF gam.paused THEN
   gam.showtext = "PAUSED"
   gam.showtext_ticks = INT_MAX
  ELSE
   gam.showtext_ticks = 0
  END IF
 END IF

 IF gam.debug_showtags = 0 OR dbg.menu <> NULL THEN  'Always accessible in debug menu
  IF dbg.def(scCtrl, scPlus) OR _
     dbg.def(scCtrl, scNumpadPlus, "Increase tick rate (Ctrl +)") THEN
   speedcontrol = large(speedcontrol - 1, 10.)
   gam.showtext = speedcontrol & "ms/frame"
   gam.showtext_ticks = 60
  END IF
  IF dbg.def(scCtrl, scMinus) OR _
     dbg.def(scCtrl, scNumpadMinus, "Decrease tick rate (Ctrl -)") THEN
   speedcontrol = small(speedcontrol + 1, 160.)
   gam.showtext = speedcontrol & "ms/frame"
   gam.showtext_ticks = 60
  END IF
 END IF

 'This is implemented in allmodex, can't provide this as a menu item, but document it anyway.
 dbg.def( , , "[Hold down to speed up:] (Shift+Tab)")

 'Ctrl+~ implemented in allmodex
 IF dbg.def( , , "Show frames-per-second (Ctrl ~)") THEN toggle_fps_display

 IF dbg.def( , , "Toggle window resizability") THEN
  IF resolution_unlocked THEN
   apply_game_window_settings()  'Reset size to genResolutionX/Y
   lock_resolution
  ELSE
   unlock_resolution 0, 0
  END IF
  gam.showtext = "Window resizable: " & yesorno(resolution_unlocked)
  gam.showtext_ticks = 60
 END IF

 IF dbg.def( , , "List slices to g_debug.txt") THEN
  debug "----------------Slice Tree Dump---------------"
  SliceDebugDumpTree SliceTable.Root
  notification "Dumped entire slice tree to g_debug.txt"
 END IF

 IF dbg.def( , , "Realign leader to grid") THEN
  (heropos(0)) = herotpos(0) * 20
  herow(0).xygo = 0
 END IF

 IF dbg.def( , , "Edit general preference bitsets") THEN edit_general_bitsets
 IF dbg.def( , , "Edit backcompat bitsets") THEN edit_backcompat_bitsets
 IF dbg.def( , , "Show/test battle formations") THEN battle_formation_testing_menu
 IF dbg.def( , , "(Advanced) Manipulate gen() array") THEN patcharray gen(), "gen"
 IF dbg.def( , , "(Advanced) Manipulate gmap() array") THEN patcharray gmap(), "gmap"
 'IF dbg.def( , , "Test Slicified Spell Screen") THEN spell_screen onwho(readglobalstring(106, "Whose Spells?", 20), NO)
 #IFDEF __FB_ANDROID__
  IF dbg.def( , , "Email saved game") THEN
   savegame 33
   email_save_to_developer 33
  END IF
 #ENDIF

 IF gen(genCurrentDebugMode) = 0 THEN
  IF dbg.def( , , "Switch to debug mode (show errors)") THEN gen(genCurrentDebugMode) = 1
 ELSE
  IF dbg.def( , , "Switch to release mode (hide errors)") THEN gen(genCurrentDebugMode) = 0
 END IF
 IF dbg.def( , , "Mouse Options") THEN edit_mouse_options()
END SUB

' Check for debug key combos.
SUB check_debug_keys()
 DIM dbg as DebugMenuDef
 debug_menu_functions(dbg)
END SUB

' Show a menu of debug functions.
SUB debug_menu()
 ' Build
 DIM dbg as DebugMenuDef
 dbg.start_building_menu()
 debug_menu_functions(dbg)
 DIM menu() as string
 vector_to_array menu(), dbg.menu

 ' Show
 DIM result as integer
 STATIC default as integer = 0
 result = multichoice("Debug Menu", menu(), default, , "game_debug_menu")
 IF result = -1 THEN EXIT SUB

 ' Enact
 default = result
 dbg.selected_item = menu(result)
 debug_menu_functions(dbg)
END SUB

SUB battle_formation_testing_menu()

 STATIC defaultval as integer = 0
 DIM form_num as integer
 DIM state as MenuState
 DIM menu as MenuDef
 ClearMenuData menu

 DIM battle_formation_set as integer
 battle_formation_set = readblock(foemap, herotx(0), heroty(0))

 IF battle_formation_set = 0 THEN
  append_menu_item(menu, "Formation set: None", 0, 1)
  menu.last->disabled = YES
  menu.last->extra(0) = -1
 ELSE
  DIM formset as FormationSet
  LoadFormationSet formset, battle_formation_set
  append_menu_item(menu, "Formation set: " & battle_formation_set & " freq=" & formset.frequency)
  menu.last->disabled = YES
  menu.last->extra(0) = -1
  FOR i as integer = 0 TO UBOUND(formset.formations)
   form_num = formset.formations(i)
   IF form_num >= 0 THEN
    DIM formdata as Formation
    LoadFormation formdata, form_num
    DIM desc as string = describe_formation(formdata)
    append_menu_item(menu, form_num & ": " & LEFT(desc, 35))
    menu.last->extra(0) = form_num
    IF defaultval = 0 THEN defaultval = 1
   END IF
  NEXT i
 END IF
 
 state.active = YES
 menu.textalign = alignLeft
 menu.maxrows = 16
 init_menu_state state, menu
 state.pt = defaultval
 menu.alignvert = alignTop
 menu.anchorvert = alignTop
 menu.offset.Y = 10

 'Keep whatever was on the screen already as a background (NOTE: this doesn't always work (not necessarily vpage))
 DIM holdscreen as integer
 holdscreen = allocatepage
 copypage vpage, holdscreen

 setkeys
 DO
  setwait 55
  setkeys

  IF keyval(scEsc) > 1 THEN
   EXIT DO
  END IF
  IF keyval(scF1) > 1 THEN show_help "game_formation_testing"

  IF enter_space_click(state) THEN
   form_num = menu.items[state.pt]->extra(0)
   IF form_num >= 0 THEN
    defaultval = state.pt
    fatal = NO
    gam.wonbattle = battle(form_num)
    prepare_map YES
    queue_fade_in 1
   END IF 
   EXIT DO
  END IF
  
  usemenu state

  copypage holdscreen, vpage
  draw_menu menu, state, vpage
  edgeprint "F1 Help", 0, pBottom, uilook(uiText), vpage
  setvispage vpage
  dowait
 LOOP
 setkeys
 freepage holdscreen
 ClearMenuData menu

END SUB

'Send an email to the game author. Currently only works on Android.
'save_slot: -1: Don't attach a save. 0+: Attach an existing save.
'Also attaches g_debug.txt, g_debug_archive.txt if a save is attached.
SUB email_save_to_developer(save_slot as integer = -1, subject as string = "", body as string = "")
 DIM as string file1, file2, file3
 IF save_slot >= 0 THEN 
  file1 = savedir & SLASH & save_slot & ".rsav"
  IF isfile(file1) = NO THEN file1 = ""
 END IF
 IF LEN(file1) THEN
  file2 = log_dir & "g_debug.txt"
  file3 = log_dir & "g_debug_archive.txt"
  IF isfile(file3) = NO THEN file3 = ""
  ' Later on it would be *awesome* to always record an .ohrkeys file since the last time the player
  ' loaded a save or started a game, and include that and the save too.
 END IF
 IF LEN(subject) = 0 THEN subject = getdisplayname(trimpath(sourcerpg)) & " feedback"
 IF LEN(body) = 0 THEN body = "(Please include a helpful description of the problem here)"

 DIM distinfo as DistribState
 load_distrib_state distinfo
 ' Note: email can be blank. User can always fill something in
 email_files(distinfo.email, subject, body, file1, file2, file3)
END SUB


'==========================================================================================
'                                tmpdir setup & cleanup
'==========================================================================================


SUB refresh_keepalive_file ()
 DIM timestamp as string
 'build a timestamp string in the format YYYY-MM-DD hh:mm:ss
 timestamp = MID(DATE, 7, 4) & "-" & MID(DATE, 1, 2) & "-" & MID(DATE, 4, 2) & " " & TIME
 DIM filename as string
 filename = tmpdir & "keepalive.tmp"
 DIM fh as integer
 OPENFILE(filename, FOR_BINARY + ACCESS_WRITE, fh)
 PUT #fh, 1, timestamp
 CLOSE #fh
END SUB

FUNCTION read_keepalive_as_days (keepalive_file as string) as integer
 DIM fh as integer
 OPENFILE(keepalive_file, FOR_BINARY + ACCESS_READ, fh)
 DIM datestr as string = "YYYY-MM-DD"
 GET #fh, 1, datestr
 CLOSE #fh
 RETURN days_since_datestr(datestr)
END FUNCTION

FUNCTION guess_age_by_tmpdir_name(dirname as string) as integer
 'The dirname argument is just the final component of the dirname, not the full path.
 'It will be in one of the following two formats:
 'Old: YYYYMMDDhhmmss.RANDOM.tmp
 'New: ohrrpgceYYYYMMDDhhmmss.RANDOM.tmp
 'New format
 IF LEFT(dirname, 8) = "ohrrpgce" THEN dirname = MID(dirname, 9)
 DIM datestr as string
 datestr = MID(dirname, 1, 4) & "-" & MID(dirname, 5, 2) & "-" & MID(dirname, 7, 2)
 RETURN days_since_datestr(datestr)
END FUNCTION

SUB cleanup_other_temp_files ()
 DIM tmp_parent as string = trimfilename(tmpdir)
 DIM tmp_cur as string = trimpath(tmpdir)
 
 REDIM filelist() as string
 'Modern tmp dirs would match the pattern "ohrrpgce*.tmp" but this would miss old tmp dirs
 '(which before 2013 had names like 20120308044737.800.tmp).
 'The pattern "*.tmp" is too broad because it could match a large number of non-ohrrpgce
 'tmp files on windows (even "*.*.tmp" is more broad than I would like for it to be)
 findfiles tmp_parent, "*.*.tmp", fileTypeDirectory, NO, filelist()

 DIM dirname as string
 DIM dirname_full as string
 DIM keepalive_file as string
 DIM age as integer
 DIM threshhold as integer

 FOR idx as integer = 0 TO UBOUND(filelist)
  dirname = filelist(idx)
  dirname_full = tmp_parent & SLASH & dirname
  keepalive_file = dirname_full & SLASH & "keepalive.tmp"
  IF dirname = tmp_cur THEN
   debuginfo "Ignore " & dirname & " because we are using it"
   CONTINUE FOR
  ELSEIF NOT isdir(dirname_full & SLASH & "playing.tmp") ANDALSO INSTR(dirname_full, "ohrrpgce") = 0 THEN
   'If either .ohrrpgce is part of the path or the directory name is ohrrpgce*.*.tmp then we can delete.
   debuginfo "Ignore " & dirname & " because it does not have playing.tmp and the name does not include ""ohrrpgce"""
  ELSE
   IF NOT isfile(keepalive_file) THEN
    'Yon tmpdir is olde beyond reckoning
    age = guess_age_by_tmpdir_name(dirname)
    threshhold = 14
   ELSE
    'This is a modern tmpdir with a valid keepalive file
    age = read_keepalive_as_days(keepalive_file)
    threshhold = 3
   END IF
#IFDEF __FB_ANDROID__
   '--Android only permits one running copy of a process, so it is always safe to clean up all tmpdirs
   threshhold = -1
#ENDIF
   IF age > threshhold THEN
    center_edgeboxstyle  , 65, 25 * 8, 16, 0, vpage, NO, YES
    edgeprint "Cleaning up files: " & INT(100 / large(UBOUND(filelist), 1) * idx) & "%", _
              pCentered, 60, uilook(uiText), vpage
    setvispage vpage, NO
    debuginfo "CLEAN " & dirname_full & " because it has been dead for about " & age & " days"
    killdir dirname_full, YES
   ELSE
    debuginfo "Ignore " & dirname & " because it has only been dead " & age & " days"
   END IF
  END IF
 NEXT idx
END SUB


'==========================================================================================
'                                   Virtual gamepad
'==========================================================================================


SUB a_script_wants_keys()
 'After running a command that checks for keys, keep the virtual gamepad visible for about half a second
 gam.pad.script_wants_keys = ideal_ticks_per_second() / 2
END SUB

SUB update_virtual_gamepad_display()
 'Based on global state, of the current game, decide whether or not the virtual gamepad should be displaying
 IF calc_virtual_gamepad_state() THEN
  IF NOT gam.pad.being_shown THEN
   show_virtual_gamepad()
   gam.pad.being_shown = YES
  END IF
 ELSE
  IF gam.pad.being_shown THEN
   hide_virtual_gamepad()
   gam.pad.being_shown = NO
  END IF
 END IF
END SUB

FUNCTION calc_virtual_gamepad_state() as bool
 'None of this matters unless we are running on a platform that actually uses a virtual gamepad
 IF NOT running_on_mobile() THEN RETURN NO

 IF gam.pad.script_hide_virtual_gamepad THEN RETURN NO
 IF gam.pad.script_show_virtual_gamepad THEN RETURN YES

 'The gamepad might be disabled for this game
 IF should_disable_virtual_gamepad() THEN RETURN NO
 
 'A script command has run recently that is checking for key input
 IF gam.pad.script_wants_keys > 0 THEN
  gam.pad.script_wants_keys -= 1
  RETURN YES
 END IF
 
 'Inside battle mode, force the gamepad visible
 IF gam.pad.in_battle THEN RETURN YES

 'Now check and see if the virtual gamepad should be disabled because of textboxes
 IF use_touch_textboxes() THEN
  IF txt.showing THEN
   'Make an exception when the current textbox has a choicebox
   IF txt.box.choice_enabled THEN RETURN YES
   IF top_menu_allows_controls() THEN RETURN YES
   'No exceptions were found, proceed to hide the virtual gamepad for this textbox
   RETURN NO
  END IF
 END IF
 
 IF readbit(gen(), genSuspendBits, suspendplayer) ANDALSO should_hide_virtual_gamepad_when_suspendplayer() THEN
  'Suspendplayer is active, and this game has the "Hide virtual gamepad when suspendplayer" bitset
  IF top_menu_allows_controls() THEN RETURN YES 'Menus still need the gamepad
  IF txt.showing THEN RETURN YES 'Non-touch textboxes still need the gamepad
  RETURN NO
 END IF
 
 'If no other conditions are met, enabled the virtual gamepad
 RETURN YES
END FUNCTION

FUNCTION top_menu_allows_controls() as bool
 IF topmenu >= 0 THEN
  'If any menus are open, we need to check the top one
  IF menus(topmenu).no_controls = NO THEN
   'The top menu menu allows controls
   RETURN YES
  END IF
 END IF
 RETURN NO
END FUNCTION


'==========================================================================================
'                                 Hero Pathfinding/Mouse controls
'==========================================================================================


FUNCTION hero_is_pathfinding() as bool
 RETURN gam.hero_pathing.mode <> HeroPathingMode.NONE
END FUNCTION

SUB cancel_hero_pathfinding()
 gam.hero_pathing.mode = HeroPathingMode.NONE
 clear_hero_pathfinding_display
END SUB

SUB trigger_hero_pathfinding()
 DIM clickpos as XYPair = XY(mapx, mapy) + readmouse().pos
 wrapxy clickpos, 20
 DIM npc_index as integer = npc_at_pixel(clickpos)
 IF npc_index >= 0 THEN
  gam.hero_pathing.mode = HeroPathingMode.NPC
  gam.hero_pathing.dest_npc = npc_index
 ELSE
  clickpos.y -= gmap(11) 'adjust for foot-offset
  DIM clicktile as XYPair = clickpos \ 20
  gam.hero_pathing.mode = HeroPathingMode.POS
  gam.hero_pathing.dest_pos = clicktile
 END IF
END SUB

SUB update_hero_pathfinding_menu_queue()
 IF gam.hero_pathing.mode = HeroPathingMode.NONE THEN EXIT SUB
 IF user_triggered_main_menu() THEN
  IF get_gen_bool("/mouse/move_hero/cancel_on_menu") THEN
   gam.hero_pathing.queued_menu = YES
   cancel_hero_pathfinding()
   EXIT SUB
  END IF
 END IF
END SUB

SUB update_hero_pathfinding(byval rank as integer)
 IF gam.hero_pathing.mode = HeroPathingMode.NONE THEN
  clear_hero_pathfinding_display()
  EXIT SUB
 END IF
 
 DIM t1 as XYPair = herotpos(rank)
 DIM t2 as XYPair
 
 SELECT CASE gam.hero_pathing.mode
  CASE HeroPathingMode.POS:
   t2 = gam.hero_pathing.dest_pos
  CASE HeroPathingMode.NPC:
   WITH npc(gam.hero_pathing.dest_npc)
    IF .id > 0 THEN
     'Target NPC still exists
      t2 = .pos \ 20
    ELSE
     'Target NPC was destroyed or tag-disabled
     cancel_hero_pathfinding()
     EXIT SUB
    END IF
   END WITH
   IF xypair_manhattan_distance(t1, t2) = 1 THEN
    'One tile away from dest NPC!
    (herodir(rank)) = xypair_direction_to(t1, t2, herodir(rank))
    usenpc 0, find_useable_npc()
   END IF
 END SELECT
 
 dim pf as AStarPathfinder = AStarPathfinder(t1, t2, 1000)
 pf.calculate(null, NO, YES)
 'pf.slow_debug()
 dim maxpath as integer = get_gen_int("/mouse/move_hero/max_path_length")
 if v_len(pf.path) > 1 andalso (maxpath = 0 orelse v_len(pf.path) <= maxpath) then
  'Don't move unless a path is found that is longer than one tile
  (herodir(rank)) = xypair_direction_to(pf.path[0], pf.path[1], herodir(rank))
  heromove_walk_ahead(rank)
  update_hero_pathfinding_display(t2)
 else
  'Give up immediately when pathing fails
  gam.hero_pathing.mode = HeroPathingMode.NONE
  clear_hero_pathfinding_display()
 end if
END SUB

SUB clear_hero_pathfinding_display()
 IF gam.hero_pathing.dest_display_sl <> 0 THEN
  DeleteSlice @(gam.hero_pathing.dest_display_sl)
 END IF
END SUB

SUB update_hero_pathfinding_display(byval tile as XYpair)
 IF get_gen_bool("/mouse/move_hero/display_dest") THEN
  DIM sl as Slice Ptr
  IF gam.hero_pathing.dest_display_sl <> 0 THEN
   sl = gam.hero_pathing.dest_display_sl
  ELSE
   gam.hero_pathing.dest_display_sl = NewSliceOfType(slEllipse, SliceTable.MapOverlay, SL_PATHFIND_DEST_DISPLAY)
   sl = gam.hero_pathing.dest_display_sl
   sl->width = 25
   sl->height = 25
   sl->AnchorHoriz = 1
   sl->AnchorVert = 1
   ChangeEllipseSlice sl, uilook(uiHighlight)
  END IF
  IF gam.hero_pathing.mode = HeroPathingMode.NPC THEN
   IF npc(gam.hero_pathing.dest_npc).sl <> null THEN
    sl->X = npc(gam.hero_pathing.dest_npc).x + 10
    sl->Y = npc(gam.hero_pathing.dest_npc).y + 10 + gmap(11) 'foot offset
    EXIT SUB
   END IF
  END IF
  DIM destpos as XYPair
  framewalkabout tile * 20 + 10, destpos, mapsizetiles * 20, gmap(5)
  sl->X = mapx + destpos.x
  sl->Y = mapy + destpos.y + gmap(11) 'foot offset
 END IF
END SUB

SUB heromove_walk_ahead(byval rank as integer)
 IF herodir(rank) = 0 THEN herow(rank).ygo = 20
 IF herodir(rank) = 2 THEN herow(rank).ygo = -20
 IF herodir(rank) = 3 THEN herow(rank).xgo = 20
 IF herodir(rank) = 1 THEN herow(rank).xgo = -20
END SUB

FUNCTION user_triggered_main_menu() as bool
 IF carray(ccMenu) > 1 THEN RETURN YES
 IF get_gen_bool("/mouse/menu_right_click") THEN
  IF readmouse().clicks AND mouseRight THEN RETURN YES
 END IF
 RETURN NO
END FUNCTION

SUB debug_mouse_state()
 DIM s as string
 WITH readmouse()
  s = "Mouse: B=" & .buttons & " C=" & .clicks & " R=" & .release & " X=" & .x & " Y=" & .y
 END WITH
 gam.showtext = s
 gam.showtext_ticks = 1
END SUB

