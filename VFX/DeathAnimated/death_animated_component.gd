extends Node2D
class_name DeathAnimatedComponent
## 死亡动画组件 - 生命值归零时播放死亡粒子和音效
##
## 注：因继承 Node2D（需要位置），无法继承 ComponentBase，
## 但手动实现了相同的 enabled + get_component_data 模式。

signal enabled_changed(is_enabled: bool)

## 组件是否启用 — 禁用时不播放死亡效果
var enabled: bool = true:
	set(v):
		if enabled == v: return
		enabled = v
		enabled_changed.emit(enabled)

@export var health_component: HealthComponent
@export var sprite: Sprite2D
@export var stream_array: Array[AudioStream]

func _ready() -> void:
	if stream_array.size() > 0:
		$AudioStreamPlayer2D.stream = stream_array.pick_random()
	$GPUParticles2D.texture = sprite.texture
	$GPUParticles2D.scale = sprite.scale
	health_component.died.connect(on_died.bind())

func on_died() -> void:
	if not enabled: return
	if owner == null: return
	global_position = owner.global_position
	$AnimationPlayer.play("death")
	$AudioStreamPlayer2D.play()

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"has_health_component": health_component != null,
		"has_sprite": sprite != null,
	}
