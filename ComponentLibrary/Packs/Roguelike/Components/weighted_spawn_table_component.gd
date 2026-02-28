extends Node
class_name WeightedSpawnTableComponent

signal rolled(entry_id: StringName, payload: Dictionary)
signal roll_failed

@export var entries: Array[Dictionary] = [
	{"id": &"coin", "weight": 50.0, "payload": {"value": 1}},
	{"id": &"gem", "weight": 20.0, "payload": {"value": 5}},
	{"id": &"potion", "weight": 10.0, "payload": {"heal": 20}},
]

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value

func randomize_seed() -> void:
	_rng.randomize()

func roll_entry() -> Dictionary:
	if entries.is_empty():
		roll_failed.emit()
		return {}

	var total_weight: float = 0.0
	for entry in entries:
		total_weight += maxf(float(entry.get("weight", 0.0)), 0.0)

	if total_weight <= 0.0:
		roll_failed.emit()
		return {}

	var cursor := _rng.randf_range(0.0, total_weight)
	for entry in entries:
		var weight := maxf(float(entry.get("weight", 0.0)), 0.0)
		if cursor <= weight:
			var id: StringName = entry.get("id", StringName())
			var payload: Dictionary = entry.get("payload", {})
			rolled.emit(id, payload)
			return {
				"id": id,
				"payload": payload.duplicate(true),
			}
		cursor -= weight

	roll_failed.emit()
	return {}
