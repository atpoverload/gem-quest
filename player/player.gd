extends "res://core/character.gd"

var level = 0
var experience = 0
var health_growth = 0

var weapon
var attack_power = 0
var magic_power = 0
var consumables = {}
var emotes = {}
var crit_chance = 6

var gold = 0

var experience_bar

signal next_event
signal game_over

func _ready():
	sprite = $PlayerUI/PlayerMenus/PlayerDescription/Description/Player/Divider/Sprite
	health_bar = $PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/HealthBar/VerticalDivider/Middle/Bar
	health_label = $PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/Health/Label
	status_bar = $PlayerUI/PlayerMenus/PlayerDescription/Description/Player/Divider/VBoxContainer/Status
	buff_bar = $PlayerUI/PlayerMenus/PlayerDescription/Description/Player/Divider/VBoxContainer/Buffs
	experience_bar = $PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/ExperienceBar/VerticalDivider/Middle/Bar

func log_state(method, message):
	print("(%s)[player.gd][%s]<%s> %s" % [Time.get_datetime_string_from_system(), method, character_name, message])

func set_player(player, level_):
	log_state('new_player', 'creating new player %s - health=%d level=%d' % [player['name'], player['health'], level_])
	character_name = player['name']
	$PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/Name/Label.text = character_name

	clear_inventory()
	$PlayerUI/PlayerMenus/ItemDescription/ItemDescription.hide()

	health_growth = int(2 * player['health'] / 10)
	level = 0
	max_health = player['health']
	health = max_health
	attack_power = 0
	magic_power = 0
	#health_growth = player['health']
	await gain_levels(level_)

	status = {}
	gold = 0

	for status_icon in status_bar.get_children():
		status_icon.hide()
	for buff_icon in buff_bar.get_children():
		buff_icon.hide()
	
	sprite.reset()

	$PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/Powers/AttackPower/Label.text = '%2d Attack' % attack_power
	$PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/Powers/GemPower/Label.text = '%2d Magic' % magic_power
	#$PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/Gold/Label.text = '%4d Gold' % gold

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
	$PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/Level/Label.text = 'Level %3d' % level
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

	$PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/Powers/AttackPower/Label.text = '%3d Attack' % attack_power
	$PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/Powers/GemPower/Label.text = '%3d Magic' % magic_power

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

# inventory management
func clear_inventory():
	log_state('clear_inventory', 'removing all items from inventory')
	$PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Weapon/Button.remove_item()
	for child in $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Gems.get_children():
		child.get_child(1).remove_item()
	for child in $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Consumables/ConsumablesDivider.get_children():
		child.get_child(1).remove_item()

