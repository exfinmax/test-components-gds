extends Node
## ════════════════════════════════════════════════════════════════
##  SaveSystem — 唯一全局存档入口（AutoLoad: "SaveSystem"）
## ════════════════════════════════════════════════════════════════
##
## 核心设计理念
## ────────────
##  ① 纯 JSON 存储：快速、人可读、无引用解析开销
##  ② 模块化多态：每个 ISaveModule 子类负责自己数据域
##  ③ 双轨道存档：全局（global.json）+ 槽位（slot_XX.json）
##  ④ Writer 积累模式：先收集所有模块变更 → 一次性写盘
##  ⑤ 可选加密（AES-GCM/AES-CBC/XOR）、压缩（gzip/deflate）、原子写入、版本迁移
##
## 信号列表
## ────────
##  global_saved(ok)                    全局存档写盘完成
##  global_loaded(ok)                   全局存档读取完成
##  slot_saved(slot, ok)                指定槽位写盘完成
##  slot_loaded(slot, ok)               指定槽位读取完成
##  slot_deleted(slot)                  槽位文件已删除
##  slot_changed(slot)                  当前活跃槽位切换
##  slot_load_failed(slot, reason)      槽位加载失败（含原因）
##  slot_backed_up(slot, backup_path)   槽位备份完成
##  save_migrated(slot, old_ver, new_ver) 存档迁移完成

signal global_saved(ok: bool)
signal global_loaded(ok: bool)
signal slot_saved(slot: int, ok: bool)
signal slot_loaded(slot: int, ok: bool)
signal slot_deleted(slot: int)
signal slot_changed(new_slot: int)
signal slot_load_failed(slot: int, reason: String)
signal slot_backed_up(slot: int, backup_path: String)
signal save_migrated(slot: int, old_version: int, new_version: int)

# ──────────────────────────────────────────────
# 配置
# ──────────────────────────────────────────────

@export var max_slots: int = 8
@export var auto_register: bool = true
@export var auto_load_global: bool = true
@export var auto_load_slot: int = 0
@export var game_version: String = "1.0.0"

## 自动存档
@export var auto_save_enabled: bool = false
@export var auto_save_interval: int = 300
@export var auto_save_slot: int = 1

## 存档预览图
@export var save_screenshots_enabled: bool = false
@export var screenshot_width: int = 640
@export var screenshot_height: int = 480

## 加密配置
@export var encryption_enabled: bool = true
@export var encryption_key: String = "your-encryption-key-here"
## 加密模式："xor" / "aes_cbc" / "aes_gcm"
@export var encryption_mode: String = "aes_gcm"

## 原子写入配置
@export var atomic_write_enabled: bool = true
@export var backup_enabled: bool = false

## 压缩配置
@export var compression_enabled: bool = false
## 压缩模式："gzip" / "deflate"
@export var compression_mode: String = "gzip"

## 分模块文件存储
@export var split_modules_enabled: bool = false

## 模块注册配置
@export var use_module_config: bool = true
@export var module_config_path: String = "res://addons/enhance_save_system/save_modules.cfg"

# ──────────────────────────────────────────────
# 路径常量
# ──────────────────────────────────────────────

const _SAVE_DIR      := "user://saves"
const _GLOBAL_PATH   := "user://saves/global.json"
const _SLOT_PATTERN  := "user://saves/slot_%02d.json"
const _MODULES_DIR_FALLBACK := "res://addons/enhance_save_system/Modules"
const _SCREENSHOT_DIR := "user://saves/screenshots"
const _SCREENSHOT_PATTERN := "user://saves/screenshots/slot_%02d.png"

# ──────────────────────────────────────────────
# 内部状态
# ──────────────────────────────────────────────

## 已注册的全局模块（key → { module, priority }）
var _global_modules: Dictionary = {}
## 已注册的槽位模块（key → { module, priority }）
var _slot_modules: Dictionary = {}

