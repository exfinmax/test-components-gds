extends Node

@export var pack_name: String = ""

func _ready():
	if pack_name != "":
		print("%s demo ready" % pack_name)
	_default_populate()
	# allow pack-specific extension
	if has_method("_populate_demo"):
		_populate_demo()

func _default_populate():
	if pack_name == "":
		return
	var base = "res://ComponentLibrary/Packs/%s/Components".format(pack_name)
	var dir = DirAccess.open(base)
	if not dir:
		return
	_spawn_in_dir(dir, base, 0, 0)

func _spawn_in_dir(dir:DirAccess, path:String, x:int, y:int) -> Array:
	while true:
		var name = dir.get_next()
		if name == "":
			break
		var fullpath = path + "/" + name
		if dir.current_is_dir():
			var sub = DirAccess.open(fullpath)
			if sub:
				var res = _spawn_in_dir(sub, fullpath, x, y)
				x = res[0]; y = res[1]
		elif name.ends_with(".tscn"):
			var scene = load(fullpath)
			if scene:
				var inst = scene.instantiate()
				inst.position = Vector2(100 + x*200, 100 + y*150)
				add_child(inst)
				x += 1
				if x > 3:
					x = 0; y += 1
	return [x,y]
