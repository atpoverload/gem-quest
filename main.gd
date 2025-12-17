extends Node2D

signal log_message(message: String)

var event_sprites;
var answer = 0;
var puzzle_event;

func _ready() -> void:
	event_sprites = {
		'damage': $Events/SpikePit,
		'status': $Events/PoisonDart,
		'battle': $Events/Battle,
		'buff': $Events/Altar,
	}
	log_state('[_ready]', 'starting new game runtime')
	start_menu()

func log_state(method, message):
	print("(%s)[main.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func hide_menus():
	$Start.hide()
	$Enemy.hide()
	$Events/Rest.hide()
	$Events/Battle.hide()
	$Events/SpikePit.hide()
	$Events/PoisonDart.hide()
	$Events/Altar.hide()
	$Events/Puzzle.hide()
	$Reward.hide()
	$Puzzle.hide()
	$Inventory.show()
	$Inventory.disable()

func start_menu() -> void:
	log_state('start_menu', 'going to the main menu')
	hide_menus()
	$Description.hide()	
	$Inventory.hide()
	$Player.hide()

	$Inventory.clear()

	$Start.show()
	log_message.emit('💎 Gem Quest 💎')

func new_game(scenario) -> void:
	log_state('new_game', 'starting a new \'%s\' scenario' % scenario)
	log_message.emit('Entering the %s' % scenario)
	hide_menus()

	# load the scenario
	$ScenarioManager.load_scenario('res://scenarios/%s.json' % scenario)
	$ItemManager.drop_tables = $ScenarioManager.drop_tables

	# create a new player
	await $Player.set_player($ScenarioManager.starting_character(), $ScenarioManager.starting_level())

	# show the starting scene
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
		await $Inventory.add_item(item, true)
		await get_tree().create_timer(0.10).timeout
	await get_tree().create_timer(0.10).timeout

	next_event()

func next_event():
	hide_menus()
	if not $ScenarioManager.has_events():
		#win_the_game()
		return

	var event = $ScenarioManager.next_event()
	process_event(event)

func process_event(event):
	log_state('next_event', 'starting next %s event' % event['type'])
	match event['type']:
		'damage':
			damage(event)
		'status':
			status(event)
		'buff':
			buff(event)
		'battle':
			battle(event)
		'treasure':
			treasure(event)
		'trap':
			trap(event)
		'puzzle':
			puzzle(event)
		'rest':
			rest(event)
		'pause':
			pause()
		'victory':
			victory()

func damage(event):
	$Events/SpikePit.show()
	log_message.emit('Found a spike pit!')
	await get_tree().create_timer(0.35).timeout
	$Player/SoundEffects/Damage.playing = true
	await $Player.damaged('normal', int(event['amount']))
	await get_tree().create_timer(0.5).timeout
	$NextEvent.show()

func status(event):
	$Events/PoisonDart.show()
	log_message.emit('Found a %s trap!' % event['effect'])
	await get_tree().create_timer(0.35).timeout
	if event['effect'] not in $Player.status:
		$Player.status[event['effect']] = 0
	$Player.set_status(event['effect'], $Player.status[event['effect']] + int(event['amount']))
	$Player.sounds[event['effect']].playing = true
	await get_tree().create_timer(0.5).timeout
	$NextEvent.show()

func buff(event):
	$Events/Altar.show()
	$Events/Altar.arrive()
	log_message.emit('Found an altar of %s!' % event['buff'])
	await get_tree().create_timer(0.35).timeout
	if event['buff'] not in $Player.buffs:
		$Player.buffs[event['buff']] = 0
	$Player.set_buff(event['buff'], $Player.status[event['buff']] + int(event['amount']))
	$Player.sounds[event['buff']].playing = true
	await get_tree().create_timer(0.5).timeout
	$NextEvent.show()

func battle(event):
	$SoundManager/Battle.playing = true
	await get_tree().create_timer(0.4).timeout

	$Enemy.set_enemy($EnemyManager.get_enemy(event['enemy']), event['level'])
	$Enemy.show()
	$Enemy/SoundEffects/BattleCry.playing = true
	log_message.emit('%s arrived' % $Enemy.character_name)
	await $Enemy.sprite.arrive()
	await get_tree().create_timer(0.4).timeout

	$Player.take_turn()

func treasure(event):
	log_message.emit('Found some %s' % event['reward'].split('_')[-1])

	$Reward.clear_rewards()
	$Reward/Skip.hide()
	$Reward.show()
	await $Reward/Sprite2D.arrive()
	await $Reward/Sprite2D.hop2(1, 0.05, 50)
	$SoundManager/Treasure.playing = true
	await get_tree().create_timer($SoundManager/Treasure.stream.get_length() / 8).timeout
	var rewards = $ItemManager.get_rewards(event)
	for reward in rewards:
		reward = $ItemManager.get_item(reward)
		$Reward.add_reward(reward)
	$Reward/Skip.show()

# TODO: this is terrible
func sell_rewards():
	$Reward.clear_rewards()
	$Player.add_emote($ItemManager.items[$ItemManager.lucky.pick_random()])
	#var reward = 0
	# TODO: find a formula to compute a price
	#for child in $Reward/Rewards/Rewards.get_children():
		#reward += 100 * child.get_child(1)._item['rarity']
	#reward /= len($Reward/Rewards/Rewards.get_children())
	#await $Player.gain_experience(reward)

	#next_event()

func trap(event):
	log_message.emit('Found a trap')
	event_sprites[event['event']['type']].show()
	event_sprites[event['event']['type']].arrive()
	$SoundManager/Battle.playing = true
	await get_tree().create_timer(0.75).timeout
	for check in event['checks']:
		var chance = randi() % int(check['danger']) + $Player.affinities[check['stat']]
		log_state('trap', 'chance to trigger %d < %d = %s' % [chance, check['danger'], chance < check['danger']])
		if chance < check['danger']:
			$SoundManager/Trap.playing = true
			log_message.emit('Failed a %s check!' % check['stat'])
			await get_tree().create_timer(0.75).timeout
			event_sprites[event['event']['type']].hide()
			process_event(event['event'])
			return
		else:
			log_message.emit('Passed a %s check!' % check['stat'])
			$SoundManager/Puzzle.playing = true
			await get_tree().create_timer(1.50).timeout
	$Player/SoundEffects/Miss.playing = true
	$Player/Sprite.shake2(3, 0.10, 15)
	log_message.emit('Evaded the trap')
	await get_tree().create_timer(0.5).timeout
	$NextEvent.show()

# TODO: create mini games for this?
# TODO: janken? :eyes:
func puzzle(event):
	log_message.emit('Found a puzzle')
	#$Events/Puzzle.show()
	#$Events/Puzzle.arrive()
	var challenge = int(event['challenge'])
	var first = randi() % challenge + 1
	var second = randi() % challenge + 1
	answer = first + second
	puzzle_event = event['event']
	$Puzzle/MarginContainer/Background/Background2/VBoxContainer/Question.text = '%d + %d = ?' % [first, second]
	$Puzzle/MarginContainer/Background/Background2/VBoxContainer/Answer.text = ''
	$Puzzle.show()
	$SoundManager/Puzzle.playing = true
	await get_tree().create_timer(0.75).timeout

func solve_puzzle(code):
	log_state('solve_puzzle', 'attempting to solve puzzle with %d, answer is %d' % [code, answer])
	if code == answer:
		$SoundManager/Trap.playing = true
		log_message.emit('Solved the puzzle!')
		await get_tree().create_timer(0.75).timeout
		$Puzzle.hide()
		process_event(puzzle_event)
	else:
		$SoundManager/PuzzleFail.playing = true
		$Player/Sprite.damaged(2)
		var tween = create_tween()
		tween.tween_property($Puzzle, 'position', position - Vector2(25, 0), 0.05)
		tween.tween_property($Puzzle, 'position', position + Vector2(25, 0), 0.1)
		tween.tween_property($Puzzle, 'position', position, 0.05)
		await tween.finished
		log_message.emit('Failed the puzzle...')
		await get_tree().create_timer(0.5).timeout
		$Puzzle.hide()
		$NextEvent.show()
	puzzle_event = null

func rest(event):
	log_message.emit('Found a rest spot')
	$Events/Rest.show()
	$SoundManager/Rest.playing = true
	for effect in $Player.status:
		await $Player.set_status(effect, 0)
	for buff_ in $Player.buffs:
		await $Player.set_buff(buff_, 0)
	var restored = event['safety'] * $Player.rest_health()
	await $Player.set_health($Player.health + restored)
	await get_tree().create_timer(0.5).timeout
	$NextEvent.show()

# TODO: choose between N events
func choice(event):
	log_message.emit('What to do?')
	# TODO: open a menu that has like arrows for two doors

func pause():
	log_state('pause', 'pausing?')
	$NextEvent.show()

func victory():
	hide_menus()
	log_message.emit('%s found the Gold Gem!' % $Player.character_name)
	$Victory.show()
	$SoundManager/Victory.playing = true
