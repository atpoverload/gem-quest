extends Control

var stage_builder = preload('res://gem_hunter/gem_hunter.tscn')
var stage = null
var event = null

signal win(event);

func start():
	var stage_ = stage_builder.instantiate()
	var player = stage_.get_child(-3)
	player.win.connect(reset)
	stage_.position = Vector2(250, 45)
	stage_.build_level(stage)

	$Sprite2D.hide()
	$Start.hide()
	$Border.show()
	#$HBoxContainer.show()
	add_child(stage_)

func reset():
	remove_child(get_child(-1))
	$Sprite2D.show()
	$Start.show()
	$Border.hide()
	stage = null
	#$HBoxContainer.hide()
	if event:
		win.emit(event)
