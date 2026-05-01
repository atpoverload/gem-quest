extends "res://gemanizer/character.gd"

var experience;
var stats;
var emotes;

var break_gem_chance = 0

var gem_protection = 100
var gem_power = 100
var freebie_chance = {
	'Drink': 0,
	'Food': 0,
}
# TODO: disaster
var on_attack = new_on_attack()
var base_affinities = new_base_affinities()
var affinities = new_base_affinities()
var attack_again = 0

var in_combat = false

signal break_gem(gem)
signal freebie(item)
signal start_turn
signal next_event
signal do_act
signal eat_food

func new_on_attack():
	return {
		'AddBlessing': {
			'Boost': 0,
			'Lucky': 0,
		},
		'AddCurse': {
			'Poison': 0,
			'Flinch': 0,
			'Banish': 0,
			'Burnt': 0,
			'Freeze': 0,
			'Shock': 0,
		}
	}

func new_base_affinities():
	return {
		'Health': 0,
		'Strength': 0,
		'Magic': 0,
		'White': 0,
		'Red': 0,
		'Blue': 0,
		'Green': 0,
		'Orange': 0,
		'Purple': 0,
		'Pink': 0,
	}

func log_state(method, message):
	print('[player.gd](%s)[%s]<%s> %s' % [character_name, Time.get_datetime_string_from_system(), method, message])

func _ready() -> void:
	health = $Info/Stats/Stats/Stats/Stats/Health
	experience = $Info/Stats/Stats/Stats/Stats/Experience
	stats = $Info/Stats/Stats/Stats/Stats/Stats
	curses = $Info/Effects/Curses
	blessings = $Info/Effects/Blessings
	emotes = $Emotes
	sprite = $Sprite
	sounds = $BattleSounds

	# TODO: this seems weird
	experience.get_child(0).hide()
	clear()
	update()

func update():
	experience.update_bar()
	health.update_bar()
	stats.update_stats()
	curses.update_status()
	blessings.update_status()

func clear():
	super.clear()
	health.value = 0
	health.max_value = 0
	stats.strength = 0
	stats.magic = 0
	break_gem_chance = 0

	emotes.clear()
	# TODO: disaster
	on_attack = new_on_attack()
	gem_protection = 100
	gem_power = 100
	freebie_chance = {
		'Drink': 0,
		'Food': 0,
	}
	base_affinities = new_base_affinities()
	affinities = new_base_affinities()

	experience.value = 0
	experience.max_value = 100
	update()

func set_player(player):
	clear()
	base_affinities = player.affinities.duplicate()
	affinities = player.affinities.duplicate()
	character_name = player['name']
	stats.strength += player.affinities['Strength']
	stats.magic += player.affinities['Magic']
	health.max_value += player.affinities['Health']
	health.value = health.max_value

func to_dict():
	var emotes_ = []
	for emote in $Emotes.emotes:
		for i in range($Emotes.emotes[emote]):
			emotes_.append(emote)
	var aff = affinities.duplicate()
	var hp = aff['Health'] + health.max_value
	var strn = aff['Strength'] + stats.strength
	var mag = aff['Magic'] + stats.magic
	var total = hp + strn + mag
	aff['Health']  = ceili((hp / total) * 10)
	aff['Strength']  = ceili((strn / total) * 10)
	aff['Magic']  = ceili((mag / total) * 10)
	return {
		'name': character_name,
		'affinities': aff,
		'emotes': emotes_
	}

func level():
	# TODO: reasses this equation
	var level_ = max(ceili(pow(
		#stats.strength
		#+ stats.magic
		#+ health.max_value
		(affinities['White']
		+ affinities['Red']
		+ affinities['Blue']
		+ affinities['Green']
		+ affinities['Orange']
		+ affinities['Purple']
		+ affinities['Pink']) / 7
		, 1.13)), 1)
	return level_

# experience
func gain_affinity(affinity):
	affinities[affinity] += 1
	log_state('gain_affinity', 'gaining %s affinity (%d)' % [affinity, affinities[affinity]])

