extends "res://core/character.gd"

var level
var experience

var power
var accuracy

var logic_

signal give_experience(experience)

func _ready():
	sprite = $EnemyUI/Sprite
	health_bar = $EnemyUI/Description/Info/Background/Info/HealthBar/VerticalDivider/Middle/Bar
	status_bar = $EnemyUI/Description/Status/Divider/Status
	buff_bar = $EnemyUI/Description/Status/Divider/Buffs

func log_state(method, message):
	print("(%s)[enemy.gd][%s]<%s> %s" % [Time.get_datetime_string_from_system(), method, character_name, message])

func set_enemy(enemy, level_: int):
	character_name = enemy['name']
	$EnemyUI/Description/Info/Background/Info/Info/Name/Label.text = character_name
	
	level = level_
	experience = enemy['experience'] * level

	$EnemyUI/Description/Info/Background/Info/Info/Level/Label.text = 'Level %3d' % level

	max_health = int(2 * level * enemy['health'] / 10) + level + 2
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	status = {}
	
	power = enemy['power']
	accuracy = enemy['accuracy']
	if 'resistances' in enemy:
		resistances = enemy['resistances']
	
	sprite.texture = enemy['sprite']
	sprite.reset()

	$SoundEffects/BattleCry.stream = enemy['battle_cry']

	for status_icon in status_bar.get_children():
		status_icon.hide()
	for buff_icon in buff_bar.get_children():
		buff_icon.hide()
	
	logic_ = enemy['logic']

#func attack(power, accuracy):
func attack():
	log_state('attack', 'attacking with %s')
	log_message.emit('%s attacks' % character_name)
	var chance = randi() % 100
	log_state('attack', 'chance to hit %d < %d' % [chance, accuracy])
	if chance < accuracy:
		var damage = power * level
		log_state('attack', 'attacking for %d' % damage)
		$SoundEffects/Attack.playing = true
		await sprite.attack(1)
		deal_damage.emit('normal', damage)
	else:
		await get_tree().create_timer(0.33).timeout
		$SoundEffects/Miss.playing = true
		log_message.emit('%s missed' % character_name)
		await get_tree().create_timer($SoundEffects/Miss.stream.get_length() + 0.5).timeout
		pass_turn.emit()

func loaf():
	log_state("loaf", "zzzz")
	log_message.emit('%s is loafing.' % character_name)
	$SoundEffects/Loaf.playing = true
	await sprite.snooze()

	pass_turn.emit()

func yawn():
	log_state("yawn", "nap time :)")
	log_message.emit('%s yawns' % character_name)
	$SoundEffects/Loaf.playing = true
	await sprite.snooze()
	var chance = randi() % 100
	log_state('yawn', 'chance to hit %d < %d' % [chance, accuracy])
	if chance < accuracy:
		var stacks = power
		log_state('yawn', 'applying %d stacks of sleep' % stacks)
		apply_status.emit('sleep', 'sleep', stacks)
	else:
		await get_tree().create_timer(0.33).timeout
		$SoundEffects/Miss.playing = true
		log_message.emit('%s missed' % character_name)
		await get_tree().create_timer($SoundEffects/Miss.stream.get_length() + 0.5).timeout
		pass_turn.emit()

func sing():
	log_state("sing", "nap time :)")
	log_message.emit('%s sings' % character_name)
	$SoundEffects/Sing.playing = true
	await sprite.snooze()
	var chance = randi() % 100
	log_state('sing', 'chance to hit %d < %d' % [chance, int(1.5 * accuracy)])
	if chance < 1.5 * accuracy:
		var stacks = power * level
		log_state('sing', 'applying %d stacks of sleep' % stacks)
		apply_status.emit('sleep', 'sleep', stacks)
	else:
		await get_tree().create_timer(0.33).timeout
		$SoundEffects/Miss.playing = true
		log_message.emit('%s missed' % character_name)
		await get_tree().create_timer($SoundEffects/Miss.stream.get_length() + 0.5).timeout
		pass_turn.emit()

func poison_gas():
	log_state('poison_gas', 'poison_gasing with %s')
	log_message.emit('%s uses Poison Gas' % character_name)
	var chance = randi() % 100
	$SoundEffects/Poison.playing = true
	await sprite.attack(1)
	await get_tree().create_timer($SoundEffects/Poison.stream.get_length() / 2).timeout
	log_state('poison_gas', 'chance to hit %d < %d' % [chance, accuracy])
	if chance < accuracy:
		var stacks = int(sqrt(power * level))
		log_state('poison_gas', 'apply for %d' % stacks)
		#$SoundEffects/Attack.playing = true
		apply_status.emit('purple', 'poison', stacks)
	else:
		await get_tree().create_timer(0.33).timeout
		$SoundEffects/Miss.playing = true
		log_message.emit('%s missed' % character_name)
		await get_tree().create_timer($SoundEffects/Miss.stream.get_length() + 0.5).timeout
		pass_turn.emit()

func psycho_boost():
	log_state('psycho_boost', 'psycho_boosting with %s')
	log_message.emit('%s uses Psycho Boost' % character_name)
	var chance = randi() % 100
	log_state('psycho_boost', 'chance to hit %d < %d' % [chance, accuracy])
	if chance < accuracy:
		var damage = 5 * power * level
		log_state('psycho_boost', 'attacking for %d' % damage)
		$SoundEffects/PsychoBoost.playing = true
		await sprite.attack(2)
		await get_tree().create_timer($SoundEffects/PsychoBoost.stream.get_length() / 2).timeout
		$SoundEffects/Attack.playing = true
		deal_damage.emit('psychic', damage)
	else:
		await get_tree().create_timer(0.33).timeout
		$SoundEffects/Miss.playing = true
		log_message.emit('%s missed' % character_name)
		await get_tree().create_timer($SoundEffects/Miss.stream.get_length() + 0.5).timeout
		pass_turn.emit()

#func spit(value):
	#log_state("spit", "yucky :(")
	#log_message.emit('%s spits poison.' % character_name)
	#$SoundEffects/Poison.playing = true
	#await $Sprite.attack(1)
#
	#await status_action('poison', 1)

func logic():
	var total_chance = 0
	for action in logic_:
		total_chance += logic_[action]
		var chance = randi() % 100
		if chance < total_chance:
			Callable(self, action).call()
			break

func death():
	$SoundEffects/BattleCry.playing = true
	await get_tree().create_timer($SoundEffects/BattleCry.stream.get_length() / 2).timeout
	give_experience.emit(experience)
