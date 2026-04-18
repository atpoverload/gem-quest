extends VBoxContainer

var status_builder = preload("res://gemanizer/status.tscn")
var emotes = {}

signal show_emote
signal hide_emote

func add_emote(emote):
	if get_child_count() == 0:
		_create_new_emote_group(emote)
	else:
		var children = get_children()
		children.reverse()
		for emote_group in children:
			if emote['name'] in emote_group.effects:
				emote_group.adjust(emote['name'], 1)
				emotes[emote['name']] += 1
				return
			elif emote_group.get_child_count() < 3:
				emote_group.add_effects({emote['name']: emote})
				emote_group.adjust(emote['name'], 1)
				emotes[emote['name']] = 1
				return
		_create_new_emote_group(emote)

func clear():
	for child in get_children():
		remove_child(child)
	emotes.clear()

func _create_new_emote_group(emote):
	var emote_group = status_builder.instantiate()
	emote_group.set_effects({emote['name']: emote})
	emote_group.adjust(emote['name'], 1)
	emote_group.show_effect.connect(_show_emote)
	emote_group.hide_effect.connect(_hide_emote)
	add_child(emote_group)
	move_child(emote_group, 0)
	emotes[emote['name']] = 1

func _show_emote(emote):
	var flavor = emote['flavor']
	if 'twitch.tv' in emote['flavor'] or 'youtube.com' in emote['flavor']:
		flavor = 'Click to watch the clip!'
	show_emote.emit(
		emote['name'],
		'Emote',
		emote['effect'],
		null,
		flavor
	)

func _hide_emote():
	hide_emote.emit()
