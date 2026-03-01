@tool
extends EditorPlugin

# just register a few standalone dependency scripts; all other components will be discovered automatically
const DEPENDENCY_CONFIGS := [
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
		"name": "LocalTimeDomainDependency",
		"base": "Node",
		"path": "res://ComponentLibrary/Dependencies/local_time_domain.gd",
	},
]

# helper to convert snake_case filenames into PascalCase type names
func _snake_to_pascal(s: String) -> String:
	var parts = s.split("_")
	for i in range(parts.size()):
		parts[i] = parts[i].capitalize()
	return parts.join("")

var _registered_types: Array[String] = []
# list of pack names (filled at runtime)
var _packs: Array[String] = []

func _load_packs() -> void:
	_packs.clear()
	var dir = DirAccess.open("res://ComponentLibrary/Packs")
	if dir:
		while true:
			var name = dir.get_next()
			if name == "":
				break
			if dir.current_is_dir():
				_packs.append(name)
	# sort for consistent order
	_packs.sort()

func _enter_tree() -> void:
	var icon := _load_icon()
	# register dependency scripts first
	for config in DEPENDENCY_CONFIGS:
		_register_config(config, icon)

	# initial pack scan
	_load_packs()
	# register components within each pack
	for pack in _packs:
		var comp_path = "res://ComponentLibrary/Packs/%s/Components" % pack
		var comp_dir = DirAccess.open(comp_path)
		if comp_dir:
			_scan_and_register(comp_dir, comp_path, icon)

	# add demo menu
	add_tool_menu_item("ComponentLibrary/Open Demo", Callable(self, "_on_open_demo"))
	# utility actions
	add_tool_menu_item("ComponentLibrary/New Pack", Callable(self, "_on_new_pack"))
	add_tool_menu_item("ComponentLibrary/New Component", Callable(self, "_on_new_component"))

func _exit_tree() -> void:
	for type_name in _registered_types:
		remove_custom_type(type_name)
	_registered_types.clear()
	remove_tool_menu_item("ComponentLibrary/Open Demo")
	remove_tool_menu_item("ComponentLibrary/New Pack")
	remove_tool_menu_item("ComponentLibrary/New Component")

# helpers for dynamic registration
func _register_config(config: Dictionary, icon: Texture2D) -> void:
	var script_path:String = config.get("path", "")
	var script = load(script_path)
	if script == null:
		push_warning("[component_library_share] script missing: %s" % script_path)
		return
	add_custom_type(config.get("name",""), config.get("base","Node"), script, icon)
	_registered_types.append(config.get("name",""))

func _scan_and_register(dir:DirAccess, base_path:String, icon:Texture2D) -> void:
	# recursively walk, register .gd files as Node types
	while true:
		var name = dir.get_next()
		if name == "":
			break
		var full = base_path + "/" + name
		if dir.current_is_dir():
			var sub = DirAccess.open(full)
			if sub:
				_scan_and_register(sub, full, icon)
		elif name.to_lower().ends_with(".gd"):
			var script = load(full)
			if script:
				var type_name = script.get_class() if script.has_method("get_class") and script.get_class() != "" else _snake_to_pascal(name.get_basename())
				add_custom_type(type_name, "Node", script, icon)
				_registered_types.append(type_name)
			else:
				push_warning("[component_library_share] failed to load %s" % full)

func _on_open_demo():
	# refresh pack list each time
	_load_packs()
	# custom grid showing thumbnails if available
	var dlg = get_node_or_null("/root/ComponentLibraryDemoDialog")
	if dlg == null:
		dlg = ConfirmationDialog.new()
		dlg.name = "ComponentLibraryDemoDialog"
		dlg.title = "Select Pack Demo"
		#dlg.popup_centered_minsize() not available, will call popup() later
		var grid = GridContainer.new()
		grid.columns = 3
		dlg.add_child(grid)
		for p in _packs:
			var h = HBoxContainer.new()
			var thumb = TextureRect.new()
			var path = "res://ComponentLibrary/Packs/%s/Demo/preview.png" % p
			if ResourceLoader.exists(path):
				thumb.texture = load(path)
			thumb.custom_minimum_size = Vector2(64,64)
			h.add_child(thumb)
			var btn = Button.new()
			btn.text = p
			var cb = Callable(self, "_open_pack_demo").bind(p, dlg)
			btn.pressed.connect(cb)
			h.add_child(btn)
			grid.add_child(h)
		get_editor_interface().get_editor_main_screen().add_child(dlg)
	dlg.popup()

