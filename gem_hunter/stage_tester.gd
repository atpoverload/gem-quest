extends Node2D

var current_stage
var stages = {}

func _ready():
	var scenario_file = "res://scenarios/demo.yaml"
	var scenario = YAML.load_file(scenario_file).get_data()
	load_arcade_stages(scenario)
	_reset(null)

func load_arcade_stages(scenario):
	for stage in scenario['arcade']['entries']:
		if not current_stage:
			current_stage = stage
		stages[stage] = scenario['arcade']['entries'][stage]
		var label = Label.new()
		label.text = stage
		$OptionButton.add_item(stage)

func _reset(event: Variant) -> void:
	$Arcade.stage = stages[current_stage]
	$Arcade.event = 'no event here'

func set_stage(stage):
	stage = $OptionButton.get_item_text(stage)
	current_stage = stage
	_reset(null)

func lose() -> void:
	$Arcade.reset()
	_reset(null)
