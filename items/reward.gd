extends Control

func log_state(method, message):
	print("(%s)[reward.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func clear_rewards():
	for child in $Rewards/Rewards.get_children():
		$Rewards/Rewards.remove_child(child)

func add_reward(item):
	log_state('add_item', 'adding %s to rewards' % item['name'])
	var reward = null
	if item['type'] == 'emote':
		reward = $EmoteReward.duplicate()
	else:
		reward = $ItemReward.duplicate()
	reward.get_child(1).set_item(item)
	#reward.get_child(1).pressed.connect(Callable(get_parent(), 'next_event'))
	reward.show()
	$Rewards/Rewards.add_child(reward)
	show()
