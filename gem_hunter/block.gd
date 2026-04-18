extends CharacterBody2D

var width: int = 0
var height: int = 0

func __add_shape():
	if not $CollisionShape2D.shape:
		$CollisionShape2D.shape = RectangleShape2D.new()

func set_width(value):
	__add_shape()
	$Sprite2D.region_rect.size.x = value
	$CollisionShape2D.shape.size.x = value

func set_height(value):
	__add_shape()
	$Sprite2D.region_rect.size.y = value
	$CollisionShape2D.shape.size.y = value

func _physics_process(delta):
	velocity.y += delta * 1000
	move_and_slide()
