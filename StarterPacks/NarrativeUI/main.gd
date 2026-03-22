extends Control

signal pack_finished(result: Dictionary)

const DIALOGUE_MODULE_SCRIPT := preload("res://addons/dialogue_manager/modify_test/dialogue_save_module.gd")
const DIALOGUE_RESOURCE_PATH := "res://addons/dialogue_manager/modify_test/demo/demo_dialogue.dialogue"
const PACK_ID := "narrative_ui"

@onready var _balloon: CanvasLayer = $DialogueBalloon
@onready var _status: Label = $NarrativePanel/Header/StatusLabel
@onready var _save_panel: Control = $NarrativePanel/SaveSlotPanel
@onready var _toast_feed = $NarrativePanel/ToastFeed
@onready var _save_system: Node = get_node_or_null("/root/SaveSystem")

var _dialogue_module: Variant = null
var _running_under_host: bool = false
var _pending_import_state: Dictionary = {}

func _ready() -> void:
	($NarrativePanel/Header/Buttons/StartButton as Button).pressed.connect(_start_dialogue)
	($NarrativePanel/Header/Buttons/ContinueButton as Button).pressed.connect(_continue_dialogue)
	($NarrativePanel/Header/Buttons/SaveButton as Button).pressed.connect(_save_slot)
	($NarrativePanel/Header/Buttons/LoadButton as Button).pressed.connect(_load_slot)
	($NarrativePanel/Header/Buttons/BackButton as Button).pressed.connect(_go_back)
	if _balloon.has_signal("dialogue_ended"):
		_balloon.dialogue_ended.connect(func(): _toast_feed.push_toast("对话已结束"))
	_register_dialogue_module()
	_refresh_save_panel()
	_apply_pending_import_state()

func _register_dialogue_module() -> void:
	if _save_system == null or not _save_system.has_method("register_module"):
		_status.text = "SaveSystem 未挂载，仍可直接体验对话。"
		return
	_dialogue_module = _save_system.get_module("dialogue")
	if _dialogue_module == null:
		_dialogue_module = DIALOGUE_MODULE_SCRIPT.new()
		_save_system.register_module(_dialogue_module)
	_status.text = "DialogueSaveModule 已注册。"

func _start_dialogue() -> void:
	var resource := load(DIALOGUE_RESOURCE_PATH)
	if resource == null:
		_status.text = "缺少对话资源: %s" % DIALOGUE_RESOURCE_PATH
		return
	_balloon.chapter_name = "Starter Intro"
	_balloon.start(resource, "start", [self])
	_toast_feed.push_toast("开始 narrative starter 对话")

func _continue_dialogue() -> void:
	if _dialogue_module == null or not _dialogue_module.has_method("has_progress") or not _dialogue_module.has_progress():
		_start_dialogue()
		return
	var resource = _dialogue_module.load_dialogue_resource()
	if resource == null:
		_start_dialogue()
		return
	_balloon.chapter_name = _dialogue_module.chapter_name if _dialogue_module.chapter_name != "" else "Continue"
	_balloon.start(resource, _dialogue_module.dialogue_title, [self])
	_toast_feed.push_toast("继续已保存的对话进度")

func _save_slot() -> void:
	if _save_system == null or not _save_system.has_method("save_slot"):
		_toast_feed.push_toast("SaveSystem 不可用")
		return
	var ok := bool(_save_system.save_slot(1))
	_status.text = "保存槽位1 %s" % ("成功" if ok else "失败")
	_refresh_save_panel()

func _load_slot() -> void:
	if _save_system == null or not _save_system.has_method("load_slot"):
		_toast_feed.push_toast("SaveSystem 不可用")
		return
	var ok := bool(_save_system.load_slot(1))
	_status.text = "读取槽位1 %s" % ("成功" if ok else "失败")
	_refresh_save_panel()
	if ok:
		_continue_dialogue()

func _refresh_save_panel() -> void:
	if _save_panel.has_method("refresh"):
		_save_panel.refresh(_save_system)

func _go_back() -> void:
	_finish_pack({
		"pack_id": PACK_ID,
		"outcome": "return",
		"state": export_pack_state(),
	})

func start_pack(context: Dictionary) -> void:
	_running_under_host = true
	if not context.is_empty():
		import_pack_state(context.get("resume_state", context))
		if bool(context.get("auto_start", false)):
			_start_dialogue()

func export_pack_state() -> Dictionary:
	var state := {
		"pack_id": PACK_ID,
		"status_text": _status.text,
	}
	if _dialogue_module != null and _dialogue_module.has_method("collect_data"):
		state["dialogue"] = _dialogue_module.collect_data()
	return state

func import_pack_state(state: Dictionary) -> void:
	_pending_import_state = state.duplicate(true)
	_apply_pending_import_state()

func _apply_pending_import_state() -> void:
	if _pending_import_state.is_empty() or _dialogue_module == null:
		return
	var dialogue_state :Dictionary= _pending_import_state.get("dialogue", {})
	if dialogue_state is Dictionary and _dialogue_module.has_method("apply_data"):
		_dialogue_module.apply_data(dialogue_state)
	var status_text := str(_pending_import_state.get("status_text", ""))
	if status_text != "":
		_status.text = status_text
	_pending_import_state.clear()

func _finish_pack(result: Dictionary) -> void:
	if _running_under_host:
		pack_finished.emit(result)
		return
	SceneChangeBridge.change_scene("res://Test/test_main.tscn")
