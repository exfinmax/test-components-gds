extends Node
class_name AttributeSetComponent
## 属性集组件 — 管理角色/物体的数值属性及其修饰符
##
## 修饰符按来源（source_id）成组管理，移除整个来源不会遗漏单条。
## 计算顺序：base + FLAT → × (1 + PERCENT_ADD) → × MULTIPLY → CLAMP
##
## 与 BuffComponent 的协作：
##   Buff 生效/消失时调用 add_modifier / remove_modifier_source；
##   本组件只负责"数值是多少"，不关心效果来自哪里。
##
## 典型用法：
##   attrs.set_base_attribute(&"attack", 20.0)
##   attrs.add_modifier(&"iron_sword", &"attack", 15.0, ModType.FLAT)
##   attrs.add_modifier(&"iron_sword", &"attack",  0.2, ModType.PERCENT_ADD)
##   print(attrs.get_attribute(&"attack"))  # (20+15) × 1.2 = 42.0

signal attribute_changed(name: StringName, old_value: float, new_value: float)
signal attribute_zeroed(name: StringName)

## 修饰符类型（计算顺序即枚举值顺序）
enum ModType {
	FLAT        = 0,  ## 加法叠加：        base + sum(flat)
	PERCENT_ADD = 1,  ## 百分比加法叠加：  × (1 + 0.1 + 0.2 …)
	MULTIPLY    = 2,  ## 独立乘法：        × 1.3 × 1.5 …（比PERCENT_ADD更强）
	CLAMP_MIN   = 3,  ## 最小值下限
	CLAMP_MAX   = 4,  ## 最大值上限
}

@export var base_attributes: Dictionary = {
	&"hp":      100.0,
	&"attack":   10.0,
	&"defense":   5.0,
}

## source_id → attr_name → Array[{type:ModType, value:float}]
var _modifiers: Dictionary = {}


# ─── 基础属性 ────────────────────────────────────────────────────

func set_base_attribute(name: StringName, value: float) -> void:
	var old := get_attribute(name)
	base_attributes[name] = value
	_emit_change(name, old, get_attribute(name))

## 在当前基础值上做增量修改（常用于扣血、回血）。
func modify_base_attribute(name: StringName, delta: float) -> void:
	set_base_attribute(name, float(base_attributes.get(name, 0.0)) + delta)

func get_base_attribute(name: StringName) -> float:
	return float(base_attributes.get(name, 0.0))


# ─── 修饰符管理 ──────────────────────────────────────────────────

## 添加一条修饰符。同一 source_id 下允许同属性多条不同类型的修饰符。
## type 传 ModType 枚举值（int）
func add_modifier(source_id: StringName, attr: StringName,
		value: float, type: int = ModType.FLAT) -> void:
	if not _modifiers.has(source_id):
		_modifiers[source_id] = {}
	var src: Dictionary = _modifiers[source_id]
	if not src.has(attr):
		src[attr] = []
	var old := get_attribute(attr)
	(src[attr] as Array).append({"type": type, "value": value})
	_emit_change(attr, old, get_attribute(attr))

## 覆盖某来源在某属性上的指定类型修饰符（更新装备时无需先 remove）。
func set_modifier(source_id: StringName, attr: StringName,
		value: float, type: int = ModType.FLAT) -> void:
	if not _modifiers.has(source_id):
		_modifiers[source_id] = {}
	var src: Dictionary = _modifiers[source_id]
	var old := get_attribute(attr)
	var kept: Array = []
	for m in (src.get(attr, []) as Array):
		if int(m.get("type", 0)) != type:
			kept.append(m)
	kept.append({"type": type, "value": value})
	src[attr] = kept
	_emit_change(attr, old, get_attribute(attr))

## 移除某来源的所有修饰符（装备卸下、Buff 消失时调用）。
func remove_modifier_source(source_id: StringName) -> void:
	if not _modifiers.has(source_id):
		return
	var touched: Array = (_modifiers[source_id] as Dictionary).keys()
	var snaps: Dictionary = {}
	for a in touched:
		snaps[a] = get_attribute(a)
	_modifiers.erase(source_id)
	for a in touched:
		_emit_change(a, float(snaps[a]), get_attribute(a))

func clear_modifiers() -> void:
	var snap := get_all_attributes()
	_modifiers.clear()
	for a in snap.keys():
		_emit_change(a, float(snap[a]), get_attribute(a))

func has_modifier_source(source_id: StringName) -> bool:
	return _modifiers.has(source_id)


# ─── 属性读取 ────────────────────────────────────────────────────

func get_attribute(name: StringName) -> float:
	var base       := float(base_attributes.get(name, 0.0))
	var flat_sum   := 0.0
	var pct_add    := 0.0
	var multiplier := 1.0
	var clamp_min  := -INF
	var clamp_max  :=  INF

	for src_id in _modifiers.keys():
		var src: Dictionary = _modifiers[src_id]
		for m in (src.get(name, []) as Array):
			var v := float(m.get("value", 0.0))
			match int(m.get("type", 0)):
				ModType.FLAT:        flat_sum   += v
				ModType.PERCENT_ADD: pct_add    += v
				ModType.MULTIPLY:    multiplier *= v
				ModType.CLAMP_MIN:   clamp_min   = maxf(clamp_min, v)
				ModType.CLAMP_MAX:   clamp_max   = minf(clamp_max, v)

	var result := (base + flat_sum) * (1.0 + pct_add) * multiplier
	return clampf(result, clamp_min, clamp_max)

func get_all_attributes() -> Dictionary:
	var result: Dictionary = {}
	for key in base_attributes.keys():
		result[key] = get_attribute(key)
	return result

func has_attribute(name: StringName) -> bool:
	return base_attributes.has(name)


# ─── 内部 ────────────────────────────────────────────────────────

func _emit_change(name: StringName, old_val: float, new_val: float) -> void:
	if is_equal_approx(old_val, new_val):
		return
	attribute_changed.emit(name, old_val, new_val)
	if new_val <= 0.0 and old_val > 0.0:
		attribute_zeroed.emit(name)

func get_component_data() -> Dictionary:
	return {
		"base":    base_attributes.duplicate(),
		"final":   get_all_attributes(),
		"sources": _modifiers.keys(),
	}
