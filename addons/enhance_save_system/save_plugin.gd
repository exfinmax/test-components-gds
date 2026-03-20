@tool
class_name SavePlugin
extends EditorPlugin

static var instance: SavePlugin

var _editor_panel: Control
var _slot_tree: Tree
var _status_label: Label

const _SAVE_DIR     := "user://saves"
const _SLOT_PATTERN := "user://saves/slot_%02d.json"
const _MAX_SLOTS    := 8

func _init() -> void:
	instance = self

func _enable_plugin() -> void:
	add_autoload_singleton("SaveSystem", get_plugin_path() + "/core/save_system.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton("SaveSystem")

func _enter_tree() -> void:
	_editor_panel = _build_editor_panel()
	add_control_to_bottom_panel(_editor_panel, "存档管理")

func _exit_tree() -> void:
	if is_instance_valid(_editor_panel):
		remove_control_from_bottom_panel(_editor_panel)
		_editor_panel.queue_free()

# ──────────────────────────────────────────────
# 编辑器面板构建
# ──────────────────────────────────────────────

func _build_editor_panel() -> Control:
	var root := VBoxContainer.new()
	root.name = "SaveEditorPanel"
	root.custom_minimum_size = Vector2(0, 180)

	# 工具栏
	var toolbar := HBoxContainer.new()
	root.add_child(toolbar)

	var refresh_btn := Button.new()
	refresh_btn.text = "🔄 刷新"
	refresh_btn.pressed.connect(_refresh_slot_list)
	toolbar.add_child(refresh_btn)

	var export_btn := Button.new()
	export_btn.text = "导出选中"
	export_btn.pressed.connect(_on_export_pressed_toolbar)
	toolbar.add_child(export_btn)

	var import_btn := Button.new()
	import_btn.text = "导入到选中"
	import_btn.pressed.connect(_on_import_pressed_toolbar)
	toolbar.add_child(import_btn)

	var delete_btn := Button.new()
	delete_btn.text = "🗑 删除选中"
	delete_btn.pressed.connect(_on_delete_pressed_toolbar)
	toolbar.add_child(delete_btn)

	# 弹性空白
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)

	_status_label = Label.new()
	_status_label.text = "就绪"
	toolbar.add_child(_status_label)

	# 槽位树
	_slot_tree = Tree.new()
	_slot_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_slot_tree.columns = 5
	_slot_tree.set_column_title(0, "槽位")
	_slot_tree.set_column_title(1, "存档时间")
	_slot_tree.set_column_title(2, "游戏版本")
	_slot_tree.set_column_title(3, "加密")
	_slot_tree.set_column_title(4, "压缩")
	_slot_tree.set_column_expand(0, false)
	_slot_tree.set_column_custom_minimum_width(0, 80)
	_slot_tree.column_titles_visible = true
	root.add_child(_slot_tree)

	# 初始刷新
	_refresh_slot_list.call_deferred()
	return root

# ──────────────────────────────────────────────
# 槽位列表刷新（直接读文件，不依赖 SaveSystem 运行时）
# ──────────────────────────────────────────────

