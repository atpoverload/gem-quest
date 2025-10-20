extends MarginContainer

func show_description(item):
	$Background/Description/DescriptionDivider/Name/Label.text = item['name']
	if item['type'] in ['weapon', 'gem'] and 'element' in item:
		$Background/Description/DescriptionDivider/Type/Label.text = '%s %s' % [item['element'], item['type']]
	else:
		$Background/Description/DescriptionDivider/Type/Label.text = item['type']
	$Background/Description/DescriptionDivider/Description/Label.text = item['description']
	if 'accuracy' in item:
		$Background/Description/DescriptionDivider/Accuracy/Label.text = 'Accuracy: %3s%%' % item['accuracy']
		$Background/Description/DescriptionDivider/Accuracy/Label.show()
	else:
		$Background/Description/DescriptionDivider/Accuracy/Label.hide()
	$Background/Description/DescriptionDivider/Flavor/Label.text = item['flavor']
