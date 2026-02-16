extends Node
class_name SaveableComponent
## 可存档组件 - 挂在需要持久化的节点上
##
## 使用方式：
##   1. 作为子节点添加到需要存档的节点
##   2. 设置唯一的 node_uuid（或自动生成）
##   3. 重写 get_save_data() 返回需要保存的数据
##   4. 重写 apply_save_data() 恢复数据
##
## GDS 没有接口，所以用继承实现多态。C# 版本用 ISaveable 接口替代。

@export var node_uuid: String = ""
@export var is_static: bool = true        ## 静态节点退出场景树时不注销
@export var auto_load: bool = false        ## _ready 时自动加载存档
@export var apply_delay_frames: int = 0    ## 延迟帧数（等待其他初始化完成）

func _ready() -> void:
	if node_uuid.is_empty():
		node_uuid = "%s_%d" % [owner.name if owner else name, randi()]

	_register()

	if auto_load:
		_try_auto_load()

func _exit_tree() -> void:
	if not is_static:
		_unregister()

#region 子类重写

## 返回需要保存的数据（子类必须重写）
func get_save_data() -> Dictionary:
	return {}

## 应用加载的数据（子类必须重写）
func apply_save_data(_data: Dictionary) -> void:
	pass

#endregion

#region 手动操作

func save_now() -> void:
	var sm := _get_save_manager()
	if sm:
		sm.save_node_data(node_uuid, get_save_data())

#endregion

#region 内部

func _register() -> void:
	var sm := _get_save_manager()
	if sm:
		sm.register_saveable(self)

func _unregister() -> void:
	var sm := _get_save_manager()
	if sm:
		sm.unregister_saveable(self)

func _try_auto_load() -> void:
	var sm := _get_save_manager()
	if not sm or not sm.has_save(): return

	var sd: SaveData = sm.get_data(node_uuid)
	if not sd: return

	if apply_delay_frames > 0:
		for i in apply_delay_frames:
			await get_tree().process_frame
	apply_save_data(sd.data)

func _get_save_manager() -> Node:
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("SaveManager")
	return null

#endregion

func get_component_data() -> Dictionary:
	return {
		"node_uuid": node_uuid,
		"is_static": is_static,
		"auto_load": auto_load,
	}
