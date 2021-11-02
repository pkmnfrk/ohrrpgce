#include "achievements_runtime.bi"
#include "achievements.bi"
#include "moresubs.bi"
#include "steam.bi"

' -- achievements_runtime
' This file contains functionality related to implementing achievements during gameplay. This includes
' keeping track of seen tags, progress values, etc, as well as logic to reward achievements if
' appropriate.
'
' Assumptions:
' * achievement definitions (achievements.rbas) have been loaded
' * the indexes in achievement_progres match the indexes in the achievement definitions
' 
' IDs (in the type-member sense) are _not_ used to match achievements. These IDs are only for save data


' uncomment to enable debug output
' #define DEBUG_ACHIEVEMENTS


declare function mark_tag_as_seen(index as integer, tag as integer) as boolean
declare function needs_rewarding(index as integer) as boolean
declare function needs_progress_update(index as integer) as boolean

#ifdef DEBUG_ACHIEVEMENTS
declare sub ach_debug(msg as string) ' this is actually defined in achievements.rbas
#else
#define ach_debug(x)
#endif


' -- globals --
redim shared achievement_progress() as AchievementProgress
dim shared rewarded_achievements as uinteger vector

' -- public api --

sub achievements_evaluate_tags()
    ach_debug("achievements_evaluate_tags")
    for index as integer = 0 to ubound(achievement_progress)
        ach_debug("evaluating #" & index)
        with achievement_definitions_get_by_index(index)
            if v_find(rewarded_achievements, .id) <> -1 then continue for ' ignore rewarded achievements

            ach_debug("evaluating '" & .name & "'")
            for t as integer = 0 to v_len(.tags) - 1
                dim tag as integer = .tags[t]

                if mark_tag_as_seen(index, tag) then
                    if needs_rewarding(index) then
                        ' reward the achievement
                        ach_debug("rewarding '" & .name & "'")
                        v_append rewarded_achievements, .id
                        reward_achievement .steam_id
                    elseif needs_progress_update(index) then
                        ' ping user with progress
                        ach_debug("notifying progress on '" & .name & "'")
                        notify_achievement_progress .steam_id, achievement_progress(index).value, .max_value
                    end if
                end if
            next
        end with
    next
end sub

sub achievements_reset
    dim count as integer = achievement_definitions_count()
    ach_debug("resetting achievement data to " & count)
    if count = 0 then
        erase achievement_progress
    else
        redim achievement_progress(count - 1)
    end if

    if rewarded_achievements <> null then
        v_free rewarded_achievements
    end if

    v_new rewarded_achievements
end sub

sub achievements_load(node as Reload.NodePtr)
    achievements_reset

    ach_debug("loading achievement data")

    for index as integer = 0 to ubound(achievement_progress)
        achievement_progress(index).id = achievement_definitions_get_by_index(index).id
    next

    if node <> null then
        ' TODO: load data from save file
    end if
end sub

sub achievements_save(node as Reload.NodePtr)

    ach_debug("saving achievement data")
    ' TODO: persist data to save file
end sub

' -- members for AchievementProgress --

constructor AchievementProgress
    ach_debug("AchivementProgress constructor")
    v_new seen_tags
end constructor

destructor AchievementProgress
    ach_debug("AchivementProgress destructor")
    v_free seen_tags
end destructor

' -- internal functions --

private function mark_tag_as_seen(index as integer, tag as integer) as boolean
    ach_debug("mark_tag_as_seen")
    with achievement_definitions_get_by_index(index)
        ach_debug("Achievement #" & index & " is already rewarded: " & (v_find(rewarded_achievements, .id) <> -1))
        if v_find(rewarded_achievements, .id) <> -1 then return false ' ignore rewarded achievements

        dim is_triggered as boolean = istag(tag)
        dim ix as integer = v_find(achievement_progress(index).seen_tags, tag)
        ach_debug("Relevant tag " & tag & " is " & is_triggered)
        if is_triggered and ix = -1 then
            ach_debug("This means that is is now on!")
            v_append achievement_progress(index).seen_tags, tag
            if .achievement_type = AchievementType.count and achievement_progress(index).value < .max_value then
                achievement_progress(index).value += 1
            end if
            return true
        elseif .latching = false andalso is_triggered = false andalso ix <> -1 then
            ach_debug("This means that is is now off!")
            v_remove achievement_progress(index).seen_tags, tag
            ' note: disabling a tag does _not_ decrement the value
            ' for this reason, we return false since the achievement state didn't really change
            return false
        end if
    end with

    return false
end function

private function needs_rewarding(index as integer) as boolean
    ach_debug("needs_rewarding")
    dim byref achievement as AchievementDefinition = achievement_definitions_get_by_index(index)
    dim byref progress as AchievementProgress = achievement_progress(index)

    if v_find(rewarded_achievements, achievement.id) <> -1 then return false 

    select case achievement.achievement_type
        case AchievementType.flag
            for ix as integer = 0 to v_len(achievement.tags) - 1
                dim tag as integer = achievement.tags[ix]
                if v_find(progress.seen_tags, tag) = -1 then
                    ach_debug(":( '" & achievement.name & "' is not complete because tag " & tag & " is not set")
                    return false
                end if
            next
        case AchievementType.count
            if progress.value < achievement.max_value then
                ach_debug(":( '" & achievement.name & "' is not complete because value " & progress.value & " is less than " & achievement.max_value)
                return false
            end if
    end select
    ach_debug(":D '" & achievement.name & "' is complete!")
    return true
end function

' call this _after_ checking is_complete!
private function needs_progress_update(index as integer) as boolean
    ach_debug("needs_progress_update(" & index & ")")
    dim byref achievement as AchievementDefinition = achievement_definitions_get_by_index(index)
    dim byref progress as AchievementProgress = achievement_progress(index)

    ach_debug((achievement.achievement_type = AchievementType.count) & _
        ", " & (achievement.progress_interval > 0) & _
        ", " & (progress.value > 0) & _
        ", " & (progress.value mod achievement.progress_interval) _
    )
    return achievement.achievement_type = AchievementType.count _
        andalso achievement.progress_interval > 0 _
        andalso progress.value > 0 _
        andalso (progress.value mod achievement.progress_interval) = 0
end function

#ifdef DEBUG_ACHIEVEMENTS
private sub ach_debug(msg as string)
    debug "achievements: " & msg
end sub
#endif