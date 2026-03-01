@tool
extends EditorPlugin
## ComponentLibrary Demo Browser Plugin v2.0
## 正确扫描 ComponentLibrary/Modules/ 并提供 Dock + Demo Browser 弹窗

const LIB_BASE := "res://ComponentLibrary/Modules/"

# ─── 模块信息 ─────────────────────────────────────────────────────────────────
class ModuleInfo:
	var name:        String
	var res_path:    String
	var category:    String
	var components:  Array[String]
	var templates:   Array[String]
	var demo_scenes: Array[String]
	var description: String

var _modules: Array = []        # Array of ModuleInfo
var _dock:    Control = null
var _tree:    Tree    = null
var _search:  LineEdit = null
var _info_box: VBoxContainer = null

# ─── 生命周期 ─────────────────────────────────────────────────────────────────
func _enter_tree() -> void:
	_scan_all_modules()
	_build_dock()
	add_tool_menu_item("ComponentLibrary: Demo Browser", _show_demo_browser)
	add_tool_menu_item("ComponentLibrary: Refresh",      _refresh)
	print("[ComponentLibrary] loaded — %d modules" % _modules.size())

func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
	remove_tool_menu_item("ComponentLibrary: Demo Browser")
	remove_tool_menu_item("ComponentLibrary: Refresh")

# ─── 扫描逻辑 ─────────────────────────────────────────────────────────────────
func _scan_all_modules() -> void:
	_modules.clear()
	_scan_dir(LIB_BASE, "")

func _scan_dir(abs_path: String, rel_path: String) -> void:
	var dir := DirAccess.open(abs_path)
	if not dir:
		return

	var has_components := DirAccess.dir_exists_absolute(abs_path + "Components")
	var has_demo       := DirAccess.dir_exists_absolute(abs_path + "Demo")

	if has_components or has_demo:
		var info          := ModuleInfo.new()
		info.name         = rel_path if not rel_path.is_empty() else abs_path.get_file()
		info.res_path     = (LIB_BASE + rel_path).rstrip("/")
		info.category     = rel_path.split("/")[0] if "/" in rel_path else rel_path
		info.components   = _list_files_in(abs_path + "Components", ".gd")
		info.templates    = _list_files_in(abs_path + "Templates",  ".gd")
		info.demo_scenes  = _collect_tscn_recursive(abs_path + "Demo")
		info.description  = _read_readme(abs_path)
		_modules.append(info)

	# 递归子目录（跳过 Components/Demo/Templates）
	var skip_dirs := ["Components", "Demo", "Templates"]
	dir.list_dir_begin()
	while true:
		var sub := dir.get_next()
		if sub == "":
			break
		if sub.begins_with(".") or sub in skip_dirs:
			continue
		if dir.current_is_dir():
			var child_rel := (rel_path + "/" + sub) if not rel_path.is_empty() else sub
			_scan_dir(abs_path + sub + "/", child_rel)
	dir.list_dir_end()

func _list_files_in(dir_path: String, ext: String) -> Array[String]:
	var result: Array[String] = []
	var d := DirAccess.open(dir_path)
	if not d:
		return result
	d.list_dir_begin()
	while true:
		var f := d.get_next()
		if f == "":
			break
		if f.ends_with(ext) and not f.ends_with(".uid"):
			result.append(f)
	d.list_dir_end()
	return result

