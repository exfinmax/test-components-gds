## 可序列化资源模板（复制后重命名 class_name 和 get_type_id）
## 继承 SaveResource，实现 to_dict / from_dict 即可被 ResourceSerializer 正确处理
@abstract
class_name SaveResourceTemplate    ## ← 改为你的资源名，如 WeaponData / QuestState
extends SaveResource

# ──────────────────────────────────────────────
# 你的数据字段（只用 JSON 安全类型）
# ──────────────────────────────────────────────
var my_field: String = ""
var my_int: int = 0
# 嵌套另一个 SaveResource：
# var nested: AnotherSaveResource = null

# ──────────────────────────────────────────────
# SaveResource 接口（必须实现）
# ──────────────────────────────────────────────

func get_type_id() -> String:
	return "SaveResourceTemplate"    ## ← 改为与 class_name 相同的唯一字符串

func to_dict() -> Dictionary:
	return {
		"my_field" : my_field,
		"my_int"   : my_int,
		# 嵌套资源："nested": ResourceSerializer.serialize(nested),
	}

func from_dict(data: Dictionary) -> void:
	my_field = str(data.get("my_field", ""))
	my_int   = int(data.get("my_int",   0))
	# 嵌套资源：nested = ResourceSerializer.deserialize(data.get("nested", {})) as AnotherSaveResource

# ──────────────────────────────────────────────
# 在模块初始化时注册（放到对应 ISaveModule._init() 或 _ready() 里）
# ──────────────────────────────────────────────
# ResourceSerializer.register(SaveResourceTemplate)
#
# 序列化（在 collect_data）：
#   var d := ResourceSerializer.serialize(my_instance)
#
# 反序列化（在 apply_data）：
#   my_instance = ResourceSerializer.deserialize(d) as SaveResourceTemplate
