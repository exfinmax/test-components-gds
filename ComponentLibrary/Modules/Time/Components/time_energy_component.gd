extends ComponentBase
class_name TimeEnergyComponent
## 时间能量组件（Gameplay/Time 层）
## 作用：管理时间能力专属能量池（消耗、恢复、暂停恢复）。

signal energy_changed(current: float, max_value: float)
signal exhausted
signal recovered

@export var max_energy: float = 100.0
@export var regen_per_second: float = 20.0
@export var regen_delay: float = 0.4
@export var self_driven: bool = true

var current_energy: float = 100.0
var _regen_block_timer: float = 0.0

func _ready() -> void:
	if not self_driven:
		set_process(false)
	_component_ready()
	current_energy = clampf(current_energy, 0.0, max_energy)
	energy_changed.emit(current_energy, max_energy)

func _process(delta: float) -> void:
	if not self_driven:
		return
	tick(delta)

func tick(delta: float) -> void:
	if not enabled:
		return
	if _regen_block_timer > 0.0:
		_regen_block_timer -= delta
		return
	if regen_per_second > 0.0 and current_energy < max_energy:
		var prev := current_energy
		current_energy = minf(max_energy, current_energy + regen_per_second * delta)
		if not is_equal_approx(prev, current_energy):
			energy_changed.emit(current_energy, max_energy)
			if prev <= 0.0 and current_energy > 0.0:
				recovered.emit()

func consume(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if current_energy < amount:
		return false
	var prev := current_energy
	current_energy = maxf(0.0, current_energy - amount)
	_regen_block_timer = regen_delay
	energy_changed.emit(current_energy, max_energy)
	if prev > 0.0 and current_energy <= 0.0:
		exhausted.emit()
	return true

func refill(amount: float) -> void:
	if amount <= 0.0:
		return
	var prev := current_energy
	current_energy = minf(max_energy, current_energy + amount)
	if not is_equal_approx(prev, current_energy):
		energy_changed.emit(current_energy, max_energy)
		if prev <= 0.0 and current_energy > 0.0:
			recovered.emit()

func set_max_energy(value: float, keep_ratio: bool = true) -> void:
	var ratio := 1.0 if max_energy <= 0.0 else current_energy / max_energy
	max_energy = maxf(0.0, value)
	current_energy = clampf(ratio * max_energy, 0.0, max_energy) if keep_ratio else minf(current_energy, max_energy)
	energy_changed.emit(current_energy, max_energy)

func get_ratio() -> float:
	if max_energy <= 0.0:
		return 0.0
	return current_energy / max_energy

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"current_energy": current_energy,
		"max_energy": max_energy,
		"ratio": get_ratio(),
		"regen_per_second": regen_per_second,
		"regen_delay": regen_delay,
		"regen_block_timer": _regen_block_timer,
	}
