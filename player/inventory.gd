extends MarginContainer

signal log_message(string);
signal next_event;
signal sell_item(reward);

var next_item = null;

var equip_sounds = {
	'weapon': load('res://player/sounds/equip-weapon.mp3'),
	'gem': load('res://player/sounds/equip-gem.mp3'),
	'drink': load('res://player/sounds/equip-drink.mp3'),
	'food': load('res://player/sounds/equip-weapon.mp3'),
}

func log_state(method, message):
	print("(%s)[inventory.gd][%s] %s" % [Time.get_datetime_string_from_system(), method, message])

func add_item(item, starting=false):
	log_state("add_item", "adding %s" % item)
	var item_button = null;
	match item['type']:
		'weapon':
			item_button = $Inventory/Inventory/Items/Weapon/Button
		'gem':
			var i = 1
			for gem in $Inventory/Inventory/Items/Items/Gems.get_children():
				if gem.get_child(1).is_empty():
					item_button = gem.get_child(1)
					break
				elif gem.get_child(1)._item['name'] == item['name']:
					log_state("add_item", "already have %s" % item['name'])
					sell_item_2('gem%d' % i)
					item_button = gem.get_child(1)
					starting = true
					break
				i += 1
		'drink':
			for drink in $Inventory/Inventory/Items/Items/Drinks.get_children():
				if drink.get_child(1).is_empty():
					item_button = drink.get_child(1)
					break
		'food':
			item_button = $Inventory/Inventory/Items/Food/Button
	if item_button:
		if not item_button.is_empty():
			log_state("add_item", "selling existing item %s" % item_button._item)
			#log_message.emit('Selling %s' % item_button._item['name'])

			log_state("add_item", "adding to slot %s" % item)
			$SoundEffect.stream = equip_sounds[item['type']]
			$SoundEffect.playing = true
			sell_item_(item['type'])
			item_button.set_item(item)
			await get_tree().create_timer(0.5).timeout
		else:
			log_state("add_item", "found empty slot for %s" % item)
			item_button.set_item(item)
			$SoundEffect.stream = equip_sounds[item['type']]
			$SoundEffect.playing = true
			if starting:
				await get_tree().create_timer($SoundEffect.stream.get_length() - 0.25).timeout

			if not starting:
				next_event.emit()
	else:
		log_state("add_item", "no slot found for %s" % item)
		match item['type']:
			'gem':
				log_message.emit('Need to trash a Gem!')
				$Inventory/Inventory/Items/Items/Gems/Gem1/DropItem.show()
				$Inventory/Inventory/Items/Items/Gems/Gem2/DropItem.show()
				next_item = item
				log_state("add_item", "no slot found for %s" % item)
			'drink':
				log_message.emit('Need to trash a Drink!')
				$Inventory/Inventory/Items/Items/Drinks/Drink1/DropItem.show()
				$Inventory/Inventory/Items/Items/Drinks/Drink2/DropItem.show()
				$Inventory/Inventory/Items/Items/Drinks/Drink3/DropItem.show()
				next_item = item
				log_state("add_item", "no slot found for %s" % item)

func remove_item(item):
	match item:
		'weapon': $Inventory/Inventory/Items/Weapon/Button.remove_item()
		'gem1': $Inventory/Inventory/Items/Items/Gems/Gem1/Button.remove_item()
		'gem2': $Inventory/Inventory/Items/Items/Gems/Gem2/Button.remove_item()
		'drink1': $Inventory/Inventory/Items/Items/Drinks/Drink1/Button.remove_item()
		'drink2': $Inventory/Inventory/Items/Items/Drinks/Drink2/Button.remove_item()
		'drink3': $Inventory/Inventory/Items/Items/Drinks/Drink3/Button.remove_item()
		'food': $Inventory/Inventory/Items/Food/Button.remove_item()

