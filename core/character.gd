extends Control

var character_name

var max_health = 0
var resistances = {}

var health = 0
var status = {}
var buffs = {}
var armor = 0

var sprite
var health_bar
var health_label
var status_bar
var buff_bar

signal log_message(message)

signal deal_damage(element, power)
signal apply_status(element, effect, power)
signal pass_turn()

func log_state(method, message):
	print('[character.gd][%s]<%s> %s' % [Time.get_datetime_string_from_system(), method, character_name, message])

func reset():
	set_health(health_bar.max_value)
	for effect in status:
		set_status(effect, 0)

func set_health(value):
	# sanitize the value just in case
	log_state('set_health', 'changing health from %d to %d' % [health, value])
	health = int(max(0, min(value, max_health)))
	log_state('set_health', 'adjusted health to %d' % health)
	if health_label != null:
		health_label.text = '%3s/%3s HP' % [health, max_health]
	var tween = health_bar.create_tween()
	tween.tween_property(health_bar, 'value', health, 2.0 * abs(health_bar.value - health) / health_bar.max_value)
	await tween.finished

func set_status(effect, value):
	# sanitize the value just in case
	value = max(0, value)
	if effect not in status:
		log_state('set_status', 'status %s not present for character' % effect)
		return
	log_state('set_status', 'changing status %s from %d to %d' % [effect, status[effect], value])
	status[effect] = value
	if status[effect] > 0:
		for child in status_bar.get_children():
			if child.name.to_lower() == effect:
				if status[effect] == 1:
					child.get_child(0).hide()
					child.show()
				else:
					child.get_child(0).text = str(status[effect])
					child.get_child(0).show()
					child.show()
	else:
		for child in status_bar.get_children():
			if child.name.to_lower() == effect:
				child.hide()

func set_buff(buff, value):
	# sanitize the value just in case
	value = max(0, value)
	if buff not in buffs:
		log_state('set_buff', 'buff %s not present for character' % buff)
		return
	log_state('set_buff', 'changing buff %s from %d to %d' % [buff, buffs[buff], value])
	buffs[buff] = value
	if buffs[buff] > 0:
		for child in buff_bar.get_children():
			if child.name.to_lower() == buff:
				if buffs[buff] == 1:
					child.get_child(0).hide()
					child.show()
				else:
					child.get_child(0).text = str(buffs[buff])
					child.get_child(0).show()
					child.show()
	else:
		for child in buff_bar.get_children():
			if child.name.to_lower() == buff:
				child.hide()

# things that react to actions
func _die() -> bool:
	log_state('die', 'are they dead yet?')
	if health <= 0:
		log_state('die', 'time to die :(')
		log_message.emit('%s has died' % character_name)
		await sprite.die()
		return true
	return false

func damaged(element, damage):
	var resistance = 1
	if element in resistances:
		resistance = resistances[element]
	var adjusted_damage = resistance * damage - armor
	log_state('damaged', '%s (%.2f) * %d = %d' % [element, resistance, damage, adjusted_damage])
	await sprite.damaged(adjusted_damage / 10 + 1)
	await set_health(health - adjusted_damage)

func gain_status(element: String, effect: String, value: int) -> void:
	log_state('gain_status', 'element: %s, effect: %s, value: %s' % [element, effect, value])

	if value > 0:
		if effect not in status:
			status[effect] = 0
		set_status(effect, status[effect] + value)
		log_message.emit('%s gains %s.' % [character_name, effect])
		await sprite.shake2(3, 0.08, 12).finished

func gain_buff(buff, stacks) -> void:
	log_state('gain_buff', 'buff: %s, stacks: %d' % [buff, stacks])

	if buff not in buffs:
		buffs[buff] = 0
	buffs[buff] += stacks
	log_message.emit('%s gains %s.' % [character_name, buff])
	set_buff(buff, buffs[buff])
	await sprite.attack(1)

func attacked(element, damage):
	if 'shield' in buffs and buffs['shield'] > 0:
		log_state('attacked', 'protected from attacks')
		log_message.emit('%s was protected.' % character_name)
		set_buff('shield', buffs['shield'] - 1)
		$SoundEffects/Shield.playing = true
		await get_tree().create_timer($SoundEffects/Shield.stream.get_length() / 2).timeout
	else:
		await damaged(element, damage)
	if await _die():
		death()
	else:
		await take_turn()

func statused(element: String, effect: String, value: int) -> void:
	gain_status(element, effect, value)
	await take_turn()

func poison() -> bool:
	if 'poison' not in status:
		return false
	var value = status['poison']
	if value > 0:
		log_state('poison', 'value: %d' % value)
		log_message.emit('%s is poisoned.' % character_name)
		$SoundEffects/Poison.playing = true

		await damaged('Poison', value)
		await get_tree().create_timer($SoundEffects/Poison.stream.get_length() / 2).timeout
		return true
	return false

func sleep() -> bool:
	if 'sleep' not in status:
		return false
	var value = status['sleep']
	if value == 0:
		return false
	if value > 0:
		log_state('sleep', 'value: %d' % value)
		log_message.emit('%s is snoozing.' % character_name)
		$SoundEffects/Sleep.playing = true
		await sprite.snooze()
		await get_tree().create_timer(0.25).timeout

	return await wake_up()

func wake_up() -> bool:
	var value = status['sleep']
	var chance = 1.0 / (sqrt(value) + 1)
	var wake_up_chance = randf()
	var awoken = wake_up_chance < chance
	var sleeping = value > 0 and not awoken;

	log_state('wake_up', 'value: %d, chance: %4f, roll: %4f, sleeping: %s' % [value, chance, wake_up_chance, sleeping])

	if sleeping:
		set_status('sleep', max(0, value / 2))
		return true
	else:
		log_message.emit('%s woke up' % character_name)
		await sprite.shake2(2, 0.05, 10)
		set_status('sleep', 0)
		await get_tree().create_timer(0.75).timeout
		return false

func take_turn():
	log_state('take_turn', 'hp: %d, status: %s' % [health, status])
	if await poison() and await _die():
		death()
	elif await sleep():
		pass_turn.emit()
	else:
		await logic()

func death():
	pass

func logic():
	pass
