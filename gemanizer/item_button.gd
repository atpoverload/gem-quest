extends TextureButton

signal show_item(item);
signal use_item(item);
signal take_item(item);

var _item = {};

func enable():
	disabled = false
	modulate = Color.WHITE

func disable():
	disabled = true
	modulate = Color.DIM_GRAY

func set_item(item):
	# just in case!
	remove_item()
	_item = item

	texture_normal = item['texture']
	var image = texture_normal.get_image()
	# Create the BitMap
	var bitmap = BitMap.new()
	# Fill it from the image alpha
	bitmap.create_from_image_alpha(image)
	# Assign it to the mask
	texture_click_mask = bitmap
	show()

func remove_item():
	_item = {}
	hide()

func is_empty() -> bool:
	return len(_item) == 0

func _show_item():
	show_item.emit(_item)
	#if not disabled:
		#modulate = Color.AZURE

func _use_item():
	if _item:
		use_item.emit(_item)
		if 'type' in _item:
			match _item['type']:
				'Drink':
					var old_count = int($Label.text)
					var count = old_count - 1
					#log_state('remove_item', 'reducing %s from %s to %s' % [item['name'], old_count, count])
					$Label.text = str(count)
					if count == 0:
						remove_item()
					elif count == 1:
						$Label.hide()
					else:
						$Label.show()
				'Food':
					remove_item()

func _take_item():
	take_item.emit(_item)

func show_flavor() -> void:
	if _item['flavor'] and 'clips.twitch.tv' in _item['flavor']:
		OS.shell_open('https://%s' % _item['flavor'])
