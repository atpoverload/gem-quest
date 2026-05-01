extends Node2D

var scenario
var logger

var section = []

func log_state(method, message):
	print('[gem_quest.gd][%s]<%s> %s' % [Time.get_datetime_string_from_system(), method, message])

func _ready() -> void:
	logger = $Logger/Background/Message/ScrollLogger

	clear()

	var scenario_file = "res://scenarios/demo.yaml"
	scenario = YAML.load_file(scenario_file).get_data()

	$ResourceManager.load_resources(scenario)

	$Player.curses.set_effects($ResourceManager.curses)
	$Player.blessings.set_effects($ResourceManager.blessings)

	$Enemy.curses.set_effects($ResourceManager.curses)
	$Enemy.blessings.set_effects($ResourceManager.blessings)

	$Start.show()
	if FileAccess.file_exists("user://savegame.save"):
		$Reset.show()
	var save_data = get_save_data()
	if save_data and 'beat_game' in save_data and save_data['beat_game']:
		$GemHunter.show()
	else:
		$GemHunter.hide()

func delete_save():
	DirAccess.remove_absolute("user://savegame.save")
	for child in $LuckyItems/GridContainer.get_children():
		$LuckyItems/GridContainer.remove_child(child)
	$GemHunter.hide()

func clear():
	logger.add_message('Gem Quest')
	$Background.set_background('Start Screen')
	$Background.set_music('Start Screen')

	$Next.disabled = true
	$Next.hide()
	$Player.hide()
	$Player.in_combat = false
	$Inventory.hide()
	$Inventory.clear()
	$NPC.hide()
	$Trap.hide()
	$Enemy.hide()
	$Arcade.hide()
	$Reward.hide()
	$Altar.hide()
	$Description.hide()
	$Rest.hide()
	$Dialogue.hide()
	section = []
	var save_data = get_save_data()
	if save_data and 'beat_game' in save_data and save_data['beat_game']:
		$GemHunter.show()
	else:
		$GemHunter.hide()

func new_game():
	# logger.add_message('%s enters the %s.' % [scenario['player']['name'], scenario['name']])
	await setup_player()
	$GemHunter.hide()

	if not section:
		section = $ResourceManager/EventManager.sections['Start'].duplicate()
	next_event()

# TODO: this whole thing is vulnerable
func setup_player():
	$Player.show()
	
	var player_data = get_save_data()
	if not player_data:
		player_data = scenario['player']

	await $Player.set_player(player_data)
	logger.add_message('Gained some experience.')
	await $Player.gain_experience(100 * $Player.level())
	$Player.health.adjust(9999)

	$Inventory.disable(null)

	$Inventory.show()
	for item in player_data['items']:
		if item['type'] == 'name':
			$Inventory.add_item($ResourceManager/ItemManager.items[item['name']])
		elif item['type'] == 'literal':
			item['literal']['texture'] = load(item['literal']['texture'].split(')')[0].split('(')[-1])
			$Inventory.add_item(item['literal'])
		await get_tree().create_timer(0.18).timeout
	for emote in player_data['emotes']:
		$Player.add_emote($ResourceManager/EmoteManager.emotes[emote])
		await get_tree().create_timer(0.18).timeout
	section = player_data['event']

func get_save_data():
	if FileAccess.file_exists("user://savegame.save"):
		var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
		var json_string = save_file.get_line()

		# Creates the helper class to interact with JSON.
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result = json.parse(json_string)
		var player_data
		if not parse_result == OK:
			return null
		else:
			player_data = json.data
			for affinity in player_data['affinities']:
				player_data['affinities'][affinity] = int(player_data['affinities'][affinity])
		return player_data
	else:
		return null

# this is junky
func next_event():
	if len(section) == 0:
		return
	$Next.disabled = true
	$Next.hide()
	var event = section.pop_front()
	if event['type'] != 'Wait':
		$NPC.hide()
		$Trap.hide()
		$Enemy.hide()
		$Reward.hide()
		$Altar.hide()
		$Rest.hide()
	$Dialogue.hide()
	log_state('next_event', 'starting event %s' % event['type'])
	Callable.create(self, event['type']).call(event)

# events
func Message(event):
	logger.add_message(event['message'])
	await get_tree().create_timer(1.25).timeout
	next_event()

func Background(event):
	$Background.set_background(event['background'])
	next_event()

func Music(event):
	$Background.set_music(event['music'])
	next_event()

