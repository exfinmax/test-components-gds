## 效果管理系统 - 管理临时效果和减益
## 
## 特性：
## - 效果的应用、持续、移除
## - 多个同类效果的处理（堆叠/覆盖）
## - 效果标签系统
## - 周期性效果（如持续伤害）
## 
## 使用示例：
##   var effect = EffectManager.new()
##   var burn = EffectData.new("Burn", 3.0)
##   burn.on_tick = func(delta): take_damage(5)
##   effect.apply_effect(burn)
##
extends Node
class_name EffectManager

## 效果数据
class EffectData:
	var effect_name: String = ""
	var duration: float = 0.0  # 0 表示永久
	var tick_interval: float = 0.0  # 0 表示不周期性
	var max_stacks: int = 1  # 最大堆叠数
	var can_stack: bool = true
	var should_replace: bool = false  # 是否替换同名效果
	
	var current_stacks: int = 1
	var elapsed: float = 0.0
	var tick_elapsed: float = 0.0
	
	var is_active: bool = true
	
	## 用于效果具体逻辑的代理
	var on_apply: Callable = func(): pass
	var on_tick: Callable = func(delta): pass
	var on_remove: Callable = func(): pass

## 活跃效果列表
var active_effects: Array[EffectData] = []

## 效果应用信号
signal effect_applied(effect: EffectData)
signal effect_stacked(effect: EffectData, new_stacks: int)
signal effect_ticked(effect: EffectData)
signal effect_removed(effect: EffectData)

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	var effects_to_remove = []
	
	for effect in active_effects:
		if not effect.is_active:
			continue
		
		# 更新持续时间
		effect.elapsed += delta
		if effect.duration > 0 and effect.elapsed >= effect.duration:
			effects_to_remove.append(effect)
			continue
		
		# 处理周期性效果
		if effect.tick_interval > 0:
			effect.tick_elapsed += delta
			if effect.tick_elapsed >= effect.tick_interval:
				effect.tick_elapsed -= effect.tick_interval
				effect.on_tick.call(effect.tick_interval)
				effect_ticked.emit(effect)

## 应用效果
func apply_effect(effect: EffectData) -> void:
	# 检查是否存在同名效果
	var existing_effect = _find_effect(effect.effect_name)
	
	if existing_effect:
		if effect.should_replace:
			# 替换模式：移除旧效果，应用新效果
			remove_effect(existing_effect)
			_apply_new_effect(effect)
		elif existing_effect.can_stack and effect.can_stack:
			# 堆叠模式：增加堆叠数
			existing_effect.current_stacks = min(
				existing_effect.current_stacks + 1,
				existing_effect.max_stacks
			)
			effect_stacked.emit(existing_effect, existing_effect.current_stacks)
			# 重置持续时间
			existing_effect.elapsed = 0.0
		# 否则忽略此效果
	else:
		_apply_new_effect(effect)

## 内部：应用新效果
func _apply_new_effect(effect: EffectData) -> void:
	active_effects.append(effect)
	effect.on_apply.call()
	effect_applied.emit(effect)

## 移除指定效果
func remove_effect(effect: EffectData) -> void:
	if effect in active_effects:
		active_effects.erase(effect)
		effect.on_remove.call()
		effect_removed.emit(effect)

## 移除指定名称的所有效果
func remove_effect_by_name(effect_name: String) -> void:
	var effects_to_remove = []
	for effect in active_effects:
		if effect.effect_name == effect_name:
			effects_to_remove.append(effect)
	
	for effect in effects_to_remove:
		remove_effect(effect)

## 清空所有效果
func clear_all_effects() -> void:
	var effects_copy = active_effects.duplicate()
	for effect in effects_copy:
		remove_effect(effect)

## 查找指定名称的效果
func _find_effect(effect_name: String) -> EffectData:
	for effect in active_effects:
		if effect.effect_name == effect_name:
			return effect
	return null

## 检查是否有指定效果
func has_effect(effect_name: String) -> bool:
	return _find_effect(effect_name) != null

## 获取指定效果
func get_effect(effect_name: String) -> EffectData:
	return _find_effect(effect_name)

## 获取所有活跃效果
func get_all_effects() -> Array[EffectData]:
	return active_effects.duplicate()

## 获取活跃效果数量
func get_effect_count() -> int:
	return active_effects.size()

## 获取指定效果的堆叠数
func get_effect_stacks(effect_name: String) -> int:
	var effect = _find_effect(effect_name)
	if effect:
		return effect.current_stacks
	return 0

## 获取指定效果的剩余时间
func get_effect_remaining(effect_name: String) -> float:
	var effect = _find_effect(effect_name)
	if effect:
		if effect.duration == 0:
			return -1.0  # 永久效果
		return max(0.0, effect.duration - effect.elapsed)
	return 0.0

## 调试：输出效果信息
func debug_effects() -> String:
	var output = "=== Active Effects ===\n"
	for effect in active_effects:
		var remaining = "∞"
		if effect.duration > 0:
			remaining = "%.1fs" % max(0.0, effect.duration - effect.elapsed)
		output += "%s (x%d): %s\n" % [
			effect.effect_name,
			effect.current_stacks,
			remaining
		]
	return output
