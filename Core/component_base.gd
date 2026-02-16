@abstract
extends Node
class_name ComponentBase
## 通用组件基类 - 所有 Node 类型组件的根基类
##
## 提供所有组件共享的基础能力：
##   1. enabled 开关 + enabled_changed 信号 + _on_enable/_on_disable 虚方法
##   2. _component_ready() 初始化钩子（替代 _ready 避免忘调 super）
##   3. get_component_data() 自省接口（调试/存档用）
##   4. find_sibling / find_siblings 同级组件查找
##
## 继承关系：
##   ComponentBase (Node) ← 所有可以用 Node 基类的组件
##   ├── CharacterComponentBase ← 角色能力组件（+character引用, self_driven, tick）
##   ├── RecordComponent, ReplayComponent, HitFlashComponent ...
##
## 对于必须继承 Area2D / Node2D 的组件（HitBox, HurtBox, HealthComponent 等），
## 无法使用此基类，但建议手动复制 enabled + get_component_data 模式保持一致性。

#region 启用/禁用

signal enabled_changed(is_enabled: bool)

## 组件是否启用 - 设置后自动触发信号和回调
var enabled: bool = true:
	set(v):
		if enabled == v: return
		enabled = v
		enabled_changed.emit(enabled)
		if enabled:
			_on_enable()
		else:
			_on_disable()

## 子类重写：启用时的回调
func _on_enable() -> void:
	pass

## 子类重写：禁用时的回调
func _on_disable() -> void:
	pass

#endregion

#region 生命周期

func _ready() -> void:
	_component_ready()

## 子类重写此方法进行初始化（替代 _ready）
## 注意：如果子类自己覆盖了 _ready()，需要手动调用 _component_ready()
func _component_ready() -> void:
	pass

#endregion

#region 自省

## 获取组件自省数据 - 子类应重写
func get_component_data() -> Dictionary:
	return {"enabled": enabled}
	

#endregion

#region 同级组件查找

## 查找同级第一个匹配类型的组件
## 搜索范围：owner 的所有子节点（排除自身）
func find_sibling(type: GDScript) -> Node:
	var search_root := owner if owner else get_parent()
	if not search_root: return null
	for child in search_root.get_children():
		if child != self and is_instance_of(child, type):
			return child
	return null

## 查找同级所有匹配类型的组件
func find_siblings(type: GDScript) -> Array[Node]:
	var result: Array[Node] = []
	var search_root := owner if owner else get_parent()
	if not search_root: return result
	for child in search_root.get_children():
		if child != self and is_instance_of(child, type):
			result.append(child)
	return result

## 按类名查找同级组件（当没有 GDScript 引用时使用）
func find_sibling_by_class(class_name_str: StringName) -> Node:
	var search_root := owner if owner else get_parent()
	if not search_root: return null
	for child in search_root.get_children():
		if child != self and child.get_class() == class_name_str:
			return child
	return null

#endregion