func Battle(event):
	var enemy = get_enemy(event['enemy'])
	var level_ = get_level(event['level'])
	await $Enemy.set_enemy(enemy, int(level_))
	logger.add_message('%s arrives!' % enemy['name'])
	await $Enemy.arrive()
	$Player.in_combat = true
	$Player.take_turn()

func get_enemy(enemy):
	match enemy['type']:
		'Pool': return $ResourceManager/EnemyManager.from_pool(enemy['pool'])
		'Name': return $ResourceManager/EnemyManager.enemies[enemy['name']]

func Reward(event):
	logger.add_message('A reward!')
	await $Reward.clear_rewards()
	await $Reward.arrive()

	var rewards = []
	for reward in event['rewards']:
		reward = choose_reward(reward)
		if not rewards.has(reward):
			rewards.append(reward)
	for reward_ in rewards: $Reward.add_reward(reward_)

	await $Reward.show_rewards()

func choose_reward(reward):
	match reward['type']:
		'generator':
			var luck = get_level(reward['luck'])
			var item = $ResourceManager/ItemManager.load_item($ResourceManager/ItemManager/SnackGenerator.new_snack(luck))
			return item
		'pool':
			return $ResourceManager/ItemManager.from_pool(reward['pool'])
		'kind':
			match reward['kind']:
				'Weapon': return $ResourceManager/ItemManager.weapons.pick_random()
				'Gem': return $ResourceManager/ItemManager.gems.pick_random()
				'Drink': return $ResourceManager/ItemManager.drinks.pick_random()
				'Food': return $ResourceManager/ItemManager.food.pick_random()
				'Emote': return $ResourceManager/EmoteManager.emotes.values().pick_random()
		'name':
			if reward['name'] in $ResourceManager/ItemManager.items:
				return $ResourceManager/ItemManager.items[reward['name']]
			elif reward['name'] in $ResourceManager/EmoteManager.emotes:
				return $ResourceManager/EmoteManager.emotes[reward['name']]

func skip_reward():
	$Reward/Skip.hide()
	$Altar/Skip.hide()
	$Inventory.disable(null)
	next_item = null
	# TODO: add something here
	LuckyItem(null)
	next_event()

func Trap(event):
	match event['event']['type']:
		'Battle':
			var enemy;
			enemy = get_enemy(event['event']['enemy'])
			var lvl = get_level(event['event']['level'])
			await $Enemy.set_enemy(enemy, lvl)
			$Enemy.obscure()
			$Enemy/Sprite.arrive()
			$Enemy.show()
			logger.add_message('A wandering monster!')
		'Damage':
			$Trap/Curse.hide()
			$Trap/Damage.obscure()
			$Trap/Damage.arrive()
			$Trap/Damage.show()
			$Trap.show()
			logger.add_message('%s found a trap!' % $Player.character_name)
		'Curse':
			$Trap/Damage.hide()
			$Trap/Curse.obscure()
			$Trap/Curse.arrive()
			$Trap/Curse.show()
			$Trap.show()
			logger.add_message('%s found a trap!' % $Player.character_name)

	$SoundManager/Trap.play()
	await get_tree().create_timer($SoundManager/Trap.stream.get_length()).timeout

	# base this on stats
	var bonus = 0
	match event['check']:
		'Health': bonus = $Player.health.max_value
		'Strength': bonus = $Player.stats.strength
		'Magic': bonus = $Player.stats.magic
	bonus = sqrt(bonus)
	var chance = randi() % 100
	var challenge = get_level(event['challenge'])
	var choice = ceili(pow(2 * challenge, 1.43))
	log_state('Trap', 'chance to trigger %d + %d < %d = %s' % [chance, bonus, choice, chance < choice])
	if chance + bonus < choice:
		match event['event']['type']:
			'Battle':
				logger.add_message('Caught by %s!' % $Enemy.character_name)
				await $Enemy.appear()
				$Player.in_combat = true
				$Player.take_turn()
				return
			'Damage':
				$Trap/Damage.modulate = Color.WHITE
				logger.add_message('%s triggered the trap!' % $Player.character_name)
				$Trap/Damage/Spike.play()
				await $Trap/Damage.attack(2)
				await get_tree().create_timer(0.25).timeout
				$Player.sounds.hit.play()
				await $Player.damaged(2 * challenge, null)
			'Curse':
				$Trap/Curse.modulate = Color.WHITE
				logger.add_message('%s triggered the trap!' % $Player.character_name)
				$Trap/Curse/Cursed.play()
				await $Trap/Curse.attack(2)
				await get_tree().create_timer(0.25).timeout
				await $Player.cursed(event['event']['curse'], challenge, null)
	else:
		match event['event']['type']:
			'Battle':
				logger.add_message('%s avoided the monster.' % $Player.character_name)
			_:
				logger.add_message('%s avoided the trap.' % $Player.character_name)
		$Player.sounds.miss.play()
		await $Player/Sprite.shake(2, 0.10, 15).finished
	#$Next.disabled = false
	#$Next.show()
	next_event()

