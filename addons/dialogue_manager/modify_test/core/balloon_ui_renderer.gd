class_name BalloonUIRenderer
extends RefCounted
## ════════════════════════════════════════════════════════════════
## 气球 UI 渲染管理器
## ════════════════════════════════════════════════════════════════
## 负责气球组件的 UI 渲染和布局管理

## 信号
signal direction_changed(direction: String)
signal layout_updated()

## 配置
var balloon_container: Control
var character_label: RichTextLabel
var dialogue_label: DialogueLabel
var responses_menu: DialogueResponsesMenu
var portrait: TextureRect

## 布局配置
var default_direction: String = "left"
var current_direction: String = "left"

## 角色颜色配置
var character_colors: Dictionary = {
	"旁白": Color(0.7, 0.7, 0.7, 1.0),
	"Narrator": Color(0.7, 0.7, 0.7, 1.0),
}

## 初始化
func setup(container: Control, char_label: RichTextLabel, 
		dlg_label: DialogueLabel, resp_menu: DialogueResponsesMenu,
		portrait_rect: TextureRect) -> void:
	balloon_container = container
	character_label = char_label
	dialogue_label = dlg_label
	responses_menu = resp_menu
	portrait = portrait_rect

## 更新角色显示
func update_character(character: String) -> void:
	if character_label == null:
		return
	
	character_label.visible = not character.is_empty()
	character_label.text = tr(character, "dialogue")
	
	_update_character_color(character)
	_update_direction(character)

## 更新角色颜色
func _update_character_color(character: String) -> void:
	if character_label == null:
		return
	
	var color: Color = character_colors.get(character, Color.WHITE)
	character_label.modulate = color

## 更新气球方向
func _update_direction(character: String) -> void:
	var new_direction := _determine_direction(character)
	
	if new_direction != current_direction:
		current_direction = new_direction
		_apply_direction(new_direction)
		direction_changed.emit(new_direction)

## 确定方向
func _determine_direction(character: String) -> String:
	if character.is_empty() or character == "旁白" or character == "Narrator":
		return default_direction
	
	var char_lower := character.to_lower()
	if char_lower in ["player", "玩家", "主角"]:
		return "right"
	
	return "left"

## 应用方向
func _apply_direction(direction: String) -> void:
	if balloon_container == null:
		return
	
	var h_box: HBoxContainer = _find_hbox_container(balloon_container)
	if h_box == null:
		return
	
	var children := h_box.get_children()
	if children.size() < 2:
		return
	
	var portrait_container: Control = null
	var content_container: Control = null
	
	for child in children:
		if child is VBoxContainer:
			content_container = child
		elif child is Control and child != content_container:
			portrait_container = child
	
	if portrait_container == null or content_container == null:
		return
	
	match direction:
		"left":
			if portrait_container.get_index() != 0:
				h_box.move_child(portrait_container, 0)
		"right":
			if portrait_container.get_index() != children.size() - 1:
				h_box.move_child(portrait_container, children.size() - 1)
	
	layout_updated.emit()

## 查找 HBoxContainer
func _find_hbox_container(node: Node) -> HBoxContainer:
	if node is HBoxContainer:
		return node
	
	for child in node.get_children():
		var result := _find_hbox_container(child)
		if result != null:
			return result
	
	return null

## 更新对话文本
func update_dialogue_text(text: String) -> void:
	if dialogue_label == null:
		return
	
	dialogue_label.text = text

## 显示/隐藏响应菜单
func show_responses(responses: Array) -> void:
	if responses_menu == null:
		return
	
	responses_menu.responses = responses
	responses_menu.show()
	responses_menu.configure_focus()

func hide_responses() -> void:
	if responses_menu == null:
		return
	
	responses_menu.hide()

## 更新头像
func update_portrait(texture: Texture2D) -> void:
	if portrait == null:
		return
	
	portrait.texture = texture
	portrait.visible = texture != null

## 设置角色颜色
func set_character_color(character: String, color: Color) -> void:
	character_colors[character] = color

## 获取当前方向
func get_current_direction() -> String:
	return current_direction

## 重置布局
func reset_layout() -> void:
	current_direction = default_direction
	_apply_direction(default_direction)
