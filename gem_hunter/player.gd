extends CharacterBody2D

const WALK_SPEED = 200.0
const JUMP_SPEED = -1000.0
const GRAVITY = 150.0
var wait = 0.5
var elapsed = wait

var health: int = 3

var hit = false

signal win

var direction = 0

func _ready():
	Input.warp_mouse(global_position)

func _input(_event):
	if not hit:
		if abs(velocity.y) <= 0 and Input.is_action_pressed("jump"):
			jump(JUMP_SPEED)
		elif Input.is_action_pressed("left"):
			direction = -1
		elif Input.is_action_pressed("right"):
			direction = 1
		else:
			direction = 0

func _physics_process(delta):
	if direction != 0:
		velocity.x = direction * WALK_SPEED
		if not hit:
			$Sprite2D.scale.x = -direction * abs($Sprite2D.scale.x)
		Input.warp_mouse(global_position)
	elif not hit:
		var dist = global_position.x - get_global_mouse_position().x
		var dir = 0
		if dist <= -5:
			dir = 1
		elif dist >= 5:
			dir = -1
		velocity.x = dir * WALK_SPEED
		if dir != 0:
			$Sprite2D.scale.x = -dir * abs($Sprite2D.scale.x)
		Input.warp_mouse(Vector2(global_position.x + dir * min(200, abs(dist)), global_position.y))
	else:
		velocity.x = 0
	velocity.y += delta * GRAVITY * (abs(velocity.y) / 10 + 1)
	if abs(velocity.y) > 5:
		velocity.x *= 1.25

	move()

	elapsed += delta
	if elapsed > wait:
		hit = false

func move():
	if move_and_slide():
		var collision = get_last_slide_collision()
		var collider = collision.get_collider()
		if 'Monster' in collider.name:
			jump(JUMP_SPEED)
			if position.y > collider.position.y - 25:
				hit = true
				direction = -direction / 2.0
				elapsed = 0
		elif 'Block' in collider.name or 'Floor' in collider.name:
			hit = false
		elif 'Treasure' in collider.name and not $Sounds/Treasure.playing:
			$Sounds/Treasure.play()
			await get_tree().create_timer($Sounds/Treasure.stream.get_length()).timeout
			win.emit()

func damage(): if not $Sounds/Damage.playing: $Sounds/Damage.play()

func jump(jump_speed):
	$Sounds/Jump.play()
	velocity.y = jump_speed

func turn_left(walk_speed):
	velocity.x = -walk_speed
	if $Sprite2D.scale.x < 0:
		$Sprite2D.scale.x = abs($Sprite2D.scale.x)

func turn_right(walk_speed):
	velocity.x = -walk_speed
	if $Sprite2D.scale.x < 0:
		$Sprite2D.scale.x = abs($Sprite2D.scale.x)
