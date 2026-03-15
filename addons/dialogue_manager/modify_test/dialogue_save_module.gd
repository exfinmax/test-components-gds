class_name DialogueSaveModule
extends ISaveModule
## ════════════════════════════════════════════════════════════════
##  DialogueSaveModule — 对话系统存档模块（槽位存档）
## ════════════════════════════════════════════════════════════════
##
## 保存当前对话进度，包括：
##   • 对话资源路径（用于重新加载）
##   • 当前对话节点 ID / 标题（用于恢复进度）
##   • 章节/场景名（显示在存档槽里）
##   • 当前发言角色名
##   • 自定义对话变量（dialogue_variables）
##
## 使用方式：
##   # 注册模块
##   SaveSystem.register_module(DialogueSaveModule.new())
##   # 保存对话进度
##   var m := SaveSystem.get_module("dialogue") as DialogueSaveModule
##   m.save_progress(dialogue_resource, current_title, "第一章", "Nathan")
##   SaveSystem.save_slot()
##   # 恢复对话进度
##   m.load_progress()   → 返回 { "resource": ..., "title": ... }
## ════════════════════════════════════════════════════════════════

## 单例引用（可选，方便外部直接获取）
static var instance: DialogueSaveModule

# ──────────────────────────────────────────────
# 数据字段
# ──────────────────────────────────────────────

## 对话资源的 res:// 路径（空字符串 = 没有进度）
var dialogue_resource_path: String = ""

## 恢复时从哪个 title / ID 开始（对应 .dialogue 文件里的 ~ title_name）
var dialogue_title: String = ""

## 章节 / 场景描述（用于存档槽 UI 显示）
var chapter_name: String = ""

## 最后发言角色名（用于存档槽 UI 缩略显示）
var character_name: String = ""

## 最后一行对话文本的摘要（用于存档槽 UI 显示）
var dialogue_snippet: String = ""

## 自定义对话变量（例如由 mutation 修改的布尔标志、计数器等）
var dialogue_variables: Dictionary = {}

# ──────────────────────────────────────────────
# 构造
# ──────────────────────────────────────────────

func _init() -> void:
	instance = self

# ──────────────────────────────────────────────
# ISaveModule 接口（必须实现）
# ──────────────────────────────────────────────

func get_module_key() -> String:
	return "dialogue"

## 槽位存档（每个存档槽保存独立的对话进度）
func is_global() -> bool:
	return false

func collect_data() -> Dictionary:
	return {
		"dialogue_resource_path": dialogue_resource_path,
		"dialogue_title":         dialogue_title,
		"chapter_name":           chapter_name,
		"character_name":         character_name,
		"dialogue_snippet":       dialogue_snippet,
		"dialogue_variables":     dialogue_variables.duplicate(true),
	}

func apply_data(data: Dictionary) -> void:
	dialogue_resource_path = data.get("dialogue_resource_path", "")
	dialogue_title         = data.get("dialogue_title",         "")
	chapter_name           = data.get("chapter_name",           "")
	character_name         = data.get("character_name",         "")
	dialogue_snippet       = data.get("dialogue_snippet",       "")
	dialogue_variables     = (data.get("dialogue_variables", {}) as Dictionary).duplicate(true)

func get_default_data() -> Dictionary:
	return {
		"dialogue_resource_path": "",
		"dialogue_title":         "",
		"chapter_name":           "",
		"character_name":         "",
		"dialogue_snippet":       "",
		"dialogue_variables":     {},
	}

# ──────────────────────────────────────────────
# 业务 API
# ──────────────────────────────────────────────

## 保存对话进度快照
## [param resource]   当前使用的 DialogueResource
## [param title]      当前 dialogue line 的 id（或者 title）
## [param chapter]    章节名（显示在存档槽中，可选）
## [param character]  最后发言角色（可选）
## [param snippet]    最后一行对话的文本摘要（可选）
func save_progress(
		resource: DialogueResource,
		title: String,
		chapter: String = "",
		character: String = "",
		snippet: String = "") -> void:
	dialogue_resource_path = resource.resource_path if is_instance_valid(resource) else ""
	dialogue_title         = title
	chapter_name           = chapter
	character_name         = character
	dialogue_snippet       = snippet.left(60)  # 最多保存 60 个字符的摘要

## 设置自定义对话变量
func set_variable(key: String, value: Variant) -> void:
	dialogue_variables[key] = value

## 获取自定义对话变量
func get_variable(key: String, default: Variant = null) -> Variant:
	return dialogue_variables.get(key, default)

## 是否有保存的进度
func has_progress() -> bool:
	return not dialogue_resource_path.is_empty() and not dialogue_title.is_empty()

## 尝试加载对话资源（失败返回 null）
func load_dialogue_resource() -> DialogueResource:
	if dialogue_resource_path.is_empty():
		return null
	if not ResourceLoader.exists(dialogue_resource_path):
		push_warning("DialogueSaveModule: resource not found: %s" % dialogue_resource_path)
		return null
	return load(dialogue_resource_path) as DialogueResource
