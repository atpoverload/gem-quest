extends "res://gemanizer/loggable.gd"

var emotes = {}

func get_effect(passive):
	match passive['type']:
		'OnAttack':
			match passive['effect']:
				'AttackAgain': return 'May attack again'
				'AddBlessing': return 'Attacks may grant %s' % passive['status']
				'AddCurse': return 'Attacks may cause %s' % passive['status']
		'Stat':
			match passive['stat']:
				'Accuracy': return 'More accurate'
				'CriticalHit': return 'More critical hits'
				'GemProtection': return 'Protects gems'
				'GemPower': return 'Gems are stronger'
				'Freebie': return '%s may be free' % passive['item_type']
				'Evasion': return 'Evade more'
				'Revive': return 'May evade death'

func load_emotes(scenario):
	log_state('emote_manager', 'load_emotes', 'loading emote data from %s' % scenario['name'])
	for item in scenario['emotes']['entries']:
		log_state('emote_manager', 'load_emotes', 'loading emote %s' % item['name'])
		item['texture'] = load('%s/emotes/sprites/%s.png' % [scenario['resources']['dir'], item['name']])
		item['description'] = {
			'name': item['name'],
			'type': 'Emote',
			'effect': get_effect(item['passive']),
			'metadata': null,
			'flavor': item['flavor']
		}
		emotes[item['name']] = item
