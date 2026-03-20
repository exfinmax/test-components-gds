extends Node2D

signal pack_finished(result: Dictionary)

const SAVE_MODULE_SCRIPT := preload("res://StarterPacks/TopDownAction/Prefabs/topdown_action_save_module.gd")
const PACK_ID := "top_down_action"
const ROOM_RECT := Rect2(80.0, 80.0, 680.0, 360.0)

@onready var _player: CharacterBody2D = $Player
@onready var _enemy: CharacterBody2D = $Enemy
@onready var _pickup: HotspotComponent = $KeyPickup
@onready var _exit: HotspotComponent = $ExitDoor
@onready var _status: Label = $HUD/Margin/Panel/VBox/StatusLabel
@onready var _objective: Label = $HUD/Margin/Panel/VBox/ObjectiveLabel
@onready var _health: Label = $HUD/Margin/Panel/VBox/HealthLabel
@onready var _save_system: Node = get_node_or_null("/root/SaveSystem")
@onready var _projectile_layer: Node2D = $ProjectileLayer

var _running_under_host: bool = false
var _focused_hotspot: HotspotComponent = null
var _save_module: ISaveModule = null
var _pending_import_state: Dictionary = {}
var _player_health: int = 5
var _enemy_health: int = 4
var _enemy_alive: bool = true
var _has_key: bool = false
var _pack_completed: bool = false
var _last_move_dir: Vector2 = Vector2.RIGHT
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _damage_cooldown_left: float = 0.0

func _ready() -> void:
	_connect_hotspot(_pickup)
	_connect_hotspot(_exit)
	($HUD/Margin/Panel/VBox/Buttons/SaveButton as Button).pressed.connect(_save_slot)
	($HUD/Margin/Panel/VBox/Buttons/LoadButton as Button).pressed.connect(_load_slot)
	($HUD/Margin/Panel/VBox/Buttons/BackButton as Button).pressed.connect(_back_out)
	_register_save_module()
	_sync_world_state()

func _physics_process(delta: float) -> void:
	_update_player(delta)
	_update_enemy(delta)
	_update_projectiles(delta)
	_sync_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _focused_hotspot != null:
		_focused_hotspot.try_trigger(_player)
	elif event.is_action_pressed("ui_accept"):
		_attack_or_fire()
	elif event.is_action_pressed("ui_cancel"):
		_back_out()

func start_pack(context: Dictionary) -> void:
	_running_under_host = true
	if not context.is_empty():
		import_pack_state(context.get("resume_state", context))

func export_pack_state() -> Dictionary:
	var state := _collect_save_state()
	state["pack_id"] = PACK_ID
	state["objective_text"] = _objective.text
	state["status_text"] = _status.text
	return state

func import_pack_state(state: Dictionary) -> void:
	_pending_import_state = state.duplicate(true)
	_apply_pending_import_state()

func _register_save_module() -> void:
	if _save_system == null or not _save_system.has_method("register_module"):
		return
	_save_module = _save_system.get_module(PACK_ID)
	if _save_module == null:
		_save_module = SAVE_MODULE_SCRIPT.new(self)
		_save_system.register_module(_save_module)
	_apply_pending_import_state()

func _save_slot() -> void:
	if _save_system == null or not _save_system.has_method("save_slot"):
		_status.text = "SaveSystem 不可用"
		return
	var ok := bool(_save_system.save_slot(1))
	_status.text = "TopDownAction 保存槽位1 %s" % ("成功" if ok else "失败")

func _load_slot() -> void:
	if _save_system == null or not _save_system.has_method("load_slot"):
		_status.text = "SaveSystem 不可用"
		return
	var ok := bool(_save_system.load_slot(1))
	_status.text = "TopDownAction 读取槽位1 %s" % ("成功" if ok else "失败")
	if ok:
		_sync_world_state()

func _back_out() -> void:
	_finish_pack({
		"pack_id": PACK_ID,
		"outcome": "return",
		"state": export_pack_state(),
	})

