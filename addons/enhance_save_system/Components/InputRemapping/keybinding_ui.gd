class_name KeybindingUI
extends Control
## 按键绑定 UI 主界面（场景版）
##
## 场景结构（keybinding_ui.tscn）：
##   Control (KeybindingUI)
##   └── Layout (VBoxContainer)
##       ├── Header (HBoxContainer)
##       │   ├── TitleLabel   (Label)
##       │   └── ResetButton  (Button) [unique_name]
##       ├── HSeparator
##       └── ScrollContainer
##           └── RowsContainer (VBoxContainer) [unique_name]
##
## 用法：
##   实例化场景后设置 label_map / action_filter，
##   _ready 自动读 InputMap 生成每一行。
##
##   $KeybindingUI.label_map = {
##       "move_left" : "向左移动",
##       "jump"      : "跳跃",
##   }

## action_name → 本地化显示字符串
@export var label_map: Dictionary = {}

## 若非空，只显示这些 action；为空则显示全部用户 action
@export var action_filter: PackedStringArray = []

## 行的场景资源（可在 Inspector 中替换为自定义美化场景）
@export var row_scene: PackedScene = preload("res://addons/enhance_save_system/Components/InputRemapping/keybinding_row.tscn")

# ──────────────────────────────────────────────
# 场景节点引用（通过 unique name % 绑定）
# ──────────────────────────────────────────────
@onready var _rows_container: VBoxContainer = %RowsContainer
@onready var _reset_btn: Button             = %ResetButton

var _capture_dialog: KeyCaptureDialog
var _rows: Array[KeybindingRow] = []

# ──────────────────────────────────────────────
# 生命周期
# ──────────────────────────────────────────────

func _ready() -> void:
	_reset_btn.pressed.connect(_on_reset_pressed)

	# 共享弹窗：挂到街景根避免被 ScrollContainer 截断
	_capture_dialog = KeyCaptureDialog.new()
	add_child(_capture_dialog)

	_build_rows()

	var km := _get_module()
	if km:
		km.bindings_changed.connect(_on_bindings_changed)

# ──────────────────────────────────────────────
# 行构建
# ──────────────────────────────────────────────

func _build_rows() -> void:
	for child in _rows_container.get_children():
		child.queue_free()
	_rows.clear()

	if row_scene == null:
		push_error("KeybindingUI: row_scene 未设置")
		return

	for action in _get_actions_to_show():
		var row: KeybindingRow = row_scene.instantiate()
		_rows_container.add_child(row)
		row.setup(action, label_map.get(action, ""), _capture_dialog)
		row.binding_changed.connect(_on_row_binding_changed)
		_rows.append(row)

func _get_actions_to_show() -> PackedStringArray:
	if action_filter.size() > 0:
		return action_filter
	var km := _get_module()
	if km:
		return km.get_user_actions()
	# 备用：直接读 InputMap（过滤 ui_ 前缀）
	var result: PackedStringArray = []
	for a in InputMap.get_actions():
		if not a.begins_with("ui_"):
			result.append(a)
	return result

# ──────────────────────────────────────────────
# 刷新所有行显示
# ──────────────────────────────────────────────

func refresh_all() -> void:
	for row in _rows:
		if is_instance_valid(row):
			row.refresh()

# ──────────────────────────────────────────────
# 信号回调
# ──────────────────────────────────────────────

func _on_reset_pressed() -> void:
	var km := _get_module()
	if km:
		km.reset_to_defaults()
		var ss := _get_save_system()
		if ss and ss.has_method("save_global"):
			ss.save_global()
	else:
		InputMap.load_from_project_settings()
	refresh_all()

func _on_bindings_changed() -> void:
	refresh_all()

func _on_row_binding_changed(_action: String, _ev: InputEvent) -> void:
	pass  # 可在子类中扩展

# ──────────────────────────────────────────────
# 内部辅助
# ──────────────────────────────────────────────

static func _get_module() -> KeybindingModule:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	var ss := tree.root.get_node_or_null("SaveSystem")
	if ss and ss.has_method("get_module"):
		return ss.get_module("keybindings") as KeybindingModule
	return null

static func _get_save_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	return tree.root.get_node_or_null("SaveSystem")
