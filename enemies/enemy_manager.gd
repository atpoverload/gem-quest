extends Node

var enemies = {}

func log_state(method, message):
	print("(%s)[enemy_manager.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func load_enemies(enemies_file):
	log_state('load_enemies', 'loading enemy data from %s' % enemies_file)
	var enemy_stats = load(enemies_file).data
	for enemy in enemy_stats['enemies']:
		log_state('load_enemies', 'loaded %s' % enemy['name'])
		enemies[enemy['name']] = {
			'name': enemy['name'],
			'health': enemy['health'],
			'power': enemy['power'],
			'accuracy': enemy['accuracy'],
			'experience': enemy['experience'],
			'sprite': load("res://enemies/sprites/%s.png" % enemy['name']),
			'battle_cry': load("res://enemies/battlecry/%s.mp3" % enemy['sound']),
			'logic': enemy['logic'],
		}
		if 'resistances' in enemy:
			enemies[enemy['name']]['resistances'] = enemy['resistances']

func _ready() -> void:
	load_enemies('res://enemies/enemies.json')

func get_enemy(enemy):
	return enemies[enemy]
