extends Node2D

signal die
signal win

var event
var credits = 0

#func _ready():
	#start()

func _die() -> void:
	die.emit()

func _win() -> void:
	win.emit()

func start():
	$Player/Sounds/Start.play()
	if $Player.starting_position:
		$Player.position = $Player.starting_position
		Input.warp_mouse($Player.get_global_transform().origin)
	$Player.paused = false

func pause():
	#if $Player.starting_position:
		#$Player.position = $Player.starting_position
	$Player.paused = true
