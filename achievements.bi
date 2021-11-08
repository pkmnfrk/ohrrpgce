#ifndef ACHIEVEMENTS_BI
#define ACHIEVEMENTS_BI

#include "common_base.bi"

enum AchievementType
    flag
    count
end enum

type AchievementDefinition
    id as uinteger = 0
    name as string = ""
    achievement_type as AchievementType = AchievementType.flag
    max_value as uint64 = 0
    progress_interval as uinteger = 0
    latching as boolean = false
    tags as integer vector ' yay, free basic
    steam_id as string = ""

    declare constructor
    declare destructor
end type

declare sub achievement_definitions_load(file_path as string)
declare sub achievement_definitions_free()
declare function achievement_definitions_count() as integer
declare function achievement_definitions_get_by_index(index as integer) byref as AchievementDefinition
declare function achievement_definitions_get_by_id(id as integer) byref as AchievementDefinition
declare function achievement_definitions_is_permanent() as boolean

#endif
