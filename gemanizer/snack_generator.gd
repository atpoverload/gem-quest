extends Node

var basic_actions = {
	'Heal': {
		'type': 'Heal',
		'power': 1
	},
	'AddBlessing': {
		'type': 'AddBlessing',
		'status': ['Boost', 'Shield', 'Lucky'],
		'power': 1
	},
	'RemoveCurse': {
		'type': 'RemoveCurse',
		'status': [
			'Poison',
			'Poison',
			'Poison',
			'Poison',
			'Poison',
			'Poison',
			'Poison',
			'Poison',
			'Poison',
			'Any'
		],
		'power': 1
	},
	'AffinityUp': {
		'type': 'AffinityUp',
		'affinities': [
			'White',
			'Red',
			'Blue',
			'Green',
			'Orange',
			'Purple',
			'Pink',
		]
	}
}
var snacks

func load_snacks(scenario):
	snacks = scenario['items']['generators'][0]['items'].duplicate()

func new_snack(luck):
	var snack = snacks.pick_random().duplicate()
	# all snacks have a primary action, and have a chance for a secondary
	var chance_for_secondary = log(luck + 10) / log(10)
	chance_for_secondary = ceili(100 * (1 - 1 / chance_for_secondary))
	var chance = randi() % 100
	if chance < chance_for_secondary:
		var action = {
			'type': 'Actions',
			'actions': []
		}
		var action_type = snack['action']['type']
		var primary_split = (randi() % 30 + 60) / 100.0
		var secondary_split = 1 - primary_split
		action['actions'].append(populate_snack_action(snack['action'], ceili(luck * primary_split) + 1))
		var secondary = basic_actions.keys().filter(func(a): return a != action_type).pick_random()
		action['actions'].append(populate_snack_action(basic_actions[secondary], ceili(luck * secondary_split) + 1))
		snack['action'] = action
	else:
		snack['action'] = populate_snack_action(snack['action'], luck)
	snack['genned_name'] = '%s #%x' % [snack['name'], hash(snack)]
	return snack

func populate_snack_action(action, luck):
	action = action.duplicate()
	match action['type']:
		'Heal':
			action['power'] = luck * (randi() % (luck + action['power']) + 1)
		'AddBlessing':
			action['status'] = action['status'].pick_random()
			action['power'] = (randi() % (luck + action['power']) + 1)
		'RemoveCurse':
			action['status'] = action['status'].pick_random()
		'AffinityUp':
			var affinities = range(luck).map(func(_a): return action['affinities'].pick_random())
			action['affinities'] = affinities
	return action
