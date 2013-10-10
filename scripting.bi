#ifndef SCRIPTING_BI
#define SCRIPTING_BI

#include "scrconst.bi"

DECLARE SUB trigger_script (byval id as integer, byval double_trigger_check as bool, scripttype as string, trigger_loc as string, scrqueue() as QueuedScript, byval trigger as integer = plottrigger)
DECLARE SUB trigger_script_arg (byval argno as integer, byval value as integer, byval argname as zstring ptr = NULL)
DECLARE SUB dequeue_scripts ()
DECLARE SUB run_queued_scripts ()

DECLARE SUB start_script_trigger_log ()
DECLARE SUB script_log_tick ()
DECLARE SUB script_log_out (text as string)
DECLARE SUB watched_script_triggered (script as QueuedScript)
DECLARE SUB watched_script_resumed ()
DECLARE SUB watched_script_finished ()

DECLARE SUB print_script_profiling

DECLARE SUB script_start_waiting(waitarg1 as integer = 0, waitarg2 as integer = 0)
DECLARE SUB script_stop_waiting(returnval as integer = 0)

DECLARE FUNCTION runscript (byval id as integer, byval newcall as integer, byval double_trigger_check as bool, byval scripttype as zstring ptr, byval trigger as integer) as integer
DECLARE FUNCTION loadscript (byval n as unsigned integer) as ScriptData ptr
DECLARE SUB freescripts (byval mem as integer)

DECLARE FUNCTION commandname (byval id as integer) as string
DECLARE FUNCTION current_command_name() as string
DECLARE FUNCTION interpreter_context_name() as string
DECLARE FUNCTION script_call_chain (byval trim_front as integer = YES) as string
DECLARE SUB scripterr (e as string, byval errorlevel as scriptErrEnum = serrBadOp)
DECLARE FUNCTION script_interrupt () as integer

' The following are in oldhsinterpreter.bas

DECLARE SUB scriptinterpreter ()
DECLARE SUB scriptdump (s as string)
DECLARE SUB breakpoint (byref mode as integer, byval callspot as integer)
DECLARE SUB scriptwatcher (byref mode as integer, byval drawloop as integer)
DECLARE SUB setScriptArg (byval arg as integer, byval value as integer)
DECLARE SUB killallscripts ()
DECLARE SUB killtopscript ()
DECLARE SUB killscriptthread ()
DECLARE SUB resetinterpreter ()
DECLARE SUB delete_scriptdata (byval scriptd as ScriptData ptr)
DECLARE SUB reload_scripts ()

#endif