func Puzzle(event):
	logger.add_message('An arcade!')
	$Arcade.reset()
	$Arcade.stage = $ResourceManager.stages[event['stage']]
	$Arcade.event = event['event']
	$Arcade.credits = 2
	$Arcade/HBoxContainer/Label.text = '%dx' % $Arcade.credits
	$Arcade/Start.hide()
	$Arcade.show()
	await $Arcade/Sprite2D.arrive()
	$Arcade/Start.show()

func solve_puzzle(event):
	logger.add_message('Beat the level!')
	$Arcade.hide()
	$Arcade.stage = null
	$Arcade.event = null
	$Arcade.credits = 0
	$Arcade/HBoxContainer/Label.text = '%dx' % $Arcade.credits
	Callable.create(self, event['type']).call(event)

func fail_puzzle():
	logger.add_message('Failed to beat the level!')
	$SoundManager/GameOver.play()
	await get_tree().create_timer($SoundManager/GameOver.stream.get_length()).timeout
	$Arcade.reset()
	$Arcade.hide()
	next_event()

func Travel(event):
	section = $ResourceManager/EventManager.sections[event['location']].duplicate()
	next_event()

func Dialogue(event):
	$NPC/NPC.texture = $ResourceManager.npcs[event['character']]
	$NPC.show()
	await $NPC/NPC.arrive()

	$Dialogue/Dialogue/Dialogue/Dialogue/Name.text = event['character']
	$Dialogue/Dialogue/Dialogue/Dialogue/Text.text = ''
	$Dialogue.show()
	await get_tree().create_timer(1.00).timeout

	for message in event['dialogue']:
		$Dialogue/Dialogue/Dialogue/Dialogue/Text.text = ''
		$NPC/NPC.hop(5, 0.1, 10)
		var tween = create_tween()
		tween.tween_property(
			$Dialogue/Dialogue/Dialogue/Dialogue/Text,
			'text',
			message,
			len(message) / 50.0
		)
		await tween.finished
		await get_tree().create_timer(1.00).timeout

	await $NPC/NPC.leave()
	$NPC.hide()
	$NPC/NPC.reset()
	$Dialogue.hide()
	next_event()

func Choice(event):
	for child in $Choice.get_children():
		$Choice.remove_child(child)
	for choice in event['choices']:
		var button: TextureButton = TextureButton.new()
		button.pressed.connect(choose_event.bind(choice))
		button.pressed.connect($Choice.hide)
		button.mouse_entered.connect($Description.show_description.bind(
			choice['type'],
			'Event',
			choice['effect'],
			null,
			choice['flavor'],
		))
		button.mouse_entered.connect($Description.show)
		button.mouse_exited.connect($Description.hide)
		button.texture_normal = choice['texture']
		$Choice.add_child(button)
	$Choice.show()

func choose_event(event):
	Callable.create(self, event['type']).call(event)

func Wait(_event):
	$Next.disabled = false
	$Next.show()

func Shrine(event):
	logger.add_message('%s found a shrine!' % $Player.character_name)

	$SoundManager/Shrine.play()
	match event['shrine_type']:
		'Heal':
			$Shrine/Heal.show()
			$Shrine/Blessing.hide()
		'Blessing':
			$Shrine/Heal.hide()
			$Shrine/Blessing.show()
	await get_tree().create_timer($SoundManager/Shrine.stream.get_length()).timeout

	match event['shrine_type']:
		'Heal':
			logger.add_message('%s is healed.' % $Player.character_name)
			$Player.act()
			$Player/BattleSounds/Heal.play()
			await $Player.health.adjust(event['power'])
			await $Player.update()
		'Blessing':
			logger.add_message('%s is blessed.' % $Player.character_name)
			$Player.act()
			await $Player.blessed(event['blessing'], event['power'], null)
	#$Next.disabled = false
	#$Next.show()

func Altar(event):
	logger.add_message('%s found an altar!' % $Player.character_name)

	$SoundManager/Shrine.play()
	logger.add_message('Sacrifice a gem?')
	$Altar/Skip.hide()
	$Altar.show()
	await $Altar/Altar.arrive()
	$Altar/Skip.show()
	$Inventory.enable_gem()
	next_item = 0

