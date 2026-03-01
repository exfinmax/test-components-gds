@tool
extends EditorPlugin
## ComponentLibrary 增强版插件
## 提供组件浏览、搜索、导入功能

const COMPONENT_LIBRARY_BASE := "res://ComponentLibrary/"

# 依赖配置
const DEPENDENCY_CONFIGS := [
	{
		"name": "ComponentBase",
		"base": "Node",
		"path": "res://ComponentLibrary/Dependencies/component_base.gd",
	},
	{
		"name": "CharacterComponentBase",
		"base": "Node",
		"path": "res://ComponentLibrary/Dependencies/character_component_base.gd",
	},
	{
		"name": "GlobalEventBus",
		"base": "Node",
		"path": "res://ComponentLibrary/Dependencies/event_bus.gd",
	},
	{
		"name": "GlobalObjectPool",
		"base": "Node",
		"path": "res://ComponentLibrary/Dependencies/object_pool.gd",
	},
	{
		"name": "GlobalTimeController",
		"base": "Node",
		"path": "res://ComponentLibrary/Dependencies/time_controller.gd",
	},
	{
		"name": "LocalTimeDomain",
		"base": "Node",
		"path": "res://ComponentLibrary/Dependencies/local_time_domain.gd",
	},
]

# 分类配置
var _categories := {
	"Core": {
		"path": "Dependencies",
		"display": "核心基础",
		"icon": "NodeWarning"
	},
	"Modules": {
		"path": "Packs",
		"display": "功能模块",
		"icon": "PackedScene",
		"subcategories": true
	}
}

var _registered_types: Array[String] = []
var _packs: Dictionary = {}  # { category: [pack_names] }
var _search_text: String = ""

# 插件UI
var _dock_scene: Control
var _tree: Tree
var _search_bar: LineEdit
var _info_panel: VBoxContainer

func _enter_tree() -> void:
	print("[ComponentLibrary] Plugin loading...")
	
	# 注册依赖
	var icon := _load_icon()
	for config in DEPENDENCY_CONFIGS:
		_register_dependency(config, icon)
	
	# 扫描组件库
	_scan_component_library()
	
	# 创建UI
	_create_dock_ui()
	
	# 添加菜单项
	add_tool_menu_item("ComponentLibrary/Refresh", Callable(self, "_on_refresh"))
	add_tool_menu_item("ComponentLibrary/Open Demo Browser", Callable(self, "_on_open_demo_browser"))
	add_tool_menu_item("ComponentLibrary/Create New Pack", Callable(self, "_on_new_pack"))
	
	print("[ComponentLibrary] Plugin loaded successfully")

func _exit_tree() -> void:
	# 清理注册
	for type_name in _registered_types:
		remove_custom_type(type_name)
	_registered_types.clear()
	
	# 移除菜单
	remove_tool_menu_item("ComponentLibrary/Refresh")
	remove_tool_menu_item("ComponentLibrary/Open Demo Browser")
	remove_tool_menu_item("ComponentLibrary/Create New Pack")
	
	# 移除Dock
	if _dock_scene:
		remove_control_from_docks(_dock_scene)
		_dock_scene.queue_free()

## 注册依赖组件
func _register_dependency(config: Dictionary, icon: Texture2D) -> void:
	var script_path: String = config.get("path", "")
	if not FileAccess.file_exists(script_path):
		push_warning("[ComponentLibrary] Dependency missing: %s" % script_path)
		return
	
	var script = load(script_path)
	if script == null:
		push_warning("[ComponentLibrary] Failed to load: %s" % script_path)
		return
	
	add_custom_type(config.get("name", ""), config.get("base", "Node"), script, icon)
	_registered_types.append(config.get("name", ""))
	print("[ComponentLibrary] Registered: %s" % config.get("name"))

## 扫描组件库
func _scan_component_library() -> void:
	_packs.clear()
	
	# 扫描Packs目录
	var packs_dir = DirAccess.open(COMPONENT_LIBRARY_BASE + "Packs")
	if not packs_dir:
		push_error("[ComponentLibrary] Packs directory not found")
		return
	
	var pack_list: Array[String] = []
	while true:
		var name = packs_dir.get_next()
		if name == "":
			break
		if packs_dir.current_is_dir() and not name.begins_with("."):
			# 过滤无效Pack
			if _is_valid_pack(name):
				pack_list.append(name)
	
	pack_list.sort()
	_packs["Modules"] = pack_list
	
	print("[ComponentLibrary] Found %d packs" % pack_list.size())

