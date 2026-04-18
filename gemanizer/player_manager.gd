extends "res://gemanizer/loggable.gd"

var accuracy = 100
var crit_chance = 100

func new_player():
	$Player.character_name = 'Light'

	$Player.stats.strength = 5
	$Player.stats.magic = 5
