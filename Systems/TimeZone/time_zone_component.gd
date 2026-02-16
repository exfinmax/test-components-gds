extends Area2D
class_name TimeZoneComponent
## 时间区域组件 - 关卡中影响时间流速的区域
##
## 什么是时间区域？
##   想象跑酷关卡中的一块区域发着蓝光，
##   玩家跑进去后整个世界变慢了——这就是时间区域。
##   
##   时间区域可以：
##     - 让区域内的一切变慢 (slow_zone: time_scale = 0.3)
##     - 让区域内的一切加速 (fast_zone: time_scale = 2.0)
##     - 完全冻结区域内的一切 (freeze_zone: time_scale = 0.0)
##     - 仅影响玩家/仅影响敌人（通过碰撞层控制）
##
##   在"时间操控"跑酷中，这些区域就是关卡设计的核心元素。
##   比如：一个旋转锯片区域设为慢速 → 玩家可以安全通过。
##
## 使用方式：
##   1. 创建 Area2D，添加 CollisionShape2D（定义区域大小）
##   2. 挂载此脚本
##   3. 设置 time_scale_in_zone = 0.3（区域内时间变为 30%）
##   4. 可选：设置 buff_effects[] 附加额外效果（如速度加成）
##   5. 当物体进入/离开区域时，自动应用/移除效果
##
## 与 BuffComponent 配合：
##   如果目标有 BuffComponent，时间区域会通过 Buff 系统应用效果
##   如果没有，则直接修改 Engine.time_scale（仅影响排除列表）

## 进入/离开信号
signal body_entered_zone(body: Node2D)
signal body_exited_zone(body: Node2D)

## 区域内的时间缩放（0.0 = 冻结，0.5 = 半速，1.0 = 正常，2.0 = 双倍）
@export_range(0.0, 5.0, 0.01) var time_scale_in_zone: float = 0.5

## 进入/离开区域的过渡时间（秒），0 = 瞬间切换
@export_range(0.0, 2.0, 0.01) var transition_duration: float = 0.3

## 是否影响全局时间（true = 修改 Engine.time_scale；false = 仅通过 Buff 影响目标）
@export var affect_global_time: bool = false

## 附加的 Buff 效果（进入区域时应用，离开时移除）
@export var buff_effects: Array[BuffEffect] = []



## 是否对玩家生效（通过碰撞层更灵活，此为快捷过滤）
@export var affect_player: bool = true
## 是否对敌人生效
@export var affect_enemies: bool = true

## 正在区域内的物体 {body: {original_time_scale, tween, buffs_applied}}
var _bodies_in_zone: Dictionary = {}

## 自动创建的时间 Buff
var _time_buff: BuffEffect

func _ready() -> void:
	# 创建时间缩放 Buff
	_time_buff = BuffEffect.create(
		&"time_zone_%s" % get_instance_id(),
		BuffEffect.BuffType.TIME_SCALE,
		time_scale_in_zone,
		-1.0  # 永久（离开区域时手动移除）
	)
	
	# 连接 Area2D 信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not _should_affect(body): return
	
	var info := {}
	
	# 1. 通过 BuffComponent 应用时间效果
	var buff_comp := _find_buff_component(body)
	if buff_comp:
		buff_comp.add_buff(_time_buff)
		# 应用附加 Buff
		for eff in buff_effects:
			buff_comp.add_buff(eff)
		info["has_buff_comp"] = true
	
	# 2. 全局时间影响
	if affect_global_time:
		info["original_time_scale"] = Engine.time_scale
		if transition_duration > 0:
			var tw := create_tween()
			tw.tween_method(_set_engine_time_scale, Engine.time_scale, time_scale_in_zone, transition_duration)
			info["tween"] = tw
		else:
			_set_engine_time_scale(time_scale_in_zone)
	
	_bodies_in_zone[body] = info
	body_entered_zone.emit(body)
	
	# 通知 EventBus
	if EventBus:
		EventBus.time_scale_changed.emit(time_scale_in_zone)

func _on_body_exited(body: Node2D) -> void:
	if not _bodies_in_zone.has(body): return
	
	var info: Dictionary = _bodies_in_zone[body]
	
	# 1. 移除 Buff
	var buff_comp := _find_buff_component(body)
	if buff_comp:
		buff_comp.remove_buff(_time_buff.id)
		for eff in buff_effects:
			buff_comp.remove_buff(eff.id)
	
	# 2. 恢复全局时间
	if affect_global_time:
		var original: float = info.get("original_time_scale", 1.0)
		if info.has("tween") and info["tween"] is Tween:
			(info["tween"] as Tween).kill()
		if transition_duration > 0:
			var tw := create_tween()
			tw.tween_method(_set_engine_time_scale, Engine.time_scale, original, transition_duration)
		else:
			_set_engine_time_scale(original)
	
	_bodies_in_zone.erase(body)
	body_exited_zone.emit(body)
	
	# 恢复时间缩放通知
	if EventBus and affect_global_time:
		EventBus.time_scale_changed.emit(Engine.time_scale)

#region 过滤逻辑

func _should_affect(body: Node2D) -> bool:
	if body is CharacterBody2D:
		# 简单过滤：通过碰撞层已经过滤了大部分，这里做额外检查
		if body.is_in_group("player") and not affect_player:
			return false
		if body.is_in_group("enemy") and not affect_enemies:
			return false
	return true

#endregion

#region 工具方法

func _find_buff_component(body: Node2D) -> BuffComponent:
	for child in body.get_children():
		if child is BuffComponent:
			return child
	return null

func _set_engine_time_scale(value: float) -> void:
	Engine.time_scale = value
	# 如果有 TimeController autoload，也通知它
	var tc := get_node_or_null("/root/TimeController")
	if tc and tc.has_method("set_all_time_scale"):
		tc.engine_time_scale = value

#endregion

#region 运行时修改

## 动态修改区域时间缩放
func set_zone_time_scale(new_scale: float) -> void:
	time_scale_in_zone = new_scale
	_time_buff.value = new_scale
	# 更新已在区域内的所有物体
	for body in _bodies_in_zone.keys():
		var buff_comp := _find_buff_component(body)
		if buff_comp:
			buff_comp.remove_buff(_time_buff.id)
			buff_comp.add_buff(_time_buff)
	if affect_global_time:
		_set_engine_time_scale(new_scale)

#endregion

#region 自省

func get_component_data() -> Dictionary:
	return {
		"time_scale_in_zone": time_scale_in_zone,
		"affect_global_time": affect_global_time,
		"bodies_count": _bodies_in_zone.size(),
		"priority": priority,
	}

#endregion
