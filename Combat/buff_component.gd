extends Node
class_name BuffComponent
## Buff 管理组件 - 管理角色身上所有临时效果（Buff/Debuff）
##
## 为什么需要 Buff 系统？
##   没有 Buff 系统时，你的代码会变成这样：
##     move_component.speed_multiplier = 1.5  # 加速
##     await get_tree().create_timer(5.0).timeout
##     move_component.speed_multiplier = 1.0  # 恢复
##   如果同时有两个加速效果怎么办？第二个结束时会把第一个也取消掉！
##   
##   Buff 系统统一管理所有效果的叠加、持续时间、冲突处理
##
## 使用方式：
##   作为 CharacterBody2D 的子节点添加
##   buff_component.add_buff(speed_buff)   # 添加 Buff
##   buff_component.remove_buff("speed")   # 手动移除
##   var multiplier = buff_component.get_speed_multiplier()  # 查询最终倍率
##
## 信号：
##   buff_added(buff_id)     - 新 Buff 添加
##   buff_removed(buff_id)   - Buff 移除（过期或手动）
##   buff_stacked(buff_id, stacks) - Buff 叠加
##   buffs_changed           - 任何 Buff 变化（UI 刷新用）

signal buff_added(buff_id: StringName)
signal buff_removed(buff_id: StringName)
signal buff_stacked(buff_id: StringName, current_stacks: int)
signal buffs_changed

## 活跃的 Buff 实例
class ActiveBuff:
	var effect: BuffEffect
	var remaining_time: float
	var current_stacks: int
	var is_permanent: bool
	
	func _init(eff: BuffEffect) -> void:
		effect = eff
		remaining_time = eff.duration
		current_stacks = 1
		is_permanent = eff.duration < 0

## {buff_id: ActiveBuff}
var _active_buffs: Dictionary = {}

## 缓存的聚合值（避免每帧重新计算）
var _cache_dirty: bool = true
var _cached_speed_multiply: float = 1.0
var _cached_speed_add: float = 0.0
var _cached_gravity_multiply: float = 1.0
var _cached_jump_multiply: float = 1.0
var _cached_damage_multiply: float = 1.0
var _cached_time_scale: float = 1.0
var _cached_is_invincible: bool = false
var _cached_is_frozen: bool = false
var _cached_custom: Dictionary = {}  # {custom_key: float}

func _process(delta: float) -> void:
	_tick_buffs(delta)

#region 添加 / 移除

## 添加一个 Buff
func add_buff(effect: BuffEffect) -> void:
	if effect.id == &"":
		push_warning("[BuffComponent] Buff 没有 id，忽略")
		return
	
	if _active_buffs.has(effect.id):
		var active: ActiveBuff = _active_buffs[effect.id]
		# 已存在 → 叠加
		if active.current_stacks < effect.max_stacks:
			active.current_stacks += 1
			buff_stacked.emit(effect.id, active.current_stacks)
		if effect.refresh_on_stack:
			active.remaining_time = effect.duration
		_mark_dirty()
		return
	
	# 新 Buff
	var active := ActiveBuff.new(effect)
	_active_buffs[effect.id] = active
	_mark_dirty()
	buff_added.emit(effect.id)

## 移除一个 Buff（全部层数）
func remove_buff(buff_id: StringName) -> void:
	if not _active_buffs.has(buff_id): return
	_active_buffs.erase(buff_id)
	_mark_dirty()
	buff_removed.emit(buff_id)

## 移除一层
func remove_buff_stack(buff_id: StringName, stacks_to_remove: int = 1) -> void:
	if not _active_buffs.has(buff_id): return
	var active: ActiveBuff = _active_buffs[buff_id]
	active.current_stacks -= stacks_to_remove
	if active.current_stacks <= 0:
		remove_buff(buff_id)
	else:
		_mark_dirty()
		buff_stacked.emit(buff_id, active.current_stacks)

## 清除所有 Buff
func clear_all_buffs() -> void:
	var ids := _active_buffs.keys().duplicate()
	_active_buffs.clear()
	_mark_dirty()
	for id in ids:
		buff_removed.emit(id)

## 清除所有 Debuff
func clear_all_debuffs() -> void:
	var to_remove: Array[StringName] = []
	for buff_id in _active_buffs:
		var active: ActiveBuff = _active_buffs[buff_id]
		if active.effect.is_debuff:
			to_remove.append(buff_id)
	for buff_id in to_remove:
		remove_buff(buff_id)

#endregion

#region 查询聚合值

## 获取最终速度倍率（所有速度 Buff 相乘）
func get_speed_multiplier() -> float:
	_ensure_cache()
	return _cached_speed_multiply

## 获取速度附加值
func get_speed_add() -> float:
	_ensure_cache()
	return _cached_speed_add

## 获取重力倍率
func get_gravity_multiplier() -> float:
	_ensure_cache()
	return _cached_gravity_multiply

