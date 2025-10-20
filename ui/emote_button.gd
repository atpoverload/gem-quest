extends TextureRect

signal show_item;

var _item = {};

func set_item(item):
	_item = item;
	texture = item['texture']

func _show_item():
	show_item.emit(_item)
