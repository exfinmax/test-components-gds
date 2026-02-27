extends ComponentBase
class_name PeriodicSpawnerComponent
## 周期生成组件（Gameplay/Common 层）
## 作用：按固定间隔生成对象，可用于陷阱子弹、循环特效、环境机关。

signal spawned(node: Node)

@export var scene: PackedScene
@export var interval: float = 1.0
@export var auto_start: bool = true
@export var spawn_parent: Node
@export var self_driven: bool = true

var _running: bool = false
var _timer: float = 0.0

func _ready() -> void:
	if not self_driven:
		set_process(false)
	_component_ready()
	if auto_start:
		start()

func _process(delta: float) -> void:
	if not self_driven:
		return
	tick(delta)

func tick(delta: float) -> void:
	if not enabled or not _running:
		return
	if interval <= 0.0:
		_spawn_once()
		return
	_timer += delta
	while _timer >= interval:
		_timer -= interval
		_spawn_once()

func start() -> void:
	_running = true

func stop() -> void:
	_running = false

func spawn_now() -> Node:
	return _spawn_once()

func _spawn_once() -> Node:
	if not scene:
		return null
	var parent := spawn_parent if spawn_parent else owner
	if not parent:
		parent = self
	var node := scene.instantiate()
	parent.add_child(node)
	spawned.emit(node)
	return node

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"running": _running,
		"interval": interval,
		"has_scene": scene != null,
		"has_spawn_parent": spawn_parent != null,
	}

