extends Control

var backgrounds = {}
var music = {}

func _ready():
	for child in $Background.get_children():
		backgrounds[child.name] = child
	for child in $Music.get_children():
		music[child.name] = child

func set_background(background):
	for b in backgrounds:
		backgrounds[b].hide()
	backgrounds[background].show()

func set_music(song):
	if not music[song].is_playing():
		for s in music:
			music[s].stop()
		music[song].play()
