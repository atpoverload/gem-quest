class_name GemQuest

extends Node

#enum ItemType {
	#Weapon,
	#Gem,
	#Drink,
	#Food,
	#Emote
#}
#
#enum EffectColor {
	#White,
	#Red,
	#Blue,
	#Green,
	#Orange,
	#Purple
#}
#
#enum AttackEffect {
	#AttackAgain,
	#BoostMe,
	#Bonk,
	#Drain
#}
#
#enum GemEffect {
	#Attack,
	#Curse,
	#Boost,
	#Luck
#}
#
#enum CurseEffect {
	#Poison,
	#Sleep,
#}
#
#const CURSE_DESCRIPTIONS = {
	#CurseEffect.Poison: ['Poison', 'Curse', 'Deals damage every turn.', null, '12 damage from brock. 15 from forest. 8 from forest to Pewter. 10 from rock tunnel. 10 from route 22. 22 from mt moon without grass.'],
	#CurseEffect.Sleep: ['Sleep', 'Curse', 'Skips your turn until you wake up.', null, 'GOTTA WAKE UP DUDE!!!']
#}
#
#enum BlessingEffect {
	#Boost,
	#Shield,
#}
#
#const BLESSING_DESCRIPTIONS = {
	#BlessingEffect.Boost: ['Boost', 'Blessing', 'Increase weapon damage.', null, 'Gimme the BOOOOOST!!!'],
	#BlessingEffect.Shield: ['Shield', 'Blessing', 'Blocks the next attack.', null, '']
#}
#
#enum ConsumableEffect {
	#Heal,
	#RemoveStatus,
	#Buff
#}
#
#enum EmoteEffect {
	#OnAttack,
	#OnGem,
	#OnDrink,
	#OnFood
#}
