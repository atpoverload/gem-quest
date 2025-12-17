extends Label

signal send_code(int);

func add_number(number) -> void:
	text += str(number)

func clear_number() -> void:
	text = ''


func input() -> void:
	var code = int(text)
	text = ''
	send_code.emit(code)
