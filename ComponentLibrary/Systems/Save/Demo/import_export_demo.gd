extends Control
## 导入 / 导出存档 Demo
##
## 演示内容：
##   - 用 FileDialog 选择目标路径执行槽位导出
##   - 用 FileDialog 选择来源文件执行槽位导入
##   - 操作结果用简单 UI 反馈（Label + 短暂颜色动画）
##
## 使用：将本脚本挂到根 Control 节点（自动构建所有子节点）。

# ──────────────────────────────────────────────
# 内部节点引用
# ──────────────────────────────────────────────
var _slot_spin:      SpinBox
var _export_btn:     Button
var _import_btn:     Button
var _feedback_label: Label
var _export_dialog:  FileDialog
var _import_dialog:  FileDialog
var _tween:          Tween

# 操作颜色
const _COLOR_OK   := Color(0.2, 0.85, 0.4)
const _COLOR_FAIL := Color(0.9, 0.25, 0.25)
const _COLOR_IDLE := Color(0.85, 0.85, 0.85)

# ──────────────────────────────────────────────
# 生命周期
# ──────────────────────────────────────────────

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_build_dialogs()

# ──────────────────────────────────────────────
# 布局
# ──────────────────────────────────────────────

func _build_ui() -> void:
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	outer.custom_minimum_size = Vector2(380, 0)
	outer.add_theme_constant_override("separation", 12)
	add_child(outer)

	# 标题
	var title := Label.new()
	title.text = "存档导入 / 导出"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	outer.add_child(title)

	outer.add_child(HSeparator.new())

	# 槽位选择行
	var slot_row := HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 8)
	outer.add_child(slot_row)

	var slot_label := Label.new()
	slot_label.text = "操作槽位："
	slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot_row.add_child(slot_label)

	_slot_spin = SpinBox.new()
	_slot_spin.min_value = 1
	_slot_spin.max_value = 8
	_slot_spin.value     = 1
	_slot_spin.step      = 1
	_slot_spin.custom_minimum_size = Vector2(80, 0)
	slot_row.add_child(_slot_spin)

	# 操作按钮行
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	outer.add_child(btn_row)

	_export_btn = Button.new()
	_export_btn.text = "导出存档…"
	_export_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_export_btn.pressed.connect(_on_export_pressed)
	btn_row.add_child(_export_btn)

	_import_btn = Button.new()
	_import_btn.text = "导入存档…"
	_import_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_import_btn.pressed.connect(_on_import_pressed)
	btn_row.add_child(_import_btn)

	outer.add_child(HSeparator.new())

	# 反馈 Label
	_feedback_label = Label.new()
	_feedback_label.text = ""
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.custom_minimum_size  = Vector2(0, 32)
	_feedback_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_color_override("font_color", _COLOR_IDLE)
	outer.add_child(_feedback_label)

# ──────────────────────────────────────────────
# 文件对话框
# ──────────────────────────────────────────────

func _build_dialogs() -> void:
	# 导出对话框（选择保存位置）
	_export_dialog = FileDialog.new()
	_export_dialog.file_mode   = FileDialog.FILE_MODE_SAVE_FILE
	_export_dialog.access      = FileDialog.ACCESS_USERDATA
	_export_dialog.filters     = PackedStringArray(["*.json ; 存档文件"])
	_export_dialog.title       = "导出存档到…"
	_export_dialog.min_size    = Vector2i(600, 400)
	_export_dialog.file_selected.connect(_on_export_path_selected)
	add_child(_export_dialog)

	# 导入对话框（选择来源文件）
	_import_dialog = FileDialog.new()
	_import_dialog.file_mode   = FileDialog.FILE_MODE_OPEN_FILE
	_import_dialog.access      = FileDialog.ACCESS_USERDATA
	_import_dialog.filters     = PackedStringArray(["*.json ; 存档文件"])
	_import_dialog.title       = "从文件导入存档…"
	_import_dialog.min_size    = Vector2i(600, 400)
	_import_dialog.file_selected.connect(_on_import_path_selected)
	add_child(_import_dialog)

# ──────────────────────────────────────────────
# 按钮回调
# ──────────────────────────────────────────────

func _on_export_pressed() -> void:
	var slot := int(_slot_spin.value)
	var ss   := _get_save_system()
	if not ss:
		_show_feedback("⚠ 未找到 SaveSystem（请检查 AutoLoad）", false)
		return
	if not ss.slot_exists(slot):
		_show_feedback("⚠ 槽位 %d 暂无存档，请先保存游戏" % slot, false)
		return
	# 设置默认文件名
	_export_dialog.current_file = "slot_%02d.json" % slot
	_export_dialog.popup_centered()

func _on_import_pressed() -> void:
	_import_dialog.popup_centered()

# ──────────────────────────────────────────────
# 文件对话框回调
# ──────────────────────────────────────────────

func _on_export_path_selected(path: String) -> void:
	var slot := int(_slot_spin.value)
	var ss   := _get_save_system()
	if not ss:
		_show_feedback("❌ 导出失败：SaveSystem 不可用", false)
		return
	var ok: bool = ss.export_slot(slot, path)
	if ok:
		_show_feedback("✅ 槽位 %d 已导出到：%s" % [slot, path.get_file()], true)
	else:
		_show_feedback("❌ 导出失败：写入文件出错", false)

func _on_import_path_selected(path: String) -> void:
	var slot := int(_slot_spin.value)
	var ss   := _get_save_system()
	if not ss:
		_show_feedback("❌ 导入失败：SaveSystem 不可用", false)
		return
	var ok: bool = ss.import_slot(slot, path)
	if ok:
		_show_feedback("✅ 已导入到槽位 %d（来源：%s）" % [slot, path.get_file()], true)
	else:
		_show_feedback("❌ 导入失败：文件无效或格式错误", false)

# ──────────────────────────────────────────────
# 反馈动画
# ──────────────────────────────────────────────

func _show_feedback(msg: String, success: bool) -> void:
	_feedback_label.text = msg
	var target_color := _COLOR_OK if success else _COLOR_FAIL

	if _tween and _tween.is_running():
		_tween.kill()

	# 立刻显示颜色 → 3 秒后淡回灰色
	_feedback_label.add_theme_color_override("font_color", target_color)
	_tween = create_tween()
	_tween.tween_interval(3.0)
	_tween.tween_method(
		func(c: Color): _feedback_label.add_theme_color_override("font_color", c),
		target_color, _COLOR_IDLE, 0.6
	)

# ──────────────────────────────────────────────
# 辅助
# ──────────────────────────────────────────────

static func _get_save_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	return tree.root.get_node_or_null("SaveSystem")
