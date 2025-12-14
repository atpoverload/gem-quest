extends "res://core/character.gd"

var level = 0
var experience = 0

var attack_power = 0
var magic_power = 0

var emotes = []
var crit_chance = 6
var luck = 0
var revives = 0
var accuracy = 1
var gem_break = 1
var gem_power = 1
var evasion = 1

var on_attack = {}
var freebies = {
	'drink': 0,
	'food': 0,
}
var gem_break_chance = 25;

var health_growth = 0
var affinities = {}

var attack_label
var magic_label
var experience_bar

signal start_turn
signal break_gem
signal eat
signal freebie
signal next_event
signal game_over

func _ready():
	sprite = $Sprite
	health_bar = $Info/Info/Info/HealthBar/VerticalDivider/Middle/Bar
	health_label = $Info/Info/Info/Health/Label
	status_bar = $Effects/Effects/Effects/Status
	buff_bar = $Effects/Effects/Effects/Buffs
	experience_bar = $Info/Info/Info/ExperienceBar/VerticalDivider/Middle/Bar
	attack_label = $Info/Info/Info/Power/Stats/Attack
	magic_label = $Info/Info/Info/Power/Stats/Magic
	sounds = {}
	for sound in $SoundEffects.get_children():
		sounds[sound.name] = sound

func log_state(method, message):
	print("(%s)[player.gd][%s]<%s> %s" % [Time.get_datetime_string_from_system(), method, character_name, message])

func set_player(player, level_):
	log_state('new_player', 'creating new player %s - health=%d level=%d' % [player['name'], player['health'], level_])

	character_name = player['name']
	$Info/Info/Info/Name/Label.text = character_name

	level = 0
	experience = 0

	attack_power = 0
	magic_power = 0

	emotes = []
	for child in $Emotes/Emotes.get_children():
		$Emotes/Emotes.remove_child(child)

	crit_chance = 6
	luck = 0

	affinities = {}

	health_growth = int(2 * player['health'] / 10)
	max_health = player['health']
	health = max_health
	await gain_levels(level_)

	status = {}

	for status_icon in status_bar.get_children():
		status_icon.hide()
	for buff_icon in buff_bar.get_children():
		buff_icon.hide()
	
	sprite.reset()

	attack_label.text = '%2d Attack' % attack_power
	magic_label.text = '%2d Magic' % magic_power

# character management
func rest_health():
	return int(max_health / 8)

func set_experience(value):
	log_state('set_experience', 'changing experience from %d to %d' % [experience, value])
	experience = value
	var bar = experience_bar
	var tween = bar.create_tween()
	tween.tween_property(bar, "value", experience, 0.75 * abs(bar.value - experience) / bar.max_value)
	await tween.finished

func gain_levels(levels):
	log_state('gain_levels', 'gaining %d levels' % levels)
	level += levels
	# doing this to adjust the health gracefully
	var old_max_health = max_health
	var extra_health = health_growth * levels
	var adjustment = 0
	for l in range(levels):
		adjustment += 6 - int(sqrt(randi() % 36))
	log_state('gain_levels', 'gaining a bonus %d + %d HP' % [extra_health, adjustment])
	max_health += int(extra_health + adjustment)
	health_bar.max_value = max_health

	adjustment = 0
	for l in range(levels):
		adjustment += 6 - int(sqrt(randi() % 36))
	log_state('gain_levels', 'gaining a bonus %d attack' % adjustment)
	attack_power += adjustment

	adjustment = 0
	for l in range(levels):
		adjustment += 6 - int(sqrt(randi() % 36))
	log_state('gain_levels', 'gaining a bonus %d magic' % adjustment)
	magic_power += adjustment

	attack_label.text = '%3d Attack' % attack_power
	magic_label.text = '%3d Magic' % magic_power

	if visible:
		var tween = sprite.hop2(2, 0.08, 20)
		if old_max_health > 0:
			var temp_health = int((1 - float(old_max_health - health) / old_max_health) * max_health)
			health_bar.value = temp_health
			await set_health(temp_health + rest_health())
		else:
			health_bar.value = max_health
			await set_health(max_health)
		await tween.finished
	else:
		if old_max_health > 0:
			var temp_health = int((1 - float(old_max_health - health) / old_max_health) * max_health)
			health_bar.value = temp_health + rest_health()
			set_health(temp_health)
		else:
			health_bar.value = max_health
			set_health(max_health)

func gain_level():
	log_state('gain_level', 'gaining one level')
	gain_levels(1)

