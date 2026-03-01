## PackDemo — 所有 Demo 场景的基类
## 每个 Demo 继承本类并覆写 _setup_demo() 来实现自己的演示内容
extends Node
class_name PackDemo

## 模块名（用于日志标识）
@export var pack_name: String = ""

func _ready() -> void:
	if pack_name.is_empty():
		# 自动从文件名推导
		pack_name = get_script().get_path().get_file().get_basename().replace("_demo", "")
	print("[Demo] %s ready" % pack_name)
	_setup_demo()

## 子类覆写此方法设置演示内容
func _setup_demo() -> void:
	pass

## 工具：在指定 res:// 目录下扫描并实例化所有 .tscn 文件（网格排列）
func spawn_scenes_from_dir(res_dir: String, cols: int = 4, gap: Vector2 = Vector2(220, 180)) -> void:
	var dir := DirAccess.open(res_dir)
	if not dir:
		push_warning("[PackDemo] directory not found: %s" % res_dir)
		return
	dir.list_dir_begin()
	var col := 0
	var row := 0
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name.ends_with(".tscn"):
			var scene: PackedScene = load(res_dir.path_join(name))
			if scene:
				var inst := scene.instantiate()
				inst.position = Vector2(100 + col * gap.x, 100 + row * gap.y)
				add_child(inst)
				col += 1
				if col >= cols:
					col = 0
					row += 1
	dir.list_dir_end()
