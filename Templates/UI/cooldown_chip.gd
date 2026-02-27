extends Control
class_name CooldownChip
## 冷却芯片 UI 模板
## 目标：给任意能力显示“就绪/冷却中”的小型状态组件。

@export var ability_name: String = "回溯"

@onready var _name: Label = $Panel/H/Name
@onready var _bar: ProgressBar = $Panel/H/Bar
@onready var _state: Label = $Panel/H/State

func _ready() -> void:
	_name.text = ability_name
	set_ready()

func set_ready() -> void:
	_bar.max_value = 1.0
	_bar.value = 1.0
	_state.text = "就绪"
	_state.modulate = Color(0.4, 1.0, 0.5, 1.0)

func set_cooldown(remaining: float, duration: float) -> void:
	var safe_duration := maxf(duration, 0.001)
	var ratio := clampf(1.0 - remaining / safe_duration, 0.0, 1.0)
	_bar.max_value = 1.0
	_bar.value = ratio
	_state.text = "冷却 %.1fs" % maxf(0.0, remaining)
	_state.modulate = Color(1.0, 0.75, 0.35, 1.0)
