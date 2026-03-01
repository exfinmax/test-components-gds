@tool
extends EditorPlugin
## ComponentLibrary Plugin v3.0
## - Dock: Tree browsing, search, info panel, actions
## - New Component Wizard: scaffold boilerplate with one click
## - Export/Import: pack/unpack modules as .clpack zip archives

const LIB_BASE     := "res://ComponentLibrary/Modules/"
const LIB_ABS      := "res://ComponentLibrary/"
const PACK_EXT     := ".clpack"
const MANIFEST_KEY := "cl_manifest_v1"

# ── 组件模板 ─────────────────────────────────────────────────────────────────
const COMP_TEMPLATES: Dictionary = {
	"基础组件 (ComponentBase)": \
"""## {NAME} - TODO: 描述此组件的功能
## 使用示例：
##   var comp = {NAME}.new()
##   add_child(comp)
extends ComponentBase
class_name {NAME}

# ── 信号 ─────────────────────────────────────────────────────────────────────

# ── 导出属性 ──────────────────────────────────────────────────────────────────

# ── 内部状态 ──────────────────────────────────────────────────────────────────

# ── 生命周期 ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	pass

# ── 公共 API ──────────────────────────────────────────────────────────────────
""",
	"角色组件 (CharacterComponentBase)": \
"""## {NAME} - TODO: 描述此角色组件
## 需要父节点为 CharacterBody2D
## 示例：add_child({NAME}.new())
extends CharacterComponentBase
class_name {NAME}

# ── 信号 ─────────────────────────────────────────────────────────────────────

# ── 导出属性 ──────────────────────────────────────────────────────────────────

# ── 内部状态 ──────────────────────────────────────────────────────────────────

# ── 初始化 ────────────────────────────────────────────────────────────────────
func _component_ready() -> void:
	pass  # character: CharacterBody2D 已可用

# ── 公共 API ──────────────────────────────────────────────────────────────────
""",
	"纯数据组件 (Node)": \
"""## {NAME} - 纯数据/逻辑组件
extends Node
class_name {NAME}

# ── 信号 ─────────────────────────────────────────────────────────────────────

# ── 导出属性 ──────────────────────────────────────────────────────────────────

# ── 内部状态 ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	pass
""",
	"Resource 数据类": \
"""## {NAME} - 可序列化的数据资源
extends Resource
class_name {NAME}

# ── 属性 ──────────────────────────────────────────────────────────────────────

""",
}

# ── 数据类 ────────────────────────────────────────────────────────────────────
class ModuleInfo:
	var name:        String
	var res_path:    String
	var category:    String
	var components:  Array[String]
	var templates:   Array[String]
	var demo_scenes: Array[String]
	var description: String

# ── 状态 ─────────────────────────────────────────────────────────────────────
var _modules: Array = []   # Array[ModuleInfo]
var _dock:      Control  = null
var _tree:      Tree     = null
var _search:    LineEdit = null
var _info_box:  VBoxContainer = null

# ── 生命周期 ──────────────────────────────────────────────────────────────────
func _enter_tree() -> void:
	_scan_all_modules()
	_build_dock()
	add_tool_menu_item("ComponentLibrary: Demo Browser",      _show_demo_browser)
	add_tool_menu_item("ComponentLibrary: New Component...",  _show_new_component_dialog)
	add_tool_menu_item("ComponentLibrary: Export Module...",  _show_export_dialog)
	add_tool_menu_item("ComponentLibrary: Import Package...", _show_import_dialog)
	add_tool_menu_item("ComponentLibrary: Refresh",           _refresh)
	print("[ComponentLibrary] v3.0 loaded — %d modules" % _modules.size())

func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
	for label: String in [
		"ComponentLibrary: Demo Browser",
		"ComponentLibrary: New Component...",
		"ComponentLibrary: Export Module...",
		"ComponentLibrary: Import Package...",
		"ComponentLibrary: Refresh",
	]:
		remove_tool_menu_item(label)

