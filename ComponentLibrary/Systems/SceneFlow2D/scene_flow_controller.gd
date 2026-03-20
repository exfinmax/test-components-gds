extends Node
class_name SceneFlowController

signal pack_mounted(pack_id: StringName, instance: Node)
signal pack_unmounted(pack_id: StringName)

var _current_manifest: GamePackManifest = null
var _current_instance: Node = null

func mount_pack(container: Node, manifest: GamePackManifest, context: Dictionary = {}) -> Node:
	if container == null or manifest == null or not manifest.is_valid_manifest():
		return null
	unmount_current()
	var scene := load(manifest.main_scene) as PackedScene
	if scene == null:
		push_error("SceneFlowController: missing pack scene '%s'" % manifest.main_scene)
		return null
	_current_instance = scene.instantiate()
	_current_manifest = manifest
	container.add_child(_current_instance)
	if _current_instance.has_method("start_pack"):
		_current_instance.call("start_pack", context)
	pack_mounted.emit(manifest.pack_id, _current_instance)
	return _current_instance

func unmount_current() -> void:
	if _current_instance != null:
		var old_pack := _current_manifest.pack_id if _current_manifest != null else &""
		_current_instance.queue_free()
		_current_instance = null
		_current_manifest = null
		if old_pack != &"":
			pack_unmounted.emit(old_pack)

func get_current_manifest() -> GamePackManifest:
	return _current_manifest

func get_current_instance() -> Node:
	return _current_instance
