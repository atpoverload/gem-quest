extends Panel

signal show_enemy(enemy);

var _enemy = {};

func set_enemy(enemy):
	# just in case!
	_enemy = {
		'name': enemy['name'],
	}
	var description = ['Actions:']
	for action in enemy['logic']:
		description.append(' - %s' % action)
	if 'resistances' in enemy:
		description += ['Resistances:']
		for resistance in enemy['resistances']:
			description.append(' - %s: %0.2f' % [resistance, enemy['resistances'][resistance]])
	_enemy['description'] = '\n'.join(description)
	
	if 'type' in enemy:
		_enemy['type'] = enemy['type']
	if 'flavor' in enemy:
		_enemy['flavor'] = enemy['flavor']
	
func _show_enemy():
	show_enemy.emit(_enemy)
