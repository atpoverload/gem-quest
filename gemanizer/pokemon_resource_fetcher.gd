extends Node

signal fetched_monster

func get_sprite(monster):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_get_sprite").bind(monster))

	# Perform a GET request. The URL below returns JSON as of writing.
	var error = null
	error = http_request.request("https://raw.githubusercontent.com/atpoverload/my-sprites/refs/heads/main/pkm/%s.png" % monster.replace(' ', '%20'))
	if error != OK:
		push_error("An error occurred in the HTTP request.")

# Called when the HTTP request is completed.
func _get_sprite(_result, _response_code, _headers, body, monster):
	var image = Image.new()
	image.call("load_png_from_buffer", body)
	image.detect_alpha()

	var sprite = ImageTexture.create_from_image(image)

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_get_battlecry").bind(monster, sprite))
	var error = http_request.request('https://play.pokemonshowdown.com/audio/cries/%s.mp3' % monster.replace(' ', '').replace('-', ''))
	if error != OK:
		push_error("An error occurred in the HTTP request.")

func _get_battlecry(_result, _response_code, _headers, body, monster, sprite):
	var battlecry = AudioStreamMP3.load_from_buffer(body)
	fetched_monster.emit(monster, sprite, battlecry)
