extends Control

var button_builder = preload("res://gemanizer/item_button.gd")

signal show_description
signal hide_description

func add(item):
	var button = button_builder.new()
	button.ignore_texture_size = true
	button.custom_minimum_size = Vector2(64, 64)
	button.stretch_mode = 0
	button.set_item(item)
	button.pressed.connect(button.show_flavor)
	button.mouse_entered.connect(_show_item.bind(item))
	button.mouse_exited.connect(_hide_description)
	$GridContainer.add_child(button)

func _show_item(item):
	var flavor = item['description']['flavor']
	if item['description']['flavor'] and (
		'twitch.tv' in item['description']['flavor'] or 'youtube.com' in item['description']['flavor']):
		flavor = 'Click to watch the clip!'
	show_description.emit(
		item['description']['name'],
		item['description']['type'],
		item['description']['effect'],
		item['description']['metadata'],
		flavor,
	)

func _hide_description():
	hide_description.emit()
