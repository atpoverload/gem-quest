extends Sprite2D

var original_position;
var original_scale;
var last_tweens = [];

func _ready() -> void:
	original_scale = scale
	original_position = position

func reset():
	scale = original_scale
	#position = original_position
	#if last_tween:
		#last_tween.kill()
	modulate = Color(1, 1, 1, 1)

func reset2():
	#scale = original_scale
	if original_position:
		position = original_position
	original_position = null
	for tween in last_tweens:
		tween.kill()
	last_tweens.clear()
	#modulate = Color(1, 1, 1, 1)

func hop(hops: int, delay: float, height: float) -> Tween:
	var tween = get_tree().create_tween()
	tween.set_parallel()
	hops = 2 * hops + 1
	if not original_position:
		original_position = Vector2(position.x, position.y)
	var pos = original_position
	for i in range(hops):
		tween.tween_property(self, "position", pos - Vector2(0, height * (i % 2)), delay).set_delay(delay * i)
	tween.set_parallel(false)
	last_tweens.append(tween)
	return tween

#func hop2(hops: int, delay: float, height: float):
	#return hop(get_tree().create_tween(), hops, delay, height)

func shake(shakes: int, delay: float, dist: float):
	var tween = get_tree().create_tween()
	tween.set_parallel()
	shakes = 2 * shakes - 2
	for i in range(shakes):
		tween.tween_property(self, "position", position - Vector2(dist * (2 * (i % 2) - 1), 0), delay).set_delay(delay * i)
	tween.tween_property(self, "position", position, delay).set_delay(delay * shakes)
	tween.set_parallel(false)
	return tween

#func shake2(shakes: int, delay: float, dist: float):
	#return shake(get_tree().create_tween(), shakes, delay, dist)

func arrive():
	var hops = 3
	var delay = 0.075
	var height = 25
	var start = Vector2(0.2, 0.2)
	var end = scale

	scale = start
	var tween = hop(hops, delay, height)
	tween.set_parallel(true)
	tween.tween_property(self, "scale", end, delay * (2 * hops + 1))
	tween.set_parallel(false)
	await tween.finished

func leave():
	var hops = 3
	var delay = 0.075
	var height = 25
	var start = scale
	var end = Vector2(0.2, 0.2)

	scale = start
	var tween = hop(hops, delay, height)
	tween.set_parallel(true)
	tween.tween_property(self, "scale", end, delay * (2 * hops + 1))
	tween.set_parallel(false)
	await tween.finished

func damaged(power: int):
	var size = sqrt(1.0 - power / 20.0)
	var start = scale * size
	var end = scale
	var delay = 0.15

	var tween = get_tree().create_tween()
	tween.set_parallel()
	tween.tween_property(self, "modulate", Color(0.5, 0.5, 0.5, 0.25), delay)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), delay).set_delay(delay)
	tween.tween_property(self, "scale", start, delay)
	tween.tween_property(self, "scale", end, delay).set_delay(delay)
	tween.set_parallel(false)
	await tween.finished

func attack(power: int):
	var size = (1 / sqrt(1.0 - power / 20.0))**2
	var start = scale * size
	var end = scale
	var delay = 0.10

	var tween = get_tree().create_tween()
	tween.set_parallel()
	tween.tween_property(self, "scale", start, delay)
	tween.tween_property(self, "scale", end, delay).set_delay(delay)
	tween.set_parallel(false)
	await tween.finished

func die():
	var start = scale * 1.25
	var delay = 0.5

	var tween = get_tree().create_tween()
	tween.set_parallel()
	tween.tween_property(self, "modulate", Color(0.0, 0.0, 0.0, 0.0), delay).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", start, delay).set_trans(Tween.TRANS_SINE)
	tween.set_parallel(false)
	await tween.finished

func snooze():
	var delay = 0.20
	var tween = shake(3, delay, 18)
	await tween.finished

func loaf():
	var delay = 0.40
	var tween = shake(3, delay, 28)
	await tween.finished

func obscure():
	modulate = Color(0.25, 0.25, 0.25)
