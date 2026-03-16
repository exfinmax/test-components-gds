extends Node
## ════════════════════════════════════════════════════════════════
##  SaveSystem — 唯一全局存档入口（AutoLoad: "SaveSystem"）
## ════════════════════════════════════════════════════════════════
##
## 核心设计理念
## ────────────
##  ① 纯 JSON 存储：快速、人可读、无引用解析开销
##  ② 模块化多态：每个 ISaveModule 子类负责自己数据域
##     SaveWriter 通过 collect_data / apply_data 与模块交互
##  ③ 双轨道存档：
##     • 全局存档（global.json）：设置、统计等不依赖槽位的数据
##     • 槽位存档（slot_01.json … slot_N.json）：关卡进度、玩家状态等
##  ④ Writer 积累模式：先收集所有模块变更 → 一次性写盘（减少 I/O）
##
## 快速上手
## ────────
##  1. 项目设置 → AutoLoad → 添加本脚本，名称设为 "SaveSystem"
##  2. 默认开启 auto_register，会自动从 Modules/ 目录加载并注册所有模块；
##     如需手动注册（覆盖/追加），在场景 _ready 里调用：
##       SaveSystem.register_module(MyCustomModule.new())
##  3. 保存 / 加载：
##       SaveSystem.quick_save()          # 保存全局 + 当前槽位
##       SaveSystem.quick_load()          # 加载全局 + 当前槽位
##       SaveSystem.save_slot(2)          # 保存到槽位 2
##       SaveSystem.load_slot(2)          # 从槽位 2 加载
##  4. 导出 / 导入（移植存档）：
##       SaveSystem.export_slot(1, "user://backup/slot1.json")
##       SaveSystem.import_slot(1, "user://backup/slot1.json")
##
## 信号列表
## ────────
##  global_saved(ok)         全局存档写盘完成
##  global_loaded(ok)        全局存档读取完成
##  slot_saved(slot, ok)     指定槽位写盘完成
##  slot_loaded(slot, ok)    指定槽位读取完成
##  slot_deleted(slot)       槽位文件已删除
##  slot_changed(slot)       当前活跃槽位切换

signal global_saved(ok: bool)
signal global_loaded(ok: bool)
signal slot_saved(slot: int, ok: bool)
signal slot_loaded(slot: int, ok: bool)
signal slot_deleted(slot: int)
signal slot_changed(new_slot: int)

# ──────────────────────────────────────────────
# 配置
# ──────────────────────────────────────────────

## 最大槽位数（1-based，1 到 max_slots）
@export var max_slots: int = 8

## 启动时自动扫描 Modules/ 目录并注册所有模块（设为 false 可完全手动管理）
@export var auto_register: bool = true

## 启动时自动加载全局存档
@export var auto_load_global: bool = true

## 启动时自动加载的槽位（0 = 不自动加载）
@export var auto_load_slot: int = 0

## game_version 写入 _meta（可在 Project Settings 里改）
@export var game_version: String = "1.0.0"

## 自动存档配置
@export var auto_save_enabled: bool = false
@export var auto_save_interval: int = 300  # 自动存档间隔（秒）
@export var auto_save_slot: int = 1  # 自动存档槽位

## 存档预览图配置
@export var save_screenshots_enabled: bool = false
@export var screenshot_width: int = 640
@export var screenshot_height: int = 480

## 存档加密配置
@export var encryption_enabled: bool = false
@export var encryption_key: String = "your-encryption-key-here"

# ──────────────────────────────────────────────
# 路径常量
# ──────────────────────────────────────────────

const _SAVE_DIR      := "user://saves"
const _GLOBAL_PATH   := "user://saves/global.json"
const _SLOT_PATTERN  := "user://saves/slot_%02d.json"

## 模块目录硬编码保险路径
## 整体复制 Save/ 文件夹后路径不变，导出包也能被 ResourceLoader 正确找到
const _MODULES_DIR_FALLBACK := "res://addons/save_system/Modules"

# ──────────────────────────────────────────────
# 内部状态
# ──────────────────────────────────────────────

## 已注册的全局模块（key → ISaveModule）
var _global_modules: Dictionary = {}   # String → ISaveModule

## 已注册的槽位模块（key → ISaveModule）
var _slot_modules: Dictionary = {}     # String → ISaveModule

## 当前活跃槽位
var current_slot: int = 1 :
	set(v):
		current_slot = clampi(v, 1, max_slots)

## 自动存档定时器
var _auto_save_timer: Timer

## 存档预览图路径
const _SCREENSHOT_DIR := "user://saves/screenshots"
const _SCREENSHOT_PATTERN := "user://saves/screenshots/slot_%02d.png"

# ──────────────────────────────────────────────
# 生命周期
# ──────────────────────────────────────────────

