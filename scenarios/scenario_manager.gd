extends Node

var level
var character
var items
var events

var cursor

func log_state(method, message):
	print("(%s)[event_manager.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func load_scenario(scenario):
	log_state('load_scenario', 'loading scenario from %s' % scenario)
	scenario = load(scenario).data
	level = scenario['level']
	log_state('load_scenario', 'starting level %d' % level)
	character = {
		'name': scenario['character']['name'],
		'health': int(scenario['character']['health'])
	}
	log_state('load_scenario', 'starting character %s' % character)
	items = scenario['items']
	log_state('load_scenario', 'starting items [%s]' % ','.join(items))
	events = scenario['events']
	log_state('load_scenario', 'found %d events' % len(events))
	cursor = 0

func starting_level():
	return level

func starting_character():
	return character

func starting_items():
	return items

func has_events():
	var has_next_event = cursor < len(events)
	log_state('has_events', has_next_event)
	return has_next_event

func next_event():
	var event = events[cursor]
	log_state('next_event', 'event %d=%s' % [cursor, event])
	cursor += 1
	return event
