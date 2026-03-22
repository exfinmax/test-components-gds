extends Node
## ════════════════════════════════════════════════════════════════
##  Demo 场景控制脚本
## ════════════════════════════════════════════════════════════════
##
## 演示内容：
##   1. 启动模块化对话气球
##   2. 对话进度自动保存到 DialogueSaveModule
##   3. 存档槽 UI（DialogueSaveSlot）保存/读取/删除
##   4. 历史记录面板（DialogueHistoryLog）

@onready var balloon: ModularBalloon = $UI/DialogueBalloon
@onready var save_slots_container: VBoxContainer = $UI/MainPanel/VBoxContainer/SlotsContainer
@onready var status_label: Label = $UI/MainPanel/VBoxContainer/StatusLabel
@onready var start_button: Button = $UI/MainPanel/VBoxContainer/ButtonRow/StartButton
@onready var restart_button: Button = $UI/MainPanel/VBoxContainer/ButtonRow/RestartButton

## 本地存档系统（演示用，不依赖全局 AutoLoad）
var _save_system: SaveSystem
var _dialogue_module: DialogueSaveModule
var _dialogue_res: DialogueResource

const DIALOGUE_PATH := "res://addons/dialogue_manager/modify_test/demo/demo_dialogue.dialogue"
const MAX_DEMO_SLOTS := 3

func _ready() -> void:
	_setup_save_system()
	_setup_balloon()
	_setup_slot_ui()
	_set_status("演示就绪。点击'开始对话'按钮开始。")


func _setup_save_system() -> void:
	_save_system = SaveSystem
	_save_system.max_slots = MAX_DEMO_SLOTS
	_save_system.auto_register = false
	_save_system.auto_load_global = false
	_save_system.auto_load_slot = 0
	_save_system.game_version = "demo-1.0"
	add_child(_save_system)

	_dialogue_module = DialogueSaveModule.new()
	_save_system.register_module(_dialogue_module)


func _setup_balloon() -> void:
	balloon.auto_save_progress = false  # 由本脚本手动控制
	balloon.chapter_name = "演示章节"

	# 监听对话结束（DialogueManager 信号）
	if Engine.has_singleton("DialogueManager"):
		var dm := Engine.get_singleton("DialogueManager")
		dm.dialogue_ended.connect(_on_dialogue_ended)
	else:
		push_warning("Demo: DialogueManager singleton not found")


func _setup_slot_ui() -> void:
	# 动态创建存档槽 UI
	var slot_scene := load("res://addons/dialogue_manager/modify_test/dialogue_save_slot.tscn") as PackedScene
	if slot_scene == null:
		push_error("Demo: failed to load dialogue_save_slot.tscn")
		return
	for i in range(1, MAX_DEMO_SLOTS + 1):
		var slot_node := slot_scene.instantiate() as DialogueSaveSlot
		slot_node.slot_index = i
		slot_node.save_requested.connect(_on_save_requested)
		slot_node.load_requested.connect(_on_load_requested)
		slot_node.delete_requested.connect(_on_delete_requested)
		save_slots_container.add_child(slot_node)


func _refresh_slot_ui() -> void:
	for child in save_slots_container.get_children():
		if child is DialogueSaveSlot:
			child.refresh(_save_system)


# ──────────────────────────────────────────────
# 按钮回调
# ──────────────────────────────────────────────

func _on_start_button_pressed() -> void:
	_load_dialogue_resource()
	if _dialogue_res == null:
		_set_status("错误：找不到对话文件！")
		return
	balloon.chapter_name = "第一章"
	balloon.start(_dialogue_res, "chapter1", [self])
	_set_status("对话进行中…（工具栏可切换自动推进 / 查看历史）")


func _on_restart_button_pressed() -> void:
	_load_dialogue_resource()
	if _dialogue_res == null:
		return
	balloon.chapter_name = "故事重新开始"
	balloon.start(_dialogue_res, "start", [self])
	_set_status("从头开始对话…")


func _on_save_requested(slot: int) -> void:
	# 保存当前对话进度到指定槽位
	if is_instance_valid(balloon) and is_instance_valid(balloon.dialogue_line):
		var line: DialogueLine = balloon.dialogue_line
		_dialogue_module.save_progress(
			balloon.dialogue_resource,
			line.id,
			balloon.chapter_name,
			line.character,
			line.text
		)
	_save_system.current_slot = slot
	var ok := _save_system.save_slot(slot)
	_set_status("存档 %d %s" % [slot, "保存成功 ✓" if ok else "保存失败 ✗"])
	_refresh_slot_ui()


func _on_load_requested(slot: int) -> void:
	var ok := _save_system.load_slot(slot)
	if not ok:
		_set_status("存档 %d 读取失败" % slot)
		return
	# 恢复对话进度
	if _dialogue_module.has_progress():
		var res := _dialogue_module.load_dialogue_resource()
		if res == null:
			_set_status("存档 %d 读取成功，但无法加载对话资源" % slot)
			return
		balloon.chapter_name = _dialogue_module.chapter_name
		balloon.start(res, _dialogue_module.dialogue_title, [self])
		_set_status("存档 %d 读取成功，继续对话中…" % slot)
	else:
		_set_status("存档 %d 读取成功（无对话进度）" % slot)
	_refresh_slot_ui()


func _on_delete_requested(slot: int) -> void:
	var ok := _save_system.delete_slot(slot)
	_set_status("存档 %d %s" % [slot, "已删除" if ok else "删除失败"])
	_refresh_slot_ui()


func _on_dialogue_ended(_res: DialogueResource) -> void:
	_set_status("对话结束。可以保存存档或重新开始。")
	_refresh_slot_ui()


# ──────────────────────────────────────────────
# 辅助
# ──────────────────────────────────────────────

func _load_dialogue_resource() -> void:
	if _dialogue_res == null:
		if ResourceLoader.exists(DIALOGUE_PATH):
			_dialogue_res = load(DIALOGUE_PATH) as DialogueResource
		else:
			push_error("Demo: dialogue file not found: %s" % DIALOGUE_PATH)


func _set_status(msg: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = msg
	print("[Demo] ", msg)
