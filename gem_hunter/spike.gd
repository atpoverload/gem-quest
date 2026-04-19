extends Area2D

signal damage;

func spike(body: Node2D) -> void:
	if 'Player' in body.name and (abs(body.velocity.y) > 0 or abs(body.last_velocity.y) > 0):
		var already_hit = body.hit
		body.jump(body.JUMP_SPEED)
		if not body.hit:
			body.direction = -body.direction / 2.0
		body.hit = true
		if not already_hit and body.wait != 2.0:
			body.elapsed = 0.0
			body.wait = 2.0
			body.get_child(2).get_child(0).play()
			await get_tree().create_timer(1.0).timeout
			damage.emit()