func gain_experience(xp):
	log_state('gain_experience', 'gaining %d XP' % xp)
	log_state('gain_experience', 'current XP %d / %d' % [experience.value, experience.max_value])
	var luck = blessings.effects['Lucky']
	var choice = randi() % 100
	if choice < luck * (luck + 1) / 10:
		log_state('gain_experience', 'gained double XP from luck %d < %d' % [choice, luck])
		log_message.emit('You are very lucky!')
		xp *= 2
	while experience.value + xp >= 100:
		var gain = (experience.value + xp) - 100
		$BattleSounds/GainExperience.play()
		if gain > 0: await experience.adjust(xp - gain)
		else: await experience.adjust(xp)
		experience.value = 0
		await experience.update_bar()
		await gain_level()
		xp = gain
	if xp > 0:
		$BattleSounds/GainExperience.play()
		await experience.adjust(xp)
	log_state('gain_experience', 'final XP %d / %d' % [experience.value, experience.max_value])

func gain_level():
	log_state('gain_level', 'gained a level')
	log_message.emit('Gained a level!')
	$BattleSounds/LevelUp.play()

	# TODO: bonus from white seems too high
	# TODO: abstract this
	log_state('gain_level', 'gaining stats:')
	var strength = stat_growth(
		'strength',
		affinities['Strength'],
		affinities['White'] + 1,
		affinities['Red'] + 1,
		affinities['Orange'])
	var magic = stat_growth(
		'magic',
		affinities['Magic'],
		affinities['White'] + 1,
		affinities['Blue'] + 1,
		affinities['Purple'])
	var hp = 2 * stat_growth(
		'health',
		affinities['Health'],
		affinities['White'] + 1,
		affinities['Green'] + 1,
		affinities['Pink']) + 1

	var lvl_ = 1
	if health.max_value > base_affinities['Health']:
		var stat_lvl = stats.strength + stats.magic + health.max_value
		lvl_ = level()
	stats.strength += max(1, strength / lvl_)
	stats.magic += max(1, magic / lvl_)
	health.max_value += max(1, hp / lvl_)
	affinities['Strength'] = base_affinities['Strength']
	affinities['Magic'] = base_affinities['Magic']
	affinities['Health'] = base_affinities['Health']
	await health.adjust(ceili(75 * hp / 100 / lvl_) + 1)
	await update()

func stat_growth(value_name, a, b, c, d):
	# magic equation i made up to get stat gains from 4 stats:
	# ((0..a) + (0..c) + (0..d)) * (1 + log10((0..b) + 1))
	var lower = a # randi() % a
	var roll = randi() % c
	var upper = randi() % d
	var factor_roll = randi() % b + 1
	var factor = 1 + log(factor_roll) / log(10)
	var value = ceil((lower + roll + upper) * factor)
	log_state(
		'stat_growth',
		'%s: (%d/%d + %d/%d + %d/%d) * %.2f (%d/%d) = %d' % [
			value_name,
			lower,
			a,
			roll,
			c,
			upper,
			d,
			100 * factor,
			factor_roll,
			b,
			value
		])
	return value

func add_trigger_chance(base_chance, adjustment):
	log_state('add_trigger_chance', 'adjusting from %d with %d' % [base_chance, adjustment])
	if base_chance == 0:
		log_state('add_trigger_chance', 'setting chance to %d' % adjustment)
		return adjustment
	var adjusted_chance = ceili(base_chance * (1 + adjustment / 100.0))
	log_state(
		'add_trigger_chance',
		'adjusting chance from %d * %.2f = %d' % [base_chance, 1 + adjustment / 100.0, adjusted_chance]
	)
	return adjusted_chance

# items
func add_emote(item) -> void:
	if 'type' in item:
		return
	log_state('add_emote', 'adding emote %s' % item['name'])
	$Emotes.add_emote(item)
	$BattleSounds/GetEmote.play()
	# parse the emote to add the effect it gives
	var passive = item['passive']
	# TODO: more mess
	log_state('add_emote', "adjusting %s" % passive['type'])
	match passive['type']:
		'OnAttack':
			log_state('add_emote', "adjusting %s on attack" % passive['effect'])
			match passive['effect']:
				'AttackAgain': # on_attack['AttackAgain'] =
					attack_again = add_trigger_chance(
						attack_again,
						passive['chance']
					)
				'AddBlessing': on_attack['AddBlessing'][passive['status']] = add_trigger_chance(
					on_attack['AddBlessing'][passive['status']],
					passive['chance']
				)
				'AddCurse': on_attack['AddCurse'][passive['status']] = add_trigger_chance(
					on_attack['AddCurse'][passive['status']],
					passive['chance']
				)
		'Stat':
			log_state('add_emote', "adjusting %s passive" % passive['stat'])
			match passive['stat']:
				'Accuracy': accuracy = add_trigger_chance(
					accuracy,
					passive['chance']
				)
				'CriticalHit': crit_chance = add_trigger_chance(
					crit_chance,
					passive['chance']
				)
				'Evasion': evasion = add_trigger_chance(
					evasion,
					passive['chance']
				)
				'Freebie': freebie_chance[passive['item_type']] = add_trigger_chance(
					freebie_chance[passive['item_type']],
					passive['chance']
				)
				'GemProtection': gem_protection = add_trigger_chance(
					gem_protection,
					passive['chance']
				)
				'GemPower': gem_power = add_trigger_chance(
					gem_power,
					passive['power']
				)
				'Revive': revives = add_trigger_chance(
					revives,
					passive['chance']
				)
	next_event.emit()

