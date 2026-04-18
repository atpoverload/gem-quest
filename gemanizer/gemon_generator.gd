extends Node

func new_monster():
	return {
		'name': '',
		'battlecry': '',
		'color': '',
		'health': '',
		'actions': [{
			'name': '',
			'chance': ''
		}],
		'resistances': {},
		'flavor': ''
	}

	#for enemy in scenario['enemies']:
		#log_state('enemy_manager', 'load_enemy', 'loading enemy %s' % enemy['name'])
		#if 'battlecry' in enemy:
			#enemy['battlecry'] = load('%s/enemies/battlecries/%s.mp3' % [scenario['resources']['dir'], enemy['battlecry']])
		#else:
			#enemy['battlecry'] = load('%s/enemies/battlecries/%s.mp3' % [scenario['resources']['dir'], enemy['name'].to_lower()])
		#enemy['texture'] = load('%s/enemies/sprites/%s.png' % [scenario['resources']['dir'], enemy['name']])
		#for action in enemy['actions']:
			#action['action'] = actions[action['name']]['action']
			#action['text'] = actions[action['name']]['text']
		#enemies[enemy['name']] = enemy
