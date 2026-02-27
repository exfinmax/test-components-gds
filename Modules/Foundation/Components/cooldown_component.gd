extends ComponentBase
class_name CooldownComponent

signal cooldown_started(tag: StringName, duration: float)
signal cooldown_ready(tag: StringName)
signal cooldown_updated(tag: StringName, remaining: float, duration: float)

@export var self_driven: bool = true

var _cooldowns: Dictionary = {}

func _ready() -> void:
	if not self_driven:
		set_process(false)
	_component_ready()

func _process(delta: float) -> void:
	if not self_driven:
		return
	tick(delta)

func tick(delta: float) -> void:
	if not enabled:
		return
	if _cooldowns.is_empty():
		return

	var finished: Array[StringName] = []
	for tag in _cooldowns.keys():
		var data: Dictionary = _cooldowns[tag]
		var remaining: float = maxf(0.0, data["remaining"] - delta)
		data["remaining"] = remaining
		_cooldowns[tag] = data
		cooldown_updated.emit(tag, remaining, data["duration"])
		if remaining <= 0.0:
			finished.append(tag)

	for tag in finished:
		_cooldowns.erase(tag)
		cooldown_ready.emit(tag)

func start_cooldown(tag: StringName, duration: float) -> void:
	if duration <= 0.0:
		_cooldowns.erase(tag)
		cooldown_ready.emit(tag)
		return
	_cooldowns[tag] = {"duration": duration, "remaining": duration}
	cooldown_started.emit(tag, duration)

func clear_cooldown(tag: StringName) -> void:
	if _cooldowns.erase(tag):
		cooldown_ready.emit(tag)

func clear_all() -> void:
	var tags := _cooldowns.keys()
	_cooldowns.clear()
	for tag in tags:
		cooldown_ready.emit(tag)

func is_ready(tag: StringName) -> bool:
	return not _cooldowns.has(tag)

func get_remaining(tag: StringName) -> float:
	if not _cooldowns.has(tag):
		return 0.0
	return (_cooldowns[tag] as Dictionary).get("remaining", 0.0)

func get_duration(tag: StringName) -> float:
	if not _cooldowns.has(tag):
		return 0.0
	return (_cooldowns[tag] as Dictionary).get("duration", 0.0)

func get_component_data() -> Dictionary:
	var tags: Dictionary = {}
	for tag in _cooldowns:
		var data: Dictionary = _cooldowns[tag]
		tags[String(tag)] = {
			"remaining": data["remaining"],
			"duration": data["duration"],
		}
	return {
		"enabled": enabled,
		"count": _cooldowns.size(),
		"cooldowns": tags,
	}
