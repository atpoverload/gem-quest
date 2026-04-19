extends Control

var stage_builder = preload('res://gem_hunter/gem_hunter.tscn')
var stage = null
var event = null
var credits = 0

signal win(event);
signal lose;

func start():
	var stage_ = stage_builder.instantiate()
	var player = stage_.get_child(-3)
	player.win.connect(reset)
	stage_.position = Vector2(250, 45)
	stage_.build_level(stage)
	for hazard in stage_.get_child(5).get_children():
		hazard.damage.connect(Callable.create(self, "damage"))

	$Sprite2D.hide()
	$Start.hide()
	$Border.show()
	$HBoxContainer.show()
	add_child(stage_)
	move_child(stage_, -2)
	$Start/Confirm.play()
	await get_tree().create_timer(0.4).timeout

func reset():
	if get_child(-2).name != 'Border':
		remove_child(get_child(-2))
	$Sprite2D.show()
	$Start.show()
	if $Border:
		$Border.hide()
	stage = null
	if $HBoxContainer:
		$HBoxContainer.hide()
	if event:
		win.emit(event)

func damage():
	if stage and event:
		lose.emit()