# logic
func pre_logic():
	# we snack when under half health
	if health.value <= health.max_value / 2:
		eat_food.emit()
		await get_tree().create_timer(0.50).timeout

func logic():
	log_message.emit('What will %s do?' % character_name)
	start_turn.emit()

func act():
	do_act.emit()
	await sprite.hop(2, 0.10, 25)

# calcs
func strength_damage(power):
	# base damage modifiers
	var base_damage = 2 * ceil(sqrt(stats.strength) * power)

	# damage roll
	var damage = boost_damage(damage_roll(base_damage))

	log_state('strength_damage', 'damage = %d' % damage)

	return damage

func magic_damage(power):
	# damage modifiers
	var base_damage = 2 * ceil(stats.magic * power * gem_power / 100)
	var damage = damage_roll(base_damage)
	log_state('magic_damage', 'damage = %d' % damage)
	return damage

# TODO: where can we use this?
func luck() -> bool:
	log_state('luck', 'checking how lucky %s is' % character_name)
	# TODO: change this to something less silly
	var luck_stacks = blessings['Lucky']
	var chance = randi() % 100
	log_state('luck', 'chance to be lucky %d < %d = %s' % [chance, luck_stacks, chance < luck_stacks])
	if chance < luck_stacks:
		log_message.emit('%s is feeling lucky.' % character_name)
		sounds.blessings['Lucky'].play()
		await get_tree().create_timer(sounds.blessings['Lucky'].stream.get_length()).timeout
		return true
	return false

# actions
func attack(weapon):
	var weapon_name = weapon['name']
	log_state('attack', 'attacking with %s' % weapon_name)
	gain_affinity('Strength')
	#gain_affinity('Health')
	if 'color' in weapon: gain_affinity(weapon['color'])
	else: gain_affinity('White')
	log_message.emit('%s attacks.' % character_name)
	$BattleSounds/Attack.play()
	await act()
	await get_tree().create_timer($BattleSounds/Attack.stream.get_length()).timeout

	var action = weapon['action']
	if await accuracy_check(action.get('accuracy', 100)):
		var damage = strength_damage(action['power'])
		var do_attack_again = false
		blessed(-max(1, ceili(blessings.effects['Boost'] / 2)), null, 'Boost')
		if trigger_check(attack_again):
			log_message.emit('%s attacks twice' % character_name)
			do_attack_again = true
			damage *= 1.5
			$BattleSounds/Attack.play()
			await act()
			await get_tree().create_timer($BattleSounds/Attack.stream.get_length() - 0.25).timeout
		damage = await critical_hit(damage)
		var color = weapon.get('color', 'Weapon')
		if color: log_state('attack', 'attacking with %s for %d %s damage' % [weapon_name, damage, color])
		else: log_state('attack', 'attacking with %s for %d damage' % [weapon_name, damage])
		deal_damage.emit(damage, color)

		# TODO: disaster
		var weapon_on_attack = weapon['action'].get('on_attack', {'action': null, 'status': null, 'chance': null})

		for effect in on_attack:
			if on_attack[effect] is Dictionary:
				for e in on_attack[effect]:
					var bonus = 0
					if weapon_on_attack['action'] == effect and weapon_on_attack['status'] == e:
						bonus = weapon_on_attack['chance']
					await _on_attack_effect(weapon, e, on_attack[effect][e] + bonus)
			else:
				var bonus = 0
				if weapon_on_attack['action'] == effect:
					bonus = weapon_on_attack['chance']
				await _on_attack_effect(weapon, effect, on_attack[effect] + bonus)
		
		if do_attack_again:
			for effect in on_attack:
				if on_attack[effect] is Dictionary:
					for e in on_attack[effect]:
						var bonus = 0
						if weapon_on_attack['action'] == effect and weapon_on_attack['status'] == e:
							bonus = weapon_on_attack['chance']
						await _on_attack_effect(weapon, e, on_attack[effect][e] + bonus)
				else:
					var bonus = 0
					if weapon_on_attack['action'] == effect:
						bonus = weapon_on_attack['chance']
					await _on_attack_effect(weapon, effect, on_attack[effect] + bonus)
	else:
		await miss()

	await get_tree().create_timer(0.3).timeout
	
	if await burnt(): die.emit()
	else: end_turn.emit()

