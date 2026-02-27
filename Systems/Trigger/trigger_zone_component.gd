extends Area2D
class_name TriggerZoneComponent
## 通用触发区域组件 - 关卡事件的万能开关
##
## 有什么用？
##   跑酷关卡里到处都是"当玩家到达某个位置时触发某件事"：
##     - 踩到地板 → 地板塌陷
##     - 经过某个点 → 摄像机拉远展示全景
##     - 进入区域 → 播放对话/教程提示
##     - 到达终点 → 触发通关
##   
##   如果每种都单独写脚本 → 代码爆炸
##   TriggerZone 就是一个"通用开关"，配置不同参数就能复用
##
## 使用方式：
##   1. 创建 Area2D + CollisionShape2D
##   2. 挂载此脚本
##   3. 设置 trigger_mode（进入/离开/停留）
##   4. 设置 max_triggers（1 = 一次性，0 = 无限）
##   5. 连接 triggered 信号到你想触发的逻辑
##
## 高级用法（链式触发）：
##   trigger_a.triggered.connect(func(_b): trigger_b.force_trigger())
##   这样可以做多米诺骨牌式的连锁机关

signal triggered(body: Node2D)
signal trigger_reset

## 触发方式
enum TriggerMode {
	ON_ENTER,       ## 进入区域时触发
	ON_EXIT,        ## 离开区域时触发
	ON_STAY,        ## 停留在区域内持续触发
	ON_ENTER_EXIT,  ## 进入和离开各触发一次
}
@export var trigger_mode: TriggerMode = TriggerMode.ON_ENTER

## 最大触发次数（0 = 无限）
@export var max_triggers: int = 1

## 触发延迟（秒）—— 进入后多久才触发
@export var trigger_delay: float = 0.0

## 冷却时间（秒）—— 两次触发之间的最短间隔
@export var cooldown: float = 0.0

## 停留模式的触发间隔（秒）
@export var stay_interval: float = 0.5

## 是否只对特定 Group 的物体触发
@export var required_group: StringName = &""

## 是否在触发后自动禁用碰撞
@export var disable_after_max: bool = true

## 是否发送 EventBus 事件
@export var event_name: StringName = &""

## 触发时的自定义数据（传给信号接收方）
@export var custom_data: Dictionary = {}

## 可视调试颜色
@export var debug_color: Color = Color(1, 1, 0, 0.3)

## --------- 内部状态 ---------
var trigger_count: int = 0
var is_active: bool = true
var _cooldown_timer: float = 0.0
var _stay_timer: float = 0.0
var _delay_timer: float = 0.0
var _pending_body: Node2D = null
var _bodies_inside: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# 冷却计时
	if _cooldown_timer > 0:
		_cooldown_timer -= delta
	
	# 延迟触发
	if _pending_body and _delay_timer > 0:
		_delay_timer -= delta
		if _delay_timer <= 0:
			_execute_trigger(_pending_body)
			_pending_body = null
	
	# 停留模式
	if trigger_mode == TriggerMode.ON_STAY and not _bodies_inside.is_empty():
		_stay_timer -= delta
		if _stay_timer <= 0:
			_stay_timer = stay_interval
			for body in _bodies_inside:
				if is_instance_valid(body):
					_try_trigger(body)

func _on_body_entered(body: Node2D) -> void:
	if not _should_trigger(body): return
	_bodies_inside.append(body)
	
	if trigger_mode == TriggerMode.ON_ENTER or trigger_mode == TriggerMode.ON_ENTER_EXIT:
		_try_trigger(body)
	
	if trigger_mode == TriggerMode.ON_STAY:
		_stay_timer = stay_interval
		# 立即触发第一次
		_try_trigger(body)

func _on_body_exited(body: Node2D) -> void:
	_bodies_inside.erase(body)
	
	if not _should_trigger(body): return
	
	if trigger_mode == TriggerMode.ON_EXIT or trigger_mode == TriggerMode.ON_ENTER_EXIT:
		_try_trigger(body)

func _should_trigger(body: Node2D) -> bool:
	if not is_active: return false
	if required_group != &"" and not body.is_in_group(required_group):
		return false
	return true

func _try_trigger(body: Node2D) -> void:
	if not is_active: return
	if _cooldown_timer > 0: return
	if max_triggers > 0 and trigger_count >= max_triggers: return
	
	if trigger_delay > 0 and not _pending_body:
		_pending_body = body
		_delay_timer = trigger_delay
		return
	
	_execute_trigger(body)

func _execute_trigger(body: Node2D) -> void:
	trigger_count += 1
	_cooldown_timer = cooldown
	
	# 发出信号
	triggered.emit(body)
	
	# EventBus 事件
	if event_name != &"" and EventBus:
		var data := custom_data.duplicate()
		data["body"] = body
		data["trigger"] = self
		data["trigger_count"] = trigger_count
		#EventBus.emit_event(event_name, data)
	
	# 检查是否达到最大次数
	if max_triggers > 0 and trigger_count >= max_triggers:
		if disable_after_max:
			is_active = false
			# 关闭碰撞检测（省性能）
			set_deferred("monitoring", false)

#region API

## 强制触发（不检查冷却和次数）
func force_trigger(body: Node2D = null) -> void:
	_execute_trigger(body)

## 重置触发次数
func reset() -> void:
	trigger_count = 0
	is_active = true
	monitoring = true
	_cooldown_timer = 0
	_pending_body = null
	trigger_reset.emit()

## 启用/禁用
func set_active(value: bool) -> void:
	is_active = value
	monitoring = value

#endregion

#region 自省

func get_component_data() -> Dictionary:
	return {
		"trigger_mode": TriggerMode.keys()[trigger_mode],
		"trigger_count": trigger_count,
		"max_triggers": max_triggers,
		"is_active": is_active,
		"bodies_inside": _bodies_inside.size(),
		"on_cooldown": _cooldown_timer > 0,
	}

#endregion
