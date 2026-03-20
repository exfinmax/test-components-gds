extends RefCounted
class_name GamePackRegistry

var _manifests: Dictionary = {}

func register_manifest(manifest: GamePackManifest) -> void:
	if manifest == null or not manifest.is_valid_manifest():
		return
	_manifests[String(manifest.pack_id)] = manifest

func load_manifest(path: String) -> GamePackManifest:
	var manifest := load(path) as GamePackManifest
	if manifest != null:
		register_manifest(manifest)
	return manifest

func load_manifests(paths: PackedStringArray) -> void:
	for path in paths:
		load_manifest(path)

func get_manifest(pack_id: StringName) -> GamePackManifest:
	return _manifests.get(String(pack_id), null) as GamePackManifest

func get_all_manifests() -> Array[GamePackManifest]:
	var items: Array[GamePackManifest] = []
	for key in _manifests.keys():
		var manifest := _manifests[key] as GamePackManifest
		if manifest != null:
			items.append(manifest)
	items.sort_custom(func(a: GamePackManifest, b: GamePackManifest): return a.display_name.naturalnocasecmp_to(b.display_name) < 0)
	return items

func get_pack_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for manifest in get_all_manifests():
		ids.append(String(manifest.pack_id))
	return ids