func _ready() -> void:
	_ensure_save_dir()
	if save_screenshots_enabled:
		_ensure_screenshot_dir()
	if auto_register:
		_auto_register_modules()
	if auto_load_global:
		load_global()
	if auto_load_slot > 0:
		load_slot(auto_load_slot)
	if auto_save_enabled:
		_setup_auto_save()

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
	auto_save_interval = max(10, seconds)  # 最小10秒
	if is_instance_valid(_auto_save_timer):
		_auto_save_timer.wait_time = auto_save_interval

# ──────────────────────────────────────────────
# 存档预览图
# ──────────────────────────────────────────────

func _ensure_screenshot_dir() -> void:
	if not DirAccess.dir_exists_absolute(_SCREENSHOT_DIR):
		DirAccess.make_dir_recursive_absolute(_SCREENSHOT_DIR)

func _capture_screenshot(slot: int) -> void:
	# 确保截图目录存在
	_ensure_screenshot_dir()
	
	var screenshot_path := _screenshot_path(slot)
	var viewport = get_viewport()
	if not viewport:
		print("[SaveSystem] 错误: 无法获取视口")
		return
	
	var texture = viewport.get_texture()
	if not texture:
		print("[SaveSystem] 错误: 无法获取视口纹理")
		return
	
	var image = texture.get_image()
	if not image:
		print("[SaveSystem] 错误: 无法获取图像")
		return
	
	# 调整图像大小
	image.resize(screenshot_width, screenshot_height)
	
	# 保存图像
	var err = image.save_png(screenshot_path)
	if err != OK:
		print("[SaveSystem] 错误: 无法保存截图到 %s" % screenshot_path)
	else:
		print("[SaveSystem] 截图已保存到 %s" % screenshot_path)

func get_screenshot_path(slot: int) -> String:
	return _screenshot_path(slot)

func _screenshot_path(slot: int) -> String:
	return _SCREENSHOT_PATTERN % slot

# ══════════════════════════════════════════════
# 模块注册
# ══════════════════════════════════════════════

# ══════════════════════════════════════════════
# 自动注册
# ══════════════════════════════════════════════

## 扫描 Modules/ 目录，用 ResourceLoader 加载每个 .gd 文件并注册为模块子节点
## 加载顺序由文件系统决定；若需严格顺序，请将 auto_register 设为 false 并手动调用
func _auto_register_modules() -> void:
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

## 从本脚本路径动态推导 Modules 目录（去掉 Core/ 换 Modules/）
## 若推导结果不存在则降级用硬编码常量路径
func _resolve_modules_dir() -> String:
	var script_path: String = (get_script() as GDScript).resource_path
	var save_dir := script_path.get_base_dir().get_base_dir()  # …/Core → …/Save
	var dynamic := save_dir.path_join("Modules")
	if DirAccess.dir_exists_absolute(dynamic):
		return dynamic
	push_warning("SaveSystem: 动态路径 '%s' 不存在，回退到保险路径 '%s'" % [dynamic, _MODULES_DIR_FALLBACK])
	return _MODULES_DIR_FALLBACK

## 尝试用 ResourceLoader 加载单个 .gd 文件并注册为模块
## 非 ISaveModule 子类的脚本会被静默跳过（模板文件、工具脚本等）
func _try_load_and_register(path: String) -> void:
	var script := ResourceLoader.load(path, "GDScript") as GDScript
	if script == null:
		push_warning("SaveSystem: 加载模块脚本失败 '%s'" % path)
		return
	var instance = script.new()
	if not instance is ISaveModule:
		# 不是模块（如模板），RefCounted 无引用自动释放，无需手动处理
		return
	# ISaveModule extends RefCounted：注册进字典后字典持有强引用，保证生命周期
	register_module(instance as ISaveModule)

## 注册一个存档模块
## module.is_global() == true  → 写入全局存档
## module.is_global() == false → 写入槽位存档
func register_module(module: ISaveModule) -> void:
	var key := module.get_module_key()
	if key.is_empty():
		push_error("SaveSystem.register_module: module key is empty")
		return
	if module.is_global():
		_global_modules[key] = module
	else:
		_slot_modules[key] = module

## 注销模块
func unregister_module(key: String) -> void:
	_global_modules.erase(key)
	_slot_modules.erase(key)

## 获取已注册模块（global + slot 合并）
func get_module(key: String) -> ISaveModule:
	if _global_modules.has(key):
		return _global_modules[key]
	return _slot_modules.get(key, null)

## 所有已注册模块 key（调试用）
func get_registered_keys() -> Dictionary:
	return {
		"global": _global_modules.keys(),
		"slot":   _slot_modules.keys(),
	}

# ══════════════════════════════════════════════
# 全局存档 API
# ══════════════════════════════════════════════

## 保存所有全局模块到 global.json
func save_global() -> bool:
	var ok :bool= SaveWriter.write(_global_modules.values(), _GLOBAL_PATH, game_version, encryption_key if encryption_enabled else "")
	global_saved.emit(ok)
	return ok

## 从 global.json 加载所有全局模块
func load_global() -> bool:
	var ok :bool= SaveWriter.read(_GLOBAL_PATH, _global_modules.values(), encryption_key if encryption_enabled else "")
	global_loaded.emit(ok)
	return ok

