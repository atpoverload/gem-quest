extends "res://gemanizer/character.gd"

var level = 0
var color = null
var flavor = ''
var actions = {}
var experience = 0
var description = {}

var tumble_stacks = 0

signal flee

func _ready() -> void:
	health = $Stats/Stats/Stats/Health
	curses = $Curses
	blessings = $Blessings
	sprite = $Sprite
	sounds = $EnemySounds
	
	health.disable_text = true
	health.update_bar()

func clear():
	super.clear()
	level = 0
	color = null
	flavor = ''
	actions = {}

func show_enemy():
	_show_description(
		description['entity_name'],
		description['type'],
		description['effect'],
		description['metadata'],
		description['flavor']
	)

func set_enemy(enemy, level_):
	await clear()

	character_name = enemy['name']
	level = level_
	flavor = enemy['flavor']
	if 'color' in enemy:
		color = enemy['color']
	else:
		color = null
	$Name.text = character_name
	$Level.text = 'LVL %2d' % level

	# TODO: vary this?
	var base_health = enemy['health']
	base_health = base_health + level * (randi() % base_health)
	log_state('set_enemy', 'setting health to %d' % base_health)
	health.max_value = base_health
	if 'resistances' in enemy:
		for color_ in enemy['resistances']:
			resistances[color_] = enemy['resistances'][color_]
	actions = enemy['actions']
	$Sprite.texture = enemy['texture']
	await health.adjust(health.max_value)
	experience = enemy['experience']

	var effect = []
	effect.append('Actions:')
	for action in actions:
		effect.append(' %s' % action['name'])
	if len(resistances) > 0:
		effect.append('Resistances:')
		for color_ in resistances:
			effect.append(' %s: %.2f' % [color_, resistances[color_]])
	var entity_type = 'Enemy'
	if color:
		entity_type = '%s Enemy' % color
	description = {
		'entity_name': name,
		'type': entity_type,
		'effect': '\n'.join(effect),
		'metadata': null,
		'flavor': flavor,
	}
	if 'LigMakuni' in character_name:
		blessings.adjust('Tumble', tumble_stacks)

	$EnemySounds/BattleCry.stream = enemy['battlecry']

func arrive():
	unobscure()
	$EnemySounds/BattleCry.play()
	show()
	await $Sprite.arrive()
	await get_tree().create_timer($EnemySounds/BattleCry.stream.get_length()).timeout

func appear():
	unobscure()
	$EnemySounds/BattleCry.play()
	show()
	await get_tree().create_timer($EnemySounds/BattleCry.stream.get_length()).timeout

func obscure():
	$Sprite.obscure()
	$Curses.hide()
	$Stats.hide()
	$Name.hide()
	$Level.hide()
	$Description.hide()

func unobscure():
	$Sprite.reset()
	$Curses.show()
	$Stats.show()
	$Name.show()
	$Level.show()
	$Description.show()

func act():
	await sprite.hop(2, 0.10, 25)

func death():
	if 'LigMakuni' in character_name:
		tumble_stacks += blessings.effects['Tumble']
	$EnemySounds/BattleCry.play()
	await super.death()
	await get_tree().create_timer($EnemySounds/BattleCry.stream.get_length()).timeout

func level_damage(power):
	# damage modifiers
	# TODO: unsure how to scale
	var base_damage = 2 * ceil(level * power)
	var damage = boost_damage(damage_roll(base_damage))
	log_state('level_damage', 'damage %d' % damage)
	return damage

func pre_logic():
	blessings.adjust('Shield', -blessings.effects['Shield'])
	blessings.adjust('Destiny Bond', -blessings.effects['Destiny Bond'])

func logic():
	await take_action()
	end_turn.emit()

func take_action():
	var chance = randi() % 100
	var choice = 0
	for action in actions:
		if chance < choice + action['chance']:
			log_state('logic', 'choosing %s (%d < %d < %d)' % [action['name'], choice, chance, choice + action['chance']])
			log_message.emit('%s %s.' % [character_name, action['text']])
			if not await Callable.create(self, action['action']['type']).call(action['name'], action['action']):
				return
			else: break
		else:
			choice += action['chance']

