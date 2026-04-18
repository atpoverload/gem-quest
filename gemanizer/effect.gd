extends TextureButton

var flavor = ''

func show_flavor() -> void:
	if 'clips.twitch.tv' in flavor or 'youtube.com' in flavor:
		OS.shell_open('https://%s' % flavor)