# TODO: this is in desperate need of clean up
func add_item(item):
	log_state('add_item', 'adding %s to inventory' % item['name'])
	match item['type']:
		'weapon':
			log_state('add_item', 'checking for free weapon slot')
			var item_button = $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Weapon/Button
			if item_button.is_empty():
				log_state('add_item', 'using %s as weapon' % item['name'])
				weapon = item
				item_button.set_item(self, item)
				$SoundEffects/WeaponAcquire.playing = true
				await get_tree().create_timer($SoundEffects/WeaponAcquire.stream.get_length() - 0.25).timeout
			else:
				log_state('add_item', 'replacing %s with %s' % [item_button._item['name'], item['name']])
				var extra_gold = item_button._item['power'] * item_button._item.get('accuracy', 100) * (item_button._item['rarity'] + 1)
				log_state('add_item', 'sold %s for %s gold ' % [item_button._item['name'], extra_gold])
				await gain_experience(extra_gold)
				$PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/Gold/Label.text = '%4d Gold' % gold
				item_button.set_item(self, item)
				$SoundEffects/WeaponAcquire.playing = true
				await get_tree().create_timer($SoundEffects/WeaponAcquire.stream.get_length() - 0.25).timeout
		'gem':
			log_state('add_item', 'checking for free gem slot')
			for child in $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Gems.get_children():
				var item_button = child.get_child(1)
				if item_button.is_empty():
					log_state('add_item', 'using %s as gem' % item['name'])
					item_button.set_item(self, item)
					$SoundEffects/GemAcquire.playing = true
					await get_tree().create_timer($SoundEffects/GemAcquire.stream.get_length() - 0.25).timeout
					return
				elif item_button._item['name'] == item['name']:
					log_state('add_item', 'found %s' % item['name'])
					#magic_power += 1
					#log_state('add_item', 'increasing gem power to %s' % magic_power)
					#$PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/GemPower/Label.text = '%2d Gem Power' % magic_power
					break
				else:
					log_state('add_item', 'already holding %s' % item_button._item['name'])
			log_state('add_item', 'no gem slots available')
			var extra_gold = 10 * (item['rarity'] + 1)
			log_state('add_item', 'sold %s for %s gold ' % [item['name'], extra_gold])
			await gain_experience(extra_gold)
		'consumable':
			log_state('add_item', 'checking for free consumable slot')
			for child in $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Consumables/ConsumablesDivider.get_children():
				var item_button = child.get_child(1)
				if (item['name'] not in consumables or consumables[item['name']] == 0) and item_button.is_empty():
					log_state('add_item', 'using %s as consumable' % item['name'])
					consumables[item['name']] = 1
					item_button.set_item(self, item)
					item_button.get_child(0).text = str(consumables[item['name']])
					if consumables[item['name']] == 1:
						item_button.get_child(0).hide()
					else:
						item_button.get_child(0).show()
					$SoundEffects/ConsumableAcquire.playing = true
					await get_tree().create_timer($SoundEffects/ConsumableAcquire.stream.get_length() - 0.25).timeout
					return
				elif not item_button.is_empty() and item_button._item['name'] == item['name']:
					log_state('add_item', 'adding %s to go from %d to %d' % [item['name'], consumables[item['name']], consumables[item['name']] + 1])
					consumables[item['name']] += 1
					item_button.get_child(0).text = str(consumables[item['name']])
					if consumables[item['name']] == 1:
						item_button.get_child(0).hide()
					else:
						item_button.get_child(0).show()
					$SoundEffects/ConsumableAcquire.playing = true
					await get_tree().create_timer($SoundEffects/ConsumableAcquire.stream.get_length() - 0.25).timeout
					return
				else:
					log_state('add_item', 'already holding %s' % item['name'])
			log_state('add_item', 'no consumable slots available')
			var extra_gold = (item['power'] * item.get('accuracy', 100) * item['rarity'] + 1)
			log_state('add_item', 'sold %s for %s gold ' % [item['name'], extra_gold])
			await gain_experience(extra_gold)
			$PlayerUI/PlayerMenus/PlayerDescription/Description/Info/Background/Info/Gold/Label.text = '%4d Gold' % gold
		'emote':
			log_state('add_item', 'adding emote')
			for row in $MarginContainer/VBoxContainer.get_children():
				for box in row.get_children():
					var button = box.get_child(1)
					if button._item['name'] == item['name']:
						log_state('add_item', 'adding %s to go from %d to %d' % [item['name'], emotes[item['name']], emotes[item['name']] + 1])
						emotes[item['name']] += 1
						button.get_child(0).text = str(emotes[item['name']])
						button.get_child(0).show()
						if item['name'] == 'Yikes':
							armor = emotes[item['name']]
						return
			log_state('add_item', '%s is a new emote, adding to table' % item['name'])
			var button = $MarginContainer/Emote.duplicate()
			emotes[item['name']] = 1
			if item['name'] == 'Yikes':
				armor = emotes[item['name']]
			if $MarginContainer/VBoxContainer.get_child_count() > 0:
				for row in $MarginContainer/VBoxContainer.get_children():
					if row.get_child_count() < 4:
						log_state('add_item', 'adding %s to existing row' % item['name'])
						row.add_child(button)
						button.get_child(1).set_item(item)
						button.show()
						return
			log_state('add_item', 'creating new row for %s' % item['name'])
			var row = HBoxContainer.new()
			row.add_child(button)
			$MarginContainer/VBoxContainer.add_child(row)
			row.show()
			button.get_child(1).set_item(item)
			button.show()

func drop_weapon():
	log_state('drop_weapon', 'dropping %s' % $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Weapon/Button._item['name'])
	$PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Weapon/Button.remove_item()

