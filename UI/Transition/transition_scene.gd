class_name Transition
extends Control

const Shader_Patterns:String = "res://Transition/transition_pattern/"

signal transition_end(next_scene:Node2D)

@export var next_scene_path:String = ""
var latest_proccess:float = 0

@onready var animation_player: AnimationPlayer = $ColorRect/AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect
@onready var prograss_bar: ProgressBar = $ProgressBar

var _png_cache := {}
var is_show_prograss:bool 
var is_stage_transition:bool
var not_emit:bool = true

func _enter_tree() -> void:
	_preload_pngs()



func _preload_pngs() -> void:
	for i in range(1,9):
		var stage_name : String = str(i)
		var stage_path : String = Shader_Patterns + stage_name + ".png"
		_png_cache[stage_name] = load(stage_path)




func rand_shader_fade(number: int = -1) -> void:
	if number < 0:
		number = randi_range(1,9)
	if number == 9:
		color_rect.set_instance_shader_parameter("fade", true)
	else:
		color_rect.material.set_shader_parameter("dissolve_texture", _png_cache.get(str(number)))
	animation_player.play("ShaderFade")
	await animation_player.animation_finished
	animation_player.play_backwards("ShaderFade")
	color_rect.set_instance_shader_parameter("fade", false)



func _ready() -> void:
	ResourceLoader.load_threaded_request(next_scene_path, "")
	rand_shader_fade()
	pass

func _process(delta: float) -> void:
	var process = []
	var loaded_status = ResourceLoader.load_threaded_get_status(next_scene_path, process)
	var new_process = process[0] * 100
	
	if new_process > latest_proccess:
		latest_proccess = new_process
		prograss_bar.value = latest_proccess
	
	
	if loaded_status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
		var next_scene = ResourceLoader.load_threaded_get(next_scene_path)
		if animation_player.is_playing():
			await animation_player.animation_finished
		if is_stage_transition && not_emit:
			not_emit = false
			transition_end.emit(next_scene)
			set_process(false)
			return
		get_tree().change_scene_to_packed(next_scene)