func _open_pack_demo(pack:String, dlg:ConfirmationDialog) -> void:
	dlg.hide()
	var path = "res://ComponentLibrary/Packs/%s/Demo/%s_demo.tscn" % [pack, pack.to_lower()]
	if FileAccess.file_exists(path):
		get_editor_interface().open_scene_from_path(path)
	else:
		push_error("Demo scene not found: %s" % path)

func _on_new_pack() -> void:
	var dlg = AcceptDialog.new()
	dlg.title = "New Pack"
	var line = LineEdit.new()
	line.placeholder_text = "Enter pack name"
	dlg.add_child(line)
	var cb2 = Callable(self, "_create_pack").bind(line, dlg)
	dlg.confirmed.connect(cb2)
	get_editor_interface().get_editor_main_screen().add_child(dlg)
	dlg.popup_centered()

func _create_pack(line:LineEdit, dlg:AcceptDialog) -> void:
	dlg.hide()
	var name = line.text.strip_edges()
	if name == "":
		push_error("Pack name cannot be empty")
		return
	var basepath = "res://ComponentLibrary/Packs/%s" % name
	var dir = DirAccess.open("res://ComponentLibrary/Packs")
	if dir and not dir.dir_exists(name):
		dir.make_dir(name)
		dir.make_dir(name + "/Components")
		dir.make_dir(name + "/Demo")
		dir.make_dir(name + "/Templates")
		# keep pack list current
		if not _packs.has(name):
			_packs.append(name)
		# create default demo scene
		var demo_scene = PackedScene.new()
		var root = Node.new()
		root.name = name + "Demo"
		root.set_script(load("res://ComponentLibrary/Shared/pack_demo.gd"))
		root.set("pack_name", name)
		demo_scene.pack(root)
		ResourceSaver.save(basepath + "/Demo/" + name.to_lower() + "_demo.tscn", demo_scene)
		# generate empty thumbnail
		var thumb_path = basepath + "/Demo/preview.png"
		var img = Image.new()
		img.create(128,128,false,Image.FORMAT_RGBA8)
		img.fill(Color(0,0,0,0))
		var tex = ImageTexture.new()
		tex.create_from_image(img)
		ResourceSaver.save(thumb_path, tex)
		# open newly created demo
		get_editor_interface().open_scene_from_path(basepath + "/Demo/" + name.to_lower() + "_demo.tscn")
	else:
		push_error("Pack '%s' already exists or packs directory missing" % name)

func _on_new_component() -> void:
	# ask for existing pack and component name
	_load_packs()
	var dlg = AcceptDialog.new()
	dlg.title = "New Component"
	var vbox = VBoxContainer.new()
	var pack_label = Label.new(); pack_label.text = "Pack:"
	var pack_box = OptionButton.new()
	for p in _packs:
		pack_box.add_item(p)
	var comp_label = Label.new(); comp_label.text = "Component Name (snake_case):"
	var comp_edit = LineEdit.new()
	vbox.add_child(pack_label); vbox.add_child(pack_box)
	vbox.add_child(comp_label); vbox.add_child(comp_edit)
	dlg.add_child(vbox)
	var cb3 = Callable(self, "_create_component").bind(pack_box, comp_edit, dlg)
	dlg.confirmed.connect(cb3)
	get_editor_interface().get_editor_main_screen().add_child(dlg)
	dlg.popup_centered()

func _create_component(pack_box:OptionButton, comp_edit:LineEdit, dlg:AcceptDialog) -> void:
	dlg.hide()
	var pack = pack_box.get_item_text(pack_box.get_selected()) if pack_box.get_selected() >= 0 else ""
	var name = comp_edit.text.strip_edges()
	if pack == "" or name == "":
		push_error("Pack and component name must not be empty")
		return
	var dir = DirAccess.open("res://ComponentLibrary/Packs/%s/Components" % pack)
	if not dir:
		push_error("Pack '%s' does not exist" % pack)
		return
	var filename = name + ".gd"
	if dir.file_exists(filename):
		push_error("Component already exists")
		return
	# create stub script
	var script = GDScript.new()
	script.source_code = "extends Node\n\nclass_name %s" % _snake_to_pascal(name)
	var result = script.reload()
	dir.remove_file(filename) # ensure not leftover
	# write new script file
	var targetPath = dir.get_current_dir() + "/" + filename
	var fs = FileAccess.open(targetPath, FileAccess.WRITE)
	fs.store_string(script.source_code)
	fs.close()
	# open script in editor
	get_editor_interface().open_script(load("res://ComponentLibrary/Packs/%s/Components/%s" % [pack, filename]))


func _load_icon() -> Texture2D:
	var maybe_icon := load("res://icon.svg")
	if maybe_icon is Texture2D:
		return maybe_icon
	return null