# ════════════════════════════════════════════════════════════════════════════════
#  扫描
# ════════════════════════════════════════════════════════════════════════════════
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
		var info         := ModuleInfo.new()
		info.name        = rel_path if not rel_path.is_empty() else abs_path.get_file()
		info.res_path    = (LIB_BASE + rel_path).rstrip("/")
		info.category    = rel_path.split("/")[0] if "/" in rel_path else rel_path
		info.components  = _list_files_in(abs_path + "Components", ".gd")
		info.templates   = _list_files_in(abs_path + "Templates", ".gd")
		info.demo_scenes = _collect_tscn_recursive(abs_path + "Demo")
		info.description = _read_readme(abs_path)
		_modules.append(info)

	var skip_dirs := ["Components", "Demo", "Templates"]
	dir.list_dir_begin()
	while true:
		var sub := dir.get_next()
		if sub == "": break
		if sub.begins_with(".") or sub in skip_dirs: continue
		if dir.current_is_dir():
			var child_rel := (rel_path + "/" + sub) if not rel_path.is_empty() else sub
			_scan_dir(abs_path + sub + "/", child_rel)
	dir.list_dir_end()

func _list_files_in(dir_path: String, ext: String) -> Array[String]:
	var result: Array[String] = []
	var d := DirAccess.open(dir_path)
	if not d: return result
	d.list_dir_begin()
	while true:
		var f := d.get_next()
		if f == "": break
		if f.ends_with(ext) and not f.ends_with(".uid"):
			result.append(f)
	d.list_dir_end()
	return result

func _collect_tscn_recursive(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var d := DirAccess.open(dir_path)
	if not d: return result
	d.list_dir_begin()
	while true:
		var n := d.get_next()
		if n == "": break
		if d.current_is_dir() and not n.begins_with("."):
			result.append_array(_collect_tscn_recursive(dir_path + "/" + n))
		elif n.ends_with(".tscn"):
			result.append(dir_path + "/" + n)
	d.list_dir_end()
	return result

func _read_readme(dir_path: String) -> String:
	var path := dir_path + "README.md"
	if not FileAccess.file_exists(path): return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if not f: return ""
	var line := f.get_line(); f.close()
	return line.lstrip("# ").strip_edges()

# ════════════════════════════════════════════════════════════════════════════════
#  Dock 构建
# ════════════════════════════════════════════════════════════════════════════════
func _build_dock() -> void:
	_dock = VBoxContainer.new()
	# 名字即 Dock 标签文字，不需要再单独加 Label
	_dock.name = "ComponentLib"

	# 工具栏（按钮行，无重复标题）
	var toolbar := HBoxContainer.new()

	_search = LineEdit.new()
	_search.placeholder_text = "搜索..."
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(_on_search_changed)
	toolbar.add_child(_search)

	var btn_new := Button.new()
	btn_new.text = "＋"; btn_new.flat = true; btn_new.tooltip_text = "新建组件"
	btn_new.pressed.connect(_show_new_component_dialog)
	toolbar.add_child(btn_new)

	var btn_exp := Button.new()
	btn_exp.text = "↑"; btn_exp.flat = true; btn_exp.tooltip_text = "导出模块为 .clpack"
	btn_exp.pressed.connect(_show_export_dialog)
	toolbar.add_child(btn_exp)

	var btn_imp := Button.new()
	btn_imp.text = "↓"; btn_imp.flat = true; btn_imp.tooltip_text = "导入 .clpack 包"
	btn_imp.pressed.connect(_show_import_dialog)
	toolbar.add_child(btn_imp)

	var btn_ref := Button.new()
	btn_ref.text = "↻"; btn_ref.flat = true; btn_ref.tooltip_text = "刷新"
	btn_ref.pressed.connect(_refresh)
	toolbar.add_child(btn_ref)

	_dock.add_child(toolbar)

	# 树
	_tree = Tree.new()
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_activated.connect(_on_item_activated)
	_dock.add_child(_tree)

	# 信息面板
	_dock.add_child(HSeparator.new())
	_info_box = VBoxContainer.new()
	_info_box.custom_minimum_size.y = 100
	_dock.add_child(_info_box)

	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _dock)
	_populate_tree("")