func _finish_pack(result: Dictionary) -> void:
	if _running_under_host:
		pack_finished.emit(result)
		return
	get_tree().change_scene_to_file("res://Test/test_main.tscn")

func _connect_hotspot(hotspot: HotspotComponent) -> void:
	hotspot.body_entered.connect(_on_hotspot_body_entered.bind(hotspot))
	hotspot.body_exited.connect(_on_hotspot_body_exited.bind(hotspot))
	hotspot.triggered.connect(_on_hotspot_triggered.bind(hotspot))

func _on_hotspot_body_entered(body: Node, hotspot: HotspotComponent) -> void:
	if body != _player:
		return
	_focused_hotspot = hotspot
	hotspot.set_focus(true, _player)
	_status.text = hotspot.prompt_text

func _on_hotspot_body_exited(body: Node, hotspot: HotspotComponent) -> void:
	if body != _player:
		return
	hotspot.set_focus(false, _player)
	if _focused_hotspot == hotspot:
		_focused_hotspot = null
	_status.text = "Shift 冲刺，Enter 攻击或发射，E 交互。"

func _on_hotspot_triggered(_interactor: Node, hotspot: HotspotComponent) -> void:
	if hotspot == _pickup:
		_has_key = true
		_pickup.visible = false
		_pickup.enabled = false
		_status.text = "拿到了门禁卡。"
	elif hotspot == _exit:
		if _can_exit_room():
			_pack_completed = true
			_finish_pack({
				"pack_id": PACK_ID,
				"outcome": "success",
				"state": export_pack_state(),
				"summary": "topdown_room_cleared",
			})
		else:
			_status.text = "出口锁定：先击败敌人并拿到门禁卡。"
	_sync_world_state()

