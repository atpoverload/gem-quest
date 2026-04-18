extends "res://gemanizer/loggable.gd"

var curses = {}
var blessings = {}
var npcs = {}
var stages = {}

func load_resources(scenario) -> void:
	# items
	$ItemManager.load_items(scenario)
	# enemies
	$EnemyManager.load_actions(scenario)
	$EnemyManager.load_enemies(scenario)
	# emotes
	$EmoteManager.load_emotes(scenario)
	# events
	$EventManager.load_events(scenario)

	load_status(scenario)
	load_npcs(scenario)
	load_arcade_stages(scenario)

func load_status(scenario):
	for curse in scenario['curses']:
		log_state('resource_manager', 'load_status', 'loading status %s' % curse)
		curses[curse] = scenario['curses'][curse]
		curses[curse]['texture'] = load('%s/curses/sprites/%s.png' % [scenario['resources']['dir'], curse])
		curses[curse]['description'] = {
			'entity_name': curse,
			'type': 'Curse',
			'effect': curses[curse]['effect'],
			'metadata': null,
			'flavor': curses[curse]['flavor']
		}
	for blessing in scenario['blessings']:
		log_state('resource_manager', 'load_status', 'loading status %s' % blessing)
		blessings[blessing] = scenario['blessings'][blessing]
		blessings[blessing]['texture'] = load('%s/blessings/sprites/%s.png' % [scenario['resources']['dir'], blessing])
		blessings[blessing]['description'] = {
			'entity_name': blessing,
			'type': 'Blessing',
			'effect': blessings[blessing]['effect'],
			'metadata': null,
			'flavor': blessings[blessing]['flavor']
		}

func load_npcs(scenario):
	for npc in scenario['npcs']:
		log_state('resource_manager', 'load_npcs', 'loading NPC %s' % npc['character'])
		npcs[npc['character']] = load('%s/npcs/sprites/%s.png' % [scenario['resources']['dir'], npc['character']])

func load_arcade_stages(scenario):
	for stage in scenario['arcade']['entries']:
		stages[stage] = scenario['arcade']['entries'][stage]
