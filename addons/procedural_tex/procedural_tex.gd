## 程序纹理烘焙工具，可以将shader导出为png贴图[br]
## [br]
## png导出路径为[member save_path]，在检查器界面有一个"Save png again!"按钮，无需运行此场景，点击即可保存png图片[br]
@tool
class_name ProceduralTex
extends SubViewport

## png导出路径
@export var save_path = "res://addons/procedural_tex/outputs/output.png"

## 程序纹理shader
@export var shader: Shader = null

## 预载纹理，如果为空，则会新建一个和[SubViewport]尺寸相同的空白贴图
@export var base_tex: Texture2D = null

## 在检查器界面有一个"Save png again!"按钮，无需运行次场景，点击即可保存png图片
@export_tool_button("Save png again!") var save_png_again := _init_sprite

## 临时创建的精灵图
var _sprite: Sprite2D = null

## 检测是否已经成功保存，防止重复保存
var _saved: bool = false

func _ready() -> void:
	_init_sprite()

func _process(_dt: float) -> void:
	_save_png()

## 重新创建临时的精灵图[member _sprite]，并且重置保存标识[member _saved]
func _init_sprite() -> void:
	if _sprite:
		_sprite.queue_free()
		_sprite = null
	_sprite = Sprite2D.new()
	if base_tex:
		_sprite.texture = base_tex
		size = base_tex.get_size()
	else:
		var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.0, 0.0, 0.0, 0.0))
		_sprite.texture = ImageTexture.create_from_image(img)
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_sprite.material = mat
	add_child(_sprite)
	_sprite.position = size * 0.5
	_saved = false

## 保存png图片[br]
## [param force]：是否无视重置保存标识[member _saved]强制保存一次
func _save_png(force := false) -> void:
	if not force and _saved:
		return
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	var img = get_texture().get_image()
	for j in img.get_height():
		for i in img.get_width():
			var c = img.get_pixel(i, j)
			if c.a > 0:
				c.r /= c.a
				c.g /= c.a
				c.b /= c.a
			img.set_pixel(i, j, c)
	img.save_png(save_path)
	_saved = true
	var fs := EditorInterface.get_resource_filesystem()
	if not fs.is_scanning():
		fs.scan()
	print("save png: ", save_path)