var current_slot: int = 1 :
	set(v):
		current_slot = clampi(v, 1, max_slots)

var _auto_save_timer: Timer
var _migration_manager: MigrationManager

# ──────────────────────────────────────────────
# 生命周期
# ──────────────────────────────────────────────

func _ready() -> void:
	_ensure_save_dir()
	if save_screenshots_enabled:
		_ensure_screenshot_dir()
	_migration_manager = MigrationManager.new()
	if auto_register:
		_auto_register_modules()
	if auto_load_global:
		load_global()
	if auto_load_slot > 0:
		load_slot(auto_load_slot)
	if auto_save_enabled:
		_setup_auto_save()
	
	get_tree().root.close_requested.connect(on_win_closed)
# ──────────────────────────────────────────────
# 自动存档
# ──────────────────────────────────────────────

func _setup_auto_save() -> void:
	_auto_save_timer = Timer.new()
	add_child(_auto_save_timer)
	_auto_save_timer.wait_time = auto_save_interval
	_auto_save_timer.autostart = true
	_auto_save_timer.timeout.connect(_on_auto_save_timeout)

func _on_auto_save_timeout() -> void:
	save_slot(auto_save_slot)
	if save_screenshots_enabled:
		_capture_screenshot(auto_save_slot)

func enable_auto_save(enabled: bool) -> void:
	auto_save_enabled = enabled
	if enabled:
		if not is_instance_valid(_auto_save_timer):
			_setup_auto_save()
		else:
			_auto_save_timer.start()
	else:
		if is_instance_valid(_auto_save_timer):
			_auto_save_timer.stop()

func set_auto_save_interval(seconds: int) -> void:
	auto_save_interval = max(10, seconds)
	if is_instance_valid(_auto_save_timer):
		_auto_save_timer.wait_time = auto_save_interval

# ──────────────────────────────────────────────
# 存档预览图
# ──────────────────────────────────────────────

func _ensure_screenshot_dir() -> void:
	if not DirAccess.dir_exists_absolute(_SCREENSHOT_DIR):
		DirAccess.make_dir_recursive_absolute(_SCREENSHOT_DIR)

func _capture_screenshot(slot: int) -> void:
	_ensure_screenshot_dir()
	var screenshot_path := _screenshot_path(slot)
	var viewport := get_viewport()
	if not viewport:
		return
	var texture := viewport.get_texture()
	if not texture:
		return
	var image := texture.get_image()
	if not image:
		return
	image.resize(screenshot_width, screenshot_height)
	image.save_png(screenshot_path)

func get_screenshot_path(slot: int) -> String:
	return _screenshot_path(slot)

func _screenshot_path(slot: int) -> String:
	return _SCREENSHOT_PATTERN % slot

# ──────────────────────────────────────────────
# 模块注册
# ──────────────────────────────────────────────