func Attack(action_name, action):
	log_state('Attack', 'attacking for %s power' % action['power'])
	var action_sound = $EnemySounds/Attack
	if action_name in $EnemySounds.attacks: action_sound = $EnemySounds.attacks[action_name]
	action_sound.play()
	await act()
	await get_tree().create_timer(action_sound.stream.get_length()).timeout

	if await accuracy_check(action.get('accuracy', 100)):
		var damage = level_damage(action['power'])
		damage = await critical_hit(damage)
		if color:
			log_state('Attack', 'attacking for %d %s damage' % [damage, color])
		else:
			log_state('Attack', 'attacking for %d damage' % damage)
		deal_damage.emit(damage, color)
		if 'on_attack' in action:
			_on_attack_effect(
				action,
				action['on_attack']['status'],
				action['on_attack']['chance']
			)
	else:
		await miss()
	await get_tree().create_timer(0.3).timeout

	if await burnt(): return false
	else: return true

func Heal(action_name, action):
	log_state('Heal', 'healing for %s power' % action['power'])
	if await freeze(): return true
	var action_sound = $EnemySounds/Heal
	action_sound.play()
	await act()
	await get_tree().create_timer(action_sound.stream.get_length()).timeout

	health.adjust(ceili(action['power'] * health.max_value / 100))
	await get_tree().create_timer(0.3).timeout

	return true

func DoNothing(action_name, _action):
	log_state("DoNothing", "zzzz")
	var action_sound = $EnemySounds/BattleCry
	action_sound.play()
	await act()
	await get_tree().create_timer(max(action_sound.stream.get_length(), 1.0)).timeout
	return true

func AddCurse(action_name, action):
	log_state('AddCurse', 'applying %s' % action['status'])
	if await freeze(): return true
	var action_sound = $EnemySounds/Curse
	if action_name in $EnemySounds.status: action_sound = $EnemySounds.status[action_name]
	action_sound.play()
	await act()
	await get_tree().create_timer(action_sound.stream.get_length()).timeout

	if await accuracy_check(action.get('accuracy', 100)):
		var power = action['power'] * sqrt(level)
		var status = action['status']
		log_state('AddCurse', 'applying %d stacks of %s' % [power, status])
		apply_curse.emit(status, power, color)
		sounds.curses[status].play()
		await get_tree().create_timer(sounds.curses[status].stream.get_length()).timeout
	else:
		miss()
	await get_tree().create_timer(0.3).timeout
	return true

func AddBlessing(action_name, action):
	log_state('AddBlessing', 'applying %s' % action['status'])
	if await freeze(): return true
	var action_sound = $EnemySounds/Blessing
	if action_name in $EnemySounds.blessings: action_sound = $EnemySounds.blessings[action_name]
	action_sound.play()
	await act()
	await get_tree().create_timer(action_sound.stream.get_length()).timeout

	var power = action['power']
	var status = action['status']
	log_state('AddBlessing', 'applying %d stacks of %s' % [power, status])
	blessed(power, color, status)
	sounds.blessings[status].play()
	await get_tree().create_timer(sounds.blessings[status].stream.get_length()).timeout
	await get_tree().create_timer(0.1).timeout
	return true

func Flee(action_name, action):
	log_state("Flee", "zzzz")
	var action_sound = $EnemySounds/Flee
	action_sound.play()
	await act()
	await get_tree().create_timer(action_sound.stream.get_length()).timeout
	flee.emit()
	return false

func ActTwice(action_name, action):
	log_state("ActTwice", "going twice")
	var action_sound = $EnemySounds/BattleCry
	action_sound.play()
	await $Sprite.hop(5, 0.1, 10)
	await get_tree().create_timer(0.12).timeout
	await get_tree().create_timer(action_sound.stream.get_length()).timeout
	await take_action()
	await get_tree().create_timer(0.3).timeout
	await take_action()
	await get_tree().create_timer(0.3).timeout

func _on_attack_effect(action, effect, on_attack_chance) -> void:
	log_state('_on_attack_effect', 'checking %d%% chance for %s' % [on_attack_chance, effect])
	if trigger_check(on_attack_chance):
		var power = action.get('power', sqrt(level))
		var color = action.get('color', null)
		log_state('on_attack_effect', 'applying %d stacks of %s %s' % [power, color, effect])
		apply_curse.emit(effect, power, color)
		sounds.curses[effect].play()
		await get_tree().create_timer(sounds.curses[effect].stream.get_length()).timeout
		await get_tree().create_timer(0.3).timeout
