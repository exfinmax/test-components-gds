extends Control
class_name AbilityWheelHUD
## 能力轮盘 HUD 模板
## 作用：以统一入口展示“能力冷却+选中态+提示文本”，适配时间能力类游戏。

@export var ability_labels: Array[String] = ["回溯", "回声", "时停", "冲刺"]
@export var selected_index: int = 0
@export var cooldown_ratio: Array[float] = [0.0, 0.0, 0.0, 0.0]

@onready var _title: Label = $Panel/Root/Title
@onready var _items: HBoxContainer = $Panel/Root/Items
@onready var _hint: Label = $Panel/Root/Hint

func _ready() -> void:
	_render()

func set_selected(index: int) -> void:
	selected_index = clampi(index, 0, max(0, ability_labels.size() - 1))
	_render()

func set_cooldown(index: int, ratio: float) -> void:
	if index < 0 or index >= cooldown_ratio.size():
		return
	cooldown_ratio[index] = clampf(ratio, 0.0, 1.0)
	_render()

func set_hint(text: String) -> void:
	_hint.text = text

func _render() -> void:
	_title.text = "能力轮盘"
	for child in _items.get_children():
		child.queue_free()
	for i in range(ability_labels.size()):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(120.0, 68.0)
		var vb := VBoxContainer.new()
		var name_label := Label.new()
		name_label.text = ability_labels[i]
		var cd_label := Label.new()
		var ratio := cooldown_ratio[i] if i < cooldown_ratio.size() else 0.0
		cd_label.text = "冷却 %d%%" % int(round(ratio * 100.0))
		vb.add_child(name_label)
		vb.add_child(cd_label)
		card.add_child(vb)
		if i == selected_index:
			card.modulate = Color(0.75, 1.0, 0.85, 1.0)
		_items.add_child(card)