func _refresh_slot_list() -> void:
	if not is_instance_valid(_slot_tree):
		return
	_slot_tree.clear()
	var root_item := _slot_tree.create_item()

	var found := 0
	for i in range(1, _MAX_SLOTS + 1):
		var path := _SLOT_PATTERN % i
		var abs_path := ProjectSettings.globalize_path(path)
		var exists := FileAccess.file_exists(path)

		var item := _slot_tree.create_item(root_item)
		item.set_text(0, "槽位 %d" % i)
		item.set_metadata(0, i)

		if not exists:
			item.set_text(1, "（空）")
			item.set_text(2, "—")
			item.set_text(3, "—")
			item.set_text(4, "—")
			item.set_custom_color(1, Color(0.5, 0.5, 0.5))
			continue

		found += 1
		# 直接读文件头获取 meta，不需要 SaveSystem 运行
		var meta := _read_meta_from_file(path)
		var saved_at: float = float(meta.get("saved_at", 0))
		if saved_at > 0:
			var dt := Time.get_datetime_dict_from_unix_time(int(saved_at))
			item.set_text(1, "%04d-%02d-%02d %02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute])
		else:
			item.set_text(1, "未知时间")
		item.set_text(2, str(meta.get("game_version", "—")))
		item.set_text(3, str(meta.get("encryption_type", "无")))
		item.set_text(4, str(meta.get("compression", "无")))

	_set_status("共 %d 个存档（最多 %d 槽）" % [found, _MAX_SLOTS])

## 直接从文件读取 _meta，支持新二进制格式和旧 JSON 格式
func _read_meta_from_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var raw := file.get_buffer(file.get_length())
	file = null

	# 尝试新二进制格式：[4字节 header_len][header JSON][body]
	if raw.size() >= 4:
		var hlen: int = raw[0] | (raw[1] << 8) | (raw[2] << 16) | (raw[3] << 24)
		if hlen > 0 and hlen <= 65536 and (4 + hlen) <= raw.size():
			var header_text := raw.slice(4, 4 + hlen).get_string_from_utf8()
			var json := JSON.new()
			if json.parse(header_text) == OK and json.data is Dictionary:
				var meta := json.data as Dictionary
				if meta.has("version"):
					return meta

	# 旧纯文本 JSON 格式
	var text := raw.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		return (json.data as Dictionary).get("_meta", {}) as Dictionary

	return {}

# ──────────────────────────────────────────────
# 工具栏操作
# ──────────────────────────────────────────────

func _on_export_pressed_toolbar() -> void:
	var slot := _get_selected_slot()
	if slot < 0:
		_set_status("请先选择一个槽位")
		return
	var path := _SLOT_PATTERN % slot
	if not FileAccess.file_exists(path):
		_set_status("槽位 %d 无存档" % slot)
		return
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.filters = ["*.json ; JSON 存档文件", "*.* ; 所有文件"]
	dialog.current_file = "slot_%02d.json" % slot
	dialog.title = "导出槽位 %d 存档" % slot
	dialog.file_selected.connect(func(dst: String):
		var ok := DirAccess.copy_absolute(path, dst) == OK
		_set_status("导出%s：%s" % ["成功" if ok else "失败", dst])
		dialog.queue_free()
	)
	get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered(Vector2(700, 450))

func _on_import_pressed_toolbar() -> void:
	var slot := _get_selected_slot()
	if slot < 0:
		_set_status("请先选择一个槽位")
		return
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = ["*.json ; JSON 存档文件", "*.* ; 所有文件"]
	dialog.title = "导入到槽位 %d" % slot
	dialog.file_selected.connect(func(src: String):
		var dst := _SLOT_PATTERN % slot
		_ensure_save_dir()
		var ok := DirAccess.copy_absolute(src, dst) == OK
		_set_status("导入%s：%s" % ["成功" if ok else "失败", src])
		_refresh_slot_list()
		dialog.queue_free()
	)
	get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered(Vector2(700, 450))

func _on_delete_pressed_toolbar() -> void:
	var slot := _get_selected_slot()
	if slot < 0:
		_set_status("请先选择一个槽位")
		return
	var path := _SLOT_PATTERN % slot
	if not FileAccess.file_exists(path):
		_set_status("槽位 %d 无存档可删除" % slot)
		return
	# 确认对话框
	var confirm := ConfirmationDialog.new()
	confirm.title = "确认删除"
	confirm.dialog_text = "确定要删除槽位 %d 的存档吗？" % slot
	confirm.confirmed.connect(func():
		var abs_path := ProjectSettings.globalize_path(path)
		var err := OS.move_to_trash(abs_path)
		if err != OK:
			# 回退：直接删除
			err = DirAccess.remove_absolute(path)
		_set_status("删除槽位 %d %s" % [slot, "成功" if err == OK else "失败"])
		_refresh_slot_list()
		confirm.queue_free()
	)
	confirm.canceled.connect(func(): confirm.queue_free())
	get_editor_interface().get_base_control().add_child(confirm)
	confirm.popup_centered()

# ──────────────────────────────────────────────
# 内部工具
# ──────────────────────────────────────────────

func _get_selected_slot() -> int:
	if not is_instance_valid(_slot_tree):
		return -1
	var selected := _slot_tree.get_selected()
	if selected == null:
		return -1
	return int(selected.get_metadata(0))

func _set_status(text: String) -> void:
	if is_instance_valid(_status_label):
		_status_label.text = text

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(_SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(_SAVE_DIR)

static func get_plugin_path() -> String:
	if not is_instance_valid(instance):
		return ""
	return instance.get_script().resource_path.get_base_dir()
