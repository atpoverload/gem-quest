extends StaticBody2D

var width: int = 0
var height: int = 0

func __add_shape():
	if not $CollisionShape2D.shape:
		$CollisionShape2D.shape = SegmentShape2D.new()

func set_width(value):
	__add_shape()
	$Sprite2D.region_rect.size.x = value
	$Sprite2D.position.x = value / 2.0
	$CollisionShape2D.shape.a[0] = 0
	$CollisionShape2D.shape.a[1] = 0
	$CollisionShape2D.shape.b[0] = value
	$CollisionShape2D.shape.b[1] = 0

func set_height(value):
	__add_shape()
	$Sprite2D.region_rect.size.y = value
	$Sprite2D.position.y = value / 2.0
