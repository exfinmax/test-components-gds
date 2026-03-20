class_name OneShotTransition
extends CanvasLayer
## ════════════════════════════════════════════════════════════════
## OneShotTransition — 一次性过渡模块
## ════════════════════════════════════════════════════════════════
##
## 放入场景树后自动执行一次过渡，完成后可选择：
##   • SEND   模式：直接调用 get_tree().change_scene_to_packed()
##   • MODIFY 模式：发出 transition_end 信号，由外部决定如何处理
##
## 使用方式：
##   1. 将 OneShotTransition.tscn 实例化并 add_child 到当前场景
##   2. 设置 next_scene_path 和 mode
##   3. 调用 start() 或设置 auto_play = true 自动触发
##
## 与 TransitionManager 的区别：
##   • OneShotTransition 是一次性节点，用完即销毁
##   • TransitionManager 是持久单例，适合全局场景管理
## ════════════════════════════════════════════════════════════════

## 过渡完成信号（仅 MODIFY 模式发出，携带加载好的 PackedScene）
signal transition_end(packed_scene: PackedScene)

# ════════════════════════════════════════════════════════════════
# 配置
# ════════════════════════════════════════════════════════════════

enum Mode {
	## 直接切换场景（调用 change_scene_to_packed）
	SEND,
	## 发出信号，由外部处理场景切换
	MODIFY,
}

## 过渡模式
@export var mode: Mode = Mode.SEND
## 目标场景路径
@export_file("*.tscn", "*.scn") var next_scene_path: String = ""
## 是否在 _ready 时自动开始
@export var auto_play: bool = true
## 是否显示加载进度条
@export var show_progress_bar: bool = true
## 花纹编号（1~8），-1 = 随机，9+ = 纯淡入淡出
@export_range(-1, 9, 1) var pattern: int = -1
## 完成后是否自动销毁此节点
@export var auto_free_on_done: bool = true

# ════════════════════════════════════════════════════════════════
# 节点引用
# ════════════════════════════════════════════════════════════════

@onready var _color_rect: ColorRect = $ColorRect
@onready var _animation_player: AnimationPlayer = $ColorRect/AnimationPlayer
@onready var _progress_bar: ProgressBar = $ProgressBar

# ════════════════════════════════════════════════════════════════
# 内部状态
# ════════════════════════════════════════════════════════════════

const SHADER_PATTERNS: String = "res://ComponentLibrary/Modules/UI/Templates/Transition/transition_pattern/"
const PATTERN_COUNT: int = 8

static var _png_cache: Dictionary = {}

var _latest_progress: float = 0.0
var _should_emit: bool = true

# ════════════════════════════════════════════════════════════════
# 生命周期
# ════════════════════════════════════════════════════════════════

func _enter_tree() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _png_cache.is_empty():
		_preload_pngs()

func _ready() -> void:
	set_process(false)
	if auto_play and not next_scene_path.is_empty():
		start(next_scene_path, show_progress_bar)

func _process(_delta: float) -> void:
	_poll_load_status()

# ════════════════════════════════════════════════════════════════
# 公共 API
# ════════════════════════════════════════════════════════════════

## 开始过渡
## path: 目标场景路径（为空时使用 next_scene_path）
## show_bar: 是否显示进度条
func start(path: String = "", show_bar: bool = true) -> void:
	if not path.is_empty():
		next_scene_path = path
	if next_scene_path.is_empty():
		push_error("OneShotTransition: next_scene_path 未设置")
		return

	_latest_progress = 0.0
	_should_emit = true

	# 启动异步加载
	ResourceLoader.load_threaded_request(next_scene_path, "PackedScene")
	set_process(true)

	# 播放遮罩动画
	_apply_pattern(pattern)
	_animation_player.play("ShaderFade")

	# 显示进度条
	if show_bar:
		_progress_bar.value = 0.0
		_progress_bar.show()
		var tween := create_tween()
		tween.tween_property(_progress_bar, "modulate:a", 1.0, 0.3).from(0.0)
	else:
		_progress_bar.hide()

# ════════════════════════════════════════════════════════════════
# 内部：加载轮询
# ════════════════════════════════════════════════════════════════

func _poll_load_status() -> void:
	var progress_arr: Array = []
	var status := ResourceLoader.load_threaded_get_status(next_scene_path, progress_arr)

	if progress_arr.size() > 0:
		var p: float = progress_arr[0]
		if p > _latest_progress:
			_latest_progress = p
			_progress_bar.value = _latest_progress * 100.0

	if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
		set_process(false)
		var packed := ResourceLoader.load_threaded_get(next_scene_path) as PackedScene
		_on_loaded(packed)

	elif status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
		set_process(false)
		push_error("OneShotTransition: 场景加载失败 '%s'" % next_scene_path)

# ════════════════════════════════════════════════════════════════
# 内部：加载完成处理
# ════════════════════════════════════════════════════════════════

func _on_loaded(packed: PackedScene) -> void:
	# 等待遮罩动画完成
	if _animation_player.is_playing():
		await _animation_player.animation_finished

	# 隐藏进度条
	var tween := create_tween()
	tween.tween_property(_progress_bar, "modulate:a", 0.0, 0.3).from(1.0)
	tween.tween_callback(_progress_bar.hide)

	# 播放揭幕动画
	_color_rect.set_instance_shader_parameter("fade", false)
	_animation_player.play_backwards("ShaderFade")
	await _animation_player.animation_finished

	if mode == Mode.MODIFY and _should_emit:
		_should_emit = false
		transition_end.emit(packed)
	else:
		get_tree().change_scene_to_packed(packed)

	if auto_free_on_done:
		queue_free()

# ════════════════════════════════════════════════════════════════
# 内部：花纹
# ════════════════════════════════════════════════════════════════

func _apply_pattern(p: int) -> void:
	if p < 0:
		p = randi_range(1, PATTERN_COUNT + 1)
	if p > PATTERN_COUNT:
		_color_rect.set_instance_shader_parameter("fade", true)
	else:
		_color_rect.set_instance_shader_parameter("fade", false)
		var tex: Texture2D = _png_cache.get(str(p))
		if tex != null:
			_color_rect.material.set_shader_parameter("dissolve_texture", tex)

func _preload_pngs() -> void:
	for i in range(1, PATTERN_COUNT + 1):
		var path := SHADER_PATTERNS + str(i) + ".png"
		if ResourceLoader.exists(path):
			_png_cache[str(i)] = load(path)
