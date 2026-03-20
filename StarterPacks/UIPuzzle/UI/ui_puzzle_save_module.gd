class_name UIPuzzleSaveModule
extends ISaveModule

var pack_root: Node = null

func _init(target: Node = null) -> void:
	pack_root = target

func get_module_key() -> String:
	return "ui_puzzle"

func is_global() -> bool:
	return false

func collect_data() -> Dictionary:
	if pack_root == null or not pack_root.has_method("_collect_puzzle_state"):
		return get_default_data()
	return pack_root.call("_collect_puzzle_state")

func apply_data(data: Dictionary) -> void:
	if pack_root != null and pack_root.has_method("_apply_puzzle_state"):
		pack_root.call("_apply_puzzle_state", data)

func get_default_data() -> Dictionary:
	return {
		"current_tab": 0,
		"solved": {
			"codepad": false,
			"pattern": false,
			"circuit": false,
			"terminal": false,
			"document": false,
		},
		"code_entry": "",
		"terminal_text": "",
		"selected_document": "",
	}