func _collect_tscn_recursive(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var d := DirAccess.open(dir_path)
	if not d:
		return result
	d.list_dir_begin()
	while true:
		var name := d.get_next()
		if name == "":
			break
		if d.current_is_dir() and not name.begins_with("."):
			result.append_array(_collect_tscn_recursive(dir_path + "/" + name))
		elif name.ends_with(".tscn"):
			result.append(dir_path + "/" + name)
	d.list_dir_end()
	return result

func _read_readme(dir_path: String) -> String:
	var path := dir_path + "README.md"
	if not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return ""
	var line := f.get_line()
	f.close()
	return line.lstrip("# ").strip_edges()

# ─── Dock ─────────────────────────────────────────────────────────────────────
func _build_dock() -> void:
	_dock = VBoxContainer.new()
	_dock.name = "ComponentLib"

	# 标题行
	var header := HBoxContainer.new()
	var title  := Label.new()
	title.text = "ComponentLib"
	title.add_theme_font_size_override("font_size", 14)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var rbtn := Button.new()
	rbtn.text = "↻"; rbtn.flat = true; rbtn.tooltip_text = "Refresh"
	rbtn.pressed.connect(_refresh)
	header.add_child(rbtn)
	_dock.add_child(header)

	# 搜索框
	_search = LineEdit.new()
	_search.placeholder_text = "Search components..."
	_search.text_changed.connect(_on_search_changed)
	_dock.add_child(_search)

	# 组件树
	_tree = Tree.new()
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_activated.connect(_on_item_activated)
	_dock.add_child(_tree)

	# 信息面板
	_dock.add_child(HSeparator.new())
	_info_box = VBoxContainer.new()
	_info_box.custom_minimum_size.y = 90
	_dock.add_child(_info_box)

	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _dock)
	_populate_tree()

func _populate_tree() -> void:
	if not is_instance_valid(_tree):
		return
	_tree.clear()
	var root := _tree.create_item()

	# 按 category 分组
	var by_cat: Dictionary = {}
	for m in _modules:
		var cat: String = m.category
		if not by_cat.has(cat):
			by_cat[cat] = []
		by_cat[cat].append(m)

	for cat in by_cat.keys():
		var cat_item := _tree.create_item(root)
		cat_item.set_text(0, "▸ " + cat)
		cat_item.set_selectable(0, false)
		cat_item.set_custom_color(0, Color(0.8, 0.9, 1.0))

		for m in by_cat[cat]:
			var display: String = m.name.trim_prefix(cat + "/")
			var suffix:  String = " [%d]" % m.components.size()
			if m.demo_scenes.size() > 0:
				suffix += " ▶"
			var mod_item := _tree.create_item(cat_item)
			mod_item.set_text(0, display + suffix)
			mod_item.set_metadata(0, {"type": "module", "module": m})

			for comp in m.components:
				var c_item := _tree.create_item(mod_item)
				c_item.set_text(0, "  " + comp.get_basename())
				c_item.set_metadata(0, {
					"type":  "component",
					"path":  m.res_path + "/Components/" + comp
				})

# ─── 树交互 ───────────────────────────────────────────────────────────────────
func _on_search_changed(text: String) -> void:
	var q := text.to_lower()
	if is_instance_valid(_tree) and _tree.get_root():
		_filter_tree(_tree.get_root(), q)

func _filter_tree(item: TreeItem, q: String) -> bool:
	if not item:
		return false
	var child_visible := false
	var child := item.get_first_child()
	while child:
		if _filter_tree(child, q):
			child_visible = true
		child = child.get_next()
	var self_match := q.is_empty() or item.get_text(0).to_lower().contains(q)
	item.visible = self_match or child_visible
	return item.visible

func _on_item_selected() -> void:
	var sel := _tree.get_selected()
	if not sel or sel.get_metadata_count() == 0:
		return
	_update_info_panel(sel.get_metadata(0))

func _on_item_activated() -> void:
	var sel := _tree.get_selected()
	if not sel or sel.get_metadata_count() == 0:
		return
	var meta: Dictionary = sel.get_metadata(0)
	match meta.get("type", ""):
		"module":
			var m: Object = meta.get("module")
			if m and m.demo_scenes.size() > 0:
				get_editor_interface().open_scene_from_path(m.demo_scenes[0])
		"component":
			_open_script(meta.get("path", ""))

