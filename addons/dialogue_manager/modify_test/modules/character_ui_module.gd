class_name CharacterUIModule
extends BalloonModule
## ════════════════════════════════════════════════════════════════
## CharacterUIModule — 角色 UI 模块
## ════════════════════════════════════════════════════════════════
##
## 持有 CharacterManager 和 BalloonUIRenderer，
## 在每行对话时更新角色名称、颜色、头像、气球方向等 UI。
## ════════════════════════════════════════════════════════════════

@export_group("UI 设置")
## 气球方向：left/right/auto（auto 时从 CharacterManager 读取）
@export_enum("left","right","auto") var balloon_direction: String = "auto"

## CharacterManager 引用（由场景配置）
var character_manager: CharacterManager

## BalloonUIRenderer 引用（由场景配置）
var ui_renderer: BalloonUIRenderer

## 角色名标签节点引用（由场景配置）
var character_label: RichTextLabel

## 头像纹理节点引用（由场景配置）
var portrait_texture: TextureRect

## 头像背景纹理节点引用（由场景配置）
var head_texture: TextureRect

## 名称背景纹理节点引用（由场景配置）
var name_texture: TextureRect

## 背景纹理节点引用（由场景配置）
var bg_texture: TextureRect

# ════════════════════════════════════════════════════════════════
# BalloonModule 接口
# ════════════════════════════════════════════════════════════════

func get_module_name() -> String:
	return "character_ui"

func on_dialogue_line_changed(line: DialogueLine) -> void:
	var character := line.character
	
	# 更新角色名标签
	_update_character_label(character)
	
	# 更新头像和背景纹理
	_update_portrait(character)
	
	# 更新气球方向
	_update_direction(character)
	
	# 通知 CharacterManager 当前角色
	if is_instance_valid(character_manager) and not character.is_empty():
		character_manager.set_current_character(character)

func on_dialogue_ended() -> void:
	# 隐藏角色名
	if is_instance_valid(character_label):
		character_label.visible = false

# ════════════════════════════════════════════════════════════════
# 公共 API
# ════════════════════════════════════════════════════════════════

## 注册角色配置（代理到 CharacterManager）
func register_character(name: String, config: Dictionary) -> void:
	if is_instance_valid(character_manager):
		character_manager.register_character(name, config)

## 设置当前表情（代理到 CharacterManager）
func set_expression(expression: String) -> void:
	if is_instance_valid(character_manager):
		character_manager.set_expression(expression)
	_update_portrait_expression(expression)

# ════════════════════════════════════════════════════════════════
# 内部方法
# ════════════════════════════════════════════════════════════════

func _update_character_label(character: String) -> void:
	if not is_instance_valid(character_label):
		return
	
	character_label.visible = not character.is_empty()
	if character.is_empty():
		return
	
	character_label.text = tr(character, "dialogue")
	
	# 应用角色颜色
	if is_instance_valid(character_manager):
		var color := character_manager.get_color(character)
		character_label.modulate = color

func _update_portrait(character: String) -> void:
	var portrait_container := portrait_texture.get_parent() if is_instance_valid(portrait_texture) else null
	if character.is_empty() or not is_instance_valid(character_manager):
		if is_instance_valid(portrait_texture):
			portrait_texture.texture = null
		if portrait_container is CanvasItem:
			portrait_container.visible = false
		return
	
	# 头像纹理
	var expression := character_manager.get_current_expression()
	var texture := character_manager.get_texture(character, expression)
	if is_instance_valid(portrait_texture):
		portrait_texture.texture = texture
	
	# 背景纹理
	if is_instance_valid(bg_texture):
		bg_texture.texture = character_manager.get_bg_texture(character, "BG")
	if is_instance_valid(name_texture):
		name_texture.texture = character_manager.get_bg_texture(character, "NAME")
		var name_scale := character_manager.get_name_scale(character)
		name_texture.scale = name_scale
		var name_offset := character_manager.get_name_offset(character)
		name_texture.position = name_offset
	if is_instance_valid(head_texture):
		head_texture.texture = character_manager.get_bg_texture(character, "HEAD")
		var head_offset := character_manager.get_head_offset(character)
		head_texture.position = head_offset
	
	if portrait_container is CanvasItem:
		portrait_container.visible = (
			texture != null
			or character_manager.get_bg_texture(character, "BG") != null
			or character_manager.get_bg_texture(character, "NAME") != null
			or character_manager.get_bg_texture(character, "HEAD") != null
		)

func _update_portrait_expression(expression: String) -> void:
	if not is_instance_valid(character_manager) or not is_instance_valid(portrait_texture):
		return
	var current_char := character_manager.get_current_character()
	if current_char.is_empty():
		return
	var texture := character_manager.get_texture(current_char, expression)
	portrait_texture.texture = texture

func _update_direction(character: String) -> void:
	var target_direction := balloon_direction
	
	if balloon_direction == "auto" and is_instance_valid(character_manager):
		target_direction = character_manager.get_direction(character)
	
	if is_instance_valid(ui_renderer):
		ui_renderer.default_direction = target_direction
		ui_renderer.update_character(character)
