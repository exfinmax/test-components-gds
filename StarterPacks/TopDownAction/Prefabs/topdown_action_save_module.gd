class_name TopDownActionSaveModule
extends ISaveModule

var pack_root: Node = null

func _init(target: Node = null) -> void:
	pack_root = target

func get_module_key() -> String:
	return "top_down_action"

func is_global() -> bool:
	return false

func collect_data() -> Dictionary:
	if pack_root == null or not pack_root.has_method("_collect_save_state"):
		return get_default_data()
	return pack_root.call("_collect_save_state")

func apply_data(data: Dictionary) -> void:
	if pack_root != null and pack_root.has_method("_apply_save_state"):
		pack_root.call("_apply_save_state", data)

func get_default_data() -> Dictionary:
	return {
		"player_position": {"x": 140.0, "y": 180.0},
		"enemy_position": {"x": 600.0, "y": 260.0},
		"player_health": 5,
		"enemy_health": 4,
		"has_key": false,
		"completed": false,
		"last_direction": {"x": 1.0, "y": 0.0},
	}
