extends Control

var character_name = ''

var health
var curses
var blessings

var resistances = {}
var accuracy = 100
var crit_chance = 6
var evasion = 0
var revives = 0

var sprite
var sounds

signal log_message(message)

signal deal_damage(power, element)
signal apply_curse(power, element, curse)
signal die()
signal end_turn()

func log_state(method, message):
	print('[character.gd](%s)[%s]<%s> %s' % [character_name, Time.get_datetime_string_from_system(), method, message])

func _ready() -> void: clear()

func clear() -> void:
	character_name = ''
	sprite.reset()

	health.max_value = 0
	health.value = 0
	health.unit = 'HP'
	health.update_bar()

	resistances.clear()

	for curse in curses.effects:
		curses.adjust(curse, -curses.effects[curse])
	curses.update_status()
	if blessings:
		for blessing in blessings.effects:
			blessings.adjust(blessing, -blessings.effects[blessing])
		blessings.update_status()
	accuracy = 100
	crit_chance = 6
	evasion = 0

# things that react to actions
func is_dead() -> bool:
	log_state('is_dead', 'are they dead yet? %s / %s' % [health.value, health.max_value])
	if health.value <= 0:
		log_state('is_dead', 'time to die :(')
		return true
	return false

# things that react to actions
func death() -> void:
	log_state('death', 'time to die :(')
	log_message.emit('%s has died!' % character_name)
	await sprite.die()
	die.emit()

func evade() -> bool:
	var evasion_ = int(evasion) + blessings.effects['Tumble']
	var chance = randi() % 100
	log_state('evade', 'chance to evade %d < %d = %s' % [chance, evasion_, chance < evasion_])
	if chance < evasion_:
		await get_tree().create_timer(0.45).timeout
		log_message.emit('%s evaded.' % character_name)
		sounds.miss.play()
		await sprite.shake(2, 0.10, 15).finished
		return true
	return false

func shield() -> bool:
	log_state('shield', 'shielding from damage')
	blessings.adjust('Shield', -1)
	sounds.blessings['Shield'].play()
	log_message.emit('Shielded from damage!')
	await get_tree().create_timer(sounds.blessings['Shield'].stream.get_length()).timeout
	return true

func boost_damage(power):
	var boost_stacks = 0
	var boost_adjustment = 1
	if 'Boost' in blessings.effects:
		boost_stacks = blessings.effects['Boost']
		boost_adjustment = 1 + log(boost_stacks + 1) / log(10)
		var damage = int(ceil(power * boost_adjustment))
		log_state(
		'boost_damage',
		'damage %d (roll) * %.2f (%d boost) = %d' % [
			power,
			boost_adjustment,
			boost_stacks,
			damage
		])
		return damage
	return power

func damaged(damage: int, color: Variant) -> int:
	log_state('damaged', 'damage: %s, color: %s' % [damage, color])
	if health.value > 0 and evasion > 0:
		if await evade():
			return health.value
	if health.value > 0 and blessings.effects['Shield'] > 0:
		return await shield()
	var adjusted_damage = damage
	var break_stacks = curses.effects['Break']
	var break_adjustment = 1 + log(break_stacks + 1) / log(10)
	adjusted_damage *= break_adjustment
	if color in resistances:
		adjusted_damage = ceili(resistances[color] * damage)
		log_state('damaged', 'taking %.2f * %d = %d damage' % [resistances[color], damage, adjusted_damage])
	else:
		log_state('damaged', 'taking %d damage' % damage)
	sprite.damaged(2)
	if health.value == 0:
		return 0
	if adjusted_damage > health.value and trigger_check(revives):
		await health.adjust(-health.value + 1)
		log_state('damaged', 'revived from death!')
		log_message.emit('Evaded death!')
		sounds.revive.play()
	else:
		await health.adjust(-adjusted_damage)
	health.update_bar()
	return health.value

func cursed(curse: String, power: int, color: Variant) -> void:
	log_state('cursed', 'power: %s, color: %s, curse: %s' % [power, color, curse])
	if color in resistances:
		var adjusted_power = int(ceil(power * resistances[color]))
		log_state('cursed', 'applying %.2f * %d = %d stacks of %s' % [resistances[color], power, adjusted_power, curse])
		if adjusted_power > 0:
			curses.adjust(curse, adjusted_power)
			log_message.emit('%s gains %s.' % [character_name, curse])
			sounds.curses[curse].play()
			await sprite.shake(3, 0.08, 12).finished
			await get_tree().create_timer(sounds.curses[curse].stream.get_length()).timeout
		else:
			log_message.emit('%s resisted %s.' % [character_name, curse])
	else:
		log_state('cursed', 'applying %d stacks of %s' % [power, curse])
		curses.adjust(curse, power)
		log_message.emit('%s gains %s.' % [character_name, curse])
		sounds.curses[curse].play()
		await sprite.shake(3, 0.08, 12).finished
		await get_tree().create_timer(sounds.curses[curse].stream.get_length()).timeout

