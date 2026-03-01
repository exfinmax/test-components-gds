extends Node
class_name LocalTimeDomainDependency

@export var local_time_scale: float = 1.0
@export var paused: bool = false

var _participants: Array[Node] = []

func register_participant(node: Node) -> void:
	if node == null or node in _participants:
		return
	if not (node.has_method("_local_time_process") or node.has_method("_local_time_physics_process")):
		return
	_participants.append(node)
	node.set_process(false)
	node.set_physics_process(false)
	node.tree_exiting.connect(_on_participant_exiting.bind(node), CONNECT_ONE_SHOT)

func unregister_participant(node: Node) -> void:
	_participants.erase(node)

func get_scaled_delta(delta: float) -> float:
	if paused:
		return 0.0
	return delta * maxf(local_time_scale, 0.0)

func _process(delta: float) -> void:
	var d := get_scaled_delta(delta)
	if d <= 0.0:
		return
	for node in _participants.duplicate():
		if is_instance_valid(node) and node.has_method("_local_time_process"):
			node.call("_local_time_process", d)

func _physics_process(delta: float) -> void:
	var d := get_scaled_delta(delta)
	if d <= 0.0:
		return
	for node in _participants.duplicate():
		if is_instance_valid(node) and node.has_method("_local_time_physics_process"):
			node.call("_local_time_physics_process", d)

func _on_participant_exiting(node: Node) -> void:
	_participants.erase(node)
