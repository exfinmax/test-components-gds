extends ComponentBase
class_name CheckpointMemoryComponent
## 检查点记忆组件（Gameplay/Common 层）
## 作用：记录/恢复对象位置与朝向，可用于轻量重生与解谜重置。

signal checkpoint_saved(position: Vector2)
signal checkpoint_restored(position: Vector2)

@export var save_rotation: bool = false
@export var save_scale: bool = false

var _saved_position: Vector2 = Vector2.ZERO
var _saved_rotation: float = 0.0
var _saved_scale: Vector2 = Vector2.ONE
var _has_checkpoint: bool = false

func save_checkpoint(target: Node2D = null) -> void:
	if not enabled:
		return
	var node := target if target else owner as Node2D
	if not node:
		return
	_saved_position = node.global_position
	_saved_rotation = node.global_rotation
	_saved_scale = node.scale
	_has_checkpoint = true
	checkpoint_saved.emit(_saved_position)

func restore_checkpoint(target: Node2D = null) -> bool:
	if not enabled or not _has_checkpoint:
		return false
	var node := target if target else owner as Node2D
	if not node:
		return false
	node.global_position = _saved_position
	if save_rotation:
		node.global_rotation = _saved_rotation
	if save_scale:
		node.scale = _saved_scale
	checkpoint_restored.emit(_saved_position)
	return true

func clear_checkpoint() -> void:
	_has_checkpoint = false

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"has_checkpoint": _has_checkpoint,
		"position": _saved_position,
		"save_rotation": save_rotation,
		"save_scale": save_scale,
	}

