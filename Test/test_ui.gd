extends Control

@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var load_button: Button = $VBoxContainer/LoadButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	save_button.pressed.connect(SaveManager.save_game)
	load_button.pressed.connect(SaveManager.load_game)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
