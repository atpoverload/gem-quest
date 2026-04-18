extends "res://gemanizer/loggable.gd"

var sections = {}
var pools = {}

func get_event_description(event):
	match event['type']:
		'Battle': return 'Battle a monster.'
		'Puzzle': return 'Solve a puzzle to get a reward.'
		'Reward': return 'Get a item.'
		'Travel': return 'Go to a new scenario.'
		'Shrine': return 'Gain a blessing.'
		'Trap': return 'Dodge a trap or pay.'
		'Rest': return 'Recover health and status.'

func load_events(scenario):
	log_state('event_manager', 'load_events', 'loading event data from %s' % scenario['name'])
	for section in scenario['events']['entries']:
		log_state('event_manager', 'load_events', 'loading section %s' % section)
		sections[section] = scenario['events']['entries'][section]
		for event in sections[section]:
			if event['type'] == 'Choice':
				for child in event['choices']:
					child['texture'] = load('%s/ui/sprites/%s.png' % [scenario['resources']['dir'], child['type']])
					child['description'] = get_event_description(child)
					child['flavor'] = ''

	log_state('event_manager', 'load_pools', 'loading event pool data from %s' % scenario['name'])
	for section in scenario['events']['pools']:
		log_state('event_manager', 'load_pools', 'loading pool %s' % section)
		pools[section] = scenario['events']['pools'][section]
