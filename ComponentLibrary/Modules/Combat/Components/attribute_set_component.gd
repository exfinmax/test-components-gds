extends ComponentBase
class_name AttributeSetComponent

signal attribute_changed(attr_name: StringName, old_value: float, new_value: float)

enum ModType {
	FLAT,
	PERCENT_ADD,
	MULTIPLY,
	CLAMP_MIN,
	CLAMP_MAX,
}

var _base_attributes: Dictionary = {}
var _modifiers_by_attr: Dictionary = {}
var _modifiers_by_source: Dictionary = {}

func set_base_attribute(attr_name: StringName, value: float) -> void:
	var old_value := get_attribute(attr_name)
	_base_attributes[attr_name] = value
	var new_value := get_attribute(attr_name)
	if not is_equal_approx(old_value, new_value):
		attribute_changed.emit(attr_name, old_value, new_value)

func get_base_attribute(attr_name: StringName) -> float:
	return float(_base_attributes.get(attr_name, 0.0))

func modify_base_attribute(attr_name: StringName, delta: float) -> void:
	set_base_attribute(attr_name, get_base_attribute(attr_name) + delta)

func get_attribute(attr_name: StringName) -> float:
	var base := get_base_attribute(attr_name)
	var flat := 0.0
	var percent_add := 0.0
	var multiply := 1.0
	var clamp_min: Variant = null
	var clamp_max: Variant = null
	for modifier in _modifiers_by_attr.get(attr_name, []):
		match int(modifier.get("type", ModType.FLAT)):
			ModType.FLAT:
				flat += float(modifier.get("value", 0.0))
			ModType.PERCENT_ADD:
				percent_add += float(modifier.get("value", 0.0))
			ModType.MULTIPLY:
				multiply *= float(modifier.get("value", 1.0))
			ModType.CLAMP_MIN:
				var v := float(modifier.get("value", 0.0))
				clamp_min = v if clamp_min == null else maxf(float(clamp_min), v)
			ModType.CLAMP_MAX:
				var v := float(modifier.get("value", 0.0))
				clamp_max = v if clamp_max == null else minf(float(clamp_max), v)
	var result := (base + flat) * (1.0 + percent_add) * multiply
	if clamp_min != null:
		result = maxf(result, float(clamp_min))
	if clamp_max != null:
		result = minf(result, float(clamp_max))
	return result

func add_modifier(source_id: StringName, attr_name: StringName, value: float, mod_type: ModType) -> void:
	var old_value := get_attribute(attr_name)
	var modifier := {
		"source": source_id,
		"attr": attr_name,
		"value": value,
		"type": mod_type,
	}
	var attr_modifiers: Array = _modifiers_by_attr.get(attr_name, [])
	attr_modifiers.append(modifier)
	_modifiers_by_attr[attr_name] = attr_modifiers
	var source_modifiers: Array = _modifiers_by_source.get(source_id, [])
	source_modifiers.append(modifier)
	_modifiers_by_source[source_id] = source_modifiers
	var new_value := get_attribute(attr_name)
	if not is_equal_approx(old_value, new_value):
		attribute_changed.emit(attr_name, old_value, new_value)

func remove_modifier_source(source_id: StringName) -> void:
	if not _modifiers_by_source.has(source_id):
		return
	var affected: Dictionary = {}
	for modifier in _modifiers_by_source[source_id]:
		affected[modifier["attr"]] = get_attribute(modifier["attr"])
		var attr_modifiers: Array = _modifiers_by_attr.get(modifier["attr"], [])
		attr_modifiers = attr_modifiers.filter(func(item): return item.get("source") != source_id)
		_modifiers_by_attr[modifier["attr"]] = attr_modifiers
	_modifiers_by_source.erase(source_id)
	for attr_name in affected.keys():
		var old_value := float(affected[attr_name])
		var new_value := get_attribute(attr_name)
		if not is_equal_approx(old_value, new_value):
			attribute_changed.emit(attr_name, old_value, new_value)

func has_modifier_source(source_id: StringName) -> bool:
	return _modifiers_by_source.has(source_id)

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"base_attributes": _base_attributes.duplicate(true),
		"modifier_sources": _modifiers_by_source.keys(),
	}