## 获取跳跃力倍率
func get_jump_multiplier() -> float:
	_ensure_cache()
	return _cached_jump_multiply

## 获取伤害倍率
func get_damage_multiplier() -> float:
	_ensure_cache()
	return _cached_damage_multiply

## 获取个体时间缩放
func get_time_scale() -> float:
	_ensure_cache()
	return _cached_time_scale

## 是否无敌
func is_invincible() -> bool:
	_ensure_cache()
	return _cached_is_invincible

## 是否冻结
func is_frozen() -> bool:
	_ensure_cache()
	return _cached_is_frozen

## 获取自定义 Buff 值
func get_custom_value(key: StringName, default_value: float = 0.0) -> float:
	_ensure_cache()
	return _cached_custom.get(key, default_value)

## 检查是否有某个 Buff
func has_buff(buff_id: StringName) -> bool:
	return _active_buffs.has(buff_id)

## 获取某个 Buff 的剩余时间
func get_buff_remaining_time(buff_id: StringName) -> float:
	if not _active_buffs.has(buff_id): return 0.0
	return (_active_buffs[buff_id] as ActiveBuff).remaining_time

## 获取某个 Buff 的当前层数
func get_buff_stacks(buff_id: StringName) -> int:
	if not _active_buffs.has(buff_id): return 0
	return (_active_buffs[buff_id] as ActiveBuff).current_stacks

## 获取所有活跃 Buff 的 id 列表
func get_active_buff_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for buff_id in _active_buffs:
		ids.append(buff_id)
	return ids

#endregion

#region 内部更新

func _tick_buffs(delta: float) -> void:
	var expired: Array[StringName] = []
	
	for buff_id in _active_buffs:
		var active: ActiveBuff = _active_buffs[buff_id]
		if active.is_permanent: continue
		
		active.remaining_time -= delta
		if active.remaining_time <= 0.0:
			expired.append(buff_id)
	
	for buff_id in expired:
		remove_buff(buff_id)

func _mark_dirty() -> void:
	_cache_dirty = true
	buffs_changed.emit()

func _ensure_cache() -> void:
	if not _cache_dirty: return
	_recalculate_cache()
	_cache_dirty = false

func _recalculate_cache() -> void:
	# 重置
	_cached_speed_multiply = 1.0
	_cached_speed_add = 0.0
	_cached_gravity_multiply = 1.0
	_cached_jump_multiply = 1.0
	_cached_damage_multiply = 1.0
	_cached_time_scale = 1.0
	_cached_is_invincible = false
	_cached_is_frozen = false
	_cached_custom.clear()
	
	for buff_id in _active_buffs:
		var active: ActiveBuff = _active_buffs[buff_id]
		var eff := active.effect
		var stacks := active.current_stacks
		
		match eff.type:
			BuffEffect.BuffType.SPEED_MULTIPLY:
				# 多个速度倍率相乘：1.5 * 0.8 = 1.2
				for i in stacks:
					_cached_speed_multiply *= eff.value
			
			BuffEffect.BuffType.SPEED_ADD:
				_cached_speed_add += eff.value * stacks
			
			BuffEffect.BuffType.GRAVITY_MULTIPLY:
				for i in stacks:
					_cached_gravity_multiply *= eff.value
			
			BuffEffect.BuffType.JUMP_MULTIPLY:
				for i in stacks:
					_cached_jump_multiply *= eff.value
			
			BuffEffect.BuffType.DAMAGE_MULTIPLY:
				for i in stacks:
					_cached_damage_multiply *= eff.value
			
			BuffEffect.BuffType.INVINCIBLE:
				_cached_is_invincible = true
			
			BuffEffect.BuffType.FREEZE:
				_cached_is_frozen = true
			
			BuffEffect.BuffType.TIME_SCALE:
				# 取最小的时间缩放（最慢的效果优先）
				_cached_time_scale = minf(_cached_time_scale, eff.value)
			
			BuffEffect.BuffType.CUSTOM:
				if eff.custom_key != &"":
					var prev: float = _cached_custom.get(eff.custom_key, 0.0)
					_cached_custom[eff.custom_key] = prev + eff.value * stacks

#endregion

#region 调试

func get_component_data() -> Dictionary:
	_ensure_cache()
	var buff_list := {}
	for buff_id in _active_buffs:
		var active: ActiveBuff = _active_buffs[buff_id]
		buff_list[buff_id] = {
			"type": BuffEffect.BuffType.keys()[active.effect.type],
			"value": active.effect.value,
			"stacks": active.current_stacks,
			"remaining": snappedf(active.remaining_time, 0.1) if not active.is_permanent else "permanent",
		}
	return {
		"type": "BuffComponent",
		"active_buffs": buff_list,
		"speed_multiply": _cached_speed_multiply,
		"gravity_multiply": _cached_gravity_multiply,
		"is_invincible": _cached_is_invincible,
		"is_frozen": _cached_is_frozen,
	}

#endregion
