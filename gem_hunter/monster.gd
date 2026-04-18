extends CharacterBody2D

var gravity: int = 500
var jump_strength: int = 250
var walk_speed: int = 0
var hop_wait: float = 0.5

var elapsed = hop_wait

func _physics_process(delta):
	velocity.x = walk_speed
	if elapsed > hop_wait and velocity.y == 0:
		velocity.y -= jump_strength
		elapsed = 0
	else:
		velocity.y += delta * gravity * (abs(velocity.y) / (gravity / 10.0) + 1)
		elapsed += delta

	if move_and_slide():
		var collision = get_last_slide_collision()
		var collider = collision.get_collider()
		if 'Block' in collider.name or \
		   'Monster' in collider.name or \
		   'Treasure' in collider.name or \
		   'Wall' in collider.name or \
		   'Player' in collider.name:
			flip()

func flip():
	walk_speed = -walk_speed
	scale.x = -scale.x
