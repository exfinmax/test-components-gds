class_name MetaProgressModule
extends ISaveModule

const DEFAULT_UNLOCKS :PackedStringArray= ([
	"meta_2d_host",
	"narrative_ui",
	"platformer_action",
	"top_down_action",
	"ui_puzzle",
])

var current_chapter: String = "hub"
var current_pack: String = ""
var unlocked_packs: PackedStringArray = DEFAULT_UNLOCKS.duplicate()
var completed_packs: PackedStringArray = PackedStringArray()
var world_flags: Dictionary = {}
var pack_states: Dictionary = {}

func get_module_key() -> String:
	return "meta_progress"

func is_global() -> bool:
	return false

func collect_data() -> Dictionary:
	return {
		"current_chapter": current_chapter,
		"current_pack": current_pack,
		"unlocked_packs": unlocked_packs,
		"completed_packs": completed_packs,
		"world_flags": world_flags.duplicate(true),
		"pack_states": pack_states.duplicate(true),
	}

func apply_data(data: Dictionary) -> void:
	current_chapter = str(data.get("current_chapter", "hub"))
	current_pack = str(data.get("current_pack", ""))
	unlocked_packs = PackedStringArray(data.get("unlocked_packs", DEFAULT_UNLOCKS))
	completed_packs = PackedStringArray(data.get("completed_packs", PackedStringArray()))
	world_flags = (data.get("world_flags", {}) as Dictionary).duplicate(true)
	pack_states = (data.get("pack_states", {}) as Dictionary).duplicate(true)
	_ensure_defaults()

func get_default_data() -> Dictionary:
	return {
		"current_chapter": "hub",
		"current_pack": "",
		"unlocked_packs": DEFAULT_UNLOCKS.duplicate(),
		"completed_packs": PackedStringArray(),
		"world_flags": {},
		"pack_states": {},
	}

func on_new_game() -> void:
	apply_data(get_default_data())

func set_current_context(chapter: String, pack_id: String) -> void:
	current_chapter = chapter
	current_pack = pack_id

func clear_current_pack() -> void:
	current_pack = ""

func unlock_pack(pack_id: String) -> void:
	if pack_id == "" or unlocked_packs.has(pack_id):
		return
	unlocked_packs.append(pack_id)

func complete_pack(pack_id: String, result: Dictionary = {}) -> void:
	if pack_id == "":
		return
	unlock_pack(pack_id)
	if not completed_packs.has(pack_id):
		completed_packs.append(pack_id)
	if not result.is_empty():
		save_pack_state(pack_id, result)

func is_pack_unlocked(pack_id: String) -> bool:
	return unlocked_packs.has(pack_id)

func has_completed(pack_id: String) -> bool:
	return completed_packs.has(pack_id)

func set_flag(flag_name: String, value: Variant = true) -> void:
	world_flags[flag_name] = value

func has_flag(flag_name: String, expected: Variant = true) -> bool:
	return world_flags.get(flag_name, null) == expected

func save_pack_state(pack_id: String, state: Dictionary) -> void:
	if pack_id == "":
		return
	pack_states[pack_id] = state.duplicate(true)

func get_pack_state(pack_id: String) -> Dictionary:
	return (pack_states.get(pack_id, {}) as Dictionary).duplicate(true)

func _ensure_defaults() -> void:
	for pack_id in DEFAULT_UNLOCKS:
		if not unlocked_packs.has(pack_id):
			unlocked_packs.append(pack_id)