func blessed(power: int, color: Variant, blessing: String) -> void:
	log_state('blessed', 'power: %s, color: %s, blessing: %s' % [power, color, blessing])
	log_state('blessed', 'applying %d stacks of %s' % [power, blessing])
	blessings.adjust(blessing, power)
	log_message.emit('%s gains %s.' % [character_name, blessing])
	sounds.blessings[blessing].play()
	await sprite.attack(2)
	await get_tree().create_timer(sounds.blessings[blessing].stream.get_length()).timeout

# things that are used with actions
func accuracy_check(chance_to_hit: int) -> bool:
	log_state('accuracy_check', 'base chance to hit %d' % chance_to_hit)

	# accuracy modifiers
	chance_to_hit *= accuracy
	chance_to_hit = int(ceil(chance_to_hit / 100.0))

	var chance = randi() % 100
	if await shock():
		chance_to_hit = shock_accuracy(chance_to_hit)
	log_state('accuracy_check', 'chance to hit %d < %d = %s' % [chance, chance_to_hit, chance < chance_to_hit])
	return chance < chance_to_hit

func damage_roll(base_damage):
	# damage modifiers
	var lower_bound = int(min(max(5 * base_damage, 50), 85))
	var upper_bound = 100 - lower_bound
	var choice = randi()
	var roll = (choice % upper_bound + lower_bound) / 100.0
	var calc = (base_damage / 3.0 + 2)
	var damage = int(ceil(calc * roll))

	log_state('level_damage', 'damage %.2f (roll) * %d = %d' % [roll, calc, damage])
	
	return damage

func trigger_check(chance_to_trigger: int) -> bool:
	log_state('trigger_check', 'base chance to trigger %d' % chance_to_trigger)

	var chance = randi() % 100
	log_state('trigger_check', 'chance to trigger %d < %d = %s' % [chance, chance_to_trigger, chance < chance_to_trigger])
	return chance < chance_to_trigger

func miss() -> void:
	sounds.miss.play()
	log_message.emit('%s missed!' % character_name)
	await get_tree().create_timer(sounds.miss.stream.get_length()).timeout

func critical_hit(damage: int) -> int:
	var chance = randi() % 100
	var crit_chance_ = floor(crit_chance)
	log_state('critical_hit', 'crit chance %d < %d' % [chance, crit_chance_])
	if chance < crit_chance_:
		var base_damage = damage
		damage *= 2
		log_state('critical_hit', 'damage boosted 2 * %d = %d' % [base_damage, damage])
		log_message.emit('It\'s a critical hit!')
		sounds.critical_hit.play()
		await get_tree().create_timer(sounds.critical_hit.stream.get_length() / 4).timeout
	else:
		sounds.hit.play()
		await get_tree().create_timer(sounds.hit.stream.get_length() / 4).timeout
	return damage

# curses
func poison() -> bool:
	if 'Poison' not in curses.effects:
		return false
	var value = curses.effects['Poison']
	# deals damage per stack
	# TODO: green element resist?
	value = max(0, value * (value + 1) / 8)
	if value > 0:
		log_state('poison', 'value: %d' % value)
		log_message.emit('%s is poisoned.' % character_name)
		sounds.curses['Poison'].play()
		if await damaged(value, null) < 1:
			await get_tree().create_timer(sounds.curses['Poison'].stream.get_length()).timeout
			return true
		else:
			await get_tree().create_timer(sounds.curses['Poison'].stream.get_length()).timeout
			await curses.adjust('Poison', -1)
			return false
	else:
		await curses.adjust('Poison', -1)
	return false

func sleep() -> bool:
	if 'Sleep' not in curses.effects:
		return false
	var value = curses.effects['Sleep']
	if value == 0:
		return false

	log_state('sleep', 'value: %d' % value)
	log_message.emit('%s is snoozing.' % character_name)
	sounds.curses['Sleep'].play()
	await sprite.snooze()
	await get_tree().create_timer(0.25).timeout

	return not await wake_up()

func wake_up() -> bool:
	# chance to wake up is 1 - 1 / (sqrt(x) + 1)
	#  -   0 = 100 %
	#  -   1 = 50 %
	#  -   2 = 41 %
	#  -   3 = 37 %
	#  -   4 = 33 %
	#  -  50 = 12 %
	#  - 100 = 10 %
	var value = curses.effects['Sleep']
	var wake_up_chance = 100 - int(ceil(100 * (1.0 / (sqrt(value) + 1))))
	var chance = randi() % 100
	var awoken = value > 0 and chance < wake_up_chance

	log_state('wake_up', 'chance to wake up %d < %d = %s' % [chance, wake_up_chance, awoken])
	if not awoken:
		# lose half of the sleep stacks
		curses.adjust('Sleep', min(0, -int(floor(value / 2))))
		return false
	else:
		log_message.emit('%s woke up.' % character_name)
		await sprite.shake(2, 0.05, 10)
		curses.adjust('Sleep', -value)
		await get_tree().create_timer(0.75).timeout
		return true

