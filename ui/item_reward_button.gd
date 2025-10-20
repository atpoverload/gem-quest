extends TextureButton

signal show_item;

var _item = {};

func set_item(user, item):
	# just in case!
	remove_item()
	_item = item;

	texture_normal = item['texture']
	#texture_disabled = item['texture']

	pressed.connect(Callable(user, 'add_item').bind(item))
	show()

func remove_item():
	# clear all the connections
	var n = 0;
	for conn in get_signal_connection_list("pressed"):
		if n < 1:
			n += 1
		else:
			pressed.disconnect(conn.callable)
	_item = {}
	# you don't need to see this anymore
	hide()

func is_empty() -> bool:
	return len(_item) == 0

func _show_item():
	show_item.emit(_item)