# ════════════════════════════════════════════════════════════════════════════════
#  树填充
# ════════════════════════════════════════════════════════════════════════════════
func _populate_tree(search: String = "") -> void:
	if not is_instance_valid(_tree): return
	_tree.clear()
	var root := _tree.create_item()
	var q    := search.to_lower()

	# 按 category 分组
	var by_cat: Dictionary = {}
	for m: ModuleInfo in _modules:
		if not by_cat.has(m.category):
			by_cat[m.category] = []
		by_cat[m.category].append(m)

	for cat: String in by_cat.keys():
		var cat_item := _tree.create_item(root)
		cat_item.set_text(0, "▸ " + cat)
		cat_item.set_selectable(0, false)
		cat_item.set_custom_color(0, Color(0.55, 0.78, 1.0))
		# 无 metadata — 不可点击

		for m: ModuleInfo in by_cat[cat]:
			var display := m.name.trim_prefix(cat + "/")
			var suffix  := " [%d]" % m.components.size()
			if m.demo_scenes.size() > 0:
				suffix += " ▶"

			# 搜索过滤
			var module_match := q.is_empty() or display.to_lower().contains(q)
			var comp_match   := false
			for c: String in m.components:
				if c.to_lower().contains(q): comp_match = true; break
			if not q.is_empty() and not module_match and not comp_match:
				continue

			var mod_item := _tree.create_item(cat_item)
			mod_item.set_text(0, display + suffix)
			mod_item.set_metadata(0, {"type": "module", "module": m})
			if m.description:
				mod_item.set_tooltip_text(0, m.description)

			for comp: String in m.components:
				if not q.is_empty() and not comp.to_lower().contains(q) and not module_match:
					continue
				var c_item := _tree.create_item(mod_item)
				c_item.set_text(0, "  " + comp.get_basename())
				c_item.set_metadata(0, {
					"type":   "component",
					"path":   m.res_path + "/Components/" + comp,
					"module": m,
				})

# ════════════════════════════════════════════════════════════════════════════════
#  树交互
# ════════════════════════════════════════════════════════════════════════════════
func _on_search_changed(text: String) -> void:
	_populate_tree(text)

func _on_item_selected() -> void:
	var sel := _tree.get_selected()
	if not sel: return
	var meta = sel.get_metadata(0)
	if not (meta is Dictionary): return
	_update_info_panel(meta)

func _on_item_activated() -> void:
	var sel := _tree.get_selected()
	if not sel: return
	var meta = sel.get_metadata(0)
	if not (meta is Dictionary): return
	match meta.get("type", ""):
		"module":
			var m: ModuleInfo = meta.get("module")
			if m and m.demo_scenes.size() > 0:
				get_editor_interface().open_scene_from_path(m.demo_scenes[0])
		"component":
			_open_script(meta.get("path", ""))

func _update_info_panel(meta: Dictionary) -> void:
	for c in _info_box.get_children():
		c.queue_free()

	match meta.get("type", ""):
		"module":
			var m: ModuleInfo = meta.get("module")
			if not m: return
			var title := Label.new()
			title.text = m.name.trim_prefix(m.category + "/")
			title.add_theme_font_size_override("font_size", 13)
			_info_box.add_child(title)

			var stats := Label.new()
			stats.text = "%d 组件  %d 模板  %d Demo" % [m.components.size(), m.templates.size(), m.demo_scenes.size()]
			stats.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0))
			_info_box.add_child(stats)

			if not m.description.is_empty():
				var desc := Label.new()
				desc.text = m.description
				desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				desc.add_theme_font_size_override("font_size", 11)
				_info_box.add_child(desc)

			var btn_row := HBoxContainer.new()
			_info_box.add_child(btn_row)

			if m.demo_scenes.size() > 0:
				var btn_demo := Button.new()
				btn_demo.text = "▶ Demo"
				btn_demo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var p: String = m.demo_scenes[0]
				btn_demo.pressed.connect(func(): get_editor_interface().open_scene_from_path(p))
				btn_row.add_child(btn_demo)

			var btn_exp := Button.new()
			btn_exp.text = "↑ 导出"
			btn_exp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn_exp.pressed.connect(func(): _export_module_prompt(m))
			btn_row.add_child(btn_exp)

		"component":
			var cpath: String = meta.get("path", "")
			var name_lbl := Label.new()
			name_lbl.text = cpath.get_file().get_basename()
			name_lbl.add_theme_font_size_override("font_size", 13)
			_info_box.add_child(name_lbl)

			var path_lbl := Label.new()
			path_lbl.text = cpath.replace(LIB_BASE, "")
			path_lbl.add_theme_font_size_override("font_size", 10)
			path_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			path_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_info_box.add_child(path_lbl)

			var btn_edit := Button.new()
			btn_edit.text = "打开脚本"
			var p: String = cpath
			btn_edit.pressed.connect(func(): _open_script(p))
			_info_box.add_child(btn_edit)