func break_gem(color):
	log_state('break_gem', 'breaking %s gem' % color)
	for child in $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Gems.get_children():
		var item_button = child.get_child(1)
		if not item_button.is_empty() and item_button._item['color'] == color:
			log_state('break_gem', 'broke %s gem' % color)
			item_button.remove_item()
			return
	log_state('break_gem', 'not holding %s gem' % color)

# ui helpers
func enable():
	log_state('enable', 'enabling items')
	$PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Weapon/Button.disabled = false
	$PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Weapon/Button.modulate = Color('White')
	for child in $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Gems.get_children():
		child.get_child(1).disabled = false
		child.get_child(1).modulate = Color('White')
	for child in $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Consumables/ConsumablesDivider.get_children():
		child.get_child(1).disabled = false
		child.get_child(1).modulate = Color('White')

func disable():
	log_state('enable', 'disabling items')
	$PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Weapon/Button.disabled = true
	$PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Weapon/Button.modulate = Color('555555')
	for child in $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Usables/UsablesDivider/Gems.get_children():
		child.get_child(1).disabled = true
		child.get_child(1).modulate = Color('555555')
	for child in $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Consumables/ConsumablesDivider.get_children():
		child.get_child(1).disabled = true
		child.get_child(1).modulate = Color('555555')
	#$PlayerUI/PlayerMenus/ItemDescription/ItemDescription.hide()

# actions
func act():
	await sprite.hop2(2, 0.10, 25)

# emote helpers
# TODO: may want to have the values in a lookup of some sort
func ligC(accuracy):
	if 'ligC' in emotes and emotes['ligC'] > 0:
		var base_accuracy = accuracy
		var adjustment = pow(1.20, emotes['ligC']) # 20% increase per rank
		accuracy = min(100, base_accuracy * adjustment)
		log_state('ligC', 'accuracy boosted %d * %.2f = %d)' % [base_accuracy, adjustment, accuracy])
		return accuracy
	else:
		return accuracy

func Slay(damage):
	if 'Slay' in emotes and emotes['Slay'] > 0:
		var base_damage = damage
		damage = base_damage + emotes['Slay']
		log_state('Slay', 'damage boosted %d * %d = %d' % [base_damage, emotes['Slay'], damage])
		return damage
	else:
		return damage

func Vampers(damage):
	if 'Vampers' in emotes and emotes['Vampers'] > 0:
		var adjustment = pow(1.10,  emotes['Vampers']) - 1
		var stolen = damage * adjustment + 1
		log_state('Vampers', 'stole %d * %.2f + 1 = %d HP' % [damage, adjustment, stolen])
		log_message.emit('%s stole health' % character_name)
		await set_health(health + stolen)

func accuracy_check(accuracy):
	# accuracy modifiers
	accuracy = ligC(accuracy)

	var chance = randi() % 100
	log_state('accuracy_check', 'chance to hit %d < %d = %s' % [chance, accuracy, chance < accuracy])
	return chance < accuracy

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
	var base_damage = int(attack_power * Slay(damage))
	
	var lower_bound = min(max(5 * base_damage, 50), 85)
	var upper_bound = 100 - lower_bound
	var damage_roll = (randi() % upper_bound + lower_bound) / 100.0
	var calc = (base_damage / 3 + 2)
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
	var calc = (base_damage / 5 + 2)
	damage =  round(calc * damage_roll)
	log_state('get_weapon_damage', 'damage roll %d * %f = %d' % [calc, damage_roll, damage])
	
	# boost
	if 'boost' in buffs:
		damage *= (1 + 0.25 * buffs['boost'])
	# crit
	damage = critical_hit(damage)

	return damage

func get_stacks(element, effect, stacks):
	return stacks + 1

func miss():
	await get_tree().create_timer(0.33).timeout
	$SoundEffects/Miss.playing = true
	log_message.emit('%s missed' % character_name)
	await get_tree().create_timer($SoundEffects/Miss.stream.get_length() + 0.5).timeout
	pass_turn.emit()

