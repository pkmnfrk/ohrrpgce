#ifndef ACHIEVEMENTS_RUNTIME_BI
#define ACHIEVEMENTS_RUNTIME_BI

#include "reload.bi"

type AchievementProgress
    id as uinteger = 0
    value as uint64 = 0
    seen_tags as integer vector
    rewarded as boolean
    rewarded_date as double

    declare constructor
    declare destructor
end type

declare sub achievements_evaluate_tags()
declare sub achievements_reset() ' clears data, for a new game
declare sub achievements_load(node as Reload.NodePtr)
declare sub achievements_save(node as Reload.NodePtr)

#endif
