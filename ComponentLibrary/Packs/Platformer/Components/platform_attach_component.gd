

extends CharacterComponentBase
class_name PlatformAttachComponent
## 平台附着组件（Gameplay/Platformer 层）
## 作用：角色站在移动平台上时，继承平台位移，减少“平台穿滑”体验问题。

@export var floor_ray_length: float = 6.0

var _last_platform_position: Vector2 = Vector2.ZERO
var _current_platform: Node2D = null

func _physics_process(_delta: float) -> void:
	if not self_driven:
		return
	physics_tick(_delta)

func physics_tick(_delta: float) -> void:
	if not enabled or not character:
		return
	if not character.is_on_floor():
		_current_platform = null
		return

	var collider := character.get_last_slide_collision().get_collider() if character.get_slide_collision_count() > 0 else null
	if collider is Node2D:
		var node2d := collider as Node2D
		if _current_platform != node2d:
			_current_platform = node2d
			_last_platform_position = node2d.global_position
		else:
			var delta_pos := node2d.global_position - _last_platform_position
			character.global_position += delta_pos
			_last_platform_position = node2d.global_position

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"has_platform": _current_platform != null,
		"platform_name": _current_platform.name if _current_platform else "",
	}
