extends Node

var hit
var critical_hit
var miss

var curses = {}
var blessings = {}

var attacks = {}
var status = {}

func _ready():
	hit = $Hit
	critical_hit = $CriticalHit
	miss = $Miss

	for curse in $Curses.get_children():
		curses[curse.name] = curse
	for blessing in $Blessings.get_children():
		blessings[blessing.name] = blessing

	for action in $Attacks.get_children():
		attacks[action.name] = action
	for action in $Status.get_children():
		status[action.name] = action
