extends HBoxContainer

func add_choice(event):
	var button: TextureButton = TextureButton.new()
	#button.pressed.connect()
	button.texture_normal = event['texture']
	#button.pressed.connect