func sacrfice_gem(gem):
	$Inventory.remove_item(gem)
	$Inventory/Weapon._item['color'] = gem['color']

func Rest(event):
	logger.add_message('A moment to rest!')
	$Rest.show()
	for curse in $Player.curses.effects:
		$Player.curses.adjust(curse, -$Player.curses.effects[curse])
	$Player.update()
	await $Player.health.adjust(event['power'] * $Player.health.max_value / 100)
	await $Player.update()
	next_event()

	#$Next.disabled = false
	#$Next.show()

func Events(event):
	log_state('Events', 'adding %d events' % len(event['events']))
	section = event['events'] + section
	next_event()

func EventSection(event):
	log_state('EventSection', 'adding section %s' % event['location'])
	section = $ResourceManager/EventManager.sections[event['location']].duplicate() + section
	next_event()

func Pool(event):
	var pool = $ResourceManager/EventManager.pools[event['pool']]
	var choice = randi() % 100
	var chance = 0
	for e in pool:
		chance += e['chance']
		if choice < chance:
			log_state('Pool', 'chose event %s' % e['type'])
			Callable.create(self, e['type']).call(e)
			return
	var e = pool.pick_random()
	log_state('Pool', 'chose event %s' % e['type'])
	Callable.create(self, e['type']).call(e)

func Victory(event):
	logger.add_message('You win!')
	$GoldGem.show()
	$SoundManager/Victory.play()
	await get_tree().create_timer($SoundManager/Victory.stream.get_length()).timeout
	await get_tree().create_timer(0.4).timeout
	$GoldGem.hide()
	save_game(true)
	clear()
	$Start.show()
	if FileAccess.file_exists("user://savegame.save"):
		$Reset.show()
	else:
		$Reset.hide()

func win_battle():
	if 'Destiny Bond' in $Enemy.blessings.effects and $Enemy.blessings.effects['Destiny Bond'] > 0:
		logger.add_message('YOU ARE A FOOL!')
		$"Enemy/EnemySounds/Blessings/Destiny Bond".play()
		$Player.health.adjust($Player.health.value - 1)
		await get_tree().create_timer($"Enemy/EnemySounds/Blessings/Destiny Bond".stream.get_length()).timeout
		$Player/BattleSounds/GameOver.play()
		game_over()
	else:
		$Player.in_combat = false
		$Enemy.hide()
		LuckyItem(null)
		await $Player.gain_experience($Enemy.experience)
		await get_tree().create_timer(0.25).timeout
		next_event()

func end_battle():
	$Player.in_combat = false
	$Enemy.hide()
	await get_tree().create_timer(0.25).timeout
	next_event()

var next_item

func set_next_item(item):
	logger.add_message('Choose an %s to trash.' % item['type'])
	next_item = item

func trash_item(item):
	if next_item is int and next_item == 0: # this is a hack for the altar
		$Inventory.remove_item(item)
		next_item = null
		var weapon = $Inventory/Weapon._item
		# TODO: no clue what to do here
		# TODO: the sword gets stronger and changes color, but i'd like it to "transform"
		imbue_weapon(weapon, item)
		#weapon['action']['power'] += 1
		#weapon['color'] = item['color']
		#weapon['description'] = $ResourceManager/ItemManager.get_description(weapon)
		$Altar/BreakGem.play()
		logger.add_message('Sacrificed the %s.' % item['name'])
		await get_tree().create_timer(0.40).timeout
		next_event()
	elif next_item:
		# TODO: add something here
		await $Inventory.remove_item(item)
		$Inventory.add_item(next_item)
		next_item = null
		LuckyItem(null)

func imbue_weapon(weapon, gem):
	weapon['action']['power'] += 1
	weapon['color'] = gem['color']
	weapon['description'] = $ResourceManager/ItemManager.get_description(weapon)

func LuckyItem(event_):
	logger.add_message('Received a lucky item.')
	var item = $ResourceManager/ItemManager/LuckyItemManager.lucky_items.pick_random()
	$LuckyItems.add(item)
	$LuckyItems/AudioStreamPlayer2D.play()
	$Player.gain_affinity(item['color'])
	if event_:
		next_event()

func game_over() -> void:
	section = []
	for child in $LuckyItems/GridContainer.get_children():
		$LuckyItems/GridContainer.remove_child(child)
	clear()
	$Start.show()
	if FileAccess.file_exists("user://savegame.save"):
		$Reset.show()
	else:
		$Reset.hide()

func next_event2(_obj) -> void:
	next_event()

func Save(event):
	logger.add_message('Saving the game...')
	save_game(false)
	$SoundManager/Save.play()
	await get_tree().create_timer(0.75).timeout
	next_event()

