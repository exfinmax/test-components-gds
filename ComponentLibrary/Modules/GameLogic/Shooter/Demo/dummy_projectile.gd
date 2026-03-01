extends Node2D

var velocity: Vector2 = Vector2.ZERO
@export var lifetime: float = 1.2

func set_velocity(v: Vector2) -> void:
	velocity = v

func _process(delta: float) -> void:
	global_position += velocity * delta
	lifetime = maxf(lifetime - delta, 0.0)
	if lifetime <= 0.0:
		queue_free()
