class_name TransitionManager
extends CanvasLayer
## ════════════════════════════════════════════════════════════════
## TransitionManager — 过渡动画全局单例
## ════════════════════════════════════════════════════════════════
##
## 作为 AutoLoad 单例使用，统一管理：
##   • 异步场景加载（ResourceLoader 线程加载）
##   • 溶解/淡入淡出过渡动画
##   • 加载进度条显示
##
## 使用方式（AutoLoad 名称建议设为 "TransitionManager"）：
##   TransitionManager.change_scene("res://scenes/game.tscn")
##   TransitionManager.change_scene("res://scenes/game.tscn", 3)  # 指定花纹编号
##
## 信号：
##   scene_changed(new_scene)   场景切换完成后发出
## ════════════════════════════════════════════════════════════════

## 场景切换完成信号（新场景实例）
signal scene_changed(new_scene: Node)
## 加载进度更新信号（0.0 ~ 1.0）
signal load_progress_changed(progress: float)

# ════════════════════════════════════════════════════════════════
# 配置
# ════════════════════════════════════════════════════════════════

## Shader 花纹贴图目录（相对 res://）
const SHADER_PATTERNS: String = "res://ComponentLibrary/Modules/UI/Templates/Transition/transition_pattern/"
## 花纹数量（1 ~ PATTERN_COUNT，超出则使用纯淡入淡出）
const PATTERN_COUNT: int = 8

## 默认是否显示进度条
@export var show_progress_bar_by_default: bool = true
## 进度条淡入淡出时长（秒）
@export_range(0.1, 1.0, 0.05) var progress_bar_fade_duration: float = 0.3

# ════════════════════════════════════════════════════════════════
# 节点引用
# ════════════════════════════════════════════════════════════════

@onready var _color_rect: ColorRect = $ColorRect
@onready var _animation_player: AnimationPlayer = $ColorRect/AnimationPlayer
@onready var _progress_bar: ProgressBar = $ProgressBar

# ════════════════════════════════════════════════════════════════
# 内部状态
# ════════════════════════════════════════════════════════════════

## 花纹贴图缓存
static var _png_cache: Dictionary = {}

## 当前加载目标路径
var _target_path: String = ""
## 最新进度（防止进度条倒退）
var _latest_progress: float = 0.0
## 是否正在过渡中（防止重复触发）
var _is_transitioning: bool = false

# ════════════════════════════════════════════════════════════════
# 生命周期
# ════════════════════════════════════════════════════════════════

func _enter_tree() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _png_cache.is_empty():
		_preload_pngs()

func _ready() -> void:
	# 初始隐藏
	_color_rect.modulate.a = 0.0
	_progress_bar.hide()
	set_process(false)

func _process(_delta: float) -> void:
	_poll_load_status()

# ════════════════════════════════════════════════════════════════
# 公共 API
# ════════════════════════════════════════════════════════════════

## 异步切换场景
## path: 目标场景路径
## pattern: 花纹编号（1~8），-1 = 随机，9 = 纯淡入淡出
## show_bar: 是否显示进度条
func change_scene(path: String, pattern: int = -1, show_bar: bool = true) -> void:
	if _is_transitioning:
		push_warning("TransitionManager: 正在过渡中，忽略重复请求")
		return
	if path.is_empty():
		push_error("TransitionManager: 目标场景路径为空")
		return

	_is_transitioning = true
	_target_path = path
	_latest_progress = 0.0

	# 启动异步加载
	ResourceLoader.load_threaded_request(_target_path, "PackedScene")
	set_process(true)

	# 播放入场动画（遮住当前场景）
	await _play_cover_animation(pattern)

	# 显示进度条
	if show_bar and show_progress_bar_by_default:
		_show_progress_bar()

## 仅播放过渡动画（不切换场景，用于自定义流程）
## 返回 true 表示动画播放完毕
func play_transition_animation(pattern: int = -1) -> void:
	await _play_cover_animation(pattern)
	await _play_reveal_animation()

## 手动触发揭幕动画（配合 play_transition_animation 使用）
func reveal() -> void:
	await _play_reveal_animation()

# ════════════════════════════════════════════════════════════════
# 内部：加载轮询
# ════════════════════════════════════════════════════════════════

func _poll_load_status() -> void:
	var progress_arr: Array = []
	var status := ResourceLoader.load_threaded_get_status(_target_path, progress_arr)

	# 更新进度条
	if progress_arr.size() > 0:
		var p: float = progress_arr[0]
		if p > _latest_progress:
			_latest_progress = p
			_progress_bar.value = _latest_progress * 100.0
			load_progress_changed.emit(_latest_progress)

	if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
		set_process(false)
		var packed := ResourceLoader.load_threaded_get(_target_path) as PackedScene
		_on_scene_loaded(packed)

	elif status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
		set_process(false)
		_is_transitioning = false
		push_error("TransitionManager: 场景加载失败 '%s'" % _target_path)

# ════════════════════════════════════════════════════════════════
# 内部：场景加载完成处理
# ════════════════════════════════════════════════════════════════

func _on_scene_loaded(packed: PackedScene) -> void:
	# 等待遮罩动画完成后再切换
	if _animation_player.is_playing():
		await _animation_player.animation_finished

	# 隐藏进度条
	_hide_progress_bar()

	# 切换场景
	SceneChangeBridge.change_scene_to_packed(packed)

	# 播放揭幕动画（显示新场景）
	await _play_reveal_animation()

	_is_transitioning = false
	scene_changed.emit(get_tree().current_scene)

# ════════════════════════════════════════════════════════════════
# 内部：动画
# ════════════════════════════════════════════════════════════════

## 播放遮罩动画（遮住屏幕）
func _play_cover_animation(pattern: int) -> void:
	_apply_pattern(pattern)
	_animation_player.play("ShaderFade")
	await _animation_player.animation_finished

## 播放揭幕动画（显示屏幕）
func _play_reveal_animation() -> void:
	_color_rect.set_instance_shader_parameter("fade", false)
	_animation_player.play_backwards("ShaderFade")
	await _animation_player.animation_finished

## 应用花纹到 Shader
func _apply_pattern(pattern: int) -> void:
	if pattern < 0:
		pattern = randi_range(1, PATTERN_COUNT + 1)  # +1 包含纯淡入淡出
	if pattern > PATTERN_COUNT:
		# 纯淡入淡出模式
		_color_rect.set_instance_shader_parameter("fade", true)
	else:
		_color_rect.set_instance_shader_parameter("fade", false)
		var tex: Texture2D = _png_cache.get(str(pattern))
		if tex != null:
			_color_rect.material.set_shader_parameter("dissolve_texture", tex)

# ════════════════════════════════════════════════════════════════
# 内部：进度条
# ════════════════════════════════════════════════════════════════

func _show_progress_bar() -> void:
	_progress_bar.value = 0.0
	_progress_bar.show()
	var tween := create_tween()
	tween.tween_property(_progress_bar, "modulate:a", 1.0, progress_bar_fade_duration).from(0.0)

func _hide_progress_bar() -> void:
	var tween := create_tween()
	tween.tween_property(_progress_bar, "modulate:a", 0.0, progress_bar_fade_duration).from(1.0)
	tween.tween_callback(_progress_bar.hide)

# ════════════════════════════════════════════════════════════════
# 内部：预加载花纹贴图
# ════════════════════════════════════════════════════════════════

func _preload_pngs() -> void:
	for i in range(1, PATTERN_COUNT + 1):
		var path := SHADER_PATTERNS + str(i) + ".png"
		if ResourceLoader.exists(path):
			_png_cache[str(i)] = load(path)

