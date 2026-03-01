## 冷却系统 - 通用的冷却管理
## 
## 特性：
## - 支持多个独立冷却计时器
## - 冷却ID识别
## - 冷却完成回调
## - 与AbilityComponent集成
## 
## 使用示例：
##   var cooldown = CooldownComponent.new()
##   cooldown.start_cooldown("attack", 2.0)
##   if cooldown.is_on_cooldown("attack"):
##       print("Cannot attack, cooldown active")
##
extends Node
class_name CooldownComponent

## 冷却条目
class CooldownEntry:
	var cooldown_id: String
	var duration: float
	var elapsed: float = 0.0
	var is_active: bool = true
	
	func _init(p_id: String, p_duration: float) -> void:
		cooldown_id = p_id
		duration = p_duration
	
	func tick(delta: float) -> bool:
		if not is_active:
			return false
		
		elapsed += delta
		return elapsed >= duration
	
	func get_remaining() -> float:
		return max(0.0, duration - elapsed)
	
	func get_progress() -> float:
		if duration == 0:
			return 1.0
		return min(1.0, elapsed / duration)

## 活跃的冷却计时器 ID -> CooldownEntry
var active_cooldowns: Dictionary[String, CooldownEntry] = {}

## 冷却完成信号
signal cooldown_started(cooldown_id: String, duration: float)
signal cooldown_finished(cooldown_id: String)

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	var finished_cooldowns = []
	
	for cooldown_id in active_cooldowns:
		var entry = active_cooldowns[cooldown_id]
		if entry.tick(delta):
			finished_cooldowns.append(cooldown_id)
	
	for cooldown_id in finished_cooldowns:
		active_cooldowns.erase(cooldown_id)
		cooldown_finished.emit(cooldown_id)

## 启动冷却
func start_cooldown(cooldown_id: String, duration: float) -> void:
	if cooldown_id in active_cooldowns:
		# 如果已存在，更新其持续时间
		active_cooldowns[cooldown_id].duration = duration
		active_cooldowns[cooldown_id].elapsed = 0.0
	else:
		active_cooldowns[cooldown_id] = CooldownEntry.new(cooldown_id, duration)
	
	cooldown_started.emit(cooldown_id, duration)

## 检查冷却是否激活
func is_on_cooldown(cooldown_id: String) -> bool:
	return cooldown_id in active_cooldowns

## 获取冷却剩余时间
func get_remaining(cooldown_id: String) -> float:
	if not cooldown_id in active_cooldowns:
		return 0.0
	return active_cooldowns[cooldown_id].get_remaining()

## 获取冷却进度百分比 (0.0 - 1.0)
func get_progress(cooldown_id: String) -> float:
	if not cooldown_id in active_cooldowns:
		return 1.0
	return active_cooldowns[cooldown_id].get_progress()

## 强制完成冷却
func finish_cooldown(cooldown_id: String) -> void:
	if cooldown_id in active_cooldowns:
		active_cooldowns.erase(cooldown_id)
		cooldown_finished.emit(cooldown_id)

## 强制取消冷却
func cancel_cooldown(cooldown_id: String) -> void:
	if cooldown_id in active_cooldowns:
		active_cooldowns.erase(cooldown_id)

## 清空所有冷却
func clear_all_cooldowns() -> void:
	active_cooldowns.clear()

## 获取所有活跃的冷却ID
func get_active_cooldowns() -> Array[String]:
	return active_cooldowns.keys()

## 获取冷却数量
func get_cooldown_count() -> int:
	return active_cooldowns.size()

## 调试：输出冷却信息
func debug_cooldowns() -> String:
	var output = "=== Active Cooldowns ===\n"
	for cooldown_id in active_cooldowns:
		var entry = active_cooldowns[cooldown_id]
		var remaining = entry.get_remaining()
		output += "%s: %.2fs remaining (%.1f%%)\n" % [
			cooldown_id,
			remaining,
			entry.get_progress() * 100
		]
	return output
