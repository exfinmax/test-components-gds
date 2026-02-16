extends CanvasLayer
class_name ScreenEffectComponent
## 全屏后处理特效组件 - 时间操控的视觉反馈
##
## 有什么用？
##   玩家按下"时间慢放"键，如果只是物体变慢了但画面没变化——
##   玩家感受不到"我在操控时间"。
##   
##   但如果按下的瞬间：
##     - 画面边缘出现蓝色渐晕
##     - 色彩饱和度降低
##     - 轻微径向模糊
##   玩家立刻感受到：时间被我掌控了！
##
##   这就是"Game Feel（游戏手感）"——不改变玩法，但极大提升体验。
##
## 预设效果：
##   TIME_SLOW   → 降饱和度 + 蓝色渐晕 + 色差
##   TIME_FREEZE → 几乎全灰 + 静止噪波 + 强渐晕
##   TIME_REWIND → 反色调 + 扫描线 + 屏幕抖动
##   SPEED_BOOST → 径向模糊 + 暖色调 + 屏幕挤压
##   DAMAGE_HIT  → 红色闪烁 + 快速淡出
##   CUSTOM      → 手动设置各参数
##
## 使用方式：
##   screen_fx.apply_preset(ScreenEffectComponent.Preset.TIME_SLOW, 0.3)
##   screen_fx.fade_out(0.5)
##   
##   或连接 EventBus 自动触发：
##     EventBus.time_freeze_started.connect(func(d): screen_fx.apply_preset(Preset.TIME_FREEZE))

signal effect_started(preset_name: String)
signal effect_ended

## 预设类型
enum Preset { NONE, TIME_SLOW, TIME_FREEZE, TIME_REWIND, SPEED_BOOST, DAMAGE_HIT, CUSTOM }

## 当前激活的预设
@export var current_preset: Preset = Preset.NONE

## 是否自动监听 EventBus
@export var auto_listen_events: bool = true

## ========= 特效参数 =========

## 渐晕强度 (0 = 无, 1 = 强)
@export_range(0.0, 1.0, 0.01) var vignette_intensity: float = 0.0

## 渐晕颜色
@export var vignette_color: Color = Color(0.0, 0.1, 0.3, 0.8)

## 色彩饱和度 (1 = 正常, 0 = 全灰)
@export_range(0.0, 1.5, 0.01) var saturation: float = 1.0

## 色差强度
@export_range(0.0, 10.0, 0.1) var chromatic_aberration: float = 0.0

## 整体色调叠加
@export var color_overlay: Color = Color(1, 1, 1, 0)

## 过渡时间（秒）
@export var transition_speed: float = 0.3

## ========= 内部节点 =========
var _color_rect: ColorRect
var _tween: Tween

## 目标参数（Tween 将当前值趋向目标值）
var _target_vignette: float = 0.0
var _target_saturation: float = 1.0
var _target_aberration: float = 0.0
var _target_overlay: Color = Color(1, 1, 1, 0)

## Shader 材质
var _material: ShaderMaterial

func _ready() -> void:
	layer = 100  # 最顶层
	_create_shader_rect()
	
	if auto_listen_events:
		_connect_events.call_deferred()

func _process(delta: float) -> void:
	if not _material: return
	
	# 平滑过渡到目标值
	var speed := delta / maxf(transition_speed, 0.01)
	
	vignette_intensity = lerpf(vignette_intensity, _target_vignette, speed)
	saturation = lerpf(saturation, _target_saturation, speed)
	chromatic_aberration = lerpf(chromatic_aberration, _target_aberration, speed)
	color_overlay = color_overlay.lerp(_target_overlay, speed)
	
	# 更新 Shader uniforms
	_material.set_shader_parameter("vignette_intensity", vignette_intensity)
	_material.set_shader_parameter("vignette_color", vignette_color)
	_material.set_shader_parameter("saturation", saturation)
	_material.set_shader_parameter("chromatic_aberration", chromatic_aberration)
	_material.set_shader_parameter("color_overlay", color_overlay)

#region 预设

