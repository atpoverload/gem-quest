extends Control

signal log_message(string);

signal use_item;
signal drop_item;
signal show_item;
signal hide_item;
signal next_event;

func log_state(method, message):
	print("(%s)[inventory.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func _ready():
	$Drinks/Drink1.hide()
	$Drinks/Drink2.hide()
	$Drinks/Drink3.hide()
	$Drinks/Drink4.hide()
	$Gems/Gem1.hide()
	$Gems/Gem2.hide()
	$Food.hide()
	$Weapon.hide()

func _use_item(item):
	use_item.emit(item)

func _show_item(item):
	var item_name = item['description']['name']
	if 'genned_name' in item:
		item_name = item['genned_name']
	show_item.emit(
		item_name,
		item['description']['type'],
		item['description']['effect'],
		item['description']['metadata'],
		item['description']['flavor'],
	)

func _hide_item():
	hide_item.emit()

func add_item(item):
	if 'type' not in item:
		return
	log_state('add_item', 'adding %s' % item['name'])
	match item['type']:
		'Weapon': add_weapon(item)
		'Gem': add_gem(item)
		'Drink': add_drink(item)
		'Food': add_food(item)

func add_weapon(item):
	$InventorySounds/GetItem.play()
	log_message.emit('Got a %s' % item['name'])
	$Weapon.set_item(item)
	next_event.emit()

func add_gem(item):
	for gem in [$Gems/Gem1, $Gems/Gem2]:
		if gem.is_empty():
			$InventorySounds/GetItem.play()
			log_message.emit('Got a %s' % item['name'])
			gem.set_item(item)
			next_event.emit()
			return
	for gem in [$Gems/Gem1, $Gems/Gem2]:
		gem.enable()
	drop_item.emit(item)

func enable_gem():
	for gem in [$Gems/Gem1, $Gems/Gem2]:
		gem.enable()

func add_drink(item):
	# TODO: this is very hacky
	for drink in [$Drinks/Drink1, $Drinks/Drink2, $Drinks/Drink3, $Drinks/Drink4]:
		if drink.is_empty():
			$InventorySounds/GetItem.play()
			log_message.emit('Got a %s' % item['name'])
			drink.set_item(item)
			drink.get_child(0).text = '1'
			drink.get_child(0).hide()
			next_event.emit()
			return
		elif item['name'] == drink._item['name'] and item['action'] == drink._item['action']:
			$InventorySounds/GetItem.play()
			drink.get_child(0).text = str(int(drink.get_child(0).text) + 1)
			drink.get_child(0).show()
			next_event.emit()
			return
	for drink in [$Drinks/Drink1, $Drinks/Drink2, $Drinks/Drink3, $Drinks/Drink4]:
		drink.enable()
	drop_item.emit(item)

func add_food(item):
	$InventorySounds/GetItem.play()
	log_message.emit('Got a %s' % item['name'])
	$Food.set_item(item)
	next_event.emit()

func add_freebie_item(item):
	if 'type' not in item:
		return
	log_state('add_freebie_item', 'adding %s' % item['name'])
	match item['type']:
		'Drink': add_freebie_drink(item)
		'Food': add_freebie_food(item)
		_: pass

func add_freebie_drink(item):
	for drink in [$Drinks/Drink1, $Drinks/Drink2, $Drinks/Drink3, $Drinks/Drink4]:
		if drink.is_empty():
			$InventorySounds/GetItem.play()
			#log_message.emit('Got a %s' % item['name'])
			drink.set_item(item)
			drink.get_child(0).text = '1'
			drink.get_child(0).hide()
			#next_event.emit()
			return
		elif item['name'] == drink._item['name'] and item['action'] == drink._item['action']:
			$InventorySounds/GetItem.play()
			drink.get_child(0).text = str(int(drink.get_child(0).text) + 1)
			drink.get_child(0).show()
			#next_event.emit()
			return
	for drink in [$Drinks/Drink1, $Drinks/Drink2, $Drinks/Drink3, $Drinks/Drink4]:
		drink.enable()
	#drop_item.emit(item)

func add_freebie_food(item):
	$InventorySounds/GetItem.play()
	#log_message.emit('Got a %s' % item['name'])
	$Food.set_item(item)

func enable(_obj) -> void:
	$Drinks/Drink1.enable()
	$Drinks/Drink2.enable()
	$Drinks/Drink3.enable()
	$Drinks/Drink4.enable()
	$Gems/Gem1.enable()
	$Gems/Gem2.enable()
	$Food.enable()
	$Weapon.enable()

func enable2() -> void:
	$Drinks/Drink1.enable()
	$Drinks/Drink2.enable()
	$Drinks/Drink3.enable()
	$Drinks/Drink4.enable()
	$Gems/Gem1.enable()
	$Gems/Gem2.enable()
	$Food.enable()
	$Weapon.enable()

func disable(_obj) -> void:
	$Drinks/Drink1.disable()
	$Drinks/Drink2.disable()
	$Drinks/Drink3.disable()
	$Drinks/Drink4.disable()
	$Gems/Gem1.disable()
	$Gems/Gem2.disable()
	$Food.disable()
	$Weapon.disable()

func clear():
	$Drinks/Drink1.remove_item()
	$Drinks/Drink2.remove_item()
	$Drinks/Drink3.remove_item()
	$Drinks/Drink4.remove_item()
	$Gems/Gem1.remove_item()
	$Gems/Gem2.remove_item()
	$Food.remove_item()
	$Weapon.remove_item()

func remove_item(item) -> void:
	log_state('remove_item', 'checking for %s' % item['name'])
	var item_name = item['description']['name']
	#if 'genned_name' in item:
		#item_name = item['genned_name']
	match item['type']:
		'Weapon':
			if not $Weapon.is_empty() and item_name == $Weapon._item['name']:
				item = $Weapon
		'Gem':
			if not $Gems/Gem1.is_empty() and item_name == $Gems/Gem1._item['name']:
				if $Gems/Gem2.is_empty():
					item = $Gems/Gem1
				else:
					$Gems/Gem1.set_item($Gems/Gem2._item)
					item = $Gems/Gem2
			elif not $Gems/Gem2.is_empty() and item_name == $Gems/Gem2._item['name']:
				item = $Gems/Gem2
		'Drink':
			if not $Drinks/Drink1.is_empty() and item_name == $Drinks/Drink1._item['name']:
				item = $Drinks/Drink1
			elif not $Drinks/Drink2.is_empty() and item_name == $Drinks/Drink2._item['name']:
				item = $Drinks/Drink2
			elif not $Drinks/Drink3.is_empty() and item_name == $Drinks/Drink3._item['name']:
				item = $Drinks/Drink3
			elif not $Drinks/Drink4.is_empty() and item_name == $Drinks/Drink4._item['name']:
				item = $Drinks/Drink4
		'Food':
			if not $Food.is_empty() and item_name == $Food._item['name']:
				item = $Food
		_: item = null
	if not item:
		log_state('remove_item', 'did not find %s' % item['name'])
	elif item._item['type'] == 'Drink' and int(item.get_child(0).text) > 1:
		var old_count = int(item.get_child(0).text)
		var count = old_count - 1
		log_state('remove_item', 'reducing %s from %s to %s' % [item['name'], old_count, count])
		item.get_child(0).text = str(count)
		if count < 2:
			item.get_child(0).hide()
		else:
			item.get_child(0).show()
		item.show()
	else:
		log_state('remove_item', 'removing %s' % item['name'])
		await item.remove_item()

func act() -> void:
	for entity in [$Weapon, $Gems/Gem1, $Hands, $Hands2]:
		var tween = get_tree().create_tween()
		tween.set_parallel()
		var hops = 2 * 2 + 1
		for i in range(hops):
			tween.tween_property(entity, "position", entity.position - Vector2(0, 25 * (i % 2)), 0.10).set_delay(0.10 * i)
		tween.set_parallel(false)

func _on_player_eat_food() -> void:
	if not $Food.is_empty():
		$Food._use_item()
