class_name SceneChangeBridge
extends RefCounted

static func change_scene(path: String, properties: Dictionary = {}, min_duration: float = 0.0, loading_properties: Dictionary = {}) -> Error:
	if path.is_empty():
		return ERR_INVALID_PARAMETER
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return ERR_UNAVAILABLE
	var scene_manager := tree.root.get_node_or_null("SceneManager")
	if scene_manager != null and scene_manager.has_method("change_scene_to_file"):
		return int(scene_manager.call("change_scene_to_file", path, properties, min_duration, loading_properties))
	return tree.change_scene_to_file(path)

static func change_scene_to_packed(packed_scene: PackedScene, properties: Dictionary = {}) -> Error:
	if packed_scene == null:
		return ERR_INVALID_PARAMETER
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return ERR_UNAVAILABLE
	var scene_manager := tree.root.get_node_or_null("SceneManager")
	if scene_manager != null and scene_manager.has_method("change_scene_to_packed"):
		return int(scene_manager.call("change_scene_to_packed", packed_scene, properties))
	return tree.change_scene_to_packed(packed_scene)
