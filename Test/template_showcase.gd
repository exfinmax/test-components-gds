extends Node2D
## 模板展示场景脚本
## 按键：
## R 按住：模拟回溯消耗 + 回声拖影
## Q：触发“回声释放”并进入冷却
## T：触发预警环
## F：触发冻结帧 + 相机震动
## E：显示消息

@onready var _hud: TimeAbilityHUD = $CanvasLayer/TimeAbilityHUD
@onready var _toast: ToastFeed = $CanvasLayer/ToastFeed
@onready var _chip: CooldownChip = $CanvasLayer/CooldownChip
@onready var _dummy: Sprite2D = $Dummy
@onready var _echo: TimeEchoVisual = $TimeEchoVisual
@onready var _freeze: FreezeFrameEffect = $FreezeFrameEffect
@onready var _shake: CameraShakeTemplate = $CameraShakeTemplate

var _energy: float = 100.0
var _max_energy: float = 100.0
var _rewind_charge: float = 1.0
var _rewinding: bool = false

var _echo_cd_total: float = 3.0
var _echo_cd_remain: float = 0.0

var _motion_t: float = 0.0
var _base_pos: Vector2

func _ready() -> void:
	_base_pos = _dummy.position
	_echo.target_path = _dummy.get_path()
	_hud.show_hint("R 按住回溯，Q 释放回声，T 预警，F 冻结帧")
	_toast.push_toast("模板演示已启动")

func _process(delta: float) -> void:
	_motion_t += delta
	_dummy.position = _base_pos + Vector2(cos(_motion_t * 1.7), sin(_motion_t * 2.1)) * 110.0

	if _rewinding:
		_energy = maxf(0.0, _energy - 20.0 * delta)
		_rewind_charge = maxf(0.0, _rewind_charge - 0.45 * delta)
	else:
		_energy = minf(_max_energy, _energy + 12.0 * delta)
		_rewind_charge = minf(1.0, _rewind_charge + 0.25 * delta)

	if _echo_cd_remain > 0.0:
		_echo_cd_remain = maxf(0.0, _echo_cd_remain - delta)
		_chip.set_cooldown(_echo_cd_remain, _echo_cd_total)
	else:
		_chip.set_ready()

	_hud.set_energy(_energy, _max_energy)
	_hud.set_rewind_charge(_rewind_charge)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q:
				_try_release_echo()
			KEY_T:
				_spawn_telegraph()
			KEY_F:
				_freeze.play(0.045)
				_shake.shake(10.0, 0.2)
				_toast.push_toast("冻结帧 + 震动")
			KEY_E:
				_toast.push_toast("提示：回溯后释放回声可重演关键动作")

	if event.is_action_pressed("ui_select") or (event is InputEventKey and event.keycode == KEY_R and event.pressed and not event.echo):
		_rewinding = true
		_echo.set_active(true)
		_toast.push_toast("回溯开始")

	if event.is_action_released("ui_select") or (event is InputEventKey and event.keycode == KEY_R and not event.pressed):
		_rewinding = false
		_echo.set_active(false)
		_toast.push_toast("回溯结束")

func _try_release_echo() -> void:
	if _echo_cd_remain > 0.0:
		_toast.push_toast("回声冷却中")
		return
	if _rewind_charge < 0.2:
		_toast.push_toast("回溯储能不足")
		return
	_echo_cd_remain = _echo_cd_total
	_rewind_charge = maxf(0.0, _rewind_charge - 0.2)
	_spawn_telegraph()
	_freeze.play(0.035)
	_shake.shake(8.0, 0.16)
	_toast.push_toast("释放回声")

func _spawn_telegraph() -> void:
	var ring_scene: PackedScene = preload("res://Templates/VFX/telegraph_ring.tscn")
	var ring := ring_scene.instantiate() as TelegraphRing
	add_child(ring)
	ring.global_position = _dummy.global_position
	ring.play(0.45)
