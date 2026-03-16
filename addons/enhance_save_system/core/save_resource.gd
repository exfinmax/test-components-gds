@abstract
class_name SaveResource
extends Resource
## 可序列化自定义资源抽象基类
##
## ⚠ Abstract Class — 继承此类后实现 to_dict / from_dict 两个抽象方法，
##   即可被 ResourceSerializer 和 SaveWriter 正确序列化 / 反序列化。
##
## 设计原则：
##   - to_dict()   ：只输出 JSON 基本类型（bool/int/float/String/Array/Dictionary）
##                   嵌套 SaveResource 请调用 ResourceSerializer.serialize(sub_res)
##   - from_dict() ：从 dict 恢复字段，嵌套资源调用 ResourceSerializer.deserialize(dict)
##   - get_type_id()：返回唯一字符串标识（用于 ResourceSerializer 的类型注册表）
##
## 使用示例：
##   class WeaponData extends SaveResource:
##       var name: String = ""
##       var damage: int = 10
##
##       func get_type_id() -> String: return "WeaponData"
##
##       func to_dict() -> Dictionary:
##           return { "name": name, "damage": damage }
##
##       func from_dict(data: Dictionary) -> void:
##           name   = data.get("name",   "")
##           damage = data.get("damage", 10)
##
##   # 注册（在 _ready 或模块初始化时）：
##   ResourceSerializer.register(WeaponData)
##
##   # 序列化（存入 collect_data）：
##   var d := ResourceSerializer.serialize(weapon_instance)
##
##   # 反序列化（在 apply_data 里）：
##   var w: WeaponData = ResourceSerializer.deserialize(d) as WeaponData

# ──────────────────────────────────────────────
# [abstract] 子类必须实现
# ──────────────────────────────────────────────

## 返回此资源在注册表中的唯一类型 ID
## 推荐直接返回类名字符串，如：return "WeaponData"
@abstract func get_type_id() -> String

## 将自身序列化为纯 Dictionary（JSON 安全）
## 嵌套 SaveResource 字段请用 ResourceSerializer.serialize(field)
@abstract func to_dict() -> Dictionary

## 从 Dictionary 恢复字段，应与 to_dict() 完全对应
@abstract func from_dict(data: Dictionary) -> void

# ──────────────────────────────────────────────
# [virtual] 默认工厂（ResourceSerializer 内部调用）
## 子类若有构造参数可重写此方法
# ──────────────────────────────────────────────
static func create() -> SaveResource:
	return null  # 由 ResourceSerializer 通过注册表反射创建
