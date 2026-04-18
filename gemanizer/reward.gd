extends Control

var button_builder = preload('res://gemanizer/reward_button.tscn')

signal choose_reward(item)
signal skip_reward
signal show_description
signal hide_description

func log_state(method, message):
	print("(%s)[reward.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func clear_rewards():
	for child in $Rewards.get_children():
		$Rewards.remove_child(child)

func add_reward(item):
	log_state('add_item', 'adding %s to rewards' % item['name'])
	var reward = button_builder.instantiate()
	reward.ignore_texture_size = true
	var size = item.texture.get_size()
	reward.custom_minimum_size = 2 * 150 * size / (size.x + size.y)
	reward.stretch_mode = 0

	reward.set_item(item)
	reward.pressed.connect(hide)
	reward.pressed.connect(_choose_reward.bind(item))
	reward.mouse_entered.connect(_show_item.bind(item))
	reward.mouse_exited.connect(_hide_description)
	$Rewards.add_child(reward)
	$Sounds/ShowRewards.play()
	show()

func arrive():
	$Skip.hide()
	$OpenChest.hide()
	$ClosedChest.show()
	show()
	await $ClosedChest.arrive()
	await $ClosedChest.attack(5)

func show_rewards():
	$ClosedChest.hide()
	$ClosedChest.reset()
	$OpenChest.show()
	$Skip.show()

func _choose_reward(item):
	choose_reward.emit(item)

func _show_item(item):
	var flavor = item['description']['flavor']
	if 'twitch.tv' in item['description']['flavor'] or 'youtube.com' in item['description']['flavor']:
		flavor = 'Click to watch the clip!'
	show_description.emit(
		item['description']['name'],
		item['description']['type'],
		item['description']['effect'],
		item['description']['metadata'],
		flavor,
	)

func _hide_description():
	hide_description.emit()


func _skip_reward() -> void:
	clear_rewards()
	skip_reward.emit()