func flinch() -> bool:
	if 'Flinch' not in  curses.effects:
		return false
	var value =  curses.effects['Flinch']
	if value == 0:
		return false
	if value > 0:
		log_state('flinch', 'value: %d' % value)
		log_message.emit('%s flinched.' % character_name)
		await sprite.damaged(1)
		await get_tree().create_timer(0.25).timeout
		curses.adjust('Flinch', -value)
		return true
	return false

func doom() -> bool:
	if 'Doom' not in curses.effects:
		return false
	var value = curses.effects['Doom']
	if value == 0:
		return false

	log_state('doom', 'value: %d' % value)
	sounds.curses['Doom'].play()
	if value >= 30:
		log_message.emit('IT\'S TOO LATE FOR YOU.')
		await damaged(health.value, null)
		return true
	else:
		curses.effects['Doom'] += 1
		log_message.emit('%s is doomed...' % character_name)
		await sprite.shake(3, 0.25, 1)
		await get_tree().create_timer(0.25).timeout

		return false

func banish() -> bool:
	if 'Banish' not in  curses.effects:
		return false
	var value =  curses.effects['Banish']
	if value > 0:
		log_state('banish', 'value: %d' % value)

		var chance = randi() % 100
		log_state('banish', 'chance to banish %d < %d = %s' % [chance, value, chance < value])
		if true:
			log_message.emit('%s is banished.' % character_name)
			sounds.curses['Banish'].playing = true
			await get_tree().create_timer(sounds.curses['Banish'].stream.get_length() / 2).timeout
			await damaged(health.value, null)
			return true
	return false

func burnt() -> bool:
	if 'Burnt' not in curses.effects:
		return false
	# deals flat damage
	# TODO: red element resist?
	# TODO: based on % max health?
	var value = curses.effects['Burnt']
	if value > 0:
		log_state('burnt', 'value: %d' % value)
		log_message.emit('%s is burnt.' % character_name)
		sounds.curses['Burnt'].play()
		if await damaged(value, null) < 1:
			await get_tree().create_timer(sounds.curses['Burnt'].stream.get_length()).timeout
			return true
		else:
			await get_tree().create_timer(sounds.curses['Burnt'].stream.get_length()).timeout
			return false
	return false

func freeze() -> bool:
	if 'Freeze' not in curses.effects:
		return false
	# TODO: blue element resist?
	var value = curses.effects['Freeze']
	if value > 0:
		log_state('freeze', 'value: %d' % value)
		# TODO: this is wrong, too hard to skip turn, need to do a log
		var freeze_chance = 100 - int(ceil(100 * (1.0 / (sqrt(value) + 1))))
		var chance = randi() % 100
		var frozen = chance < freeze_chance

		log_state('freeze', 'chance to be frozen %d < %d = %s' % [chance, freeze_chance, frozen])
		if not frozen:
			return false
		else:
			log_message.emit('%s is frozen.' % character_name)
			await sprite.shake(2, 0.05, 10)
			sounds.curses['Freeze'].play()
			await get_tree().create_timer(0.75).timeout
			return true
	return false

func shock() -> bool:
	if 'Shock' not in curses.effects:
		return false
	# TODO: orange element resist?
	var value = curses.effects['Shock']
	if value > 0:
		log_state('shock', 'value: %d' % value)
		var shock_chance = 100 - int(ceil(100 * (1.0 / (sqrt(value) + 1))))
		var chance = randi() % 100
		var frozen = chance < shock_chance

		log_state('shock', 'chance to be shocked %d < %d = %s' % [chance, shock_chance, frozen])
		if not frozen:
			return false
		else:
			log_message.emit('%s is shocked.' % character_name)
			await sprite.shake(2, 0.05, 10)
			sounds.curses['Shock'].play()
			await get_tree().create_timer(0.75).timeout
			return true
	return false

func shock_accuracy(accuracy) -> int:
	return ceili(accuracy * 0.75)

func take_turn():
	if is_dead(): return

	await pre_logic()

	if await doom(): return
	elif await poison(): return
	elif await banish(): return
	elif await flinch() or await sleep(): end_turn.emit()
	else: await logic()

func pre_logic():
	pass

func logic():
	pass

signal show_description(
	entity_name,
	type,
	effect,
	metadata,
	flavor
)
signal hide_description

func _show_description(
	entity_name,
	type,
	effect,
	metadata,
	flavor
) -> void:
	show_description.emit(
		entity_name,
		type,
		effect,
		metadata,
		flavor
	)

func _show_dictionary_description(d) -> void:
	_show_description(
		d['entity_name'],
		d['type'],
		d['effect'],
		d['metadata'],
		d['flavor'],
	)

func _hide_description():
	hide_description.emit()
