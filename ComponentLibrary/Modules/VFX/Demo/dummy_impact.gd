extends Node2D

@export var lifetime: float = 0.25

func _process(delta: float) -> void:
	lifetime = maxf(lifetime - delta, 0.0)
	if lifetime <= 0.0:
		queue_free()
