## 程序纹理烘焙工具，可以将shader材质导出为png贴图
## 
## 特性：
## - 实时预览：编辑器中持续更新显示最新效果
## - 材质导出：导出完整ShaderMaterial，保留所有参数设置
## - 参数可调：支持调整shader参数并实时预览
## - 快速保存：无需运行场景，检查器一键保存
## - Alpha预乘修正：自动处理透明度，准确导出
@tool
class_name ProceduralTex
extends SubViewport

## png导出路径
@export_file("*.png") var save_path = "res://addons/procedural_tex/outputs/output.png"

## 程序纹理材质（使用ShaderMaterial可以调整参数）
@export var material: ShaderMaterial = null:
	set(value):
		material = value
		_init_sprite()

## 预载纹理，如果为空，则会新建一个和[SubViewport]尺寸相同的空白贴图
@export var base_tex: Texture2D = null:
	set(value):
		base_tex = value
		_init_sprite()

@export_group("实时预览")
## 启用实时更新（每帧重新渲染）
@export var real_time_preview: bool = true

## 预览更新频率（帧/秒），0表示每帧更新
@export_range(0, 60, 1) var preview_fps: int = 30

@export_group("保存操作")
## 在检查器界面点击此按钮保存png图片
@export_tool_button("💾 Save PNG", "Save") var save_png_button := _save_png_manual

## 临时创建的精灵图
var _sprite: Sprite2D = null

## 检测是否已经成功保存，防止重复保存
var _saved: bool = false

## 上次保存的时间
var _last_save_time: float = 0.0

## 上次预览更新时间
var _last_preview_time: float = 0.0

func _ready() -> void:
	_init_sprite()

func _process(delta: float) -> void:
	# 实时预览模式：持续更新渲染
	if real_time_preview and material:
		var current_time := Time.get_ticks_msec() / 1000.0
		var frame_interval := 1.0 / preview_fps if preview_fps > 0 else 0.0
		
		if frame_interval == 0.0 or (current_time - _last_preview_time) >= frame_interval:
			render_target_update_mode = SubViewport.UPDATE_ONCE
			_last_preview_time = current_time

## 手动保存PNG（通过检查器按钮触发）
func _save_png_manual() -> void:
	_save_png(true)

## 重新创建临时的精灵图[member _sprite]，并且重置保存标识[member _saved]
func _init_sprite() -> void:
	if _sprite:
		_sprite.queue_free()
		_sprite = null
	
	if not material:
		return
	
	_sprite = Sprite2D.new()
	
	if base_tex:
		_sprite.texture = base_tex
		size = base_tex.get_size()
	else:
		var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.0, 0.0, 0.0, 0.0))
		_sprite.texture = ImageTexture.create_from_image(img)
	
	_sprite.material = material
	add_child(_sprite)
	_sprite.position = size * 0.5
	_saved = false
	
	# 启用实时渲染
	if real_time_preview:
		render_target_update_mode = SubViewport.UPDATE_ALWAYS
	else:
		render_target_update_mode = SubViewport.UPDATE_ONCE

## 保存png图片
## [param force]：是否无视保存标识[member _saved]强制保存一次
func _save_png(force := false) -> void:
	if not force and _saved:
		return
	
	if not material:
		push_warning("ProceduralTex: No material assigned, cannot save PNG")
		return
	
	# 确保Sprite已创建
	if not _sprite:
		_init_sprite()
		if not _sprite:
			return
	
	# 触发渲染
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	
	# 获取渲染结果
	var img = get_texture().get_image()
	
	# Alpha预乘修正：Godot渲染结果是预乘Alpha的，需要还原
	for j in img.get_height():
		for i in img.get_width():
			var c = img.get_pixel(i, j)
			if c.a > 0:
				c.r /= c.a
				c.g /= c.a
				c.b /= c.a
			img.set_pixel(i, j, c)
	
	# 确保目录存在
	var dir_path := save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	
	# 保存文件
	var err := img.save_png(save_path)
	if err != OK:
		push_error("ProceduralTex: Failed to save PNG to %s (Error: %d)" % [save_path, err])
		return
	
	_saved = true
	_last_save_time = Time.get_ticks_msec() / 1000.0
	
	# 刷新文件系统
	var fs := EditorInterface.get_resource_filesystem()
	if fs and not fs.is_scanning():
		fs.scan()
	
	print("✓ ProceduralTex: Saved PNG to %s (%dx%d)" % [save_path, img.get_width(), img.get_height()])
	
	# 恢复实时渲染模式
	if real_time_preview:
		render_target_update_mode = SubViewport.UPDATE_ALWAYS
