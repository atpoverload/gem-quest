extends Area2D

const WALK_SPEED = 200.0

func spike(body: Node2D) -> void:
	var dim = $Sprite2D.scale.x * $Sprite2D.texture.get_width()
	# TODO: doesn't seem to work as expected
	if 'Player' in body.name and body.velocity.y > 0:
		body.push(self)
