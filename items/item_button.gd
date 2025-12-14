extends TextureButton

signal show_item(item);
signal use_item(item);
signal take_item(item);

var _item = {};

func set_item(item):
	# just in case!
	remove_item()
	_item = item

	texture_normal = item['texture']
	show()

func remove_item():
	_item = {}
	hide()

func is_empty() -> bool:
	return len(_item) == 0

func _show_item():
	show_item.emit(_item)

func _use_item():
	if _item:
		use_item.emit(_item)
		match _item['type']:
			'drink', 'food':
				remove_item()

func _take_item():
	take_item.emit(_item)
