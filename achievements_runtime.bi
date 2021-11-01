#ifndef ACHIEVEMENTS_RUNTIME_BI
#define ACHIEVEMENTS_RUNTIME_BI

#include "reload.bi"

type AchievementProgress
    id as uinteger
    value as uint64
    seen_tags as integer vector

    declare constructor
    declare destructor
end type

declare sub achievements_evaluate_tags()
declare sub achievements_reset() ' clears data, for a new game
declare sub achievements_load(node as Reload.NodePtr)
declare sub achievements_save(node as Reload.NodePtr)

#endif
