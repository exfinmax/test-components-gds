extends Control
class_name ToastFeed

@export var max_items: int = 4
@export var life_time: float = 2.0
@export var fade_in_time: float = 0.15
@export var fade_out_time: float = 0.25
@export var ignore_empty_text: bool = true

@onready var _list: VBoxContainer = $Margin/VBox
var _active_tweens: Dictionary = {}

func push_toast(text: String) -> void:
	var content := text.strip_edges()
	if ignore_empty_text and content.is_empty():
		return

	var label := Label.new()
	label.text = content
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_list.add_child(label)

	_play_toast_animation(label)
	_trim_overflow()

func clear_all() -> void:
	for child in _list.get_children():
		_remove_toast(child)

func _play_toast_animation(label: Label) -> void:
	var tween := create_tween()
	var key := label.get_instance_id()
	_active_tweens[key] = tween

	tween.tween_property(label, "modulate:a", 1.0, max(fade_in_time, 0.0))
	tween.tween_interval(max(life_time, 0.0))
	tween.tween_property(label, "modulate:a", 0.0, max(fade_out_time, 0.0))
	tween.finished.connect(func():
		_active_tweens.erase(key)
		_remove_toast(label)
	)

func _trim_overflow() -> void:
	var keep_count :int= max(max_items, 1)
	var overflow := _list.get_child_count() - keep_count
	for _i in range(max(overflow, 0)):
		_remove_toast(_list.get_child(0))

func _remove_toast(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var key := node.get_instance_id()
	var tween: Tween = _active_tweens.get(key, null)
	if tween:
		tween.kill()
	_active_tweens.erase(key)
	if node.get_parent() == _list:
		_list.remove_child(node)
	node.queue_free()
