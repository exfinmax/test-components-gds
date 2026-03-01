extends ComponentBase
class_name CooldownComponent
## 冷却组件 — 多标签并发冷却管理器
##
## 支持为任意 StringName 标签独立启动冷却。
## 可用于技能冷却、攻击间隔、道具使用频率等所有需要"等待后才能再用"的场景。
##
## 与 BuffComponent 的区别：
##   CooldownComponent 只管"能不能用"、"还剩多久"；
##   BuffComponent 管理"正在生效的临时效果"。
##
## 典型用法：
##   cooldown.start_cooldown(&"attack", 0.5)
##   if cooldown.is_ready(&"attack"):
##       cooldown.start_cooldown(&"attack", 0.5)
##       _do_attack()

signal cooldown_started(tag: StringName, duration: float)
signal cooldown_ready(tag: StringName)
signal cooldown_updated(tag: StringName, remaining: float, duration: float)


var _cooldowns: Dictionary = {}


func _process(delta: float) -> void:
	tick(delta)

func tick(delta: float) -> void:
	if not enabled:
		return
	if _cooldowns.is_empty():
		return

	var finished: Array[StringName] = []
	for tag in _cooldowns.keys():
		var data: Dictionary = _cooldowns[tag]
		var remaining: float = maxf(0.0, data["remaining"] - delta)
		data["remaining"] = remaining
		_cooldowns[tag] = data
		cooldown_updated.emit(tag, remaining, data["duration"])
		if remaining <= 0.0:
			finished.append(tag)

	for tag in finished:
		_cooldowns.erase(tag)
		cooldown_ready.emit(tag)

func start_cooldown(tag: StringName, duration: float) -> void:
	if duration <= 0.0:
		_cooldowns.erase(tag)
		cooldown_ready.emit(tag)
		return
	_cooldowns[tag] = {"duration": duration, "remaining": duration}
	cooldown_started.emit(tag, duration)

func clear_cooldown(tag: StringName) -> void:
	if _cooldowns.erase(tag):
		cooldown_ready.emit(tag)

func clear_all() -> void:
	var tags := _cooldowns.keys()
	_cooldowns.clear()
	for tag in tags:
		cooldown_ready.emit(tag)

func is_ready(tag: StringName) -> bool:
	return not _cooldowns.has(tag)

func get_remaining(tag: StringName) -> float:
	if not _cooldowns.has(tag):
		return 0.0
	return (_cooldowns[tag] as Dictionary).get("remaining", 0.0)

func get_duration(tag: StringName) -> float:
	if not _cooldowns.has(tag):
		return 0.0
	return (_cooldowns[tag] as Dictionary).get("duration", 0.0)

## 返回冷却进度 0.0（刚开始）→ 1.0（可用）。不在冷却中时返回 1.0。
func get_progress(tag: StringName) -> float:
	if not _cooldowns.has(tag):
		return 1.0
	var data: Dictionary = _cooldowns[tag]
	var dur: float = float(data.get("duration", 0.0))
	if dur <= 0.0:
		return 1.0
	return 1.0 - float(data.get("remaining", 0.0)) / dur

## is_on_cooldown 是 is_ready 的语义反转别名，适合"攻击型"写法。
func is_on_cooldown(tag: StringName) -> bool:
	return _cooldowns.has(tag)

## 返回当前所有正在冷却的标签。
func get_active_tags() -> Array:
	return _cooldowns.keys()

func get_component_data() -> Dictionary:
	var tags: Dictionary = {}
	for tag in _cooldowns:
		var data: Dictionary = _cooldowns[tag]
		tags[String(tag)] = {
			"remaining": data["remaining"],
			"duration": data["duration"],
		}
	return {
		"enabled": enabled,
		"count": _cooldowns.size(),
		"cooldowns": tags,
	}
