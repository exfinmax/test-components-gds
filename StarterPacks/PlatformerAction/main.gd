extends Node2D

signal pack_finished(result: Dictionary)

const PLAYER_SAVE_MODULE := preload("res://StarterPacks/PlatformerAction/Prefabs/platformer_player_save_module.gd")
const PACK_ID := "platformer_action"

@onready var _player: Node = $PlatformerPlayer
@onready var _camera: Camera2D = $Camera2D
@onready var _health_label: Label = $HUD/Header/HealthLabel
@onready var _prompt_label: Label = $HUD/Header/PromptLabel
@onready var _toast_feed = $HUD/ToastFeed
@onready var _sign: InteractableComponent = $SignInteraction
@onready var _pause_overlay: CanvasLayer = $PauseOverlay
@onready var _save_system: Node = get_node_or_null("/root/SaveSystem")

var _player_near_sign: bool = false
var _running_under_host: bool = false
var _player_save_module: ISaveModule = null
var _pending_import_state: Dictionary = {}

func _ready() -> void:
	_pause_overlay.hide()
	$PauseOverlay/Dim.hide()
	$PauseOverlay/Panel.hide()
	var health := _player.get_node_or_null("%HealthComponent") as HealthComponent
	if health != null:
		health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.get_health_percent())
	_sign.body_entered.connect(_on_sign_body_entered)
	_sign.body_exited.connect(_on_sign_body_exited)
	_sign.interacted.connect(_on_sign_interacted)
	($HUD/Buttons/SaveButton as Button).pressed.connect(_save_slot)
	($HUD/Buttons/LoadButton as Button).pressed.connect(_load_slot)
	($HUD/Buttons/PauseButton as Button).pressed.connect(_toggle_pause)
	($HUD/Buttons/BackButton as Button).pressed.connect(_go_back)
	($PauseOverlay/Panel/VBox/ResumeButton as Button).pressed.connect(_toggle_pause)
	($PauseOverlay/Panel/VBox/ResetButton as Button).pressed.connect(_reset_to_spawn)
	_register_save_module()
	_prompt_label.text = "靠近路牌后按 E 交互。按 Esc 打开暂停页。"

func _process(_delta: float) -> void:
	_camera.global_position = _camera.global_position.lerp(_player.global_position, 0.12)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
	elif event.is_action_pressed("interact") and _player_near_sign:
		_sign.try_interact(_player)

func _register_save_module() -> void:
	if _save_system == null or not _save_system.has_method("register_module"):
		return
	_player_save_module = _save_system.get_module("platformer_player")
	if _player_save_module == null:
		_player_save_module = PLAYER_SAVE_MODULE.new(_player, $SpawnPoint.global_position)
		_save_system.register_module(_player_save_module)
	_toast_feed.push_toast("SaveSystem 已挂载 Platformer 存档模块")
	_apply_pending_import_state()

func _save_slot() -> void:
	if _save_system == null or not _save_system.has_method("save_slot"):
		_toast_feed.push_toast("SaveSystem 不可用")
		return
	var ok := bool(_save_system.save_slot(1))
	_toast_feed.push_toast("保存槽位1 %s" % ("成功" if ok else "失败"))

func _load_slot() -> void:
	if _save_system == null or not _save_system.has_method("load_slot"):
		_toast_feed.push_toast("SaveSystem 不可用")
		return
	var ok := bool(_save_system.load_slot(1))
	_toast_feed.push_toast("读取槽位1 %s" % ("成功" if ok else "失败"))

func _toggle_pause() -> void:
	var is_open := not _pause_overlay.visible
	_pause_overlay.visible = is_open
	$PauseOverlay/Dim.visible = is_open
	$PauseOverlay/Panel.visible = is_open
	get_tree().paused = is_open

func _go_back() -> void:
	get_tree().paused = false
	_finish_pack({
		"pack_id": PACK_ID,
		"outcome": "return",
		"state": export_pack_state(),
	})

func _reset_to_spawn() -> void:
	get_tree().paused = false
	_pause_overlay.hide()
	$PauseOverlay/Dim.hide()
	$PauseOverlay/Panel.hide()
	_player.global_position = $SpawnPoint.global_position
	if _player.has_method("reset_death"):
		_player.reset_death()
	var health := _player.get_node_or_null("%HealthComponent") as HealthComponent
	if health != null:
		health.current_health = health.max_health
		health.health_changed.emit(health.get_health_percent())
	_toast_feed.push_toast("玩家已重置到出生点")

func _on_health_changed(ratio: float) -> void:
	_health_label.text = "生命: %d%%" % int(round(ratio * 100.0))

func _on_sign_body_entered(body: Node) -> void:
	if body != _player:
		return
	_player_near_sign = true
	_sign.set_focused(true, _player)
	_prompt_label.text = "按 E 与路牌交互。红色区域会触发受击与飘字。"

func _on_sign_body_exited(body: Node) -> void:
	if body != _player:
		return
	_player_near_sign = false
	_sign.set_focused(false, _player)
	_prompt_label.text = "靠近路牌后按 E 交互。按 Esc 打开暂停页。"

func _on_sign_interacted(_interactor: Node) -> void:
	_toast_feed.push_toast("Starter Pack: Movement + Combat + UI + Save hook")

func start_pack(context: Dictionary) -> void:
	_running_under_host = true
	if not context.is_empty():
		import_pack_state(context.get("resume_state", context))

func export_pack_state() -> Dictionary:
	var state := {
		"pack_id": PACK_ID,
		"player_near_sign": _player_near_sign,
		"prompt_text": _prompt_label.text,
	}
	if _player_save_module != null and _player_save_module.has_method("collect_data"):
		state["player"] = _player_save_module.collect_data()
	return state

func import_pack_state(state: Dictionary) -> void:
	_pending_import_state = state.duplicate(true)
	_apply_pending_import_state()

func _apply_pending_import_state() -> void:
	if _pending_import_state.is_empty():
		return
	_player_near_sign = bool(_pending_import_state.get("player_near_sign", false))
	var prompt_text := str(_pending_import_state.get("prompt_text", ""))
	if prompt_text != "":
		_prompt_label.text = prompt_text
	var player_state :Dictionary= _pending_import_state.get("player", {})
	if _player_save_module != null and player_state is Dictionary and _player_save_module.has_method("apply_data"):
		_player_save_module.apply_data(player_state)
	_pending_import_state.clear()

func _finish_pack(result: Dictionary) -> void:
	if _running_under_host:
		pack_finished.emit(result)
		return
	SceneChangeBridge.change_scene("res://Test/test_main.tscn")
