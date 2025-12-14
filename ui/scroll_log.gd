extends ScrollContainer

var scroll_speed = 250
var messages = []

func log_state(method, message):
	print("(%s)[scroll_logger.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func add_message(message) -> void:
	log_state('add_message', 'added: %s' % message)
	messages.append(message)

func _process(_delta: float):
	while len(messages) > 0:
		var message = messages.pop_front()
		log_state('_process', 'showing: %s' % message)
		var label = Label.new()
		label.text = message
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		$VBoxContainer.add_child(label)
		if label.get_theme_default_font().get_string_size(message).x > 300:
			label.add_theme_font_size_override(
				'font_size',
				int(label.get_theme_default_font_size() * 0.75)
			)
		var start = get_v_scroll_bar().value
		var end = get_v_scroll_bar().max_value

		var tween = create_tween()
		tween.tween_property(self, "scroll_vertical", get_v_scroll_bar().max_value + 100, (end - start) / scroll_speed)
		await tween.finished
		await get_tree().create_timer(0.7).timeout