# ══════════════════════════════════════════════
# 槽位存档 API
# ══════════════════════════════════════════════

## 将所有槽位模块保存到指定槽（默认 current_slot）
func save_slot(slot: int = -1) -> bool:
	var s := _resolve_slot(slot)
	if not _valid(s):
		return false
	var ok := SaveWriter.write(_slot_modules.values(), _slot_path(s), game_version, encryption_key if encryption_enabled else "")
	if ok and save_screenshots_enabled:
		_capture_screenshot(s)
	slot_saved.emit(s, ok)
	return ok

## 从指定槽加载所有槽位模块（默认 current_slot）
func load_slot(slot: int = -1) -> bool:
	var s := _resolve_slot(slot)
	if not _valid(s):
		return false
	var ok := SaveWriter.read(_slot_path(s), _slot_modules.values(), encryption_key if encryption_enabled else "")
	if ok:
		current_slot = s
		slot_changed.emit(s)
	slot_loaded.emit(s, ok)
	return ok

## 切换到另一个槽位（自动加载）
func set_slot(slot: int) -> bool:
	if not _valid(slot):
		return false
	var ok := load_slot(slot)
	if ok:
		current_slot = slot
		slot_changed.emit(slot)
	return ok

## 删除指定槽位文件
func delete_slot(slot: int = -1) -> bool:
	var s := _resolve_slot(slot)
	var path := _slot_path(s)
	if not FileAccess.file_exists(path):
		return false
	DirAccess.remove_absolute(path)
	slot_deleted.emit(s)
	return true

## 槽位文件是否存在
func slot_exists(slot: int = -1) -> bool:
	return FileAccess.file_exists(_slot_path(_resolve_slot(slot)))

## 列出所有槽位信息（用于 UI 展示）
func list_slots() -> Array[SlotInfo]:
	var result: Array[SlotInfo] = []
	for i in range(1, max_slots + 1):
		var path := _slot_path(i)
		var exists := FileAccess.file_exists(path)
		var meta: Dictionary = {}
		if exists:
			meta = SaveWriter.peek_meta(path)
		# 添加预览图路径
		if save_screenshots_enabled:
			var screenshot_path := _screenshot_path(i)
			if FileAccess.file_exists(screenshot_path):
				meta["screenshot_path"] = screenshot_path
		result.append(SlotInfo.make(i, exists, meta))
	return result

# ══════════════════════════════════════════════
# 快捷存档
# ══════════════════════════════════════════════

## 同时保存全局 + 当前槽位（一次 I/O 调用两个文件）
func quick_save() -> bool:
	var g := save_global()
	var s := save_slot(current_slot)
	return g and s

## 同时加载全局 + 当前槽位
func quick_load() -> bool:
	var g := load_global()
	var s := load_slot(current_slot)
	return g or s       # 只要有一个成功就算可用

## 新游戏：清空所有槽位模块（调用各模块 on_new_game）
func new_game(slot: int = -1) -> void:
	var s := _resolve_slot(slot)
	current_slot = s
	for m: ISaveModule in _slot_modules.values():
		m.on_new_game()

# ══════════════════════════════════════════════
# 导入 / 导出（槽位文件迁移）
# ══════════════════════════════════════════════

## 将槽位存档导出为外部 JSON 文件
func export_slot(slot: int, out_path: String) -> bool:
	var src := _slot_path(_resolve_slot(slot))
	if not FileAccess.file_exists(src):
		push_warning("SaveSystem.export_slot: slot %d not found" % slot)
		return false
	SaveWriter._ensure_dir(out_path)
	return DirAccess.copy_absolute(src, out_path) == OK

## 从外部 JSON 文件导入到指定槽位
## ⚠ 会覆盖目标槽位
func import_slot(slot: int, in_path: String) -> bool:
	if not _valid(slot):
		return false
	if not FileAccess.file_exists(in_path):
		push_warning("SaveSystem.import_slot: file not found '%s'" % in_path)
		return false
	# 验证格式（只要能解析 JSON 就接受）
	var payload := SaveWriter.read_json(in_path)
	if payload.is_empty():
		push_error("SaveSystem.import_slot: invalid JSON in '%s'" % in_path)
		return false
	var dst := _slot_path(slot)
	SaveWriter._ensure_dir(dst)
	var err := DirAccess.copy_absolute(in_path, dst)
	return err == OK

# ══════════════════════════════════════════════
# Debug / Inspector
# ══════════════════════════════════════════════

func get_component_data() -> Dictionary:
	return {
		"current_slot":    current_slot,
		"max_slots":       max_slots,
		"global_modules":  _global_modules.keys(),
		"slot_modules":    _slot_modules.keys(),
		"global_exists":   FileAccess.file_exists(_GLOBAL_PATH),
		"slot_exists":     slot_exists(current_slot),
		"slots":           list_slots().map(func(s): return str(s)),
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