## 检查是否是有效的Pack
func _is_valid_pack(name: String) -> bool:
	# 排除特殊文件夹
	var excluded = ["README.md", "111", "SamplePackage"]
	if name in excluded:
		return false
	
	# 检查是否有Components目录
	var components_path = "%sPacks/%s/Components" % [COMPONENT_LIBRARY_BASE, name]
	return DirAccess.dir_exists_absolute(components_path)

## 创建Dock UI
func _create_dock_ui() -> void:
	_dock_scene = VBoxContainer.new()
	_dock_scene.name = "ComponentLibrary"
	
	# 标题和搜索
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "Component Library"
	title.add_theme_font_size_override("font_size", 16)
	header.add_child(title)
	
	_search_bar = LineEdit.new()
	_search_bar.placeholder_text = "Search components..."
	_search_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_bar.text_changed.connect(_on_search_changed)
	header.add_child(_search_bar)
	
	var refresh_btn = Button.new()
	refresh_btn.text = "🔄"
	refresh_btn.tooltip_text = "Refresh"
	refresh_btn.pressed.connect(_on_refresh)
	header.add_child(refresh_btn)
	
	_dock_scene.add_child(header)
	
	# 分类树
	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.hide_root = true
	_tree.item_selected.connect(_on_tree_item_selected)
	_tree.item_activated.connect(_on_tree_item_activated)
	_dock_scene.add_child(_tree)
	
	# 信息面板
	_info_panel = VBoxContainer.new()
	_info_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	var info_label = Label.new()
	info_label.text = "Select a component to view details"
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_panel.add_child(info_label)
	_dock_scene.add_child(_info_panel)
	
	# 添加到编辑器
	var dock = EditorDock.new()
	dock.DockLayout = DOCK_SLOT_RIGHT_BL
	dock.add_child(_dock_scene)
	add_dock(dock)
	
	# 填充树
	_populate_tree()

## 填充树结构
func _populate_tree() -> void:
	_tree.clear()
	var root = _tree.create_item()
	
	# Core分类
	var core_item = _tree.create_item(root)
	core_item.set_text(0, "🔧 Core (核心基础)")
	core_item.set_metadata(0, {"type": "category", "name": "Core"})
	_add_dependencies_to_tree(core_item)
	
	# Modules分类
	var modules_item = _tree.create_item(root)
	modules_item.set_text(0, "📦 Modules (功能模块)")
	modules_item.set_metadata(0, {"type": "category", "name": "Modules"})
	
	if _packs.has("Modules"):
		for pack in _packs["Modules"]:
			var pack_item = _tree.create_item(modules_item)
			var component_count = _count_components_in_pack(pack)
			pack_item.set_text(0, "%s (%d)" % [pack, component_count])
			pack_item.set_metadata(0, {"type": "pack", "name": pack})
			
			# 添加组件子项
			_add_components_to_tree(pack_item, pack)

## 添加依赖到树
func _add_dependencies_to_tree(parent: TreeItem) -> void:
	for config in DEPENDENCY_CONFIGS:
		var item = _tree.create_item(parent)
		item.set_text(0, config.get("name", ""))
		item.set_metadata(0, {
			"type": "component",
			"path": config.get("path", ""),
			"name": config.get("name", "")
		})

## 添加组件到树
func _add_components_to_tree(parent: TreeItem, pack: String) -> void:
	var components_path = "%sPacks/%s/Components" % [COMPONENT_LIBRARY_BASE, pack]
	var dir = DirAccess.open(components_path)
	if not dir:
		return
	
	var components: Array[String] = []
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with(".gd") and not file.ends_with(".uid"):
			components.append(file)
	
	components.sort()
	for comp in components:
		var item = _tree.create_item(parent)
		item.set_text(0, comp.get_basename())
		item.set_metadata(0, {
			"type": "component",
			"path": components_path + "/" + comp,
			"name": comp.get_basename(),
			"pack": pack
		})

