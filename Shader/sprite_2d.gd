extends Sprite2D





# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_distance :Vector2 = get_global_mouse_position()-global_position
	(material as ShaderMaterial).set_shader_parameter("mouse_distance", mouse_distance)
