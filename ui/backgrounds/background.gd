extends CenterContainer

var backgrounds = {};

func log_state(method, message):
	print("(%s)[background.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func load_backgrounds(setting):
	log_state('load_backgrounds', 'loading backgrounds from %s' % setting)
	var dir = DirAccess.open(setting)
	for background in dir.get_files():
		if not background.ends_with('.png'):
			continue
		log_state('load_backgrounds', 'loading %s/%s' % [setting, background])
		backgrounds[int(background.split('.')[0])] = load('%s/%s' % [setting, background])

func _ready() -> void:
	load_backgrounds('res://ui/backgrounds/dungeon')

func set_background(doors):
	$Background.texture = backgrounds[doors]