## 统计Pack中的组件数量
func _count_components_in_pack(pack: String) -> int:
	var components_path = "%sPacks/%s/Components" % [COMPONENT_LIBRARY_BASE, pack]
	var dir = DirAccess.open(components_path)
	if not dir:
		return 0
	
	var count = 0
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with(".gd") and not file.ends_with(".uid"):
			count += 1
	return count

## 树项选中事件
func _on_tree_item_selected() -> void:
	var selected = _tree.get_selected()
	if not selected:
		return
	
	var metadata = selected.get_metadata(0)
	if not metadata:
		return
	
	_update_info_panel(metadata)

## 树项激活事件（双击）
func _on_tree_item_activated() -> void:
	var selected = _tree.get_selected()
	if not selected:
		return
	
	var metadata = selected.get_metadata(0)
	if metadata.get("type") == "component":
		_open_component_script(metadata.get("path", ""))
	elif metadata.get("type") == "pack":
		_open_demo_for_pack(metadata.get("name", ""))

## 更新信息面板
func _update_info_panel(metadata: Dictionary) -> void:
	# 清空面板
	for child in _info_panel.get_children():
		child.queue_free()
	
	var type = metadata.get("type", "")
	
	if type == "component":
		var name_label = Label.new()
		name_label.text = "Component: %s" % metadata.get("name", "Unknown")
		name_label.add_theme_font_size_override("font_size", 14)
		_info_panel.add_child(name_label)
		
		var path_label = Label.new()
		path_label.text = metadata.get("path", "")
		path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		path_label.add_theme_font_size_override("font_size", 10)
		_info_panel.add_child(path_label)
		
		var btn_container = HBoxContainer.new()
		
		var view_btn = Button.new()
		view_btn.text = "View Code"
		view_btn.pressed.connect(func(): _open_component_script(metadata.get("path", "")))
		btn_container.add_child(view_btn)
		
		if metadata.has("pack"):
			var demo_btn = Button.new()
			demo_btn.text = "Open Demo"
			demo_btn.pressed.connect(func(): _open_demo_for_pack(metadata.get("pack", "")))
			btn_container.add_child(demo_btn)
		
		_info_panel.add_child(btn_container)
	
	elif type == "pack":
		var name_label = Label.new()
		name_label.text = "Pack: %s" % metadata.get("name", "Unknown")
		name_label.add_theme_font_size_override("font_size", 14)
		_info_panel.add_child(name_label)
		
		var demo_btn = Button.new()
		demo_btn.text = "Open Demo"
		demo_btn.pressed.connect(func(): _open_demo_for_pack(metadata.get("name", "")))
		_info_panel.add_child(demo_btn)

## 打开组件脚本
func _open_component_script(path: String) -> void:
	if FileAccess.file_exists(path):
		var script = load(path)
		if script:
			get_editor_interface().edit_script(script)
			get_editor_interface().set_main_screen_editor("Script")

## 打开Pack的Demo场景
func _open_demo_for_pack(pack: String) -> void:
	var demo_path = "%sPacks/%s/Demo/%s_demo.tscn" % [COMPONENT_LIBRARY_BASE, pack, pack.to_lower()]
	if FileAccess.file_exists(demo_path):
		get_editor_interface().open_scene_from_path(demo_path)
	else:
		push_warning("[ComponentLibrary] Demo not found: %s" % demo_path)

## 搜索变化事件
func _on_search_changed(new_text: String) -> void:
	_search_text = new_text.to_lower()
	_filter_tree()

## 过滤树
func _filter_tree() -> void:
	if _search_text.is_empty():
		_show_all_items()
	else:
		_hide_non_matching_items(_tree.get_root())

func _show_all_items() -> void:
	var item = _tree.get_root()
	while item:
		item.visible = true
		item = _get_next_item(item)

func _hide_non_matching_items(item: TreeItem) -> bool:
	if not item:
		return false
	
	var has_matching_child = false
	var child = item.get_first_child()
	while child:
		if _hide_non_matching_items(child):
			has_matching_child = true
		child = child.get_next()
	
	var text = item.get_text(0).to_lower()
	var matches = text.contains(_search_text)
	
	item.visible = matches or has_matching_child
	return item.visible

