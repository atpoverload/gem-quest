extends Node

func log_state(name, method, message):
	print("(%s)[%s][%s] %s" % [Time.get_datetime_string_from_system(), name, method, message])
