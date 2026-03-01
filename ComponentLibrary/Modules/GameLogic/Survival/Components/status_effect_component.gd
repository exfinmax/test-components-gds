extends Node
class_name StatusEffectComponent

signal effect_applied(effect_id: StringName, stacks: int)
signal effect_refreshed(effect_id: StringName, remaining: float, stacks: int)
signal effect_ticked(effect_id: StringName, payload: Dictionary, stacks: int)
signal effect_expired(effect_id: StringName)

## effect_id -> { remaining, duration, tick_interval, tick_elapsed, stacks, payload }
var _effects: Dictionary = {}

func add_effect(effect_id: StringName, duration: float, payload: Dictionary = {}, tick_interval: float = 1.0, stacks: int = 1) -> void:
	if effect_id == StringName():
		return

	var safe_duration := maxf(duration, 0.0)
	var safe_interval := maxf(tick_interval, 0.01)
	var safe_stacks := maxi(stacks, 1)

	if _effects.has(effect_id):
		var old_state: Dictionary = _effects[effect_id]
		old_state["remaining"] = maxf(float(old_state.get("remaining", 0.0)), safe_duration)
		old_state["duration"] = maxf(float(old_state.get("duration", safe_duration)), safe_duration)
		old_state["stacks"] = int(old_state.get("stacks", 1)) + safe_stacks
		old_state["payload"] = payload.duplicate(true)
		old_state["tick_interval"] = safe_interval
		_effects[effect_id] = old_state
		effect_refreshed.emit(effect_id, old_state["remaining"], old_state["stacks"])
		return

	_effects[effect_id] = {
		"remaining": safe_duration,
		"duration": safe_duration,
		"tick_interval": safe_interval,
		"tick_elapsed": 0.0,
		"stacks": safe_stacks,
		"payload": payload.duplicate(true),
	}
	effect_applied.emit(effect_id, safe_stacks)

func remove_effect(effect_id: StringName) -> bool:
	if not _effects.has(effect_id):
		return false
	_effects.erase(effect_id)
	effect_expired.emit(effect_id)
	return true

func has_effect(effect_id: StringName) -> bool:
	return _effects.has(effect_id)

func get_effect_stacks(effect_id: StringName) -> int:
	if not _effects.has(effect_id):
		return 0
	return int((_effects[effect_id] as Dictionary).get("stacks", 0))

func clear_effects() -> void:
	var ids := _effects.keys().duplicate()
	_effects.clear()
	for id in ids:
		effect_expired.emit(id)

func _process(delta: float) -> void:
	_tick(delta)

func _local_time_process(delta: float) -> void:
	_tick(delta)

func _tick(delta: float) -> void:
	if _effects.is_empty():
		return

	var expired_ids: Array[StringName] = []
	for effect_id in _effects.keys():
		var state: Dictionary = _effects[effect_id]
		state["remaining"] = maxf(0.0, float(state.get("remaining", 0.0)) - delta)
		state["tick_elapsed"] = float(state.get("tick_elapsed", 0.0)) + delta

		var interval := maxf(float(state.get("tick_interval", 1.0)), 0.01)
		while float(state.get("tick_elapsed", 0.0)) >= interval:
			state["tick_elapsed"] = float(state.get("tick_elapsed", 0.0)) - interval
			effect_ticked.emit(effect_id, state.get("payload", {}), int(state.get("stacks", 1)))

		_effects[effect_id] = state
		if float(state.get("remaining", 0.0)) <= 0.0:
			expired_ids.append(effect_id)

	for effect_id in expired_ids:
		_effects.erase(effect_id)
		effect_expired.emit(effect_id)
