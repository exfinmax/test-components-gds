extends Camera2D
class_name RoomCameraComponent

@export var follow_target: NodePath
@export_range(0.0, 1.0, 0.01) var follow_lerp: float = 0.18
@export var clamp_to_room: bool = true
@export var room_rect: Rect2 = Rect2(-100000.0, -100000.0, 200000.0, 200000.0)

func _process(_delta: float) -> void:
	var target := get_node_or_null(follow_target) as Node2D
	if target == null:
		return
	var next_position := global_position.lerp(target.global_position, follow_lerp)
	if clamp_to_room:
		next_position.x = clampf(next_position.x, room_rect.position.x, room_rect.end.x)
		next_position.y = clampf(next_position.y, room_rect.position.y, room_rect.end.y)
	global_position = next_position
