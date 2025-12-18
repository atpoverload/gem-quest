extends Node

var items = {}
# we need some sort of rarity/loot table
var weapons = []
var gems = []
var drinks = []
var food = []
var emotes = []
var damages = []
var healing = []
var lucky = []

var drop_tables = {}

func log_state(method, message):
	print("(%s)[item_manager.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func load_items(items_file):
	log_state('load_items', 'loading item data from %s' % items_file)
	var item_stats = load(items_file).data
	for item in item_stats['items']:
		log_state('load_items', 'loading %s' % item['name'])
		items[item['name']] = {
			'name': item['name'],
			'type': item['type'],
			'texture': load("res://items/sprites/%s.png" % item['name']),
			'sound': load("res://items/sounds/%s.mp3" % item['sound']),
		}
		if 'element' in item:
			items[item['name']]['element'] = item['element']
		if 'power' in item:
			# TODO: this is very brittle if there's a healing or draining gem
			items[item['name']]['power'] = int(item['power'])
			if item['type'] in ['weapon', 'gem']:
				damages.append(item['name'])
			else:
				healing.append(item['name'])
		if 'status' in item:
			items[item['name']]['status'] = item['status']
		if 'buff' in item:
			items[item['name']]['buff'] = item['buff']
		if 'stacks' in item:
			items[item['name']]['stacks'] = item['stacks']
		if 'accuracy' in item:
			items[item['name']]['accuracy'] = int(item['accuracy'])
		if 'flavor' in item:
			items[item['name']]['flavor'] = item['flavor']
		else:
			items[item['name']]['flavor'] = ''
		if 'rarity' in item:
			items[item['name']]['rarity'] = int(item['rarity'])
		else:
			items[item['name']]['rarity'] = 0
		# TODO: BAD! BAD! BAD! the player API shouldn't live here
		match item['type']:
			'weapon':
				items[item['name']]['description'] = '%d Attack Power' % items[item['name']]['power']
				items[item['name']]['action'] = 'weapon_attack'
				weapons.append(item['name'])
			'gem':
				if 'power' in item:
					items[item['name']]['description'] = '%d Gem Power' % items[item['name']]['power']
				elif 'status' in item:
					items[item['name']]['description'] = 'Apply %s' % items[item['name']]['status']
				elif 'buff' in item:
					items[item['name']]['description'] = 'Grant %s' % items[item['name']]['buff']
				else:
					items[item['name']]['description'] = 'It does nothing?'
				items[item['name']]['action'] = 'use_gem'
				gems.append(item['name'])
			'drink':
				var description = []
				if 'power' in item:
					description.append('Heal %s HP' % items[item['name']]['power'])
				if 'status' in item:
					description.append('Remove %s' % items[item['name']]['status'])
				if 'buff' in item:
					description.append('Grant %s' % items[item['name']]['buff'])
				items[item['name']]['description'] = '\n'.join(description)
				items[item['name']]['action'] = 'use_consumable'
				drinks.append(item['name'])
			'food':
				var description = []
				if 'power' in item:
					description.append('Heal %s HP' % items[item['name']]['power'])
				if 'status' in item:
					description.append('Remove %s' % items[item['name']]['status'])
				if 'buff' in item:
					description.append('Grant %s' % items[item['name']]['buff'])
				items[item['name']]['description'] = '\n'.join(description)
				items[item['name']]['action'] = 'use_consumable'
				food.append(item['name'])
			'emote':
				items[item['name']]['description'] = item['description']
				items[item['name']]['effect'] = item['effect']
				emotes.append(item['name'])
				if 'stat' in item['effect'] and item['effect']['stat'] == 'luck':
					lucky.append(item['name'])
		log_state('load_items', 'loaded %s' % item['name'])

func _ready() -> void:
	load_items('res://items/items.json')

func get_item(item):
	return items[item]

func get_rewards(event):
	log_state('get_rewards', 'creates rewards for event %s' % event)
	# TODO: totally change this
	var rewards = []
	if event['reward'] in drop_tables:
		rewards = drop_tables[event['reward']]
	else:
		match event['reward']:
			'weapon':
				for weapon in weapons:
					if items[weapon]['rarity'] <= event['rarity']:
						rewards.append(weapon)
			'gem':
				for gem in gems:
					if items[gem]['rarity'] <= event['rarity']:
						rewards.append(gem)
			'drink':
				for drink in drinks:
					if items[drink]['rarity'] <= event['rarity']:
						rewards.append(drink)
			'food':
				for food_ in food:
					if items[food_]['rarity'] <= event['rarity']:
						rewards.append(food_)
			'emote':
				for emote in emotes:
					if emote not in lucky:
						rewards.append(emote)
			'damage':
				for damage in damages:
					if items[damage]['rarity'] <= event['rarity']:
						rewards.append(damage)
			'heal':
				for heal in healing:
					if items[heal]['rarity'] <= event['rarity']:
						rewards.append(heal)
			'shiny', 'shinies', 'lucky':
				for luck in lucky:
					if items[luck]['rarity'] <= event['rarity']:
						rewards.append(luck)
			_:
				for item in items:
					if items[item]['rarity'] <= event['rarity']:
						rewards.append(item)
	log_state('get_rewards', 'pool of items found: %s' % ', '.join(rewards))
	rewards.shuffle()
	rewards = rewards.slice(0, event['count'])
	log_state('get_rewards', 'items chosen: %s' % ', '.join(rewards))
	return rewards
