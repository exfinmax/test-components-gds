extends CharacterComponentBase
class_name AirJumpComponent
## 空中跳组件（Gameplay/Platformer 层）
## 作用：提供双跳/多段跳能力，和 JumpComponent 解耦。

signal air_jumped(remaining: int)

@export var max_air_jumps: int = 1
@export var air_jump_speed: float = 520.0
@export var reset_on_floor: bool = true
@export var input_component: InputComponent

var remaining_air_jumps: int = 0

func _component_ready() -> void:
	if not input_component:
		input_component = find_component(InputComponent) as InputComponent
	if input_component:
		input_component.jump_pressed.connect(_on_jump_pressed)
	remaining_air_jumps = max_air_jumps

func _physics_process(_delta: float) -> void:
	if not self_driven:
		return
	if not enabled or not character:
		return
	if reset_on_floor and character.is_on_floor():
		remaining_air_jumps = max_air_jumps

func _on_jump_pressed() -> void:
	if not enabled or not character:
		return
	if character.is_on_floor():
		return
	if remaining_air_jumps <= 0:
		return
	remaining_air_jumps -= 1
	character.velocity.y = -air_jump_speed
	air_jumped.emit(remaining_air_jumps)

func refill() -> void:
	remaining_air_jumps = max_air_jumps

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"max_air_jumps": max_air_jumps,
		"remaining_air_jumps": remaining_air_jumps,
		"air_jump_speed": air_jump_speed,
	}
