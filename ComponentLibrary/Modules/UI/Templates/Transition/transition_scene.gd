class_name Transition
extends CanvasLayer

# --- modes --------------------------------------------------------------
enum Mode { SEND, MODIFY }
@export var mode:Mode = Mode.SEND   # default to sending (automatic scene change)

# path for the target scene when mode = SEND or MODIFY
@export var next_scene_path:String = ""

# signals
signal transition_end(next_scene:Node2D)  # emitted only when mode == MODIFY

# node references
@onready var animation_player: AnimationPlayer = $ColorRect/AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect
@onready var progress_bar: ProgressBar = $ProgressBar

# caching dissolve textures used by the shaders
static var _png_cache := {}

# internal state
var _latest_progress:float = 0
var _should_emit:bool = true

# inspector helpers
@export var auto_play:bool = true  # automatically call start() in _ready when path is set


const SHADER_PATTERNS:String = "res://Scenes/UI/UIorgan/Transition/transition_pattern/"

func _enter_tree() -> void:
	if _png_cache.is_empty():
		_preload_pngs()



func _preload_pngs() -> void:
	for i in range(1, 9):
		var stage_name: String = str(i)
		var stage_path: String = SHADER_PATTERNS + stage_name + ".png"
		_png_cache[stage_name] = load(stage_path)

func start(path: String, is_show_bar:bool = true) -> void:
	# kick off an asynchronous load and show transition animation
	next_scene_path = path
	ResourceLoader.load_threaded_request(next_scene_path, "")
	rand_shader_fade()
	set_process(true)
	if is_show_bar:
		var tween = create_tween()
		progress_bar.show()
		tween.tween_property(progress_bar, "modulate:a", 1, .3).from(0)
	else:
		progress_bar.hide()


func rand_shader_fade(number: int = -1) -> void:
	if number < 0:
		number = randi_range(1, 9)
	if number == 9:
		color_rect.set_instance_shader_parameter("fade", true)
	else:
		color_rect.material.set_shader_parameter("dissolve_texture", _png_cache.get(str(number)))
	animation_player.play("ShaderFade")
	await animation_player.animation_finished
	var tween = create_tween()
	tween.tween_property(progress_bar, "modulate:a", 0, .3).from(1)
	tween.tween_callback(progress_bar.hide)
	animation_player.play_backwards("ShaderFade")
	color_rect.set_instance_shader_parameter("fade", false)
	await animation_player.animation_finished




func _ready() -> void:
	# optional automatic start when a path is already populated
	if auto_play and next_scene_path != "":
		start(next_scene_path)

func _process(delta: float) -> void:
	var progress_arr = []
	var status = ResourceLoader.load_threaded_get_status(next_scene_path, progress_arr)
	var percent = 0
	if progress_arr.size() > 0:
		percent = progress_arr[0] * 100

	if percent > _latest_progress:
		_latest_progress = percent
		progress_bar.value = _latest_progress

	if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
		var packed = ResourceLoader.load_threaded_get(next_scene_path)
		if animation_player.is_playing():
			await animation_player.animation_finished

		if mode == Mode.MODIFY and _should_emit:
			_should_emit = false
			transition_end.emit(packed)
			set_process(false)
			return

		# default SEND behaviour
		get_tree().change_scene_to_packed(packed)
