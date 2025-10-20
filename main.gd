extends Node2D

signal log_message(message: String)

func _ready() -> void:
	log_state('[_ready]', 'starting new game runtime')
	start_menu()

func log_state(method, message):
	print("(%s)[main.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func hide_menus():
	$Start.hide()
	$Enemy.hide()
	$Rest.hide()
	$Reward.hide()
	$Player.disable()

func start_menu() -> void:
	log_state('start_menu', 'going to the main menu')
	hide_menus()
	$Player.clear_inventory()
	$Player.hide()

	$BackgroundManager.set_background(-1)
	$Start.show()
	log_message.emit('💎 Gem Quest 💎')

func new_game(scenario) -> void:
	log_state('new_game', 'starting a new \'%s\' scenario' % scenario)
	log_message.emit('Entering the %s' % scenario)
	hide_menus()

	# load the scenario
	$ScenarioManager.load_scenario('res://scenarios/%s.json' % scenario)

	# create a new player
	await $Player.set_player($ScenarioManager.starting_character(), $ScenarioManager.starting_level())

	# show the starting scene
	$BackgroundManager.set_background(1)
	$Player.show()

	await get_tree().create_timer(0.50).timeout

	# starting inventory for player
	log_state('new_game', 'create starting inventory')
	for item in $ScenarioManager.starting_items():
		log_state('new_game', 'adding %s' % item)
		if item[0] in 'AEIOUaeiou':
			log_message.emit('Found an %s' % item)
		else:
			log_message.emit('Found a %s' % item)
		item = $ItemManager.get_item(item)
		await $Player.add_item(item)
		await get_tree().create_timer(0.10).timeout
	await get_tree().create_timer(0.10).timeout

	next_event()

func next_event():
	hide_menus()
	if not $ScenarioManager.has_events():
		#win_the_game()
		return

	var event = $ScenarioManager.next_event()
	log_state('next_event', 'starting next %s event' % event['type'])
	match event['type']:
		'battle':
			battle(event)
		'treasure':
			treasure(event)
		'rest':
			rest(event)
		'pause':
			pause()
		'victory':
			victory()

func battle(event):
	$SoundManager/Battle.playing = true
	await get_tree().create_timer($SoundManager/Battle.stream.get_length() / 8).timeout

	$Enemy.set_enemy($EnemyManager.get_enemy(event['enemy']), event['level'])
	$Enemy.show()
	$Enemy/SoundEffects/BattleCry.playing = true
	log_message.emit('%s arrived' % $Enemy.character_name)
	await $Enemy.sprite.arrive()
	await get_tree().create_timer(0.4).timeout

	$Player.take_turn()

func treasure(event):
	log_message.emit('Found some %s' % event['reward'])
	$SoundManager/Treasure.playing = true
	await get_tree().create_timer($SoundManager/Treasure.stream.get_length() / 8).timeout

	$Reward.clear_rewards()
	var rewards = $ItemManager.get_rewards(event)
	for reward in rewards:
		reward = $ItemManager.get_item(reward)
		$Reward.add_reward($Player, reward)
	$Reward.show()

func sell_rewards():
	var reward = 0
	for child in $Reward/Rewards/Rewards.get_children():
		reward += 100 * child.get_child(1)._item['rarity']
	reward /= len($Reward/Rewards/Rewards.get_children())
	$Reward.clear_rewards()
	await $Player.gain_experience(reward)

	next_event()

func rest(event):
	log_message.emit('Found a rest spot')
	$Rest.show()
	$SoundManager/Rest.playing = true
	for effect in $Player.status:
		await $Player.set_status(effect, 0)
	var restored = event['safety'] * $Player.rest_health()
	if 'Sleep' in $Player.emotes:
		restored += 5 * $Player.emotes['Sleep']
	await $Player.set_health($Player.health + restored)
	await get_tree().create_timer(0.5).timeout
	$NextEvent.show()

func pause():
	$NextEvent.show()

func victory():
	hide_menus()
	log_message.emit('%s found the Gold Gem!' % $Player.character_name)
	$Victory.show()
	$SoundManager/Victory.playing = true