func _auto_register_modules() -> void:
	if use_module_config:
		var registry := ModuleRegistry.new()
		var modules := registry.load_from_config(module_config_path)
		for m in modules:
			register_module(m)
		print(modules)
		return

	var modules_dir := _resolve_modules_dir()
	var dir := DirAccess.open(modules_dir)
	if dir == null:
		push_warning("SaveSystem._auto_register_modules: 无法打开模块目录 '%s'" % modules_dir)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gd"):
			_try_load_and_register(modules_dir.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

func _resolve_modules_dir() -> String:
	var script_path: String = (get_script() as GDScript).resource_path
	var save_dir := script_path.get_base_dir().get_base_dir()
	var dynamic := save_dir.path_join("Modules")
	if DirAccess.dir_exists_absolute(dynamic):
		return dynamic
	push_warning("SaveSystem: 动态路径 '%s' 不存在，回退到保险路径 '%s'" % [dynamic, _MODULES_DIR_FALLBACK])
	return _MODULES_DIR_FALLBACK

func _try_load_and_register(path: String) -> void:
	var script := ResourceLoader.load(path, "GDScript") as GDScript
	if script == null:
		push_warning("SaveSystem: 加载模块脚本失败 '%s'" % path)
		return
	var instance = script.new()
	if not instance is ISaveModule:
		return
	register_module(instance as ISaveModule)

## 注册存档模块
## priority: 执行优先级，数值越小越先执行 collect_data / apply_data（默认 100）
func register_module(module: ISaveModule, priority: int = 100) -> void:
	var key := module.get_module_key()
	if key.is_empty():
		push_error("SaveSystem.register_module: module key is empty")
		return
	var entry := { "module": module, "priority": priority }
	if module.is_global():
		_global_modules[key] = entry
	else:
		_slot_modules[key] = entry

func unregister_module(key: String) -> void:
	_global_modules.erase(key)
	_slot_modules.erase(key)

func get_module(key: String) -> ISaveModule:
	if _global_modules.has(key):
		return _global_modules[key]["module"]
	var entry = _slot_modules.get(key, null)
	return entry["module"] if entry != null else null

func get_registered_keys() -> Dictionary:
	return {
		"global": _global_modules.keys(),
		"slot":   _slot_modules.keys(),
	}

## 注册全局迁移函数（供开发者在游戏启动时调用）
## from_version: 旧版本号
## migration_fn: func(payload: Dictionary) -> Dictionary
func register_migration(from_version: int, migration_fn: Callable) -> void:
	_migration_manager.register(from_version, migration_fn)

# ──────────────────────────────────────────────
# 内部：构建 WriteOptions / ReadOptions
# ──────────────────────────────────────────────

func _make_write_opts() -> SaveWriter.WriteOptions:
	var opts := SaveWriter.WriteOptions.new()
	opts.game_version         = game_version
	opts.encryption_enabled   = encryption_enabled
	opts.encryption_key       = encryption_key
	opts.encryption_mode      = encryption_mode
	opts.compression_enabled  = compression_enabled
	opts.compression_mode     = compression_mode
	opts.atomic_write_enabled = atomic_write_enabled
	opts.backup_enabled       = backup_enabled
	opts.split_modules_enabled = split_modules_enabled
	return opts

func _make_read_opts() -> SaveWriter.ReadOptions:
	var opts := SaveWriter.ReadOptions.new()
	opts.encryption_key        = encryption_key if encryption_enabled else ""
	opts.split_modules_enabled = split_modules_enabled
	return opts

## 按 priority 升序排列模块数组
func _sorted_modules(registry: Dictionary) -> Array:
	var entries := registry.values()
	entries.sort_custom(func(a, b): return a["priority"] < b["priority"])
	var result: Array = []
	for e in entries:
		result.append(e["module"])
	return result

# ──────────────────────────────────────────────
# 全局存档 API
# ──────────────────────────────────────────────

func save_global() -> bool:
	var modules := _sorted_modules(_global_modules)
	var ok := SaveWriter.write(modules, _GLOBAL_PATH, _make_write_opts())
	global_saved.emit(ok)
	return ok

func load_global() -> bool:
	var modules := _sorted_modules(_global_modules)
	var ok := SaveWriter.read(_GLOBAL_PATH, modules, _make_read_opts())
	global_loaded.emit(ok)
	return ok

# ──────────────────────────────────────────────
# 单模块读写 API
# ──────────────────────────────────────────────

func save_module(module_key: String, slot: int = -1) -> bool:
	var module := get_module(module_key)
	if module == null:
		push_warning("SaveSystem.save_module: module '%s' not registered" % module_key)
		return false
	var path: String
	if module.is_global():
		path = _GLOBAL_PATH
	else:
		var s := _resolve_slot(slot)
		if not _valid(s):
			return false
		path = _slot_path(s)
	return _write_module_to_file(module, path)

func load_module(module_key: String, slot: int = -1) -> bool:
	var module := get_module(module_key)
	if module == null:
		push_warning("SaveSystem.load_module: module '%s' not registered" % module_key)
		return false
	var path: String
	if module.is_global():
		path = _GLOBAL_PATH
	else:
		var s := _resolve_slot(slot)
		if not _valid(s):
			return false
		path = _slot_path(s)
	return _read_module_from_file(module, path)

func _write_module_to_file(module: ISaveModule, path: String) -> bool:
	var opts := _make_write_opts()
	var payload := SaveWriter.read_json(path, _make_read_opts())
	# 如果文件不存在或解析失败，payload 为空；此时直接创建一个新 payload
	if payload.is_empty():
		payload = {}
	# 更新当前模块对应的数据
	payload[module.get_module_key()] = module.collect_data()
	return SaveWriter.write_json(payload, path, opts)

func _read_module_from_file(module: ISaveModule, path: String) -> bool:
	var payload := SaveWriter.read_json(path, _make_read_opts())
	if payload.is_empty():
		return false
	var key := module.get_module_key()
	if payload.has(key):
		module.apply_data(payload[key] as Dictionary)
		return true
	return false

# ──────────────────────────────────────────────
# 槽位存档 API
# ──────────────────────────────────────────────

func save_slot(slot: int = -1) -> bool:
	var s := _resolve_slot(slot)
	if not _valid(s):
		return false
	var modules := _sorted_modules(_slot_modules)
	var ok := SaveWriter.write(modules, _slot_path(s), _make_write_opts())
	if ok:
		if save_screenshots_enabled:
			_capture_screenshot(s)
		if backup_enabled:
			var bak_path := AtomicWriter.get_backup_path(_slot_path(s))
			slot_backed_up.emit(s, bak_path)
	slot_saved.emit(s, ok)
	return ok

func load_slot(slot: int = -1) -> bool:
	var s := _resolve_slot(slot)
	if not _valid(s):
		return false
	var path := _slot_path(s)

	# 读取原始 payload（含 _meta）
	var payload := SaveWriter.read_json(path, _make_read_opts())
	if payload.is_empty():
		slot_load_failed.emit(s, "read_failed")
		slot_loaded.emit(s, false)
		return false

	# 检查加密完整性错误（read_json 返回空时已处理，此处检查特殊标记）
	# 注：Encryptor 在验证失败时返回空 PackedByteArray，read_json 返回 {}
	# 若 payload 非空但 _meta 缺失，视为格式错误
	var meta: Dictionary = payload.get("_meta", {})

	# 版本迁移
	var file_version := int(meta.get("version", 0))
	if _migration_manager.needs_migration(payload, SaveWriter.FORMAT_VERSION):
		# 迁移前备份原始文件
		var pre_bak := path + ".pre_migration.bak"
		DirAccess.copy_absolute(path, pre_bak)

		var modules_arr := _sorted_modules(_slot_modules)
		var migrated := _migration_manager.migrate(payload, file_version, SaveWriter.FORMAT_VERSION, modules_arr)
		if not _migration_manager.last_error.is_empty():
			push_error("SaveSystem: migration failed for slot %d: %s" % [s, _migration_manager.last_error])
			slot_load_failed.emit(s, "migration_failed")
			slot_loaded.emit(s, false)
			return false
		payload = migrated
		save_migrated.emit(s, file_version, SaveWriter.FORMAT_VERSION)

	# 应用数据
	var modules := _sorted_modules(_slot_modules)
	SaveWriter.apply(payload, modules)
	current_slot = s
	slot_changed.emit(s)
	slot_loaded.emit(s, true)
	return true

func set_slot(slot: int) -> bool:
	if not _valid(slot):
		return false
	var ok := load_slot(slot)
	if ok:
		current_slot = slot
		slot_changed.emit(slot)
	return ok

func delete_slot(slot: int = -1) -> bool:
	var s := _resolve_slot(slot)
	var path := _slot_path(s)
	if not FileAccess.file_exists(path):
		return false
	# user:// 路径需要 globalize 后才能被 DirAccess.remove_absolute 正确处理
	var abs_path := ProjectSettings.globalize_path(path)
	var err := DirAccess.remove_absolute(abs_path)
	if err != OK:
		push_error("SaveSystem.delete_slot: failed to delete '%s' (err=%d)" % [path, err])
		return false
	slot_deleted.emit(s)
	return true

func slot_exists(slot: int = -1) -> bool:
	return FileAccess.file_exists(_slot_path(_resolve_slot(slot)))

func list_slots() -> Array[SlotInfo]:
	var result: Array[SlotInfo] = []
	for i in range(1, max_slots + 1):
		var path := _slot_path(i)
		var exists := FileAccess.file_exists(path)
		var meta: Dictionary = {}
		if exists:
			meta = SaveWriter.peek_meta(path)
		if save_screenshots_enabled:
			var screenshot_path := _screenshot_path(i)
			if FileAccess.file_exists(screenshot_path):
				meta["screenshot_path"] = screenshot_path
		result.append(SlotInfo.make(i, exists, meta))
	return result

# 兼容旧接口，避免旧 starter 和自定义场景在迁移期间失效。
func save_game_to_slot(slot: int = -1) -> bool:
	return save_slot(slot)

func load_game_from_slot(slot: int = -1) -> bool:
	return load_slot(slot)

# ──────────────────────────────────────────────
# 快捷存档
# ──────────────────────────────────────────────

func quick_save() -> bool:
	var g := save_global()
	var s := save_slot(current_slot)
	return g and s

func quick_load() -> bool:
	var g := load_global()
	var s := load_slot(current_slot)
	return g or s

func new_game(slot: int = -1) -> void:
	var s := _resolve_slot(slot)
	current_slot = s
	for entry in _slot_modules.values():
		(entry["module"] as ISaveModule).on_new_game()

# ──────────────────────────────────────────────
# 导入 / 导出
# ──────────────────────────────────────────────

func export_slot(slot: int, out_path: String) -> bool:
	var src := _slot_path(_resolve_slot(slot))
	if not FileAccess.file_exists(src):
		push_warning("SaveSystem.export_slot: slot %d not found" % slot)
		return false
	SaveWriter._ensure_dir(out_path)
	return DirAccess.copy_absolute(src, out_path) == OK

func import_slot(slot: int, in_path: String) -> bool:
	if not _valid(slot):
		return false
	if not FileAccess.file_exists(in_path):
		push_warning("SaveSystem.import_slot: file not found '%s'" % in_path)
		return false
	var payload := SaveWriter.read_json(in_path)
	if payload.is_empty():
		push_error("SaveSystem.import_slot: invalid JSON in '%s'" % in_path)
		return false
	var dst := _slot_path(slot)
	SaveWriter._ensure_dir(dst)
	return DirAccess.copy_absolute(in_path, dst) == OK

# ──────────────────────────────────────────────
# Debug
# ──────────────────────────────────────────────

func get_component_data() -> Dictionary:
	return {
		"current_slot":   current_slot,
		"max_slots":      max_slots,
		"global_modules": _global_modules.keys(),
		"slot_modules":   _slot_modules.keys(),
		"global_exists":  FileAccess.file_exists(_GLOBAL_PATH),
		"slot_exists":    slot_exists(current_slot),
	}

# ──────────────────────────────────────────────
# 内部辅助
# ──────────────────────────────────────────────

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(_SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(_SAVE_DIR)

func _valid(slot: int) -> bool:
	if slot < 1 or slot > max_slots:
		push_warning("SaveSystem: slot %d out of range (1–%d)" % [slot, max_slots])
		return false
	return true

func _resolve_slot(slot: int) -> int:
	return current_slot if slot < 0 else slot

func _slot_path(slot: int) -> String:
	return _SLOT_PATTERN % slot

func on_win_closed() -> void:
	for i:Dictionary in _global_modules.values():
		var module = i["module"]
		if module.has_method("on_win_closed"):
			module.on_win_closed()
			
