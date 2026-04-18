extends "res://gemanizer/loggable.gd"

var actions = {}
var enemies = {}
var pools = {}

func load_actions(scenario):
	log_state('enemy_manager', 'load_actions', 'loading action data from %s' % scenario['name'])
	for action in scenario['actions']['entries']:
		log_state('enemy_manager', 'load_action', 'loading action %s' % action['name'])
		actions[action['name']] = action

func load_enemies(scenario):
	log_state('enemy_manager', 'load_enemy', 'loading enemy data from %s' % scenario['name'])
	for enemy in scenario['enemies']['entries']:
		log_state('enemy_manager', 'load_enemy', 'loading enemy %s' % enemy['name'])
		if 'battlecry' in enemy:
			enemy['battlecry'] = load('%s/enemies/battlecries/%s.mp3' % [scenario['resources']['dir'], enemy['battlecry']])
		else:
			enemy['battlecry'] = load('%s/enemies/battlecries/%s.mp3' % [scenario['resources']['dir'], enemy['name'].to_lower()])
		enemy['texture'] = load('%s/enemies/sprites/%s.png' % [scenario['resources']['dir'], enemy['name']])
		for action in enemy['actions']:
			action['action'] = actions[action['name']]['action']
			action['text'] = actions[action['name']]['text']
		enemies[enemy['name']] = enemy

	log_state('enemy_manager', 'load_enemies', 'loading enemy pool data from %s' % scenario['name'])
	for pool in scenario['enemies']['pools']:
		log_state('enemy_manager', 'load_enemies', 'loading pool %s' % pool)
		pools[pool] = scenario['enemies']['pools'][pool]

func from_pool(pool):
	pool = pools[pool]
	var choice = randi() % 100
	var chance = 0
	for enemy in pool:
		chance += pool[enemy]
		if choice < chance:
			return enemies[enemy]
	return pool[pool.keys().pick_random()]
