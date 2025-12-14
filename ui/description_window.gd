extends MarginContainer

func show_description(entity):
	$Description/Description/DescriptionDivider/Name/Label.text = entity['name']
	if 'type' in entity:
		$Description/Description/DescriptionDivider/Type/Label.text = entity['type']
	else:
		$Description/Description/DescriptionDivider/Type/Label.text = 'Enemy'
	$Description/Description/DescriptionDivider/Description/Label.text = entity['description']
	if 'flavor' in entity:
		$Description/Description/DescriptionDivider/Flavor/Label.text = entity['flavor']
	else:
		$Description/Description/DescriptionDivider/Flavor/Label.text = ''
	visible = true

func show_item(item) -> void:
	$Description/Description/DescriptionDivider/Name/Label.text = item['name']
	if 'element' in item:
		$Description/Description/DescriptionDivider/Type/Label.text = item['element'] + ' ' + item['type']
	else:
		$Description/Description/DescriptionDivider/Type/Label.text = item['type']
	if 'accuracy' in item:
		$Description/Description/DescriptionDivider/Description/Label.text = '\n'.join([item['description'], 'ACC: %3d%%' % item['accuracy']])
	else:
		$Description/Description/DescriptionDivider/Description/Label.text = item['description']
	$Description/Description/DescriptionDivider/Flavor/Label.text = item['flavor']
	visible = true