func _update_player(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down")
	if input_dir != Vector2.ZERO:
		_last_move_dir = input_dir.normalized()
	if _dash_cooldown_left > 0.0:
		_dash_cooldown_left = maxf(0.0, _dash_cooldown_left - delta)
	if _damage_cooldown_left > 0.0:
		_damage_cooldown_left = maxf(0.0, _damage_cooldown_left - delta)
	if _dash_time_left > 0.0:
		_dash_time_left = maxf(0.0, _dash_time_left - delta)
		_player.velocity = _last_move_dir * 420.0
	else:
		if Input.is_action_just_pressed("dash") and _dash_cooldown_left <= 0.0 and input_dir != Vector2.ZERO:
			_dash_time_left = 0.16
			_dash_cooldown_left = 0.5
			_last_move_dir = input_dir.normalized()
			_player.velocity = _last_move_dir * 420.0
		else:
			_player.velocity = input_dir * 220.0
	_player.move_and_slide()
	_player.global_position = _clamp_to_room(_player.global_position)

func _update_enemy(delta: float) -> void:
	if not _enemy_alive:
		_enemy.velocity = Vector2.ZERO
		return
	var to_player := _player.global_position - _enemy.global_position
	var distance := to_player.length()
	if distance < 260.0:
		_enemy.velocity = to_player.normalized() * 140.0
	else:
		_enemy.velocity = Vector2.ZERO
	_enemy.move_and_slide()
	_enemy.global_position = _clamp_to_room(_enemy.global_position)
	if distance < 28.0 and _damage_cooldown_left <= 0.0:
		_player_health = maxi(0, _player_health - 1)
		_damage_cooldown_left = 0.6
		_status.text = "被敌人命中。"
		if _player_health <= 0:
			_player_health = 5
			_player.global_position = Vector2(140.0, 180.0)
			_status.text = "玩家倒下，已重置到起点。"

func _update_projectiles(delta: float) -> void:
	for projectile in _projectile_layer.get_children():
		var velocity: Vector2 = projectile.get_meta("velocity", Vector2.ZERO)
		var life := float(projectile.get_meta("life", 0.0)) - delta
		projectile.position += velocity * delta
		projectile.set_meta("life", life)
		if _enemy_alive and projectile.position.distance_to(_enemy.global_position) < 24.0:
			_damage_enemy(1, "投射物命中敌人。")
			projectile.queue_free()
		elif life <= 0.0 or not ROOM_RECT.has_point(projectile.position):
			projectile.queue_free()

func _attack_or_fire() -> void:
	if _enemy_alive and _player.global_position.distance_to(_enemy.global_position) < 80.0:
		_damage_enemy(2, "近战命中。")
		return
	var bullet := Node2D.new()
	bullet.position = _player.global_position + _last_move_dir * 20.0
	bullet.set_meta("velocity", _last_move_dir * 420.0)
	bullet.set_meta("life", 1.0)
	var sprite := Polygon2D.new()
	sprite.color = Color(1, 0.87451, 0.356863, 1)
	sprite.polygon = PackedVector2Array([-4, -2, 4, -2, 4, 2, -4, 2])
	bullet.add_child(sprite)
	_projectile_layer.add_child(bullet)
	_status.text = "发射了一枚投射物。"

func _damage_enemy(amount: int, message: String) -> void:
	if not _enemy_alive:
		return
	_enemy_health = maxi(0, _enemy_health - amount)
	_status.text = message
	if _enemy_health <= 0:
		_enemy_alive = false
		_enemy.visible = false
		_enemy.process_mode = Node.PROCESS_MODE_DISABLED
		_status.text = "敌人已清除，出口只差门禁卡。"
	_sync_world_state()

func _can_exit_room() -> bool:
	return _has_key and not _enemy_alive

func _sync_world_state() -> void:
	_pickup.visible = not _has_key
	_pickup.enabled = not _has_key
	_exit.prompt_text = "离开房间" if _can_exit_room() else "出口锁定"
	_objective.text = "目标：击败敌人并拿到门禁卡。" if not _can_exit_room() else "目标：前往出口离开房间。"
	_sync_ui()

func _sync_ui() -> void:
	var enemy_text := "敌人存活" if _enemy_alive else "敌人已击败"
	var key_text := "已拿钥匙" if _has_key else "未拿钥匙"
	_health.text = "HP %d  |  %s  |  %s" % [_player_health, enemy_text, key_text]

func _collect_save_state() -> Dictionary:
	return {
		"player_position": {"x": _player.global_position.x, "y": _player.global_position.y},
		"enemy_position": {"x": _enemy.global_position.x, "y": _enemy.global_position.y},
		"player_health": _player_health,
		"enemy_health": _enemy_health,
		"has_key": _has_key,
		"completed": _pack_completed,
		"last_direction": {"x": _last_move_dir.x, "y": _last_move_dir.y},
	}

func _apply_save_state(data: Dictionary) -> void:
	_player.global_position = Vector2(float(data.get("player_position", {}).get("x", 140.0)), float(data.get("player_position", {}).get("y", 180.0)))
	_enemy.global_position = Vector2(float(data.get("enemy_position", {}).get("x", 600.0)), float(data.get("enemy_position", {}).get("y", 260.0)))
	_player_health = int(data.get("player_health", 5))
	_enemy_health = int(data.get("enemy_health", 4))
	_enemy_alive = _enemy_health > 0
	_has_key = bool(data.get("has_key", false))
	_pack_completed = bool(data.get("completed", false))
	var last_direction :Dictionary= data.get("last_direction", {"x": 1.0, "y": 0.0})
	_last_move_dir = Vector2(float(last_direction.get("x", 1.0)), float(last_direction.get("y", 0.0))).normalized()
	_enemy.visible = _enemy_alive
	_enemy.process_mode = Node.PROCESS_MODE_INHERIT if _enemy_alive else Node.PROCESS_MODE_DISABLED
	_sync_world_state()

func _apply_pending_import_state() -> void:
	if _pending_import_state.is_empty() or _save_module == null:
		return
	_save_module.apply_data(_pending_import_state)
	var status_text := str(_pending_import_state.get("status_text", ""))
	if status_text != "":
		_status.text = status_text
	_pending_import_state.clear()

func _clamp_to_room(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, ROOM_RECT.position.x, ROOM_RECT.end.x),
		clampf(point.y, ROOM_RECT.position.y, ROOM_RECT.end.y)
	)
