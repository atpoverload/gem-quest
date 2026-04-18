extends "res://gemanizer/loggable.gd"

var items = {}
var weapons = []
var gems = []
var drinks = []
var food = []

var pools = {}

var resources

func get_item_type(item):
	if 'color' in item: return '%s %s' % [item['color'], item['type']]
	else: return item['type']

func get_effect(action):
	match action['type']:
		'Attack', 'Weapon':
			var effect = '%d Power\n%d Accuracy' % [action['power'], action['accuracy']]
			if 'on_attack' in action:
				match action['on_attack']['action']:
					'AttackAgain': effect += '\nMay attack again'
					'AddBlessing': effect += '\nAttacks may grant %s' % action['on_attack']['status']
					'AddCurse': effect += '\nAttacks may cause %s' % action['on_attack']['status']
			return effect
		'Heal': return 'Restores %d HP' % [action['power']]
		'AddCurse': return 'Causes %s\n%d Accuracy' % [action['status'], action['accuracy']]
		'AddBlessing': return 'Grants %s' % action['status']
		'RemoveCurse', 'RemoveBlessing': return 'Removes %s' % action['status']
		'DoNothing': return 'It does nothing?'
		'AffinityUp': return 'Increases affinities.'
		'Actions':
			var message = []
			for a in action['actions']:
				message.append(get_effect(a))
			return '\n'.join(message)

func get_description(item):
	return {
		'name': item['name'],
		'type': get_item_type(item),
		'effect': get_effect(item['action']),
		'metadata': null,
		'flavor': item['flavor']
	}

func load_item(item):
	item['texture'] = load('%s/items/sprites/%s.png' % [resources, item['name']])
	item['description'] = get_description(item)
	return item

func load_items(scenario):
	log_state('item_manager', 'load_items', 'loading item data from %s' % scenario['name'])
	resources = scenario['resources']['dir']
	for item in scenario['items']['entries']:
		log_state('item_manager', 'load_items', 'loading item %s' % item['name'])
		item = load_item(item.duplicate())
		items[item['name']] = item
		match item['type']:
			'Weapon': weapons.append(item)
			'Gem': gems.append(item)
			'Drink': drinks.append(item)
			'Food': food.append(item)

	log_state('item_manager', 'load_items', 'loading item pool data from %s' % scenario['name'])
	for pool in scenario['items']['pools']:
		log_state('item_manager', 'load_items', 'loading pool %s' % pool)
		pools[pool] = scenario['items']['pools'][pool]

	$LuckyItemManager.load_lucky_items(scenario)
	$SnackGenerator.load_snacks(scenario)

func from_pool(pool):
	pool = pools[pool]
	var choice = randi() % 100
	var chance = 0
	for item in pool:
		chance += pool[item]
		if choice < chance:
			return items[item]
	return items[items.keys().pick_random()]
