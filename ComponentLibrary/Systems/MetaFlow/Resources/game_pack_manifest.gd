extends Resource
class_name GamePackManifest

@export var pack_id: StringName = &""
@export var genre: StringName = &""
@export_file("*.tscn") var main_scene: String = ""
@export var display_name: String = ""
@export var supports_resume: bool = true
@export var tags: PackedStringArray = PackedStringArray()
@export var entry_transition: StringName = &"fade"
@export var exit_transition: StringName = &"fade"

func is_valid_manifest() -> bool:
	return not String(pack_id).is_empty() and not main_scene.is_empty()

func to_dictionary() -> Dictionary:
	return {
		"pack_id": String(pack_id),
		"genre": String(genre),
		"main_scene": main_scene,
		"display_name": display_name if display_name != "" else String(pack_id),
		"supports_resume": supports_resume,
		"tags": tags,
		"entry_transition": String(entry_transition),
		"exit_transition": String(exit_transition),
	}
