extends Panel

var log_wait_duration = 1
var elapsed = log_wait_duration # hack so that the first message immediately appears
var messages = []

func add_message(message) -> void:
	messages.append(message)

func clear() -> void:
	messages.clear()
	elapsed = log_wait_duration

func _process(delta: float) -> void:
	if len(messages) > 0 and (elapsed > log_wait_duration / len(messages)):
		$Background/Message/Label.text = messages.pop_front()
		elapsed = 0
	elapsed += delta
