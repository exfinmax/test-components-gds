extends ComponentBase
class_name ButtonEffectModule

@export var ease_type: Tween.EaseType
@export var trans_type: Tween.TransitionType
@export var anim_duration:float = 0.07
@export var scale_amount:Vector2 = Vector2.ONE * 1.1
@export var rotation_amount:float = 3.

@onready var button:Button = get_parent()

var tween: Tween

func _component_ready() -> void:
	_on_enable()

func _on_disable() -> void:
	button.mouse_entered.disconnect(_on_mouse_hovered.bind(true))
	button.mouse_exited.disconnect(_on_mouse_hovered.bind(false))
	button.pressed.disconnect(_on_button_pressed)
	

func _on_enable() -> void:
	button.mouse_entered.connect(_on_mouse_hovered.bind(true))
	button.mouse_exited.connect(_on_mouse_hovered.bind(false))
	button.pressed.connect(_on_button_pressed)
	button.pivot_offset_ratio = Vector2.ONE / 2

func _on_button_pressed() -> void:
	_reset_tween()
	tween.tween_property(button, "scale", 
		scale_amount, anim_duration).from(Vector2.ONE * .8)
	tween.tween_property(button,"rotation_degrees",
		rotation_amount * [-1,1].pick_random(), anim_duration).from(0)

func _reset_tween() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(ease_type).set_trans(trans_type).set_parallel()

func _on_mouse_hovered(hovered:bool) -> void:
	_reset_tween()
	tween.tween_property(button, "scale", 
		scale_amount if hovered else Vector2.ONE, anim_duration)
	tween.tween_property(button,"rotation_degrees",
		rotation_amount * [-1,1].pick_random() if hovered else 0., anim_duration)
	
