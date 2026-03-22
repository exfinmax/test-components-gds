extends Node

const META_PROGRESS_SCRIPT := preload("res://ComponentLibrary/Systems/MetaFlow/Modules/meta_progress_module.gd")
const REGISTRY_SCRIPT := preload("res://ComponentLibrary/Systems/MetaFlow/game_pack_registry.gd")
const MANIFEST_PATHS :PackedStringArray= ([
	"res://StarterPacks/NarrativeUI/manifest.tres",
	"res://StarterPacks/PlatformerAction/manifest.tres",
	"res://StarterPacks/TopDownAction/manifest.tres",
	"res://StarterPacks/UIPuzzle/manifest.tres",
])

@onready var _pack_container: Node = $PackContainer
@onready var _scene_flow: SceneFlowController = $SceneFlowController
@onready var _pack_list: VBoxContainer = %PackList
@onready var _status: Label = %StatusLabel
@onready var _summary: Label = %SummaryLabel
@onready var _save_panel: Control = %SlotPanel
@onready var _save_system: Node = get_node_or_null("/root/SaveSystem")

var _registry: GamePackRegistry = REGISTRY_SCRIPT.new()
var _meta_progress: MetaProgressModule = null

func _ready() -> void:
	(%ContinueButton as Button).pressed.connect(_continue_progress)
	(%SaveButton as Button).pressed.connect(_save_progress)
	(%LoadButton as Button).pressed.connect(_load_progress)
	(%BackButton as Button).pressed.connect(_go_back)
	_load_manifests()
	_ensure_meta_progress_module()
	_build_pack_list()
	_refresh_summary()
	if _save_panel.has_method("refresh"):
		_save_panel.refresh(_save_system)

func _load_manifests() -> void:
	_registry.load_manifests(MANIFEST_PATHS)

func _ensure_meta_progress_module() -> void:
	if _save_system == null or not _save_system.has_method("register_module"):
		_status.text = "SaveSystem 未挂载，宿主只提供 pack 浏览。"
		return
	_meta_progress = _save_system.get_module("meta_progress") as MetaProgressModule
	if _meta_progress == null:
		_meta_progress = META_PROGRESS_SCRIPT.new()
		_save_system.register_module(_meta_progress)

func _build_pack_list() -> void:
	for child in _pack_list.get_children():
		child.queue_free()
	for manifest in _registry.get_all_manifests():
		var button := Button.new()
		button.text = "%s  [%s]" % [manifest.display_name, String(manifest.genre)]
		button.disabled = _meta_progress != null and not _meta_progress.is_pack_unlocked(String(manifest.pack_id))
		button.custom_minimum_size = Vector2(0.0, 44.0)
		button.pressed.connect(_open_pack.bind(String(manifest.pack_id), false))
		_pack_list.add_child(button)

func _continue_progress() -> void:
	if _meta_progress == null or _meta_progress.current_pack == "":
		_status.text = "当前没有可继续的玩法包。"
		return
	_open_pack(_meta_progress.current_pack, true)

func _save_progress() -> void:
	_capture_active_pack_state()
	if _save_system == null or not _save_system.has_method("save_slot"):
		_status.text = "SaveSystem 不可用"
		return
	var ok := bool(_save_system.save_slot(1))
	_status.text = "Meta2DHost 保存槽位1 %s" % ("成功" if ok else "失败")
	if _save_panel.has_method("refresh"):
		_save_panel.refresh(_save_system)

func _load_progress() -> void:
	if _save_system == null or not _save_system.has_method("load_slot"):
		_status.text = "SaveSystem 不可用"
		return
	var ok := bool(_save_system.load_slot(1))
	_status.text = "Meta2DHost 读取槽位1 %s" % ("成功" if ok else "失败")
	if not ok:
		return
	_meta_progress = _save_system.get_module("meta_progress") as MetaProgressModule
	_build_pack_list()
	_refresh_summary()
	if _meta_progress != null and _meta_progress.current_pack != "":
		_open_pack(_meta_progress.current_pack, true)
	if _save_panel.has_method("refresh"):
		_save_panel.refresh(_save_system)

func _open_pack(pack_id: String, resume: bool) -> void:
	var manifest := _registry.get_manifest(pack_id)
	if manifest == null:
		_status.text = "未找到 pack: %s" % pack_id
		return
	_capture_active_pack_state()
	var context := {
		"entry_point": "meta_host",
		"chapter": "hub",
	}
	if resume and _meta_progress != null:
		context["resume_state"] = _meta_progress.get_pack_state(pack_id)
	if _meta_progress != null:
		_meta_progress.unlock_pack(pack_id)
		_meta_progress.set_current_context("hub", pack_id)
	var instance := _scene_flow.mount_pack(_pack_container, manifest, context)
	if instance != null and instance.has_signal("pack_finished"):
		instance.connect("pack_finished", Callable(self, "_on_pack_finished"))
	_status.text = "已载入玩法包：%s" % manifest.display_name
	_refresh_summary()

func _on_pack_finished(result: Dictionary) -> void:
	var pack_id := str(result.get("pack_id", ""))
	var outcome := str(result.get("outcome", "return"))
	var saved_state :Dictionary= result.get("state", {})
	if _meta_progress != null and pack_id != "":
		if saved_state is Dictionary:
			_meta_progress.save_pack_state(pack_id, saved_state)
		if outcome == "success":
			_meta_progress.complete_pack(pack_id, saved_state if saved_state is Dictionary else {})
			_meta_progress.set_flag("%s_success" % pack_id, true)
		elif outcome == "fail":
			_meta_progress.set_flag("%s_failed_once" % pack_id, true)
		_meta_progress.clear_current_pack()
	_scene_flow.unmount_current()
	_status.text = "玩法包退出：%s (%s)" % [pack_id, outcome]
	_refresh_summary()
	if outcome == "success" and _save_system != null and _save_system.has_method("save_slot"):
		_save_system.save_slot(1)
	if _save_panel.has_method("refresh"):
		_save_panel.refresh(_save_system)

func _capture_active_pack_state() -> void:
	if _meta_progress == null:
		return
	var manifest := _scene_flow.get_current_manifest()
	var instance := _scene_flow.get_current_instance()
	if manifest == null or instance == null:
		return
	if instance.has_method("export_pack_state"):
		var state = instance.call("export_pack_state")
		if state is Dictionary:
			_meta_progress.save_pack_state(String(manifest.pack_id), state)

func _refresh_summary() -> void:
	if _meta_progress == null:
		_summary.text = "当前运行：无 SaveSystem，作为纯浏览宿主使用。"
		return
	_summary.text = "当前 pack: %s | 已解锁: %d | 已完成: %d" % [
		_meta_progress.current_pack if _meta_progress.current_pack != "" else "无",
		_meta_progress.unlocked_packs.size(),
		_meta_progress.completed_packs.size(),
	]

func _go_back() -> void:
	_capture_active_pack_state()
	SceneChangeBridge.change_scene("res://Test/test_main.tscn")
