extends Control
class_name TimeAbilityHUD
## 时间能力 HUD 模板
## 目标：提供“能量 + 回溯进度 + 当前能力提示”的统一 UI 模板。

@export var title_text: String = "Time Runner HUD"

@onready var _title_label: Label = $Margin/Panel/VBox/Title
@onready var _energy_bar: ProgressBar = $Margin/Panel/VBox/EnergyRow/EnergyBar
@onready var _energy_text: Label = $Margin/Panel/VBox/EnergyRow/EnergyText
@onready var _rewind_bar: ProgressBar = $Margin/Panel/VBox/RewindRow/RewindBar
@onready var _rewind_text: Label = $Margin/Panel/VBox/RewindRow/RewindText
@onready var _hint_label: Label = $Margin/Panel/VBox/Hint

func _ready() -> void:
	_title_label.text = title_text
	set_energy(100.0, 100.0)
	set_rewind_charge(1.0)
	show_hint("按 R 模拟回溯，按 T 触发预警特效")

func set_energy(current: float, max_value: float) -> void:
	var safe_max := maxf(max_value, 1.0)
	_energy_bar.max_value = safe_max
	_energy_bar.value = clampf(current, 0.0, safe_max)
	_energy_text.text = "能量 %.0f / %.0f" % [_energy_bar.value, safe_max]

func set_rewind_charge(ratio: float) -> void:
	var safe_ratio := clampf(ratio, 0.0, 1.0)
	_rewind_bar.max_value = 1.0
	_rewind_bar.value = safe_ratio
	_rewind_text.text = "回溯储能 %d%%" % int(round(safe_ratio * 100.0))

func show_hint(text: String) -> void:
	_hint_label.text = text

