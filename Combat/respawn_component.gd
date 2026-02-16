extends Node
class_name RespawnComponent
## 重生组件 - 连接死亡和检查点的桥梁
##
## 为什么需要单独的重生组件？
##   HealthComponent 只管"血量归零 → 发出 died 信号"
##   CheckpointComponent 只管"记录重生位置"
##   但"死亡 → 等一下 → 播放特效 → 传送到检查点 → 恢复血量"这条完整流程
##   不属于任何一个组件的职责——这就是 RespawnComponent 的工作。
##
##   它就像一个**导演**：
##     1. 听到 "died" 信号
##     2. 禁用玩家控制（防止空中操作）
##     3. 播放死亡特效（屏幕变暗、角色消失）
##     4. 等待一段时间
##     5. 把角色传送到检查点
##     6. 恢复血量、重新启用控制
##     7. 播放重生特效
##
## 使用方式：
##   作为 CharacterBody2D 的子节点
##   自动连接 HealthComponent.died 信号
##   自动使用 CheckpointComponent.respawn_position
##
## 需要 HealthComponent + CheckpointComponent 配合

signal respawn_started
signal respawn_completed
signal death_count_changed(count: int)

## 重生延迟（秒）—— 死亡后多久重生
@export var respawn_delay: float = 0.8

## 重生后无敌时间（秒）
@export var invincibility_duration: float = 1.5

## 是否自动连接 HealthComponent
@export var auto_connect: bool = true

## 默认重生位置（没有检查点时使用）
@export var default_respawn_position: Vector2 = Vector2.ZERO

## 死亡次数
var death_count: int = 0

## 是否正在重生流程中
var is_respawning: bool = false

## 引用缓存
var _character: CharacterBody2D
var _health_comp: Node  # HealthComponent
var _buff_comp: BuffComponent

func _ready() -> void:
	# 自动绑定角色
	if owner is CharacterBody2D:
		_character = owner
	elif get_parent() is CharacterBody2D:
		_character = get_parent()
	
	if not _character:
		push_warning("[RespawnComponent] 未找到 CharacterBody2D")
		return
	
	# 记录初始位置作为默认重生点
	if default_respawn_position == Vector2.ZERO:
		default_respawn_position = _character.global_position
	
	# 自动连接
	if auto_connect:
		_connect_deferred.call_deferred()

func _connect_deferred() -> void:
	# 查找 HealthComponent
	for child in _character.get_children():
		if child is HealthComponent:
			_health_comp = child
			break
		# 支持名字匹配
		if "health" in child.name.to_lower() and child.has_signal("died"):
			_health_comp = child
			break
	
	if _health_comp:
		_health_comp.died.connect(_on_died)
	else:
		push_warning("[RespawnComponent] 未找到 HealthComponent，需手动调用 trigger_death()")
	
	# 查找 BuffComponent
	for child in _character.get_children():
		if child is BuffComponent:
			_buff_comp = child
			break

## 手动触发死亡流程（用于无 HealthComponent 的场景，如坠落死亡）
func trigger_death() -> void:
	_on_died()

func _on_died() -> void:
	if is_respawning: return  # 防止重复触发
	is_respawning = true
	death_count += 1
	death_count_changed.emit(death_count)
	
	# 通知 EventBus
	if EventBus:
		EventBus.player_died.emit({"position": _character.global_position, "death_count": death_count})
	
	# 1. 禁用角色控制
	_set_character_enabled(false)
	
	# 2. 死亡表演（子类可重写）
	await _death_sequence()
	
	# 3. 传送到重生点
	_teleport_to_respawn()
	
	# 4. 恢复角色
	_restore_character()
	
	# 5. 重生特效
	await _respawn_sequence()
	
	# 6. 完成
	is_respawning = false
	respawn_completed.emit()
	
	if EventBus:
		EventBus.player_respawned.emit({"position": _character.global_position})

#region 可重写的流程步骤

## 死亡动画/特效序列（子类可重写添加自定义效果）
func _death_sequence() -> void:
	# 默认：简单淡出 + 等待
	if _character.has_node("Body"):
		var body := _character.get_node("Body") as Node2D
		if body:
			var tw := create_tween()
			tw.tween_property(body, "modulate:a", 0.0, respawn_delay * 0.5)
			await tw.finished
	
	# 等待剩余时间
	await get_tree().create_timer(respawn_delay * 0.5).timeout

## 重生动画/特效序列（子类可重写）
func _respawn_sequence() -> void:
	# 默认：简单淡入
	if _character.has_node("Body"):
		var body := _character.get_node("Body") as Node2D
		if body:
			body.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(body, "modulate:a", 1.0, 0.3)
			await tw.finished

#endregion

#region 内部方法

func _get_respawn_position() -> Vector2:
	# 优先使用 CheckpointComponent 的重生位置
	if CheckpointComponent.last_checkpoint:
		return CheckpointComponent.respawn_position
	return default_respawn_position

func _teleport_to_respawn() -> void:
	var pos := _get_respawn_position()
	_character.global_position = pos
	_character.velocity = Vector2.ZERO

func _set_character_enabled(value: bool) -> void:
	# 禁用/启用所有角色组件
	for child in _character.get_children():
		if child == self: continue  # 不要禁用自己
		if child.has_method("set") and "enabled" in child:
			child.enabled = value

func _restore_character() -> void:
	# 恢复血量
	if _health_comp and _health_comp.has_method("heal"):
		var max_hp: float = _health_comp.get("max_health") if "max_health" in _health_comp else 10.0
		_health_comp.current_health = max_hp
		_health_comp.health_changed.emit(_health_comp.get_health_percent())
	
	# 启用角色
	_set_character_enabled(true)
	
	# 应用无敌 Buff
	if _buff_comp and invincibility_duration > 0:
		var invincible_buff := BuffEffect.create(
			&"respawn_invincibility",
			BuffEffect.BuffType.INVINCIBLE,
			1.0,
			invincibility_duration
		)
		_buff_comp.add_buff(invincible_buff)

#endregion

#region API

## 重置死亡计数
func reset_death_count() -> void:
	death_count = 0
	death_count_changed.emit(0)

## 设置自定义重生点（不通过检查点）
func set_custom_respawn(pos: Vector2) -> void:
	default_respawn_position = pos

#endregion

#region 自省

func get_component_data() -> Dictionary:
	return {
		"death_count": death_count,
		"is_respawning": is_respawning,
		"respawn_delay": respawn_delay,
		"invincibility_duration": invincibility_duration,
		"respawn_position": _get_respawn_position(),
	}

#endregion
