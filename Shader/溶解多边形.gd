@tool
extends Polygon2D

@onready var mat := material as ShaderMaterial

func _ready():
	update_proj_range()

func update_proj_range():
	var dir = (mat.get_shader_parameter("direction") as Vector2).normalized()
	var min_proj = INF
	var max_proj = -INF
	for v in polygon:
		var proj = v.dot(dir)
		if proj < min_proj:
			min_proj = proj
		if proj > max_proj:
			max_proj = proj
	mat.set_shader_parameter("min_proj", min_proj)
	mat.set_shader_parameter("max_proj", max_proj)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		update_proj_range()
