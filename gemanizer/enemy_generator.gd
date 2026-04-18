extends Node

func new_enemy(level):
	return {
		'name': 'Imakuni',
		'health': level,
		'logic': {
			'attack': 25,
			'loaf': 25,
			'yawn': 50,
		}
	}
