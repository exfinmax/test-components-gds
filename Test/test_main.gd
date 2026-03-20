extends Control

const SECTIONS := [
	{
		"title": "Starter Packs",
		"items": [
			{"label": "Meta2D Host", "path": "res://StarterPacks/Meta2DHost/Main.tscn"},
			{"label": "Platformer Action", "path": "res://StarterPacks/PlatformerAction/Main.tscn"},
			{"label": "Narrative UI", "path": "res://StarterPacks/NarrativeUI/Main.tscn"},
			{"label": "TopDown Action", "path": "res://StarterPacks/TopDownAction/Main.tscn"},
			{"label": "UI Puzzle", "path": "res://StarterPacks/UIPuzzle/Main.tscn"},
		],
	},
	{
		"title": "Mainline Demos",
		"items": [
			{"label": "Movement State Demo", "path": "res://ComponentLibrary/Modules/Movement/Demo/movement_state_demo.tscn"},
			{"label": "Combat Demo", "path": "res://ComponentLibrary/Modules/Combat/Demo/combat_demo.tscn"},
			{"label": "UI Demo", "path": "res://ComponentLibrary/Modules/UI/Demo/ui_demo.tscn"},
			{"label": "VFX Demo", "path": "res://ComponentLibrary/Modules/VFX/Demo/vfx_demo.tscn"},
			{"label": "Card Demo", "path": "res://ComponentLibrary/Modules/GameLogic/Card/Demo/card_demo.tscn"},
		],
	},
	{
		"title": "Shader And Test",
		"items": [
			{"label": "Test UI", "path": "res://Test/test_ui.tscn"},
			{"label": "FFT Test", "path": "res://Test/快速傅里叶变换求卷积/快速傅里叶变换求卷积.tscn"},
			{"label": "Black Hole Shader", "path": "res://Shader/黑洞/黑洞.tscn"},
			{"label": "Melt Ball Shader", "path": "res://Shader/融球/融球.tscn"},
		],
	},
	{
		"title": "Addon Self Test",
		"items": [
			{"label": "Enhanced Save Demo", "path": "res://addons/enhance_save_system/demo/enhanced_save_demo.tscn"},
			{"label": "Full Feature Save Demo", "path": "res://addons/enhance_save_system/demo/full_feature_demo.tscn"},
			{"label": "Dialogue Modify Demo", "path": "res://addons/dialogue_manager/modify_test/demo/enhanced_demo.tscn"},
			{"label": "Illustration Dialogue Demo", "path": "res://addons/dialogue_manager/modify_test/demo/illustration_test_scene.tscn"},
		],
	},
]

@onready var _sections: VBoxContainer = %Sections
@onready var _status: Label = %Status

func _ready() -> void:
	_build_sections()

func _build_sections() -> void:
	for child in _sections.get_children():
		child.queue_free()
	for section in SECTIONS:
		var panel := PanelContainer.new()
		var wrapper := VBoxContainer.new()
		wrapper.custom_minimum_size = Vector2(0.0, 0.0)
		wrapper.set("theme_override_constants/separation", 8)
		panel.add_child(wrapper)

		var title := Label.new()
		title.text = str(section["title"])
		title.add_theme_font_size_override("font_size", 24)
		wrapper.add_child(title)

		var grid := GridContainer.new()
		grid.columns = 2
		grid.set("theme_override_constants/h_separation", 8)
		grid.set("theme_override_constants/v_separation", 8)
		wrapper.add_child(grid)

		for item in section["items"]:
			var button := Button.new()
			button.text = str(item["label"])
			button.custom_minimum_size = Vector2(260.0, 48.0)
			button.pressed.connect(_open_scene.bind(str(item["path"])))
			grid.add_child(button)

		_sections.add_child(panel)

func _open_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		_status.text = "Missing: %s" % path
		return
	_status.text = "Opening %s" % path
	get_tree().change_scene_to_file(path)
