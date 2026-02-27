extends ColorRect
class_name ScreenFlashOverlay
## 屏幕闪白模板（VFX 模板层）
## 作用：用于受击、时停、解谜成功等全屏反馈。

@export var default_color: Color = Color(1.0, 1.0, 1.0, 0.0)
@export var peak_alpha: float = 0.4
@export var in_duration: float = 0.05
@export var out_duration: float = 0.15

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = default_color
	visible = true

func flash(custom_color: Color = Color(1.0, 1.0, 1.0, 1.0), alpha_scale: float = 1.0) -> void:
	var target_alpha := clampf(peak_alpha * alpha_scale, 0.0, 1.0)
	var c := custom_color
	c.a = 0.0
	color = c
	var tw := create_tween()
	tw.tween_property(self, "color:a", target_alpha, maxf(0.01, in_duration))
	tw.tween_property(self, "color:a", 0.0, maxf(0.01, out_duration))