func gain_experience(xp_):
	var xp = xp_ / level;
	log_state('gain_experience', 'player: %s, base experience: %d, adjusted experience: %d' % [character_name, xp_, xp])
	log_message.emit('%s gains experience' % character_name)

	while xp > 0:
		var next_level = experience_bar.max_value
		$SoundEffects/GainExperience.playing = true
		var e = min(next_level, experience + xp)
		await set_experience(e)
		xp = max(0, xp - next_level)

		while experience >= next_level:
			log_state('gain_experience', '%s level up to %s' % [character_name, level])
			log_message.emit('%s gains a level' % character_name)

			await gain_level()
			experience -= next_level
			experience_bar.value = 0
			$SoundEffects/GainLevel.playing = true
			await get_tree().create_timer($SoundEffects/GainLevel.stream.get_length() - 0.25).timeout

func grant_experience(xp):
	await gain_experience(xp)
	next_event.emit()

func add_emote(emote):
	log_state('add_emote', 'emote: %s' % emote['name'])
	emotes.append(emote['name'])
	var row = null
	if $Emotes/Emotes.get_child_count() == 0:
		row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		$Emotes/Emotes.add_child(row)
	else:
		row = $Emotes/Emotes.get_child(0)
		if row.get_child_count() == 5:
			row = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_END
			$Emotes/Emotes.add_child(row)
			$Emotes/Emotes.move_child(row, 0)
	var emote_button = $Emotes/Emote.duplicate()
	emote_button.get_child(1).set_item(emote)
	row.add_child(emote_button)
	row.move_child(emote_button, 0)
	emote_button.show()

	# static boosts
	if 'stat' in emote['effect']:
		match emote['effect']['stat']:
			'luck': luck += emote['effect']['amount']
			'revives': revives += emote['effect']['amount']
			'accuracy': accuracy *= 1 + emote['effect']['amount']
			'gem_break': gem_break *= 1 + emote['effect']['amount']
			'gem_power': gem_power *= 1 + emote['effect']['amount']
			'evasion': evasion *= 1 + emote['effect']['amount']
	elif 'attack' in emote['effect']:
		if emote['effect']['attack'] not in on_attack:
			on_attack[emote['effect']['attack']] = emote['effect']['chance']
		else:
			on_attack[emote['effect']['attack']] *= 1 + emote['effect']['chance'] / 100.0
		log_state('add_emote', 'increased %s to %d' % [emote['effect']['attack'], on_attack[emote['effect']['attack']]])
	elif 'resistance' in emote['effect']:
		if emote['effect']['resistance'] not in resistances:
			resistances[emote['effect']['resistance']] = emote['effect']['amount']
		else:
			resistances[emote['effect']['resistance']] *= emote['effect']['amount']
		log_state('add_emote', 'adjusted %s to %d' % [emote['effect']['resistance'], resistances[emote['effect']['resistance']]])
	elif 'freebie' in emote['effect']:
		if emote['effect']['freebie'] not in freebies or freebies[emote['effect']['freebie']] == 0:
			freebies[emote['effect']['freebie']] = emote['effect']['chance']
		else:
			freebies[emote['effect']['freebie']] *= 1 + emote['effect']['chance']
		log_state('add_emote', 'adjusted %s to %d' % [emote['effect']['freebie'], freebies[emote['effect']['freebie']]])
	next_event.emit()

func check_break_gem(color):
	log_state('break_gem', 'breaking %s gem' % color)
	for child in $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Gems.get_children():
		var item_button = child.get_child(1)
		if not item_button.is_empty() and item_button._item['color'] == color:
			log_state('break_gem', 'broke %s gem' % color)
			item_button.remove_item()
			return
	log_state('break_gem', 'not holding %s gem' % color)

# actions
func act():
	await sprite.hop2(2, 0.10, 25)

func accuracy_check(accuracy_):
	log_state('accuracy_check', 'base chance to hit %d' % accuracy_)

	# accuracy modifiers
	accuracy_ *= accuracy

	var chance = randi() % 100
	log_state('accuracy_check', 'chance to hit %d < %d = %s' % [chance, accuracy_, chance < accuracy_])
	return chance < accuracy_

func critical_hit(damage):
	var crit = randi() % 100
	log_state('critical_hit', 'crit chance %d < %d' % [crit, crit_chance])
	if crit < crit_chance:
		var base_damage = damage
		damage *= 2
		log_state('critical_hit', 'damage boosted %d * 2 = %d' % [base_damage, damage])
		log_message.emit('It\'s a critical hit!')
	return damage

func get_weapon_damage(element, damage):
	# damage modifiers
	#var base_damage = int(attack_power * Slay(damage))
	var base_damage = int(attack_power * damage)
	
	var lower_bound = min(max(5 * base_damage, 50), 85)
	var upper_bound = 100 - lower_bound
	var damage_roll = (randi() % upper_bound + lower_bound) / 100.0
	var calc = (base_damage / 3.0 + 2)
	damage =  round(calc * damage_roll)
	log_state('get_weapon_damage', 'damage roll %d * %f = %d' % [calc, damage_roll, damage])

	# boost
	if 'boost' in buffs:
		damage *= (1 + 0.25 * buffs['boost'])
	# crit
	damage = critical_hit(damage)

	return int(damage)

