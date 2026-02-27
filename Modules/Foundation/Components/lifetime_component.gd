extends ComponentBase
class_name LifetimeComponent

signal expired

@export var lifetime_seconds: float = 1.0
@export var auto_start: bool = true
@export var destroy_on_expire: bool = true
@export var self_driven: bool = true

var _running: bool = false
var _remaining: float = 0.0

func _ready() -> void:
	if not self_driven:
		set_process(false)
	_component_ready()
	if auto_start:
		start(lifetime_seconds)

func _process(delta: float) -> void:
	if not self_driven:
		return
	tick(delta)

func tick(delta: float) -> void:
	if not enabled or not _running:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		_running = false
		expired.emit()
		if destroy_on_expire and owner:
			owner.queue_free()

func start(duration: float = -1.0) -> void:
	if duration >= 0.0:
		lifetime_seconds = duration
	_running = true
	_remaining = maxf(0.0, lifetime_seconds)

func stop() -> void:
	_running = false

func reset() -> void:
	_running = true
	_remaining = maxf(0.0, lifetime_seconds)

func get_remaining() -> float:
	return _remaining if _running else 0.0

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"lifetime_seconds": lifetime_seconds,
		"running": _running,
		"remaining": get_remaining(),
		"destroy_on_expire": destroy_on_expire,
	}