func invoke(gem):
	var color = gem.get('color')

	var gem_name = gem['name']
	log_state('invoke', 'using the %s' % gem_name)
	gain_affinity('Magic')
	#gain_affinity('Health')
	gain_affinity(color)
	log_message.emit('%s uses the %s.' % [character_name, gem_name])
	$BattleSounds/Gem.play()
	await act()
	await get_tree().create_timer($BattleSounds/Gem.stream.get_length()).timeout

	sounds.gems[color].play()
	await get_tree().create_timer(sounds.gems[color].stream.get_length()).timeout

	var action = gem['action']
	match action['type']:
		'Attack': 
			if await accuracy_check(action.get('accuracy', 100)):
				var damage = magic_damage(action['power'])
				damage = await critical_hit(damage)
				log_state('invoke', 'attacking with %s for %d %s damage' % [gem_name, damage, color])
				deal_damage.emit(damage, color)

				if 'on_attack' in action:
					var on_attack_ = action['on_attack']
					log_state('invoke', 'checking %s on attack' % on_attack_['action'])
					if trigger_check(on_attack_['chance']):
						await get_tree().create_timer(0.4).timeout
						match on_attack_['action']:
							'AddCurse':
								var power = sqrt(magic_damage(on_attack_['power']))
								var status = on_attack_['status']
								log_state('gem', 'applying %d stacks of %s %s' % [power, color, status])
								apply_curse.emit(status, power, color)
			else:
				await miss()
		'Weapon':
			if await accuracy_check(action.get('accuracy', 100)):
				var damage = magic_damage(action['power'])
				var do_attack_again = false
				if trigger_check(attack_again):
					log_message.emit('%s attacks twice' % character_name)
					do_attack_again = true
					damage *= 1.5
					await act()
					await get_tree().create_timer(0.5).timeout
				damage = await critical_hit(damage)
				log_state('invoke', 'attacking with %s for %d %s damage' % [gem_name, damage, color])
				deal_damage.emit(damage, color)
				for effect in on_attack:
					if on_attack[effect] is Dictionary:
						for e in on_attack[effect]:
							await _on_attack_effect(gem, e, on_attack[effect][e])
					else:
						await _on_attack_effect(gem, effect, on_attack[effect])

				if do_attack_again:
					if attack_again > 0:
						for effect in on_attack:
							if on_attack[effect] is Dictionary:
								for e in on_attack[effect]:
									await _on_attack_effect(gem, e, on_attack[effect][e])
							else:
								await _on_attack_effect(gem, effect, on_attack[effect])
			else:
				await miss()
		'AddCurse':
			if not await freeze():
				var power = 2 * ceili(sqrt(magic_damage(action['power'])))
				var status = action['status']
				log_state('gem', 'applying %d stacks of %s %s' % [power, color, status])
				apply_curse.emit(status, power, color)
		'AddBlessing':
			if not await freeze():
				var power = magic_damage(action['power'])
				var status = action['status']
				log_state('gem', 'gaining %d stacks of %s' % [power, status])
				blessed(power, color, status)
		'DoNothing':
			log_message.emit('Nothing happened?')
			match action['effect']:
				'AffinityUp':
					for affinity in affinities:
						if affinity not in ['Strength', 'Magic', 'Health', 'White'] and randi() % 100 < 50:
							gain_affinity(affinity)
				_: pass
			$BattleSounds/Crickets.play()
			await get_tree().create_timer($BattleSounds/Crickets.stream.get_length()).timeout
#
	await get_tree().create_timer(0.4).timeout

	await _break_gem(gem)
	end_turn.emit()

