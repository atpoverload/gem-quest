extends Node

var lucky_items = []

func load_lucky_items(scenario):
	for item in scenario['lucky_items']:
		item = item.duplicate()
		item['texture'] = load('%s/lucky_items/sprites/%s.png' % [scenario['resources']['dir'], item['name']])
		item['description'] = {
			'name': item['name'],
			'type': '%s Lucky Item' % item['color'],
			'effect': 'Increases luck.',
			'metadata': null,
			'flavor': item['flavor']
		}
		lucky_items.append(item)