func _update_info_panel(meta: Dictionary) -> void:
	for c in _info_box.get_children():
		c.queue_free()
	match meta.get("type", ""):
		"module":
			var m: Object = meta.get("module")
			if not m:
				return
			var title := Label.new()
			title.text = m.name
			title.add_theme_font_size_override("font_size", 13)
			_info_box.add_child(title)
			var stats := Label.new()
			stats.text = "%d comps | %d tpls | %d demo(s)" % [
				m.components.size(), m.templates.size(), m.demo_scenes.size()]
			stats.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
			_info_box.add_child(stats)
			if not m.description.is_empty():
				var desc := Label.new()
				desc.text = m.description
				desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				_info_box.add_child(desc)
			if m.demo_scenes.size() > 0:
				var btn := Button.new()
				btn.text = "▶ Open Demo"
				var p: String = m.demo_scenes[0]
				btn.pressed.connect(func(): get_editor_interface().open_scene_from_path(p))
				_info_box.add_child(btn)
		"component":
			var name_lbl := Label.new()
			name_lbl.text = meta.get("path", "").get_file().get_basename()
			name_lbl.add_theme_font_size_override("font_size", 13)
			_info_box.add_child(name_lbl)
			var btn := Button.new()
			btn.text = "Open Script"
			var p: String = meta.get("path", "")
			btn.pressed.connect(func(): _open_script(p))
			_info_box.add_child(btn)

func _open_script(path: String) -> void:
	if FileAccess.file_exists(path):
		var script := load(path)
		if script is Script:
			get_editor_interface().edit_script(script)
			get_editor_interface().set_main_screen_editor("Script")

# ─── Demo Browser 弹窗 ────────────────────────────────────────────────────────
func _show_demo_browser() -> void:
	var dlg := Window.new()
	dlg.title = "Component Library — Demo Browser"
	dlg.size  = Vector2i(720, 520)
	dlg.close_requested.connect(func(): dlg.queue_free())
	dlg.wrap_controls = true

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	dlg.add_child(vbox)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tabs)

	# 按分类建页签
	var by_cat: Dictionary = {}
	for m in _modules:
		if m.demo_scenes.size() == 0:
			continue
		if not by_cat.has(m.category):
			by_cat[m.category] = []
		by_cat[m.category].append(m)

	for cat in by_cat.keys():
		var scroll := ScrollContainer.new()
		scroll.name = cat
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var grid := GridContainer.new()
		grid.columns = 3
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(grid)

		for m in by_cat[cat]:
			var card := PanelContainer.new()
			card.custom_minimum_size = Vector2(210, 120)
			var cv := VBoxContainer.new()
			cv.add_theme_constant_override("separation", 4)
			card.add_child(cv)

			var n := Label.new()
			n.text = m.name.trim_prefix(cat + "/")
			n.add_theme_font_size_override("font_size", 14)
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(n)

			var il := Label.new()
			il.text = "%d components" % m.components.size()
			il.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
			il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(il)

			if not m.description.is_empty():
				var dl := Label.new()
				dl.text = m.description
				dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				dl.add_theme_font_size_override("font_size", 11)
				cv.add_child(dl)

			var btn := Button.new()
			btn.text = "Open Demo"
			var demo_path: String = m.demo_scenes[0]
			btn.pressed.connect(func():
				get_editor_interface().open_scene_from_path(demo_path)
				dlg.queue_free()
			)
			cv.add_child(btn)
			grid.add_child(card)

		tabs.add_child(scroll)

	if tabs.get_tab_count() == 0:
		var empty := Label.new()
		empty.text = "No demo scenes found.\nEach module needs a Demo/*.tscn file."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty)

	get_editor_interface().get_base_control().add_child(dlg)
	dlg.popup_centered()

# ─── Refresh ──────────────────────────────────────────────────────────────────
func _refresh() -> void:
	_scan_all_modules()
	_populate_tree()
	print("[ComponentLibrary] refreshed — %d modules" % _modules.size())
