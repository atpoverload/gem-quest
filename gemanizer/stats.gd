extends HBoxContainer

@export var strength = 1
@export var magic = 1

signal show_stat(
	stat_name,
	type,
	effect,
	metadata,
	flavor
)

func update_stats():
	$Strength.text = '%d STR' % strength
	$Magic.text = '%d MAG' % magic

func _show_stat(stat):
	match stat:
		'strength': show_stat.emit(
			'Strength',
			'Stat',
			'Related to weapon damage.',
			null,
			'',
		)
		'magic': show_stat.emit(
			'Magic',
			'Stat',
			'Related to gem power.',
			null,
			'',
		)
