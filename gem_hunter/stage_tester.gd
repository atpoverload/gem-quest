extends Node2D

var current_stage
var stages = {}

func _ready():
	$Arcade/HBoxContainer.hide()
	var scenario_file = "res://scenarios/demo.yaml"
	var scenario = YAML.load_file(scenario_file).get_data()
	load_arcade_stages(scenario)
	_reset(null)

func load_arcade_stages(scenario):
	for stage in scenario['arcade']['entries']:
		stages[stage] = scenario['arcade']['entries'][stage]
		if not current_stage:
			current_stage = stages[stage]
		var label = Label.new()
		label.text = stage
		$OptionButton.add_item(stage)

func _reset(event: Variant) -> void:
	$Arcade/HBoxContainer.hide()
	$Arcade.stage = current_stage
	$Arcade.event = 'no event here'

func set_stage(stage):
	stage = $OptionButton.get_item_text(stage)
	current_stage = stages[stage]
	_reset(null)

func lose() -> void:
	$Arcade.reset()
	_reset(null)

func start_from_clipboard() -> void:
	# Get the current contents of the clipboard
	var current_clipboard = DisplayServer.clipboard_get()
	$Logger/Background/Message/ScrollLogger.add_message('Loading from clipboard')
	var stage = YAML.try_parse(current_clipboard)
	if stage is Dictionary:
		$Logger/Background/Message/ScrollLogger.add_message('Loaded level from clipboard')
		current_stage = stage
		$Arcade.stage = current_stage
		$Arcade.event = 'no event here'
		$OptionButton.selected = -1
	else:
		$Logger/Background/Message/ScrollLogger.add_message('Unable to load from clipboard')


func save_stage() -> void:
	# Get the current contents of the clipboard
	var stage_yaml = YAML.stringify(current_stage).get_data()
	print(stage_yaml)
	DisplayServer.clipboard_set(stage_yaml)
