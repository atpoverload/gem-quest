extends VBoxContainer

@export var value: int = 50
@export var max_value: int = 100
@export var unit: String = '%'
@export var color: Color = Color.WHITE

var updating = false
var disable_text = false

signal zero_value

func _ready() -> void:
	update_bar()

func update_bar():
	if $Value and not disable_text:
		$Value.text = '%d/%d %s' % [value, max_value, unit]
	elif disable_text:
		$Value.text = ''
	if $Bar/Middle/Bar:
		$Bar/Middle/Bar.value = value
		$Bar/Middle/Bar.max_value = max_value
		var stylebox = $Bar/Middle/Bar.get_theme_stylebox('fill')
		stylebox.bg_color = color
		$Bar/Middle/Bar.add_theme_stylebox_override('fill', stylebox)

func adjust(value_):
	update_bar()

	var new_value = max(min(value_ + value, max_value), 0)
	value_ = max(min(value_, max_value), -max_value)
	var adjustment_time = 0.65 * abs(value_) / max_value

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property($Bar/Middle/Bar, 'value', new_value, adjustment_time)
	if not disable_text:
		tween.tween_method(_update_counter, value, new_value, adjustment_time)
	var old_value = value
	value = new_value
	await tween.finished
	if new_value == 0 and old_value > 0:
		zero_value.emit()

func _update_counter(value_: int):
	$Value.text = '%d/%d %s' % [value_, max_value, unit]
