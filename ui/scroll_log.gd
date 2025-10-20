extends ScrollContainer

var scroll_speed = 250

func log_state(method, message):
	print("(%s)[scroll_logger.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func add_message(message) -> void:
	log_state('add_message', 'added: %s' % message)
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
