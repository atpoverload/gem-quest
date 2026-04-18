extends Node

var evolutions = {}

func evolve_item(item1, item2):
	if [item1, item2] in evolutions:
		pass
	if [item2, item1] in evolutions:
		pass

	
