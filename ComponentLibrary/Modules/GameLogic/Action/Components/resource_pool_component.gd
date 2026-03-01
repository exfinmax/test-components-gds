extends ComponentBase
class_name ResourcePoolComponent

signal value_changed(current: float, max_value: float)
signal depleted
signal refilled

@export var max_value: float = 100.0
@export var start_full: bool = true
@export var regen_per_second: float = 0.0
@export var self_driven: bool = true

var current_value: float = 0.0

func _ready() -> void:
	if not self_driven:
		set_process(false)
	_component_ready()
	current_value = max_value if start_full else 0.0
	value_changed.emit(current_value, max_value)

func _process(delta: float) -> void:
	if not self_driven:
		return
	tick(delta)

func tick(delta: float) -> void:
	if not enabled:
		return
	if regen_per_second > 0.0:
		restore(regen_per_second * delta)

func consume(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if current_value < amount:
		return false
	var prev := current_value
	current_value = maxf(0.0, current_value - amount)
	_emit_changes(prev)
	return true

func restore(amount: float) -> void:
	if amount <= 0.0:
		return
	var prev := current_value
	current_value = minf(max_value, current_value + amount)
	_emit_changes(prev)

func set_max_value(value: float, keep_ratio: bool = true) -> void:
	var ratio := 1.0 if max_value <= 0.0 else current_value / max_value
	max_value = maxf(0.0, value)
	var prev := current_value
	current_value = clampf(ratio * max_value, 0.0, max_value) if keep_ratio else minf(current_value, max_value)
	_emit_changes(prev)

func set_current_value(value: float) -> void:
	var prev := current_value
	current_value = clampf(value, 0.0, max_value)
	_emit_changes(prev)

func is_depleted() -> bool:
	return current_value <= 0.0

func get_ratio() -> float:
	if max_value <= 0.0:
		return 0.0
	return current_value / max_value

func _emit_changes(prev: float) -> void:
	if is_equal_approx(prev, current_value):
		return
	value_changed.emit(current_value, max_value)
	if prev > 0.0 and current_value <= 0.0:
		depleted.emit()
	elif prev < max_value and current_value >= max_value:
		refilled.emit()

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"current": current_value,
		"max": max_value,
		"ratio": get_ratio(),
		"regen_per_second": regen_per_second,
	}
