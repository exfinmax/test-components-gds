class_name DialogueSaveSlot
extends PanelContainer
## ════════════════════════════════════════════════════════════════
##  DialogueSaveSlot — 对话存档槽 UI 组件
## ════════════════════════════════════════════════════════════════
##
## 展示单个存档槽的状态（空/已用），并提供保存/读取操作按钮。
## 配合 DialogueSaveModule + SaveSystem 一起使用。
##
## 信号：
##   save_requested(slot)    用户点击"保存"
##   load_requested(slot)    用户点击"读取"
##   delete_requested(slot)  用户点击"删除"
## ════════════════════════════════════════════════════════════════

## 用户点击保存按钮
signal save_requested(slot: int)
## 用户点击读取按钮
signal load_requested(slot: int)
## 用户点击删除按钮
signal delete_requested(slot: int)

# ──────────────────────────────────────────────
# 配置
# ──────────────────────────────────────────────

## 当前显示的槽位编号（1-based）
@export var slot_index: int = 1 :
	set(v):
		slot_index = v
		_refresh_display()

# ──────────────────────────────────────────────
# 子节点引用
# ──────────────────────────────────────────────

@onready var _slot_label: Label       = %SlotLabel
@onready var _chapter_label: Label    = %ChapterLabel
@onready var _character_label: Label  = %CharacterLabel
@onready var _snippet_label: Label    = %SnippetLabel
@onready var _time_label: Label       = %TimeLabel
@onready var _save_button: Button     = %SaveButton
@onready var _load_button: Button     = %LoadButton
@onready var _delete_button: Button   = %DeleteButton
@onready var _empty_label: Label      = %EmptyLabel

# ──────────────────────────────────────────────
# 生命周期
# ──────────────────────────────────────────────

func _ready() -> void:
	_save_button.pressed.connect(func(): save_requested.emit(slot_index))
	_load_button.pressed.connect(func(): load_requested.emit(slot_index))
	_delete_button.pressed.connect(func(): delete_requested.emit(slot_index))
	_refresh_display()

# ──────────────────────────────────────────────
# 公共 API
# ──────────────────────────────────────────────

## 刷新当前槽位的显示（从 SaveSystem 读取 SlotInfo + DialogueSaveModule）
func refresh(save_system: Node = null) -> void:
	_refresh_display(save_system)

# ──────────────────────────────────────────────
# 内部辅助
# ──────────────────────────────────────────────

func _refresh_display(save_system: Node = null) -> void:
	if not is_node_ready():
		return

	_slot_label.text = "存档 %d" % slot_index

	# 尝试从 SaveSystem 获取槽位信息
	var sys: Node = save_system
	if sys == null and Engine.has_singleton("SaveSystem"):
		sys = Engine.get_singleton("SaveSystem")

	if sys == null:
		_show_empty_state()
		return

	var slots: Array = sys.list_slots()
	var info: SlotInfo = null
	for s in slots:
		if (s as SlotInfo).slot == slot_index:
			info = s
			break

	if info == null or not info.exists:
		_show_empty_state()
		return

	# 槽位有存档，尝试读取对话模块数据
	_empty_label.hide()
	_chapter_label.show()
	_character_label.show()
	_snippet_label.show()
	_time_label.show()
	_load_button.disabled = false
	_delete_button.disabled = false

	_time_label.text = info.get_time_string()

	# 尝试临时读取存档中的 dialogue 字段（不改变当前内存状态）
	var path: String = "user://saves/slot_%02d.json" % slot_index
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var json := JSON.new()
			var err := json.parse(file.get_as_text())
			file.close()
			if err == OK:
				var data: Dictionary = json.get_data()
				var d: Dictionary = data.get("dialogue", {})
				_chapter_label.text   = d.get("chapter_name",   "未知章节")
				_character_label.text = d.get("character_name", "")
				_snippet_label.text   = d.get("dialogue_snippet", "…")
				if _snippet_label.text.is_empty():
					_snippet_label.text = "…"
				return

	# 无法读取详细数据，只显示时间
	_chapter_label.text   = "未知章节"
	_character_label.text = ""
	_snippet_label.text   = "…"

func _show_empty_state() -> void:
	_empty_label.show()
	_chapter_label.hide()
	_character_label.hide()
	_snippet_label.hide()
	_time_label.hide()
	_load_button.disabled = true
	_delete_button.disabled = true
