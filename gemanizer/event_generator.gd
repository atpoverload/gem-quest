extends Node

func log_state(method, message):
	print("(%s)[event_generator.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func new_reward():
	var rewards = []
	return {
		"type": "reward",
		"reward": rewards,
	}

func new_battle():
	var enemy = null
	return {
		"type": "battle",
		"enemy": enemy,
	}
