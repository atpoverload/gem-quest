extends Node

var attack
var gem
var drink
var eat
var hit
var critical_hit
var miss
var crickets
var break_gem
var revive
var gems = {}
var curses = {}
var blessings = {}

func _ready():
	attack = $Attack
	gem = $Gem
	drink = $Drink
	eat = $Eat
	hit = $Hit
	critical_hit = $CriticalHit
	miss = $Miss
	crickets = $Crickets
	break_gem = $BreakGem
	revive = $Miss

	for gem_ in $GemColors.get_children():
		gems[gem_.name] = gem_
	for curse in $Curses.get_children():
		curses[curse.name] = curse
	for blessing in $Blessings.get_children():
		blessings[blessing.name] = blessing
