@abstract ##— 抽象基类，不可直接实例化，必须继承后实现所有 [abstract] 方法
class_name ISaveModule
extends RefCounted
## 存档模块抽象基类
##
## ⚠ Abstract Class — 不可直接实例化
##   GDScript 暂无原生 abstract 关键字，此处用 assert(false) 在 Debug 模式下强制崩溃提示。
##
## 继承示例：
##   class MyLevelModule extends ISaveModule:
##       func get_module_key() -> String: return "level"
##       func is_global() -> bool: return false
##       func collect_data() -> Dictionary:
##           return { "current_level": GameState.current_level }
##       func apply_data(data: Dictionary) -> void:
##           GameState.current_level = data.get("current_level", 1)
##
## 存储复杂资源（继承 SaveResource）：
##   collect_data 中：ResourceSerializer.serialize(my_resource)
##   apply_data   中：ResourceSerializer.deserialize(data["key"]) as MyResource
##   使用前需注册：  ResourceSerializer.register(MyResource)
##
## 存储 InputEvent（按键绑定等）：
##   collect_data 中：ResourceSerializer.serialize_event(event)
##   apply_data   中：ResourceSerializer.deserialize_event(data["key"])

# ──────────────────────────────────────────────
# 构造保护：防止直接实例化
# ──────────────────────────────────────────────

func _init() -> void:
	pass


# ──────────────────────────────────────────────
# [abstract] 子类必须重写
# ──────────────────────────────────────────────

## 模块在存档字典里的唯一键名（如 "settings"、"level"、"player"）
## ⚠ 同一 SaveSystem 内不可重复
@abstract func get_module_key() -> String


## true = 全局存档 global.json；false = 槽位存档 slot_XX.json
@abstract func is_global() -> bool


## 收集当前状态，返回可 JSON 序列化的 Dictionary
## ⚠ 只允许基本类型：bool / int / float / String / Array / Dictionary
@abstract func collect_data() -> Dictionary


## 将加载到的 data 应用到游戏状态
@abstract func apply_data(_data: Dictionary) -> void

# ──────────────────────────────────────────────
# [virtual] 子类可选重写
# ──────────────────────────────────────────────

## 新游戏 / 清空槽位时调用，重置到初始状态（默认调用 apply_data(get_default_data())）
func on_new_game() -> void:
	apply_data(get_default_data())

## 返回该模块的初始默认数据
func get_default_data() -> Dictionary:
	return {}

## 模块元信息（Debug / 编辑器工具用）
func get_meta_data() -> Dictionary:
	return { "key": get_module_key(), "global": is_global() }

## [virtual] 存档版本迁移钩子
## 当存档版本低于当前 FORMAT_VERSION 时，MigrationManager 会依次调用此方法
## old_version: 存档文件中的旧版本号
## old_payload: 该模块在旧版本中的数据字典
## 返回迁移后的数据字典（默认不做任何转换）
func migrate_payload(old_payload: Dictionary, _old_version: int) -> Dictionary:
	return old_payload