func apply_preset(preset: Preset, fade_time: float = -1.0) -> void:
	current_preset = preset
	if fade_time >= 0:
		transition_speed = fade_time
	
	match preset:
		Preset.NONE:
			_set_targets(0.0, 1.0, 0.0, Color(1, 1, 1, 0))
			vignette_color = Color(0, 0, 0, 0.8)
		
		Preset.TIME_SLOW:
			vignette_color = Color(0.0, 0.1, 0.4, 0.7)
			_set_targets(0.5, 0.6, 2.0, Color(0.8, 0.85, 1.0, 0.1))
		
		Preset.TIME_FREEZE:
			vignette_color = Color(0.0, 0.05, 0.2, 0.9)
			_set_targets(0.8, 0.15, 4.0, Color(0.6, 0.7, 1.0, 0.15))
		
		Preset.TIME_REWIND:
			vignette_color = Color(0.3, 0.0, 0.3, 0.6)
			_set_targets(0.4, 0.5, 5.0, Color(1.0, 0.8, 0.6, 0.1))
		
		Preset.SPEED_BOOST:
			vignette_color = Color(0.3, 0.15, 0.0, 0.5)
			_set_targets(0.3, 1.2, 1.0, Color(1.0, 0.95, 0.85, 0.05))
		
		Preset.DAMAGE_HIT:
			vignette_color = Color(0.5, 0.0, 0.0, 0.8)
			_set_targets(0.7, 0.8, 3.0, Color(1.0, 0.3, 0.3, 0.2))
			# 自动淡出
			if _tween: _tween.kill()
			_tween = create_tween()
			_tween.tween_callback(func(): apply_preset(Preset.NONE, 0.4)).set_delay(0.15)
		
		Preset.CUSTOM:
			pass  # 手动设置参数
	
	effect_started.emit(Preset.keys()[preset])

## 淡出当前效果
func fade_out(duration: float = 0.5) -> void:
	transition_speed = duration
	apply_preset(Preset.NONE, duration)

func _set_targets(vig: float, sat: float, aber: float, overlay: Color) -> void:
	_target_vignette = vig
	_target_saturation = sat
	_target_aberration = aber
	_target_overlay = overlay

#endregion

#region EventBus 自动连接

func _connect_events() -> void:
	if not EventBus: return
	
	EventBus.time_freeze_started.connect(func(_d): apply_preset(Preset.TIME_FREEZE))
	EventBus.time_freeze_ended.connect(func(): fade_out(0.3))
	EventBus.time_scale_changed.connect(_on_time_scale_changed)
	EventBus.time_rewind_started.connect(func(): apply_preset(Preset.TIME_REWIND))
	EventBus.time_rewind_ended.connect(func(): fade_out(0.3))
	EventBus.entity_damaged.connect(func(_t, _a, _s): 
		apply_preset(Preset.DAMAGE_HIT, 0.05)
	)

func _on_time_scale_changed(new_scale: float) -> void:
	if new_scale < 0.8:
		apply_preset(Preset.TIME_SLOW, 0.3)
	elif new_scale > 1.5:
		apply_preset(Preset.SPEED_BOOST, 0.2)
	else:
		fade_out(0.3)

#endregion

#region Shader 创建

func _create_shader_rect() -> void:
	_color_rect = ColorRect.new()
	_color_rect.name = "ScreenEffectRect"
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shader := Shader.new()
	shader.code = _get_shader_code()
	
	_material = ShaderMaterial.new()
	_material.shader = shader
	_color_rect.material = _material
	
	add_child(_color_rect)

func _get_shader_code() -> String:
	return """
shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.1, 0.3, 0.8);
uniform float saturation : hint_range(0.0, 1.5) = 1.0;
uniform float chromatic_aberration : hint_range(0.0, 10.0) = 0.0;
uniform vec4 color_overlay : source_color = vec4(1.0, 1.0, 1.0, 0.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = vec2(0.5);
	
	// 色差（Chromatic Aberration）
	float ca = chromatic_aberration * 0.001;
	vec2 dir = uv - center;
	float r = texture(SCREEN_TEXTURE, uv + dir * ca).r;
	float g = texture(SCREEN_TEXTURE, uv).g;
	float b = texture(SCREEN_TEXTURE, uv - dir * ca).b;
	vec3 col = vec3(r, g, b);
	
	// 饱和度
	float gray = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(gray), col, saturation);
	
	// 颜色叠加
	col = mix(col, color_overlay.rgb, color_overlay.a);
	
	// 渐晕
	float dist = distance(uv, center);
	float vig = smoothstep(0.3, 0.9, dist) * vignette_intensity;
	col = mix(col, vignette_color.rgb, vig * vignette_color.a);
	
	COLOR = vec4(col, 1.0);
}
"""

#endregion

#region 自省

func get_component_data() -> Dictionary:
	return {
		"current_preset": Preset.keys()[current_preset],
		"vignette_intensity": vignette_intensity,
		"saturation": saturation,
		"chromatic_aberration": chromatic_aberration,
	}

#endregion