func weapon_attack(item):
	disable()
	log_state('weapon_attack', 'attacking with %s' % item['name'])
	log_message.emit('%s attacks' % character_name)
	await act()

	if accuracy_check(item.get('accuracy', 100)):
		var element = item.get('element', 'normal')
		var damage = get_weapon_damage(element, item['power'])
		log_state('weapon_attack', 'attacking with %s for %d %s damage' % [item['name'], damage, element])
		$SoundEffects/Action.stream = item['sound']
		$SoundEffects/Action.playing = true
		deal_damage.emit(element, damage)
		await Vampers(damage)
	else:
		await miss()

func use_gem(item):
	disable()
	log_state('use_gem', 'using the %s' % item['name'])
	log_message.emit('%s uses the' % character_name)
	await get_tree().create_timer(0.25).timeout
	log_message.emit('%s' % item['name'])
	$SoundEffects/UseGem.playing = true
	await act()
	await get_tree().create_timer($SoundEffects/UseGem.stream.get_length() / 2).timeout

	if accuracy_check(item.get('accuracy', 100)):
		$SoundEffects/Action.stream = item['sound']
		$SoundEffects/Action.playing = true
		var element = item.get('element', 'normal')
		# TODO: this is a fake switch and it's bad
		if 'power' in item:
			var damage = get_gem_damage(element, item['power'])
			log_state('use_gem', 'attacking with %s for %d %s damage' % [item['name'], damage, element])
			deal_damage.emit(element, damage)
		elif 'status' in item:
			var effect = item['status']
			var stacks = item.get('stacks', 0)
			stacks = get_stacks(element, effect, stacks)
			log_state('use_gem', 'applying %d stacks of %s with %s' % [stacks, effect, item['name']])
			apply_status.emit(element, effect, stacks)
		elif 'buff' in item:
			var buff = item['buff']
			var stacks = item.get('stacks', 0)
			stacks = get_stacks(element, buff, stacks)
			log_state('use_gem', 'gain %s' % item['buff'])
			await gain_buff(buff, stacks)
			await get_tree().create_timer($SoundEffects/Action.stream.get_length() / 4).timeout
			pass_turn.emit()
		else:
			log_message.emit('It did nothing?')
			await get_tree().create_timer(0.50).timeout
			pass_turn.emit()
		
		break_gem
	else:
		await miss()

func use_consumable(item):
	disable()
	log_state('use_consumable', 'using %s' % item['name'])
	$SoundEffects/Action.stream = item['sound']
	$SoundEffects/Action.playing = true
	await act()

	if item['name'][0] in 'AEIOUaeiou':
		log_message.emit('Using an %s' % item['name'])
	else:
		log_message.emit('Using a %s' % item['name'])
	if 'power' in item:
		log_state('use_consumable', 'restoring %s health' % item['power'])
		set_health(health + item['power'])
	if 'status' in item:
		if 'status' == 'all':
			log_state('use_consumable', 'removing all status effects')
			for effect in status:
				log_state('use_consumable', 'removing status effect %s' % effect)
				set_status(effect, 0)
		else:
			log_state('use_consumable', 'removing status effect %s' % item['status'])
			set_status(item['status'], 0)
	# TODO: move into some sort of item amangement
	for child in $PlayerUI/PlayerMenus/ActionMenu/Background/Inventory/Consumables/ConsumablesDivider.get_children():
		var item_button = child.get_child(1)
		if not item_button.is_empty() and item_button._item['name'] == item['name']:
			log_state('use_consumable', 'removing a %s out of %s' % [item['name'], consumables[item['name']]])
			consumables[item['name']] -= 1
			item_button.get_child(0).text = str(consumables[item['name']])
			if consumables[item['name']] == 1:
				item_button.get_child(0).hide()
			else:
				item_button.get_child(0).show()
			
			if consumables[item['name']] == 0:
				log_state('use_consumable', 'removing %s from inventory' % item['name'])
				item_button.remove_item()
			break
	await get_tree().create_timer($SoundEffects/Action.stream.get_length()).timeout
	pass_turn.emit()

func logic():
	log_message.emit('What will %s do?' % character_name)
	enable()

func death():
	log_state('death', 'game over :(')
	log_message.emit('%s died' % character_name)
	sprite.die()
	await get_tree().create_timer(0.25).timeout
	log_message.emit('Game Over!')
	$SoundEffects/GameOver.playing = true
	await get_tree().create_timer($SoundEffects/GameOver.stream.get_length() * 3 / 4).timeout
	game_over.emit()
