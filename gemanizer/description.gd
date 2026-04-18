extends MarginContainer

func show_description(
	entity_name,
	type,
	effect,
	metadata,
	flavor
):
	#await get_tree().create_timer(0.10).timeout
	$Description/Description/Description/Name.text = entity_name
	$Description/Description/Description/Type.text = type
	$Description/Description/Description/Effect.text = effect
	if metadata == null or len(metadata) == 0:
		$Description/Description/Description/Metadata.hide()
	else:
		$Description/Description/Description/Metadata.text = metadata
		$Description/Description/Description/Metadata.show()
	if flavor:
		$Description/Description/Description/Flavor.text = flavor
	else:
		$Description/Description/Description/Flavor.text = ''
	visible = true
	$AudioStreamPlayer2D.play()
