extends HBoxContainer

var status_builder = preload("res://gemanizer/effect.tscn")

var effects = {}
var icons = {}
var descriptions = {}

signal show_effect;
signal hide_effect;

func has_effects():
	for effect in effects:
		if effects[effect] > 0:
			return true
	return false

func update_status():
	for effect in effects:
		if effects[effect] > 0:
			icons[effect].show()
			if effects[effect] > 1:
				icons[effect].get_child(0).text = str(effects[effect])
				icons[effect].get_child(0).show()
			else:
				icons[effect].get_child(0).hide()
		else:
			icons[effect].hide()
			icons[effect].get_child(0).hide()

func set_effects(effects_):
	for child in get_children():
		remove_child(child)
	effects = {}
	icons = {}
	descriptions = {}
	for effect in effects_:
		effects[effect] = 0
		var effect_icon = status_builder.instantiate()
		effect_icon.ignore_texture_size = true
		effect_icon.stretch_mode = 0
		effect_icon.custom_minimum_size = Vector2(64, 64)
		effect_icon.mouse_entered.connect(_show_effect.bind(effect))
		effect_icon.mouse_exited.connect(_hide_effect)
		effect_icon.texture_normal = effects_[effect]['texture']
		if 'flavor' in effects_[effect]:
			effect_icon.flavor = effects_[effect]['flavor']
			effect_icon.pressed.connect(effect_icon.show_flavor)
		icons[effect] = effect_icon
		descriptions[effect] = effects_[effect]['description']
		effect_icon.hide()
		add_child(effect_icon)

func add_effects(effects_):
	for effect in effects_:
		effects[effect] = 0
		var effect_icon = status_builder.instantiate()
		effect_icon.ignore_texture_size = true
		effect_icon.stretch_mode = 0
		effect_icon.custom_minimum_size = Vector2(64, 64)
		effect_icon.mouse_entered.connect(_show_effect.bind(effect))
		effect_icon.mouse_exited.connect(_hide_effect)
		effect_icon.texture_normal = effects_[effect]['texture']
		if 'flavor' in effects_[effect]:
			effect_icon.flavor = effects_[effect]['flavor']
			effect_icon.pressed.connect(effect_icon.show_flavor)
		icons[effect] = effect_icon
		descriptions[effect] = effects_[effect]['description']
		effect_icon.hide()
		add_child(effect_icon)

func adjust(effect, power):
	if effect not in effects:
		return
	effects[effect] = max(0, effects[effect] + int(ceil(power)))
	if effects[effect] > 0:
		icons[effect].show()
		if effects[effect] > 1:
			icons[effect].get_child(0).text = str(effects[effect])
			icons[effect].get_child(0).show()
		else:
			icons[effect].get_child(0).hide()
	else:
		icons[effect].hide()
		icons[effect].get_child(0).hide()

func scale(power, effect):
	if effect not in effects:
		return
	effects[effect] = max(0, int(ceil(effects[effect] * power)))
	if effects[effect] > 0:
		icons[effect].show()
		if effects[effect] > 1:
			icons[effect].get_child(0).text = str(effects[effect])
			icons[effect].get_child(0).show()
		else:
			icons[effect].get_child(0).hide()
	else:
		icons[effect].hide()
		icons[effect].get_child(0).hide()

func remove(effect):
	scale(effect, 0)

func _show_effect(effect):
	show_effect.emit(descriptions[effect])

func _hide_effect():
	hide_effect.emit()