func quaff(drink):
	var drink_name = drink['name']
	log_state('quaff', 'drinking %s' % drink_name)
	#gain_affinity('Health')
	gain_affinity('Health')
	if 'color' in drink: gain_affinity(drink['color'])
	else: gain_affinity('White')
	log_message.emit('%s drinks a %s.' % [character_name, drink_name])
	$BattleSounds/Drink.play()
	await act()
	await get_tree().create_timer($BattleSounds/Drink.stream.get_length() / 2).timeout

	_snack(drink['action'])

	if trigger_check(freebie_chance['Drink']):
		log_state('quaff', 'got a freebie')
		log_message.emit('Got a freebie!')
		freebie.emit(drink)

	await get_tree().create_timer(0.3).timeout
	end_turn.emit()

func eat(food):
	var food_name = food['name']
	log_state('eat', 'eating %s' % food_name)
	#gain_affinity('Health')
	gain_affinity('Health')
	if 'color' in food: gain_affinity(food['color'])
	else: gain_affinity('White')
	log_message.emit('%s eats a %s.' % [character_name, food_name])
	$BattleSounds/Eat.play()
	await act()
	await get_tree().create_timer($BattleSounds/Eat.stream.get_length()).timeout

	_snack(food['action'])

	if trigger_check(freebie_chance['Food']):
		log_state('eat', 'got a freebie')
		log_message.emit('Got a freebie!')
		freebie.emit(food)

func _snack(action):
	await act()
	match action['type']:
		'Heal': 
			var power = action['power']
			var adjustment = 1
			var adjusted_power = adjustment * power
			log_state('_snack', 'healing for %d * %d = %d' % [adjustment, power, adjusted_power])
			$BattleSounds/Heal.play()
			await health.adjust(power)
		'RemoveCurse':
			var status = action['status']
			log_state('_snack', 'removing %s' % status)
			match status:
				'All':
					for curse in curses.effects:
						await curses.adjust(curse, -curses.effects[curse])
				'Any':
					var curse_pool = []
					for curse in curses.effects:
						if curses.effects[curse] > 0:
							curse_pool.append(curse)
					var curse = curse_pool.pick_random()
					if curse:
						await curses.adjust(curse, -curses.effects[curse])
				_: await curses.adjust(status, -curses.effects[status])
		'AddBlessing':
			var power = action['power']
			var status = action['status']
			log_state('_snack', 'gaining %d stacks of %s' % [power, status])
			blessed(power, null, status)
		'AffinityUp':
			$BattleSounds/AffinityUp.play()
			for affinity in action['affinities']:
				gain_affinity(affinity)
			log_message.emit('Affinities up!')
			await get_tree().create_timer($BattleSounds/AffinityUp.stream.get_length()).timeout
		'Actions':
			for a in action['actions']:
				_snack(a)
		_: pass

func _on_attack_effect(weapon, effect, on_attack_chance) -> void:
	log_state('_on_attack_effect', 'checking %d%% chance for %s' % [on_attack_chance, effect])
	if trigger_check(on_attack_chance):
		match effect:
			'Boost':
				# TODO: not sure about how to scale this
				var power = sqrt(level())
				var status = 'Boost'
				log_state('on_attack_effect', 'gaining %d stacks of %s' % [power, status])
				blessed(power, null, status)
				#sounds.blessings[status].play()
				#await blessings.adjust(status, power)
				#await get_tree().create_timer(sounds.blessings[status].stream.get_length()).timeout
			'Banish', 'Flinch', 'Burnt', 'Freeze', 'Shock':
				# TODO: not sure about how to scale this
				var power = sqrt(level())
				var color = weapon.get('color', null)
				log_state('on_attack_effect', 'applying %d stacks of %s %s' % [power, color, effect])
				apply_curse.emit(effect, power, color)
				sounds.curses[effect].play()
				await get_tree().create_timer(sounds.curses[effect].stream.get_length()).timeout
		await get_tree().create_timer(0.3).timeout

func _break_gem(gem):
	log_state('break_gem', 'base chance to break %d' % break_gem_chance)
	var chance = randi() % 100
	var break_chance = int(floor(break_gem_chance * gem_protection / 100.0))
	log_state('break_gem', 'chance to break %d < %d = %s' % [chance, break_chance, chance < break_chance])
	if chance < break_chance:
		log_message.emit('The %s broke!' % gem['name'])
		$BattleSounds/BreakGem.play()
		break_gem.emit(gem)
		await get_tree().create_timer($BattleSounds/BreakGem.stream.get_length()).timeout
		break_gem_chance = 0
	else:
		break_gem_chance += 2

func use_item(item) -> void:
	if not in_combat:
		return
	match item['type']:
		'Weapon': attack(item)
		'Gem': invoke(item)
		'Drink': quaff(item)
		'Food': eat(item)
