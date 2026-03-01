extends PackDemo

func _ready():
	pack_name = "VFX"
	super._ready()

func _populate_demo():
	_vfx_spawn_from_dir("res://ComponentLibrary/Packs/VFX/Templates", 0, 0)
	var comp_path = "res://ComponentLibrary/Packs/VFX/Components/impact_vfx_component.gd"
	if ResourceLoader.exists(comp_path):
		var comp = load(comp_path).new()
		add_child(comp)
		comp.play_at(Vector2(300,200))

func _vfx_spawn_from_dir(dirpath:String, x_offset:float, y_offset:float):
	var dir = DirAccess.open(dirpath)
	if not dir:
		return
	var x = 0
	var y = 0
	while true:
		var file = dir.get_next()
		if file == "":
			break
		var full = dirpath + "/" + file
		if dir.current_is_dir():
			_vfx_spawn_from_dir(full, x_offset + x*200, y_offset + y*150)
		elif file.ends_with(".tscn"):
			var scene = load(full)
			if scene:
				var inst = scene.instantiate()
				inst.position = Vector2(x_offset + x*200 + 100, y_offset + y*150 + 100)
				add_child(inst)
				x += 1
				if x > 3:
					x = 0
					y += 1
