@tool
class_name LiHui
extends Resource
## 立绘资源
## 使用 GradientTexture2D 模拟不同表情

@export var character_name: String = ""
@export var sprites: Dictionary[String, Texture2D] = {}

## 默认表情键名（进入场景时显示的初始表情）
@export var default_expression: String = "ax"
## 默认朝向（"left" 或 "right"）
@export_enum("left", "right") var default_direction: String = "left"
## 角色专属颜色（用于历史记录、角色名标签等）
@export var character_color: Color = Color.WHITE

func _init() -> void:
	character_name = "Default"

## 检查指定表情键名是否存在
func has_expression(key: String) -> bool:
	return sprites.has(key)

## 获取所有表情键名列表
func get_expression_keys() -> Array[String]:
	var keys: Array[String] = []
	for k in sprites.keys():
		keys.append(k)
	return keys

func create_default_sprites() -> void:
	sprites.clear()
	
	var expressions := ["ax", "ex", "hp", "sd", "sp", "an"]
	var colors := [
		Color(0.4, 0.6, 0.9),  # ax - 普通(蓝色)
		Color(0.9, 0.9, 0.4),  # ex - 开心(黄色)
		Color(0.9, 0.5, 0.7),  # hp - 高兴(粉色)
		Color(0.5, 0.5, 0.7),  # sd - 悲伤(灰蓝)
		Color(0.9, 0.6, 0.3),  # sp - 惊讶(橙色)
		Color(0.9, 0.3, 0.3),  # an - 生气(红色)
	]
	
	for i in expressions.size():
		var gradient := Gradient.new()
		gradient.add_point(0.0, colors[i].lightened(0.3))
		gradient.add_point(0.5, colors[i])
		gradient.add_point(1.0, colors[i].darkened(0.3))
		
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 256
		texture.height = 512
		
		sprites[expressions[i]] = texture

static func create_character(name: String, color: Color) -> LiHui:
	var resource := LiHui.new()
	resource.character_name = name
	
	var expressions := ["ax", "ex", "hp", "sd", "sp", "an"]
	var modifiers := [0.0, 0.2, 0.3, -0.2, 0.4, -0.3]
	
	for i in expressions.size():
		var gradient := Gradient.new()
		var base_color := color
		var modified_color := color
		
		if modifiers[i] > 0:
			modified_color = color.lightened(modifiers[i])
		elif modifiers[i] < 0:
			modified_color = color.darkened(-modifiers[i])
		
		gradient.add_point(0.0, modified_color.lightened(0.2))
		gradient.add_point(0.3, modified_color)
		gradient.add_point(0.7, modified_color.darkened(0.1))
		gradient.add_point(1.0, modified_color.darkened(0.3))
		
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 256
		texture.height = 512
		
		resource.sprites[expressions[i]] = texture
	
	return resource
