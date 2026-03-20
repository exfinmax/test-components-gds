class_name MigrationManager
extends RefCounted
## 存档版本迁移管理器
##
## 维护从旧版本号到新版本号的迁移函数注册表，
## 在加载存档时自动将旧版本存档升级到当前格式。
##
## 用法：
##   var mm := MigrationManager.new()
##   mm.register(1, func(payload): payload["player"]["new_field"] = 0; return payload)
##   mm.register(2, func(payload): payload["level"]["renamed"] = payload["level"].get("old_name"); return payload)
##
##   # 加载时自动迁移
##   var migrated := mm.migrate(payload, old_version, SaveWriter.FORMAT_VERSION, modules)

## 最后一次迁移错误信息（空字符串表示无错误）
var last_error: String = ""

## 迁移函数注册表：{ from_version: int → migration_fn: Callable }
## migration_fn 签名：func(payload: Dictionary) -> Dictionary
var _migrations: Dictionary = {}

# ──────────────────────────────────────────────
# 公开 API
# ──────────────────────────────────────────────

## 注册迁移函数
## from_version: 旧版本号（该函数将 from_version 的存档升级到 from_version+1）
## migration_fn: 迁移函数，签名 func(payload: Dictionary) -> Dictionary
func register(from_version: int, migration_fn: Callable) -> void:
	_migrations[from_version] = migration_fn

## 执行迁移
## payload:         存档数据（含 _meta）
## current_version: 存档文件中的版本号
## target_version:  目标版本号（通常为 SaveWriter.FORMAT_VERSION）
## modules:         已注册的模块数组（用于调用各模块的 migrate_payload）
## 返回迁移后的 payload；失败时返回原始 payload 并设置 last_error
func migrate(payload: Dictionary, current_version: int, target_version: int, modules: Array = []) -> Dictionary:
	last_error = ""

	if current_version >= target_version:
		return payload  # 无需迁移

	# 深拷贝备份原始数据，用于失败回滚
	var backup := _deep_copy(payload)

	var working := _deep_copy(payload)
	var version := current_version

	while version < target_version:
		# 调用全局迁移函数（若已注册）
		if _migrations.has(version):
			var fn: Callable = _migrations[version]
			var result = fn.call(working)
			if result == null or not (result is Dictionary):
				last_error = "Migration fn for version %d returned invalid result" % version
				push_error("MigrationManager: " + last_error)
				return backup
			working = result

		# 调用各模块的 migrate_payload（若已重写）
		for module in modules:
			if not (module is ISaveModule):
				continue
			var key: String = module.get_module_key()
			if not working.has(key):
				continue
			var module_data: Dictionary = working[key]
			var migrated_data: Dictionary = module.migrate_payload(module_data, version)
			working[key] = migrated_data

		version += 1

	# 更新 _meta.version
	if working.has("_meta"):
		working["_meta"]["version"] = target_version
	else:
		working["_meta"] = { "version": target_version }

	return working

## 检查 payload 是否需要迁移
## target_version: 目标版本号（通常为 SaveWriter.FORMAT_VERSION）
func needs_migration(payload: Dictionary, target_version: int) -> bool:
	var meta: Dictionary = payload.get("_meta", {})
	var ver: int = int(meta.get("version", 0))
	return ver < target_version

# ──────────────────────────────────────────────
# 内部工具
# ──────────────────────────────────────────────

## 深拷贝 Dictionary（支持嵌套 Dictionary 和 Array）
static func _deep_copy(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in data:
		var val = data[key]
		if val is Dictionary:
			result[key] = _deep_copy(val)
		elif val is Array:
			result[key] = _deep_copy_array(val)
		else:
			result[key] = val
	return result

static func _deep_copy_array(arr: Array) -> Array:
	var result: Array = []
	for item in arr:
		if item is Dictionary:
			result.append(_deep_copy(item))
		elif item is Array:
			result.append(_deep_copy_array(item))
		else:
			result.append(item)
	return result
