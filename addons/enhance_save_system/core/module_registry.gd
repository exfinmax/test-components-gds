class_name ModuleRegistry
extends RefCounted
## 配置文件驱动的模块注册系统
##
## 从 save_modules.cfg 读取模块列表，按 priority 升序加载并注册模块，
## 替代 SaveSystem 中基于文件系统顺序的自动扫描。
##
## save_modules.cfg 格式：
##   [player_module]
##   path = "res://addons/enhance_save_system/Modules/player_module.gd"
##   enabled = true
##   priority = 10
##
## 用法：
##   var registry := ModuleRegistry.new()
##   var modules := registry.load_from_config("res://save_modules.cfg")
##   for m in modules:
##       SaveSystem.register_module(m)

# ──────────────────────────────────────────────
# 公开 API
# ──────────────────────────────────────────────

## 从配置文件加载并实例化模块
## config_path: ConfigFile 路径（通常为 "res://save_modules.cfg"）
## 返回按 priority 升序排列的 ISaveModule 数组
## enabled=false 的条目被跳过；路径不存在的条目打印警告后跳过
func load_from_config(config_path: String) -> Array:
	var cfg := ConfigFile.new()
	var err := cfg.load(config_path)
	if err != OK:
		push_warning("ModuleRegistry: cannot load config '%s' (err=%d)" % [config_path, err])
		return []

	# 解析所有条目
	var entries: Array = []
	for section in cfg.get_sections():
		var entry := _parse_entry(cfg, section)
		if entry.is_empty():
			continue
		entries.append(entry)

	# 按 priority 升序排序
	entries.sort_custom(func(a, b): return a["priority"] < b["priority"])

	# 加载并实例化模块
	var modules: Array = []
	for entry in entries:
		if not entry.get("enabled", true):
			continue  # 跳过禁用模块，不发出警告
		var module := _load_module(entry["path"], entry["section"])
		if module != null:
			modules.append(module)

	return modules

# ──────────────────────────────────────────────
# 内部工具
# ──────────────────────────────────────────────

## 解析单个配置节
## 返回 { section, path, enabled, priority }；无效时返回空 Dictionary
func _parse_entry(cfg: ConfigFile, section: String) -> Dictionary:
	if not cfg.has_section_key(section, "path"):
		push_warning("ModuleRegistry: section '[%s]' missing 'path' key, skipped" % section)
		return {}
	return {
		"section":  section,
		"path":     str(cfg.get_value(section, "path", "")),
		"enabled":  bool(cfg.get_value(section, "enabled", true)),
		"priority": int(cfg.get_value(section, "priority", 100)),
	}

## 加载并实例化单个模块脚本
func _load_module(path: String, section: String) -> ISaveModule:
	if not ResourceLoader.exists(path):
		push_warning("ModuleRegistry: script not found '%s' (section '[%s]'), skipped" % [path, section])
		return null
	var script := ResourceLoader.load(path, "GDScript") as GDScript
	if script == null:
		push_warning("ModuleRegistry: failed to load script '%s' (section '[%s]'), skipped" % [path, section])
		return null
	var instance = script.new()
	if not (instance is ISaveModule):
		push_warning("ModuleRegistry: '%s' is not an ISaveModule subclass, skipped" % path)
		return null
	return instance as ISaveModule
