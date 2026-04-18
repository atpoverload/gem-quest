extends TextureButton

signal show_item(item);
signal drop_item(item);

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


func _use_item():
	if _item:
		drop_item.emit(_item)
		remove_item()
