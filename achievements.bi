#ifndef ACHIEVEMENTS_BI
#define ACHIEVEMENTS_BI

#include "common_base.bi"

enum AchievementType
    flag
    count
end enum

type AchievementDefinition
    id as uinteger
    name as string
    achievement_type as AchievementType
    max_value as uint64
    progress_interval as uinteger
    latching as boolean
    tags(any) as integer ' yay, free basic
    steam_id as string
end type

declare sub load_achievements(file_path as string)
declare sub free_achievements()
declare sub achievement_tag_notify(id as integer, state as boolean)

#endif