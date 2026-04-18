extends Node2D

var ledge_builder = preload("res://gem_hunter/ledge.tscn")
var block_builder = preload("res://gem_hunter/block.tscn") # 45 seems to be the peak jump height
var hazard_builder = preload("res://gem_hunter/spike.tscn")
var monster_builder = preload("res://gem_hunter/monster.tscn")

signal win;

func build_level(level):
	var player_ = level['player']
	$Player.position = Vector2(player_['x'], player_['y'])

	var treasure_ = level['treasure']
	$Treasure.position = Vector2(treasure_['x'], treasure_['y'])

	for ledge_ in level['ledges']:
		var ledge = ledge_builder.instantiate()
		ledge.set_width(ledge_['width'])
		ledge.set_height(ledge_['height'])
		ledge.position = Vector2(ledge_['x'], ledge_['y'])
		$Ledges.add_child(ledge)
		ledge.name = 'Ledge'

	for block_ in level['blocks']:
		var block = block_builder.instantiate()
		block.set_width(block_['width'])
		block.set_height(block_['height'])
		block.position = Vector2(block_['x'], block_['y'])
		$Blocks.add_child(block)
		block.name = 'Block'

	for monster_ in level['monsters']:
		var monster = monster_builder.instantiate()
		monster.gravity = monster_['gravity']
		monster.jump_strength = monster_['jump_strength']
		monster.walk_speed = monster_['walk_speed']
		monster.hop_wait = monster_['hop_wait']
		monster.position = Vector2(monster_['x'], monster_['y'])
		$Monsters.add_child(monster)
		monster.name = 'Monster'

	for hazard_ in level['hazards']:
		var hazard = hazard_builder.instantiate()
		hazard.position = Vector2(hazard_['x'], hazard_['y'])
		$Hazards.add_child(hazard)
		hazard.name = 'Hazard'
