extends Label

var log_wait_duration = 1
var elapsed = log_wait_duration # hack so that the first message immediately appears
var messages = []

func log_state(method, message):
	print("(%s)[ui_logger.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func set_message():
	text = '\n'.join(messages.slice(0, 2).filter(func(m): return not m.is_empty()))

func add_message(message) -> void:
	log_state('add_message', 'added: %s' % message)
	messages.append(message)

	set_message()

func _process(delta: float) -> void:
	if len(messages) > 1 and (elapsed > log_wait_duration):
		messages.pop_front()
		set_message()
		elapsed = 0

	elapsed += delta
