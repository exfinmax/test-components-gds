extends Control
class_name ToastFeed
## 消息流 UI 模板
## 目标：在屏幕角落显示短暂提示（获得能力、解谜反馈、错误提示）。

@export var max_items: int = 4
@export var life_time: float = 2.0

@onready var _list: VBoxContainer = $Margin/VBox

func push_toast(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_list.add_child(label)

	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.15)
	tw.tween_interval(life_time)
	tw.tween_property(label, "modulate:a", 0.0, 0.25)
	tw.finished.connect(func():
		if is_instance_valid(label):
			label.queue_free()
	)

	while _list.get_child_count() > max_items:
		(_list.get_child(0) as Node).queue_free()
