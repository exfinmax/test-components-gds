class_name Card
extends Panel

const SIZE := Vector2(100, 140)

@export var text: String
@onready var label: Label = $Label

var tween:Tween
var current_pos:Vector2

func _ready() -> void:
	label.text = text
	mouse_entered.connect(on_mouse_entered)


func on_mouse_entered() -> void:
	if tween.is_running():
		tween.kill()
	
	tween = create_tween()
	tween.tw