func _get_next_item(item: TreeItem) -> TreeItem:
	if item.get_child_count() > 0:
		return item.get_first_child()
	
	while item:
		if item.get_next():
			return item.get_next()
		item = item.get_parent()
	
	return null

## 刷新
func _on_refresh() -> void:
	_scan_component_library()
	_populate_tree()
	print("[ComponentLibrary] Refreshed")

## Demo浏览器
func _on_open_demo_browser() -> void:
	var dlg = ConfirmationDialog.new()
	dlg.title = "Component Library - Demo Browser"
	dlg.size = Vector2i(600, 400)
	
	var grid = GridContainer.new()
	grid.columns = 3
	
	if _packs.has("Modules"):
		for pack in _packs["Modules"]:
			var card = VBoxContainer.new()
			
			# 缩略图
			var thumb = TextureRect.new()
			var preview_path = "%sPacks/%s/Demo/preview.png" % [COMPONENT_LIBRARY_BASE, pack]
			if ResourceLoader.exists(preview_path):
				thumb.texture = load(preview_path)
			else:
				thumb.custom_minimum_size = Vector2(100, 100)
			card.add_child(thumb)
			
			# 按钮
			var btn = Button.new()
			btn.text = pack
			btn.pressed.connect(func(): 
				_open_demo_for_pack(pack)
				dlg.hide()
			)
			card.add_child(btn)
			
			grid.add_child(card)
	
	dlg.add_child(grid)
	get_editor_interface().get_base_control().add_child(dlg)
	dlg.popup_centered()

## 创建新Pack
func _on_new_pack() -> void:
	var dlg = AcceptDialog.new()
	dlg.title = "Create New Pack"
	
	var vbox = VBoxContainer.new()
	vbox.add_child(Label.new())
	vbox.get_child(0).text = "Pack Name:"
	
	var name_edit = LineEdit.new()
	name_edit.placeholder_text = "MyNewPack"
	vbox.add_child(name_edit)
	
	var category_label = Label.new()
	category_label.text = "Category:"
	vbox.add_child(category_label)
	
	var category_option = OptionButton.new()
	category_option.add_item("Modules")
	vbox.add_child(category_option)
	
	dlg.add_child(vbox)
	
	dlg.confirmed.connect(func():
		var pack_name = name_edit.text.strip_edges()
		if pack_name:
			_create_pack_structure(pack_name)
			dlg.hide()
	)
	
	get_editor_interface().get_base_control().add_child(dlg)
	dlg.popup_centered()

## 创建Pack结构
func _create_pack_structure(name: String) -> void:
	var base_path = "%sPacks/%s" % [COMPONENT_LIBRARY_BASE, name]
	
	# 创建目录
	DirAccess.make_dir_recursive_absolute(base_path + "/Components")
	DirAccess.make_dir_recursive_absolute(base_path + "/Demo")
	DirAccess.make_dir_recursive_absolute(base_path + "/Templates")
	
	# 创建README
	var readme_content = "# %s Pack\n\n## Components\n\nList your components here.\n\n## Usage\n\nProvide usage examples.\n" % name
	var readme_file = FileAccess.open(base_path + "/README.md", FileAccess.WRITE)
	if readme_file:
		readme_file.store_string(readme_content)
		readme_file.close()
	
	# 创建Demo脚本
	var demo_script = "extends PackDemo\n\nfunc _ready():\n\tpack_name = \"%s\"\n\tsuper._ready()\n\nfunc _populate_demo():\n\tpass\n" % name
	var demo_file = FileAccess.open(base_path + "/Demo/" + name.to_lower() + "_demo.gd", FileAccess.WRITE)
	if demo_file:
		demo_file.store_string(demo_script)
		demo_file.close()
	
	print("[ComponentLibrary] Created pack: %s" % name)
	_on_refresh()

## 加载图标
func _load_icon() -> Texture2D:
	var icon = load("res://icon.svg")
	if icon is Texture2D:
		return icon
	return null