func sell_item_(item):
	log_state("sell_item_", "selling item %s" % item)
	# TODO: find a formula to compute a price
	var price = 0
	match item:
		'weapon':
			price = $Inventory/Inventory/Items/Weapon/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Weapon/Button._item['name'])
		'gem1':
			price = $Inventory/Inventory/Items/Items/Gems/Gem1/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Items/Gems/Gem1/Button._item['name'])
		'gem2':
			price = $Inventory/Inventory/Items/Items/Gems/Gem2/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Items/Gems/Gem2/Button._item['name'])
		'drink1':
			price = $Inventory/Inventory/Items/Items/Drinks/Drink1/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Items/Drinks/Drink1/Button._item['name'])
		'drink2':
			price = $Inventory/Inventory/Items/Items/Drinks/Drink2/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Items/Drinks/Drink2/Button._item['name'])
		'drink3':
			price = $Inventory/Inventory/Items/Items/Drinks/Drink3/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Items/Drinks/Drink3/Button._item['name'])
		'food':
			price = $Inventory/Inventory/Items/Food/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Food/Button._item['name'])
	remove_item(item)

	$Inventory/Inventory/Items/Items/Gems/Gem1/DropItem.hide()
	$Inventory/Inventory/Items/Items/Gems/Gem2/DropItem.hide()
	$Inventory/Inventory/Items/Items/Drinks/Drink1/DropItem.hide()
	$Inventory/Inventory/Items/Items/Drinks/Drink2/DropItem.hide()
	$Inventory/Inventory/Items/Items/Drinks/Drink3/DropItem.hide()

	#sell_item.emit(100 * price)
	sell_item.emit()
	if next_item != null:
		item = next_item
		next_item = null
		add_item(item, true)
	#else:
		#await get_tree().create_timer(1).timeout
		#next_event.emit()

func sell_item_2(item):
	log_state("sell_item_2", "selling item %s" % item)
	var price = 0
	match item:
		'weapon':
			price = $Inventory/Inventory/Items/Weapon/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Weapon/Button._item['name'])
		'gem1':
			price = $Inventory/Inventory/Items/Items/Gems/Gem1/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Items/Gems/Gem1/Button._item['name'])
		'gem2':
			price = $Inventory/Inventory/Items/Items/Gems/Gem2/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Items/Gems/Gem2/Button._item['name'])
		'drink1':
			price = $Inventory/Inventory/Items/Items/Drinks/Drink1/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Items/Drinks/Drink1/Button._item['name'])
		'drink2':
			price = $Inventory/Inventory/Items/Items/Drinks/Drink2/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Items/Drinks/Drink2/Button._item['name'])
		'drink3':
			price = $Inventory/Inventory/Items/Items/Drinks/Drink3/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Items/Drinks/Drink3/Button._item['name'])
		'food':
			price = $Inventory/Inventory/Items/Food/Button._item['rarity']
			log_message.emit('Trashing %s' % $Inventory/Inventory/Items/Food/Button._item['name'])
	remove_item(item)

	$Inventory/Inventory/Items/Items/Gems/Gem1/DropItem.hide()
	$Inventory/Inventory/Items/Items/Gems/Gem2/DropItem.hide()
	$Inventory/Inventory/Items/Items/Drinks/Drink1/DropItem.hide()
	$Inventory/Inventory/Items/Items/Drinks/Drink2/DropItem.hide()
	$Inventory/Inventory/Items/Items/Drinks/Drink3/DropItem.hide()

	#sell_item.emit(100 * price)
	sell_item.emit()

func break_gem(item):
	if $Inventory/Inventory/Items/Items/Gems/Gem1/Button._item == item:
		$Inventory/Inventory/Items/Items/Gems/Gem1/Button.remove_item()
	elif $Inventory/Inventory/Items/Items/Gems/Gem2/Button._item == item:
		$Inventory/Inventory/Items/Items/Gems/Gem2/Button.remove_item()

func clear():
	remove_item('weapon')
	remove_item('gem1')
	remove_item('gem2')
	remove_item('drink1')
	remove_item('drink2')
	remove_item('drink3')
	remove_item('food')

func enable():
	log_state('enable', 'enabling items')
	$Inventory/Inventory/Items/Weapon/Button.disabled = false
	$Inventory/Inventory/Items/Weapon/Button.modulate = Color('White')
	for child in $Inventory/Inventory/Items/Items/Gems.get_children():
		child.get_child(1).disabled = false
		child.get_child(1).modulate = Color('White')
	for child in $Inventory/Inventory/Items/Items/Drinks.get_children():
		child.get_child(1).disabled = false
		child.get_child(1).modulate = Color('White')
	$Inventory/Inventory/Items/Food/Button.modulate = Color('White')

func disable():
	log_state('enable', 'disabling items')
	$Inventory/Inventory/Items/Weapon/Button.disabled = true
	$Inventory/Inventory/Items/Weapon/Button.modulate = Color('555555')
	for child in $Inventory/Inventory/Items/Items/Gems.get_children():
		child.get_child(1).disabled = true
		child.get_child(1).modulate = Color('555555')
	for child in $Inventory/Inventory/Items/Items/Drinks.get_children():
		child.get_child(1).disabled = true
		child.get_child(1).modulate = Color('555555')
	$Inventory/Inventory/Items/Food/Button.modulate = Color('555555')