func save_game(beat_game):
	var player_dict = $Player.to_dict()
	player_dict['items'] = []
	if $Inventory/Weapon._item:
		player_dict['items'].append(
			{ 'type': 'literal',
			'literal': $Inventory/Weapon._item
		})
	if $Inventory/Gems/Gem1._item:
		player_dict['items'].append({
			'type': 'literal',
			'literal': $Inventory/Gems/Gem1._item
		})
	if $Inventory/Gems/Gem2._item:
		player_dict['items'].append({
			'type': 'literal',
			'literal': $Inventory/Gems/Gem2._item
		})
	if $Inventory/Gems/Gem3._item:
		player_dict['items'].append({
			'type': 'literal',
			'literal': $Inventory/Gems/Gem3._item
		})
	if $Inventory/Drinks/Drink1._item:
		for i in range(int($Inventory/Drinks/Drink1.get_child(0).text)):
			player_dict['items'].append({
				'type': 'name',
				'name': $Inventory/Drinks/Drink1._item['name']
			})
	if $Inventory/Drinks/Drink2._item:
		for i in range(int($Inventory/Drinks/Drink2.get_child(0).text)):
			player_dict['items'].append({
				'type': 'name',
				'name': $Inventory/Drinks/Drink2._item['name']
			})
	if $Inventory/Drinks/Drink3._item:
		for i in range(int($Inventory/Drinks/Drink3.get_child(0).text)):
			player_dict['items'].append({
				'type': 'name',
				'name': $Inventory/Drinks/Drink3._item['name']
			})
	if $Inventory/Drinks/Drink4._item:
		for i in range(int($Inventory/Drinks/Drink4.get_child(0).text)):
			player_dict['items'].append({
				'type': 'name',
				'name': $Inventory/Drinks/Drink4._item['name']
			})
	if $Inventory/Drinks/Drink5._item:
		for i in range(int($Inventory/Drinks/Drink5.get_child(0).text)):
			player_dict['items'].append({
				'type': 'name',
				'name': $Inventory/Drinks/Drink5._item['name']
			})
	if $Inventory/Drinks/Drink6._item:
		for i in range(int($Inventory/Drinks/Drink6.get_child(0).text)):
			player_dict['items'].append({
				'type': 'name',
				'name': $Inventory/Drinks/Drink6._item['name']
			})
	if $Inventory/Drinks/Drink7._item:
		for i in range(int($Inventory/Drinks/Drink7.get_child(0).text)):
			player_dict['items'].append({
				'type': 'name',
				'name': $Inventory/Drinks/Drink7._item['name']
			})
	if $Inventory/Drinks/Drink8._item:
		for i in range(int($Inventory/Drinks/Drink8.get_child(0).text)):
			player_dict['items'].append({
				'type': 'name',
				'name': $Inventory/Drinks/Drink8._item['name']
			})
	if $Inventory/Drinks/Drink9._item:
		for i in range(int($Inventory/Drinks/Drink9.get_child(0).text)):
			player_dict['items'].append({
				'type': 'name',
				'name': $Inventory/Drinks/Drink9._item['name']
			})
	if $Inventory/Drinks/Drink10._item:
		for i in range(int($Inventory/Drinks/Drink10.get_child(0).text)):
			player_dict['items'].append({
				'type': 'name',
				'name': $Inventory/Drinks/Drink10._item['name']
			})
	if $Inventory/Food._item:
		player_dict['items'].append({
			'type': 'name',
			'name': $Inventory/Food._item
		})
	if beat_game:
		player_dict['beat_game'] = beat_game
	else:
		player_dict['event'] = section

	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var json_string = JSON.stringify(player_dict)
	save_file.store_line(json_string)

func get_level(level):
	match level:
		'dynamic':
			level = max($Player.level(), 1)
			return max(1, floori((75 * level + randi() % ceili(25 * level)) / 100))
		_: return level

func lose_puzzle():
	$Player/Sprite.damaged(1)
	await $Player/Sprite.shake(3, 0.04, 12)
	if $Arcade.credits > 0:
		$Arcade.credits -= 1
		var stage = $Arcade.stage
		var event = $Arcade.event
		$Arcade.stage = null
		$Arcade.event = null

		$Arcade.reset()
		$Arcade.stage = stage
		$Arcade.event = event
		$Arcade.start()
		$Arcade/HBoxContainer/Label.text = '%dx' % $Arcade.credits
	else:
		$Arcade.stage = null
		$Arcade.event = null
		fail_puzzle()
