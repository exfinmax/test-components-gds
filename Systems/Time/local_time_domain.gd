extends Node
class_name LocalTimeDomain

signal local_time_scale_changed(value: float)
signal paused_changed(value: bool)
signal participant_registered(node: Node)
signal participant_unregistered(node: Node)

@export var local_time_scale: float = 1.0:
	set(v):
		var safe_value := maxf(v, 0.0)
		if is_equal_approx(local_time_scale, safe_value):
			return
		local_time_scale = safe_value
		local_time_scale_changed.emit(local_time_scale)

@export var paused: bool = false:
	set(v):
		if paused == v:
			return
		paused = v
		paused_changed.emit(paused)

@export var auto_scan_on_ready: bool = true
@export var scan_recursive: bool = true

var _participants: Array[Node] = []
var _participant_modes: Dictionary = {}

func _ready() -> void:
	if auto_scan_on_ready:
		rescan_participants()

func get_scaled_delta(delta: float) -> float:
	if paused:
		return 0.0
	return delta * local_time_scale

func set_time_scale(value: float) -> void:
	local_time_scale = value

func set_paused(value: bool) -> void:
	paused = value

func pause_for(duration: float) -> void:
	if duration <= 0.0:
		return
	paused = true
	await get_tree().create_timer(duration, true, false, true).timeout
	paused = false

func register_participant(node: Node) -> void:
	if node == null or node == self or node in _participants:
		return
	if not (node.has_method("_local_time_process") or node.has_method("_local_time_physics_process")):
		return

	_participants.append(node)
	_participant_modes[node.get_instance_id()] = {
		"process": node.is_processing(),
		"physics": node.is_physics_processing(),
	}
	node.set_process(false)
	node.set_physics_process(false)
	node.tree_exiting.connect(_on_participant_exiting.bind(node), CONNECT_ONE_SHOT)
	participant_registered.emit(node)

func unregister_participant(node: Node) -> void:
	if node == null:
		return
	_participants.erase(node)
	_restore_participant_mode(node)
	participant_unregistered.emit(node)

func rescan_participants() -> void:
	for node in _participants:
		_restore_participant_mode(node)
	_participants.clear()
	_participant_modes.clear()

	if scan_recursive:
		_scan_recursive(self)
	else:
		for child in get_children():
			register_participant(child)

func get_participant_count() -> int:
	return _participants.size()

func _process(delta: float) -> void:
	var scaled_delta := get_scaled_delta(delta)
	if scaled_delta <= 0.0:
		return

	for node in _participants.duplicate():
		if is_instance_valid(node) and node.has_method("_local_time_process"):
			node.call("_local_time_process", scaled_delta)

func _physics_process(delta: float) -> void:
	var scaled_delta := get_scaled_delta(delta)
	if scaled_delta <= 0.0:
		return

	for node in _participants.duplicate():
		if is_instance_valid(node) and node.has_method("_local_time_physics_process"):
			node.call("_local_time_physics_process", scaled_delta)

func _scan_recursive(root: Node) -> void:
	for child in root.get_children():
		register_participant(child)
		_scan_recursive(child)

func _on_participant_exiting(node: Node) -> void:
	_participants.erase(node)
	_participant_modes.erase(node.get_instance_id())

func _restore_participant_mode(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var key := node.get_instance_id()
	if not _participant_modes.has(key):
		return
	var mode: Dictionary = _participant_modes[key]
	node.set_process(bool(mode.get("process", true)))
	node.set_physics_process(bool(mode.get("physics", true)))
	_participant_modes.erase(key)