func _open_script(path: String) -> void:
	if FileAccess.file_exists(path):
		var script := load(path)
		if script is Script:
			get_editor_interface().edit_script(script)
			get_editor_interface().set_main_screen_editor("Script")

# ════════════════════════════════════════════════════════════════════════════════
#  新建组件向导
# ════════════════════════════════════════════════════════════════════════════════
func _show_new_component_dialog() -> void:
	var dlg := AcceptDialog.new()
	dlg.title       = "新建组件"
	dlg.min_size    = Vector2i(460, 400)
	dlg.ok_button_text = "创建"

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	dlg.add_child(vbox)

	# 分类
	var cats: Array[String] = []
	for m: ModuleInfo in _modules:
		if m.category not in cats: cats.append(m.category)
	cats.sort()

	var row_cat := HBoxContainer.new()
	var lbl_cat  := Label.new(); lbl_cat.text = "分类 (Category)"; lbl_cat.custom_minimum_size.x = 130
	row_cat.add_child(lbl_cat)
	var opt_cat := OptionButton.new(); opt_cat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var custom_cat_index := cats.size()
	for c: String in cats: opt_cat.add_item(c)
	opt_cat.add_item("── 新建分类 ──")
	row_cat.add_child(opt_cat)
	vbox.add_child(row_cat)

	var row_newcat := HBoxContainer.new(); row_newcat.visible = false
	var lbl_newcat := Label.new(); lbl_newcat.text = "新分类名"; lbl_newcat.custom_minimum_size.x = 130
	row_newcat.add_child(lbl_newcat)
	var edit_newcat := LineEdit.new(); edit_newcat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_newcat.placeholder_text = "例如: Physics"
	row_newcat.add_child(edit_newcat)
	vbox.add_child(row_newcat)
	opt_cat.item_selected.connect(func(idx: int): row_newcat.visible = (idx == custom_cat_index))

	# 模块
	var row_mod := HBoxContainer.new()
	var lbl_mod := Label.new(); lbl_mod.text = "模块 (Module)"; lbl_mod.custom_minimum_size.x = 130
	row_mod.add_child(lbl_mod)
	var opt_mod := OptionButton.new(); opt_mod.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt_mod.add_item("── 与分类同名 ──")
	for m: ModuleInfo in _modules: opt_mod.add_item(m.name)
	opt_mod.add_item("── 新建模块 ──")
	row_mod.add_child(opt_mod)
	vbox.add_child(row_mod)

	var row_newmod := HBoxContainer.new(); row_newmod.visible = false
	var lbl_newmod := Label.new(); lbl_newmod.text = "新模块名"; lbl_newmod.custom_minimum_size.x = 130
	row_newmod.add_child(lbl_newmod)
	var edit_newmod := LineEdit.new(); edit_newmod.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_newmod.placeholder_text = "例如: Dash"
	row_newmod.add_child(edit_newmod)
	vbox.add_child(row_newmod)
	opt_mod.item_selected.connect(func(idx: int): row_newmod.visible = (idx == _modules.size() + 1))

	# 组件名
	var row_name := HBoxContainer.new()
	var lbl_name := Label.new(); lbl_name.text = "组件名 (class_name)"; lbl_name.custom_minimum_size.x = 130
	row_name.add_child(lbl_name)
	var edit_name := LineEdit.new()
	edit_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_name.placeholder_text = "例如: TeleportComponent"
	row_name.add_child(edit_name)
	vbox.add_child(row_name)

	# 模板类型
	var row_type := HBoxContainer.new()
	var lbl_type := Label.new(); lbl_type.text = "继承模板"; lbl_type.custom_minimum_size.x = 130
	row_type.add_child(lbl_type)
	var opt_type := OptionButton.new(); opt_type.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for k: String in COMP_TEMPLATES.keys(): opt_type.add_item(k)
	row_type.add_child(opt_type)
	vbox.add_child(row_type)

	# 路径预览
	vbox.add_child(HSeparator.new())
	var lbl_prev := Label.new(); lbl_prev.text = "📁 创建路径预览:"
	vbox.add_child(lbl_prev)
	var path_prev := Label.new()
	path_prev.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	path_prev.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(path_prev)

	var get_cat_str := func() -> String:
		if opt_cat.selected == custom_cat_index:
			return edit_newcat.text.strip_edges()
		return cats[opt_cat.selected] if opt_cat.selected < cats.size() else ""

	var get_mod_str := func(cat_str: String) -> String:
		if opt_mod.selected == _modules.size() + 1:
			return edit_newmod.text.strip_edges()
		if opt_mod.selected == 0:
			return cat_str
		return _modules[opt_mod.selected - 1].name if opt_mod.selected - 1 < _modules.size() else cat_str

	var refresh_preview := func():
		var cat_str: String = get_cat_str.call()
		var mod_str: String = get_mod_str.call(cat_str)
		var comp_str := edit_name.text.strip_edges()
		if cat_str and comp_str:
			path_prev.text = "res://ComponentLibrary/Modules/%s/%s/Components/%s.gd" % [
				cat_str, mod_str, _to_snake_case(comp_str)]
		else:
			path_prev.text = "(请填写分类和组件名)"

	opt_cat.item_selected.connect(func(_i): refresh_preview.call())
	opt_mod.item_selected.connect(func(_i): refresh_preview.call())
	edit_name.text_changed.connect(func(_t): refresh_preview.call())
	edit_newcat.text_changed.connect(func(_t): refresh_preview.call())
	edit_newmod.text_changed.connect(func(_t): refresh_preview.call())
	refresh_preview.call()

	dlg.confirmed.connect(func():
		var cat_str: String = get_cat_str.call()
		var mod_str: String = get_mod_str.call(cat_str)
		var comp_name := edit_name.text.strip_edges()
		var tmpl_key  := opt_type.get_item_text(opt_type.selected)
		if cat_str.is_empty() or comp_name.is_empty():
			OS.alert("请填写分类名和组件名！", "创建失败")
			return
		_create_component_file(cat_str, mod_str, comp_name, tmpl_key)
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	get_editor_interface().get_base_control().add_child(dlg)
	dlg.popup_centered()

func _create_component_file(
	category: String,
	module_name: String,
	comp_name: String,
	template_key: String
) -> void:
	var snake     := _to_snake_case(comp_name)
	var mod_path  := "res://ComponentLibrary/Modules/%s/%s/Components/" % [category, module_name]
	var full_path := mod_path + snake + ".gd"
	var abs_dir   := ProjectSettings.globalize_path(mod_path)

	if not DirAccess.dir_exists_absolute(abs_dir):
		DirAccess.make_dir_recursive_absolute(abs_dir)

	if FileAccess.file_exists(full_path):
		OS.alert("文件已存在：\n" + full_path, "创建失败")
		return

	var tmpl: String = COMP_TEMPLATES.get(template_key, COMP_TEMPLATES.values()[0])
	var fa := FileAccess.open(full_path, FileAccess.WRITE)
	if not fa:
		OS.alert("无法创建文件：\n" + full_path, "创建失败")
		return
	fa.store_string(tmpl.replace("{NAME}", comp_name))
	fa.close()

	get_editor_interface().get_resource_filesystem().scan()
	await get_tree().create_timer(0.5).timeout
	var script := load(full_path)
	if script is Script:
		get_editor_interface().edit_script(script)
		get_editor_interface().set_main_screen_editor("Script")
	_refresh()
	print("[ComponentLibrary] 创建组件: " + full_path)

# ════════════════════════════════════════════════════════════════════════════════
#  导出模块
# ════════════════════════════════════════════════════════════════════════════════
func _export_module_prompt(m: ModuleInfo = null) -> void:
	_show_export_dialog(m)

func _show_export_dialog(preset_module: ModuleInfo = null) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "导出模块为 .clpack"
	dlg.min_size = Vector2i(430, 270)
	dlg.ok_button_text = "导出"

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	dlg.add_child(vbox)

	var row := HBoxContainer.new()
	var lbl := Label.new(); lbl.text = "选择模块"; lbl.custom_minimum_size.x = 100
	var opt := OptionButton.new(); opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for m: ModuleInfo in _modules: opt.add_item(m.name)
	row.add_child(lbl); row.add_child(opt)
	vbox.add_child(row)

	if preset_module:
		for i in _modules.size():
			if _modules[i] == preset_module:
				opt.selected = i; break

	var row_ver := HBoxContainer.new()
	var lbl_ver := Label.new(); lbl_ver.text = "版本号"; lbl_ver.custom_minimum_size.x = 100
	var edit_ver := LineEdit.new(); edit_ver.text = "1.0.0"; edit_ver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_ver.add_child(lbl_ver); row_ver.add_child(edit_ver)
	vbox.add_child(row_ver)

	var row_path := HBoxContainer.new()
	var lbl_path := Label.new(); lbl_path.text = "保存到"; lbl_path.custom_minimum_size.x = 100
	var edit_path := LineEdit.new(); edit_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_path.placeholder_text = "res://exports/ModuleName.clpack"
	row_path.add_child(lbl_path); row_path.add_child(edit_path)
	vbox.add_child(row_path)

	var update_path := func():
		if opt.selected >= 0 and opt.selected < _modules.size():
			var m: ModuleInfo = _modules[opt.selected]
			var safe := m.name.replace("/", "_")
			var v    := edit_ver.text.strip_edges().replace(".", "_")
			edit_path.text = "res://" + safe + "_v" + v + PACK_EXT
	opt.item_selected.connect(func(_i): update_path.call())
	edit_ver.text_changed.connect(func(_t): update_path.call())
	update_path.call()

	var note := Label.new()
	note.text = "将整个模块文件夹打包为 .clpack (ZIP格式)\n包含 Components / Demo / Templates 及 README"
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(note)

	dlg.confirmed.connect(func():
		if opt.selected < 0 or opt.selected >= _modules.size():
			OS.alert("请选择一个模块", "导出失败"); return
		var m: ModuleInfo = _modules[opt.selected]
		var dest := edit_path.text.strip_edges()
		if dest.is_empty():
			OS.alert("请指定输出路径", "导出失败"); return
		_export_module(m, edit_ver.text.strip_edges(), dest)
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	get_editor_interface().get_base_control().add_child(dlg)
	dlg.popup_centered()

func _export_module(m: ModuleInfo, version: String, dest_path: String) -> void:
	var src_abs := ProjectSettings.globalize_path(m.res_path + "/")
	var dst_abs := ProjectSettings.globalize_path(dest_path)
	var dst_dir := dst_abs.get_base_dir()
	if not DirAccess.dir_exists_absolute(dst_dir):
		DirAccess.make_dir_recursive_absolute(dst_dir)

	var all_files: Array[String] = _collect_all_files(src_abs)
	if all_files.is_empty():
		OS.alert("模块目录无文件：\n" + src_abs, "导出失败"); return

	var zip := ZIPPacker.new()
	var err := zip.open(dst_abs, ZIPPacker.APPEND_CREATE)
	if err != OK:
		OS.alert("无法创建 ZIP：%s\n%s" % [error_string(err), dst_abs], "导出失败"); return

	var manifest := {
		MANIFEST_KEY: true,
		"name":        m.name,
		"category":    m.category,
		"version":     version,
		"description": m.description,
		"files":       [],
	}

	for abs_file: String in all_files:
		var rel: String = abs_file.replace(src_abs, "")
		var arc: String = (m.name + "/" + rel).replace("\\", "/").replace("//", "/")
		var fa := FileAccess.open(abs_file, FileAccess.READ)
		if not fa: continue
		var data := fa.get_buffer(fa.get_length()); fa.close()
		zip.start_file(arc)
		zip.write_file(data)
		zip.close_file()
		manifest["files"].append(arc)

	zip.start_file("manifest.json")
	zip.write_file(JSON.stringify(manifest, "\t").to_utf8_buffer())
	zip.close_file()
	zip.close()

	print("[ComponentLibrary] 导出 → %s  (%d 文件)" % [dst_abs, all_files.size()])
	OS.alert("导出成功！\n%s\n共 %d 个文件" % [dest_path, all_files.size()], "导出完成")

func _collect_all_files(abs_dir: String) -> Array[String]:
	var result: Array[String] = []
	var d := DirAccess.open(abs_dir)
	if not d: return result
	d.list_dir_begin()
	while true:
		var n := d.get_next()
		if n == "": break
		if n.begins_with("."): continue
		if d.current_is_dir():
			result.append_array(_collect_all_files(abs_dir + n + "/"))
		else:
			result.append(abs_dir + n)
	d.list_dir_end()
	return result

# ════════════════════════════════════════════════════════════════════════════════
#  导入模块
# ════════════════════════════════════════════════════════════════════════════════
func _show_import_dialog(_unused = null) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "导入 .clpack 包"
	dlg.min_size = Vector2i(430, 240)
	dlg.ok_button_text = "导入"

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	dlg.add_child(vbox)

	var row_path := HBoxContainer.new()
	var lbl_path := Label.new(); lbl_path.text = ".clpack 路径"; lbl_path.custom_minimum_size.x = 110
	var edit_path := LineEdit.new()
	edit_path.placeholder_text = "res://SomeModule_v1_0_0.clpack"
	edit_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_path.add_child(lbl_path); row_path.add_child(edit_path)
	vbox.add_child(row_path)

	var row_dest := HBoxContainer.new()
	var lbl_dest := Label.new(); lbl_dest.text = "安装到"; lbl_dest.custom_minimum_size.x = 110
	var edit_dest := LineEdit.new(); edit_dest.text = LIB_BASE
	edit_dest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_dest.add_child(lbl_dest); row_dest.add_child(edit_dest)
	vbox.add_child(row_dest)

	var lbl_info := Label.new()
	lbl_info.text = "选择用'导出模块'生成的 .clpack，\n文件会解压到'安装到'目录下对应模块子文件夹中。"
	lbl_info.add_theme_font_size_override("font_size", 11)
	lbl_info.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	lbl_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_info)

	var status_lbl := Label.new()
	vbox.add_child(status_lbl)

	edit_path.text_changed.connect(func(_t):
		var p := edit_path.text.strip_edges()
		if not FileAccess.file_exists(p): status_lbl.text = ""; return
		var info := _read_package_manifest(p)
		if info.is_empty():
			status_lbl.text = "❌ 无效的 .clpack 文件"
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		else:
			status_lbl.text = "✅ %s  v%s  (%d 文件)" % [
				info.get("name","?"), info.get("version","?"),
				(info.get("files",[]) as Array).size()]
			status_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	)

	dlg.confirmed.connect(func():
		var src := edit_path.text.strip_edges()
		var dst := edit_dest.text.strip_edges()
		if src.is_empty(): OS.alert("请指定 .clpack 路径", "导入失败"); return
		if not FileAccess.file_exists(src): OS.alert("文件不存在：\n" + src, "导入失败"); return
		_import_package(src, dst)
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	get_editor_interface().get_base_control().add_child(dlg)
	dlg.popup_centered()

func _read_package_manifest(zip_path: String) -> Dictionary:
	var zip := ZIPReader.new()
	if zip.open(ProjectSettings.globalize_path(zip_path)) != OK: return {}
	if not zip.file_exists("manifest.json"): zip.close(); return {}
	var raw := zip.read_file("manifest.json"); zip.close()
	var json := JSON.new()
	if json.parse(raw.get_string_from_utf8()) != OK: return {}
	var data = json.get_data()
	if not data is Dictionary: return {}
	if not data.has(MANIFEST_KEY): return {}
	return data

func _import_package(zip_path: String, dest_base: String) -> void:
	var abs_zip  := ProjectSettings.globalize_path(zip_path)
	var abs_dest := ProjectSettings.globalize_path(dest_base)
	if not abs_dest.ends_with("/"): abs_dest += "/"

	var manifest := _read_package_manifest(zip_path)
	if manifest.is_empty():
		OS.alert("无效的 .clpack 文件（缺少 manifest.json）", "导入失败"); return

	var zip := ZIPReader.new()
	if zip.open(abs_zip) != OK:
		OS.alert("无法打开 ZIP：\n" + abs_zip, "导入失败"); return

	var files: Array = manifest.get("files", [])
	var count := 0
	for arc: String in files:
		if not zip.file_exists(arc): continue
		var data := zip.read_file(arc)
		var out_abs := abs_dest + arc
		var out_dir := out_abs.get_base_dir()
		if not DirAccess.dir_exists_absolute(out_dir):
			DirAccess.make_dir_recursive_absolute(out_dir)
		var fa := FileAccess.open(out_abs, FileAccess.WRITE)
		if not fa: continue
		fa.store_buffer(data); fa.close()
		count += 1
	zip.close()

	get_editor_interface().get_resource_filesystem().scan()
	_refresh()
	print("[ComponentLibrary] 导入完成 → %s  (%d 文件)" % [abs_dest, count])
	OS.alert("导入成功！\n模块：%s  v%s\n%d 个文件已安装到：\n%s" % [
		manifest.get("name","?"), manifest.get("version","?"),
		count, dest_base], "导入完成")

# ════════════════════════════════════════════════════════════════════════════════
#  Demo Browser 弹窗
# ════════════════════════════════════════════════════════════════════════════════
func _show_demo_browser() -> void:
	var dlg := Window.new()
	dlg.title = "Component Library — Demo Browser"
	dlg.size  = Vector2i(760, 540)
	dlg.wrap_controls = true
	dlg.close_requested.connect(func(): dlg.queue_free())

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	dlg.add_child(vbox)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tabs)

	var by_cat: Dictionary = {}
	for m: ModuleInfo in _modules:
		if m.demo_scenes.size() == 0: continue
		if not by_cat.has(m.category): by_cat[m.category] = []
		by_cat[m.category].append(m)

	for cat: String in by_cat.keys():
		var scroll := ScrollContainer.new()
		scroll.name = cat
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var grid := GridContainer.new()
		grid.columns = 3
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		scroll.add_child(grid)

		for m: ModuleInfo in by_cat[cat]:
			var card := PanelContainer.new()
			card.custom_minimum_size = Vector2(220, 130)
			var cv := VBoxContainer.new()
			cv.add_theme_constant_override("separation", 4)
			card.add_child(cv)

			var n := Label.new()
			n.text = m.name.trim_prefix(cat + "/")
			n.add_theme_font_size_override("font_size", 14)
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(n)

			var il := Label.new()
			il.text = "%d 组件" % m.components.size()
			il.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
			il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(il)

			if not m.description.is_empty():
				var dl := Label.new()
				dl.text = m.description
				dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				dl.add_theme_font_size_override("font_size", 11)
				cv.add_child(dl)

			var btn_row := HBoxContainer.new()
			cv.add_child(btn_row)

			var btn_demo := Button.new()
			btn_demo.text = "▶ Demo"
			btn_demo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var demo_p: String = m.demo_scenes[0]
			btn_demo.pressed.connect(func():
				get_editor_interface().open_scene_from_path(demo_p)
				dlg.queue_free()
			)
			btn_row.add_child(btn_demo)

			if m.demo_scenes.size() > 1:
				var btn_more := MenuButton.new()
				btn_more.text = "▼"
				var pop := btn_more.get_popup()
				for i: int in range(1, m.demo_scenes.size()):
					pop.add_item(m.demo_scenes[i].get_file(), i - 1)
				pop.id_pressed.connect(func(id: int):
					get_editor_interface().open_scene_from_path(m.demo_scenes[id + 1])
					dlg.queue_free()
				)
				btn_row.add_child(btn_more)

			grid.add_child(card)
		tabs.add_child(scroll)

	if tabs.get_tab_count() == 0:
		var empty := Label.new()
		empty.text = "未找到 Demo 场景。\n每个模块需要一个 Demo/*.tscn 文件。"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty)

	get_editor_interface().get_base_control().add_child(dlg)
	dlg.popup_centered()

# ════════════════════════════════════════════════════════════════════════════════
#  刷新
# ════════════════════════════════════════════════════════════════════════════════
func _refresh() -> void:
	_scan_all_modules()
	_populate_tree(_search.text if is_instance_valid(_search) else "")
	print("[ComponentLibrary] 已刷新 — %d 模块" % _modules.size())

# ════════════════════════════════════════════════════════════════════════════════
#  工具函数
# ════════════════════════════════════════════════════════════════════════════════
func _to_snake_case(pascal: String) -> String:
	var result := ""
	for i: int in pascal.length():
		var c := pascal[i]
		if c == c.to_upper() and c != c.to_lower() and i > 0:
			result += "_"
		result += c.to_lower()
	return result
