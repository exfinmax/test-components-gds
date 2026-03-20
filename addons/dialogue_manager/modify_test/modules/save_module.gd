class_name SaveModule
extends BalloonModule
## ════════════════════════════════════════════════════════════════
## SaveModule — 存档模块
## ════════════════════════════════════════════════════════════════
##
## 对接 SaveSystem 单例，在每行对话时自动保存进度。
## SaveSystem 不存在时静默跳过，不产生任何错误。
## ════════════════════════════════════════════════════════════════

@export_group("存档设置")
## 是否自动保存对话进度
@export var auto_save_progress: bool = true
## 存档章节名（显示在存档槽中）
@export var chapter_name: String = ""

# ════════════════════════════════════════════════════════════════
# 内部状态
# ════════════════════════════════════════════════════════════════

var _current_resource: DialogueResource = null

# ════════════════════════════════════════════════════════════════
# BalloonModule 接口
# ════════════════════════════════════════════════════════════════

func get_module_name() -> String:
	return "save"

func on_dialogue_started(resource: DialogueResource, _title: String) -> void:
	_current_resource = resource

func on_dialogue_line_changed(line: DialogueLine) -> void:
	if not auto_save_progress:
		return
	_try_save(line)

func on_dialogue_ended() -> void:
	_current_resource = null

# ════════════════════════════════════════════════════════════════
# 内部方法
# ════════════════════════════════════════════════════════════════

## 尝试保存进度（SaveSystem 不存在时静默跳过）
func _try_save(line: DialogueLine) -> void:
	if not Engine.has_singleton("SaveSystem"):
		return
	
	var sys: Node = Engine.get_singleton("SaveSystem")
	if not sys.has_method("get_module"):
		return
	
	var module = sys.get_module("dialogue")
	if module == null:
		return
	if not module.has_method("save_progress"):
		return
	
	module.call("save_progress",
		_current_resource,
		line.id,
		chapter_name,
		line.character,
		line.text
	)