func get_gem_damage(element, damage):
	# damage modifiers
	var base_damage = int(magic_power * damage)

	var lower_bound = min(max(5 * base_damage, 50), 85)
	var upper_bound = 100 - lower_bound
	var damage_roll = (randi() % upper_bound + lower_bound) / 100.0
	var calc = (base_damage / 3.0 + 2)
	damage =  round(calc * damage_roll)
	log_state('get_gem_damage', 'damage roll %d * %f = %d' % [calc, damage_roll, damage])

	# boost
	if 'boost' in buffs:
		damage *= (1 + 0.25 * buffs['boost'])
	# crit
	damage = critical_hit(damage)

	return damage

func get_stacks(element, effect, stacks):
	return stacks + 1

func sum(accum, number):
	return accum + number

func logic():
	# TODO: make this trigger off status correctly, but we don't know the food's effect here
	if health < max_health / 3.0:
		await get_tree().create_timer(0.5).timeout
		eat.emit()
		await get_tree().create_timer(1.0).timeout
	start_turn.emit()
	log_message.emit('What will %s do?' % character_name)

func miss():
	await get_tree().create_timer(0.33).timeout
	$SoundEffects/Miss.playing = true
	log_message.emit('%s missed' % character_name)
	await get_tree().create_timer($SoundEffects/Miss.stream.get_length() + 0.5).timeout

func death():
	if revives > 0:
		log_state('death', 'used one of %d revives' % revives)
		revives -= 1
		log_message.emit('%s evades death' % character_name)
		await reset()
	else:
		log_state('death', 'game over :(')
		log_message.emit('%s died' % character_name)
		sprite.die()
		await get_tree().create_timer(0.25).timeout
		log_message.emit('Game Over!')
		$SoundEffects/GameOver.playing = true
		await get_tree().create_timer($SoundEffects/GameOver.stream.get_length() * 3 / 4).timeout
		game_over.emit()

func use_weapon(weapon) -> void:
	log_state('use_weapon', 'attacking with %s' % weapon['name'])
	log_message.emit('%s attacks' % character_name)
	await act()

	if accuracy_check(weapon.get('accuracy', 100)):
		var element = weapon.get('element', 'normal')
		var damage = get_weapon_damage(element, weapon['power'])
		log_state('weapon_attack', 'attacking with %s for %d %s damage' % [weapon['name'], damage, element])
		$SoundEffects/Action.stream = weapon['sound']
		$SoundEffects/Action.playing = true
		deal_damage.emit(element, damage)
		await get_tree().create_timer(1.4).timeout
		for effect in on_attack:
			log_state('use_weapon', 'base chance to trigger %s %d' % [effect, on_attack[effect]])
			var chance = randi() % 100
			log_state('use_weapon', 'chance to trigger %d < %d = %s' % [chance, on_attack[effect], chance < on_attack[effect]])
			if chance < on_attack[effect]:
				match effect:
					'repeat':
						log_message.emit('%s attacks again' % character_name)
						await act()
						if accuracy_check(weapon.get('accuracy', 100)):
							damage = get_weapon_damage(element, weapon['power']) / 2
							log_state('weapon_attack', 'attacking with %s for %d %s damage' % [weapon['name'], damage, element])
							$SoundEffects/Action.stream = weapon['sound']
							$SoundEffects/Action.playing = true
							deal_damage.emit(element, damage)
							await get_tree().create_timer(1.4).timeout
						else:
							await miss()
					'boost':
						await gain_buff('boost', 1)
					'flinch':
						apply_status.emit(element, 'flinch', 1)
					'banish':
						apply_status.emit(element, 'banish', 1)
	else:
		await miss()

	await get_tree().create_timer(0.5).timeout
	pass_turn.emit()

