extends Node
class_name AttributeSetComponent

signal attribute_changed(name: StringName, old_value: float, new_value: float)
signal attribute_zeroed(name: StringName)

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
