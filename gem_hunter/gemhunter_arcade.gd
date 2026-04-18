extends Node2D

var level = 0
var scenario
var logger

var stage = 0
var stage_obj

func _ready():
	stage = 0
	$Start.show()
	remove_child(stage_obj)
	$Border.hide()
	Input.warp_mouse($Start.get_transform().origin)
	#$HBoxContainer.hide()

func start():
	stage = 0
	next_stage()

func next_stage():
	if stage > 4:
		stage_obj.pause()
		$Win.play()
		await get_tree().create_timer($Win.stream.get_length() / 2.0).timeout
		_ready()
	else:
		remove_child(stage_obj)

		stage += 1
		stage_obj = load("res://gemhunter/stage%s.tscn" % stage).instantiate()

		stage_obj.credits = 2
		stage_obj.position = Vector2(250, 110)
		stage_obj.win.connect(next_stage)
		stage_obj.die.connect(_ready)
		stage_obj.die.connect($Lose.play)
		#$HBoxContainer/Label.text = '%sx' % stage_obj.credits

		$Start.hide()
		$Border.show()
		#$HBoxContainer.show()
		add_child(stage_obj)
		move_child(stage_obj, -2)

		stage_obj.start()
