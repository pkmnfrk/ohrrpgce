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
    tags as integer vector ' yay, free basic
    steam_id as string

    declare constructor
    declare destructor
end type

declare sub achievement_definitions_load(file_path as string)
declare sub achievement_definitions_free()
declare function achievement_definitions_count() as integer
declare function achievement_definitions_get_by_index(index as integer) as AchievementDefinition ptr
declare function achievement_definitions_get_by_id(id as integer) as AchievementDefinition ptr
declare function achievement_definitions_new() as AchievementDefinition ptr

#endif
