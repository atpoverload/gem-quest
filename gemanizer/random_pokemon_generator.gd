extends Node

var monsters = {}
var action_pool

func fetch_monster(monster):
	monsters[monster['name']] = monster
	$PokemonResourceFetcher.get_sprite(monster['name'])

func add_monster(monster_name: String, sprite, battlecry):
	var monster = monsters[monster_name[0].to_upper() + monster_name.substr(1)]
	monster['texture'] = sprite
	monster['battlecry'] = battlecry
	var exp = int(ceil(sqrt(monster['bst'])))
	exp = exp + randi() % exp
	monster['experience'] = exp
	monster['health'] = 1
	monster['actions'] = [{
		'name': 'Splash',
		'action' : {
			'type': 'DoNothing',
		},
		'chance': 100
	}]
	monster['flavor'] = 'Gimme 60 HP.'
	monsters.append(monster)

func random_monster():
	return monsters.pick_random()
