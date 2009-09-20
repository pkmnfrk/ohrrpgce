'OHRRPGCE - bmodsubs.bi
'(C) Copyright 1997-2006 James Paige and Hamster Republic Productions
'Please read LICENSE.txt for GPL License details and disclaimer of liability
'See README.txt for code docs and apologies for crappyness of this code ;)
'Auto-generated by MAKEBI from bmodsubs.bas

#IFNDEF BMODSUBS_BI
#DEFINE BMODSUBS_BI

#INCLUDE "udts.bi"
#INCLUDE "battle_udts.bi"

declare function is_hero(who as integer) as integer
declare function is_enemy(who as integer) as integer
declare function is_attack(who as integer) as integer
declare function is_weapon(who as integer) as integer
declare sub anim_advance (who as integer, attack as AttackData, bslot() as battlesprite)
declare function atkallowed OVERLOAD (atkbuf() as integer, attacker as integer, spclass as integer, lmplev as integer, bstat() AS BattleStats) as integer
declare function atkallowed OVERLOAD (atk as AttackData, attacker as integer, spclass as integer, lmplev as integer, bstat() AS BattleStats) as integer
declare function checktheftchance (item as integer, itemp as integer, rareitem as integer, rareitemp as integer) as integer
declare sub control
declare function countai (ai as integer, them as integer, es() as integer) as integer
declare function enemycount (bslot() as battlesprite, bstat() AS BattleStats) as integer
declare function targenemycount (bslot() AS BattleSprite, bstat() AS BattleStats, for_alone_ai as integer=0) as integer
declare sub anim_enemy (who as integer, attack as AttackData, bslot() AS BattleSprite)
declare function getweaponpos(w as integer,f as integer,isy as integer) as integer'or x?
declare function getheropos(h as integer,f as integer,isy as integer) as integer'or x?
declare sub anim_hero (who as integer, attack as AttackData, bslot() AS BattleSprite)
declare function inflict (w as integer, as integer, bstat() AS BattleStats, bslot() as battlesprite, harm() as string, hc() as integer, hx() as integer, hy() as integer, attack as AttackData, tcount as integer) as integer
declare function liveherocount overload (bstat() AS BattleStats) as integer
declare function liveherocount (oobstat() AS integer) as integer
declare sub loadfoe (i as integer, formdata() as integer, es() as integer, BYREF bat AS BattleState, bslot() AS BattleSprite, bstat() AS BattleStats, BYREF rew AS RewardsState, allow_dead as integer = NO)
declare function randomally (who as integer) as integer
declare function randomfoe (who as integer) as integer
declare sub anim_retreat (who as integer, attack as AttackData, bslot() AS BattleSprite)
declare function safesubtract (number as integer, minus as integer) as integer
declare function safemultiply (number as integer, by as single) as integer
declare sub setbatcap (BYREF bat AS BattleState, cap as string, captime as integer, capdelay as integer)
declare sub smartarrowmask (inrange() as integer, d as integer, axis as integer, bslot() as battlesprite, targ AS TargettingState)
declare sub smartarrows (d as integer, axis as integer, bslot() as battlesprite, BYREF targ AS TargettingState, allow_spread as integer=0)
declare function targetable (attacker as integer, target as integer, bslot() as battlesprite) as integer
declare function targetmaskcount (tmask() as integer) as integer
declare sub traceshow (s as string)
declare function trytheft (BYREF bat AS BattleState, who as integer, targ as integer, attack as AttackData, es() as integer) as integer
declare function exptolevel (level as integer) as integer
declare sub updatestatslevelup (i as integer, exstat() as integer, bstat() AS BattleStats, allowforget as integer)
declare sub giveheroexperience (i as integer, exstat() as integer, exper as integer)
declare sub setheroexperience (byval who as integer, byval amount as integer, byval allowforget as integer, exstat() as integer, exlev() as integer)
declare function visibleandalive (o as integer, bstat() AS BattleStats, bslot() as battlesprite) as integer
declare sub writestats (exstat() as integer, bstat() AS BattleStats)

declare sub get_valid_targs OVERLOAD (tmask() as integer, who as integer, atkbuf() as integer, bslot() AS BattleSprite, bstat() AS BattleStats)
declare sub get_valid_targs OVERLOAD (tmask() as integer, who as integer, atk as AttackData, bslot() AS BattleSprite, bstat() AS BattleStats)
declare function attack_can_hit_dead(who as integer, attack as AttackData) as integer
declare sub autotarget OVERLOAD (who as integer, atkbuf() as integer, bslot() AS BattleSprite, bstat() AS BattleStats)
declare sub autotarget OVERLOAD (who as integer, atk as AttackData, bslot() AS BattleSprite, bstat() AS BattleStats)
declare function find_preferred_target OVERLOAD (tmask() as integer, who as integer, atkbuf() as integer, bslot() AS BattleSprite, bstat() AS BattleStats) as integer
declare function find_preferred_target OVERLOAD (tmask() as integer, who as integer, atk as AttackData, bslot() AS BattleSprite, bstat() AS BattleStats) as integer

#ENDIF
