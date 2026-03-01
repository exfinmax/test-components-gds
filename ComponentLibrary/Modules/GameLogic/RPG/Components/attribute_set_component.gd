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
func add_modifier(source_id: StringName, attr: StringName,
		value: float, type: ModType = ModType.FLAT) -> void:
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
		value: float, type: ModType = ModType.FLAT) -> void:
	if not _modifiers.has(source_id):
		_modifiers[source_id] = {}
	var src: Dictionary = _modifiers[source_id]
	var old := get_attribute(attr)
	var kept: Array = []
	for m: Dictionary in (src.get(attr, []) as Array):
		if int(m.get("type", 0)) != int(type):
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
	for a: StringName in touched:
		snaps[a] = get_attribute(a)
	_modifiers.erase(source_id)
	for a: StringName in touched:
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
		for m: Dictionary in (src.get(name, []) as Array):
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


@export var base_attributes: Dictionary = {
	&"hp": 100.0,
	&"attack": 10.0,
	&"defense": 5.0,
}

var _modifiers_by_source: Dictionary = {}

func set_base_attribute(name: StringName, value: float) -> void:
	var old_value := get_attribute(name)
	base_attributes[name] = value
	var new_value := get_attribute(name)
	_emit_attribute_change(name, old_value, new_value)

func add_modifier(source_id: StringName, name: StringName, delta: float) -> void:
	if not _modifiers_by_source.has(source_id):
		_modifiers_by_source[source_id] = {}
	var source_mods: Dictionary = _modifiers_by_source[source_id]
	var old_value := get_attribute(name)
	source_mods[name] = float(source_mods.get(name, 0.0)) + delta
	_modifiers_by_source[source_id] = source_mods
	var new_value := get_attribute(name)
	_emit_attribute_change(name, old_value, new_value)

func set_modifier(source_id: StringName, name: StringName, value: float) -> void:
	if not _modifiers_by_source.has(source_id):
		_modifiers_by_source[source_id] = {}
	var source_mods: Dictionary = _modifiers_by_source[source_id]
	var old_value := get_attribute(name)
	source_mods[name] = value
	_modifiers_by_source[source_id] = source_mods
	var new_value := get_attribute(name)
	_emit_attribute_change(name, old_value, new_value)

func remove_modifier_source(source_id: StringName) -> void:
	if not _modifiers_by_source.has(source_id):
		return

	var touched_attrs: Dictionary = {}
	for attr_name in (_modifiers_by_source[source_id] as Dictionary).keys():
		touched_attrs[attr_name] = get_attribute(attr_name)

	_modifiers_by_source.erase(source_id)

	for attr_name in touched_attrs.keys():
		var old_value: float = touched_attrs[attr_name]
		var new_value := get_attribute(attr_name)
		_emit_attribute_change(attr_name, old_value, new_value)

func clear_modifiers() -> void:
	var snapshot := {}
	for key in base_attributes.keys():
		snapshot[key] = get_attribute(key)
	_modifiers_by_source.clear()
	for key in snapshot.keys():
		_emit_attribute_change(key, float(snapshot[key]), get_attribute(key))

func get_attribute(name: StringName) -> float:
	var value := float(base_attributes.get(name, 0.0))
	for source in _modifiers_by_source.keys():
		var source_mods: Dictionary = _modifiers_by_source[source]
		value += float(source_mods.get(name, 0.0))
	return value

func get_all_attributes() -> Dictionary:
	var result := {}
	for key in base_attributes.keys():
		result[key] = get_attribute(key)
	return result

func _emit_attribute_change(name: StringName, old_value: float, new_value: float) -> void:
	if is_equal_approx(old_value, new_value):
		return
	attribute_changed.emit(name, old_value, new_value)
	if new_value <= 0.0 and old_value > 0.0:
		attribute_zeroed.emit(name)
