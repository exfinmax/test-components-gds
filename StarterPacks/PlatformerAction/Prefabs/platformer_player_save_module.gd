class_name PlatformerPlayerSaveModule
extends ISaveModule

var player: Node = null
var default_position: Vector2 = Vector2.ZERO

func _init(target: Node = null, spawn_position: Vector2 = Vector2.ZERO) -> void:
	player = target
	default_position = spawn_position

func is_global() -> bool:
	return false

func get_module_key() -> String:
	return "platformer_player"

func collect_data() -> Dictionary:
	if player == null:
		return get_default_data()
	var health := player.get_node_or_null("%HealthComponent")
	return {
		"position": {
			"x": player.global_position.x,
			"y": player.global_position.y,
		},
		"health": health.current_health if health != null else 0.0,
		"is_dead": bool(player.get("is_dead")) if player != null else false,
	}

func apply_data(data: Dictionary) -> void:
	if player == null:
		return
	var position_data :Dictionary= data.get("position", {})
	if position_data is Dictionary:
		player.global_position = Vector2(
			float(position_data.get("x", default_position.x)),
			float(position_data.get("y", default_position.y))
		)
	else:
		player.global_position = default_position
	if player.has_method("reset_death"):
		player.reset_death()
	var health := player.get_node_or_null("%HealthComponent")
	if health != null:
		health.current_health = float(data.get("health", health.max_health))
		health.health_changed.emit(health.get_health_percent())

func get_default_data() -> Dictionary:
	return {
		"position": {
			"x": default_position.x,
			"y": default_position.y,
		},
		"health": 10.0,
		"is_dead": false,
	}
