extends Control

var stage_tester = preload("res://gem_hunter/stage_tester.tscn")


func _on_start_pressed() -> void:
	$GemHunter.hide()
	$Close.show()
	var stage = stage_tester.instantiate()
	add_child(stage)

func _on_close_pressed() -> void:
	$GemHunter.show()
	$Close.hide()
	remove_child(get_child(-1))