func use_gem(gem) -> void:
	# disable()
	log_state('use_gem', 'using the %s' % gem['name'])
	log_message.emit('%s uses the' % character_name)
	await get_tree().create_timer(0.25).timeout
	log_message.emit('%s' % gem['name'])
	$SoundEffects/UseGem.playing = true
	await act()
	await get_tree().create_timer($SoundEffects/UseGem.stream.get_length() / 2).timeout

	if accuracy_check(gem.get('accuracy', 100)):
		$SoundEffects/Action.stream = gem['sound']
		$SoundEffects/Action.playing = true
		var element = gem.get('element', 'normal')
		# TODO: this is a fake switch and it's bad
		if 'power' in gem:
			var damage = get_gem_damage(element, gem['power'])
			log_state('use_gem', 'attacking with %s for %d %s damage' % [gem['name'], damage, element])
			deal_damage.emit(element, damage)
			await get_tree().create_timer(1.4).timeout
		elif 'status' in gem:
			var effect = gem['status']
			var stacks = gem.get('stacks', 0)
			stacks = get_stacks(element, effect, stacks)
			log_state('use_gem', 'applying %d stacks of %s with %s' % [stacks, effect, gem['name']])
			apply_status.emit(element, effect, stacks)
			await get_tree().create_timer(1).timeout
		elif 'buff' in gem:
			var buff = gem['buff']
			var stacks = gem.get('stacks', 0)
			stacks = get_stacks(element, buff, stacks)
			log_state('use_gem', 'gain %s' % gem['buff'])
			await gain_buff(buff, stacks)
			await get_tree().create_timer($SoundEffects/Action.stream.get_length() / 4).timeout
		else:
			log_message.emit('It did nothing?')
			await get_tree().create_timer(1).timeout
	else:
		await miss()

	await get_tree().create_timer(0.5).timeout

	log_state('use_gem', 'base chance to break %d' % gem_break)
	var chance = randi() % 100
	var break_chance = gem_break_chance * gem_break
	log_state('use_gem', 'chance to break %d < %d = %s' % [chance, break_chance, chance < break_chance])
	# TODO: Think about other ways to do this.
	if chance < break_chance:
		break_gem.emit(gem)
		log_message.emit('%s broke!' % gem['name'])
		$SoundEffects/GemBreak.playing = true
		await get_tree().create_timer($SoundEffects/GemBreak.stream.get_length() / 2).timeout
		gem_break_chance = 25
	else:
		gem_break_chance += 1

	pass_turn.emit()

func use_drink(drink) -> void:
	# disable()
	log_state('use_drink', 'using %s' % drink['name'])
	$SoundEffects/Action.stream = drink['sound']
	$SoundEffects/Action.playing = true
	if drink['name'][0] in 'AEIOUaeiou':
		log_message.emit('Drank an %s' % drink['name'])
	else:
		log_message.emit('Drank a %s' % drink['name'])
	await act()

	if 'power' in drink:
		log_state('use_consumable', 'restoring %s health' % drink['power'])
		set_health(health + drink['power'])
	if 'status' in drink:
		if 'status' == 'all':
			log_state('use_consumable', 'removing all status effects')
			for effect in status:
				log_state('use_consumable', 'removing status effect %s' % effect)
				set_status(effect, 0)
		else:
			log_state('use_consumable', 'removing status effect %s' % drink['status'])
			set_status(drink['status'], 0)

	if freebies['drink'] > 0:
		log_state('use_drink', 'base chance to freebie %d' % freebies['drink'])
		var chance = randi() % 100
		log_state('use_drink', 'chance to freebie %d < %d = %s' % [chance, freebies['drink'], chance < freebies['drink']])
		if chance < freebies['drink']:
			await get_tree().create_timer(0.75).timeout
			freebie.emit(drink)
			log_message.emit('Light got a freebie!')
			await get_tree().create_timer($SoundEffects/ConsumableAcquire.stream.get_length() / 2).timeout

	await get_tree().create_timer($SoundEffects/Action.stream.get_length()).timeout
	pass_turn.emit()

func use_food(food) -> void:
	# disable()
	log_state('use_food', 'using %s' % food['name'])
	$SoundEffects/Action.stream = food['sound']
	$SoundEffects/Action.playing = true

	if food['name'][0] in 'AEIOUaeiou':
		log_message.emit('Ate an %s' % food['name'])
	else:
		log_message.emit('Ate a %s' % food['name'])
	if 'power' in food:
		log_state('use_consumable', 'restoring %s health' % food['power'])
		set_health(health + food['power'])
	if 'status' in food:
		if 'status' == 'all':
			log_state('use_consumable', 'removing all status effects')
			for effect in status:
				log_state('use_consumable', 'removing status effect %s' % effect)
				set_status(effect, 0)
		else:
			log_state('use_consumable', 'removing status effect %s' % food['status'])
			set_status(food['status'], 0)

	await act() 

	if freebies['food'] > 0:
		log_state('use_food', 'base chance to freebie %d' % freebies['food'])
		var chance = randi() % 100
		log_state('use_food', 'chance to freebie %d < %d = %s' % [chance, freebies['food'], chance < freebies['food']])
		if chance < freebies['food']:
			await get_tree().create_timer(0.75).timeout
			freebie.emit(food)
			log_message.emit('Light got a freebie!')
			await get_tree().create_timer($SoundEffects/ConsumableAcquire.stream.get_length() + 1.0).timeout

	#await get_tree().create_timer($SoundEffects/Action.stream.get_length()).timeout
