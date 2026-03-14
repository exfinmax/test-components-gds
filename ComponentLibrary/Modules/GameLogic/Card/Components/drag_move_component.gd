class_name DragMoveComponent
extends Node
## 拖拽移动组件
## 将此节点作为子节点挂在任意 Control 节点下，父节点即可被鼠标左键拖拽移动。
## 拖拽期间自动覆盖父节点的 rotation_degrees；松手后由父节点（Card）的 _process 负责还原。

## 拖拽时跟随鼠标的 lerp 系数（帧率无关，follow_speed * delta）。0 = 瞬间吸附
@export var follow_speed: float = 20.0
## 拖拽过程中父节点 rotation_degrees 的目标值
@export var drag_rotation_degrees: float = 8.0
## 进入拖拽旋转的过渡时长（秒）
@export var drag_rotation_tween_duration: float = 0.15

## 开始拖拽（鼠标左键按下）时发出
signal drag_started
## 松开鼠标左键时发出
signal drag_ended

var is_dragging: bool = false

var _parent: Control
var _drag_offset: Vector2
var _rot_tween: Tween


func _ready() -> void:
	_parent = get_parent() as Control
	assert(_parent != null, "DragMoveComponent 必须挂在 Control 节点下")
	_parent.gui_input.connect(_on_gui_input)
	_parent.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed and not is_dragging:
		_start_drag()
	elif not mb.pressed and is_dragging:
		_end_drag()


func _process(delta: float) -> void:
	if not is_dragging:
		return
	var target: Vector2 = _parent.get_global_mouse_position() - _drag_offset
	if follow_speed <= 0.0:
		_parent.global_position = target
	else:
		_parent.global_position = _parent.global_position.lerp(
			target, minf(follow_speed * delta, 1.0)
		)


func _start_drag() -> void:
	is_dragging = true
	_drag_offset = _parent.get_global_mouse_position() - _parent.global_position
	if _rot_tween and _rot_tween.is_running():
		_rot_tween.kill()
	_rot_tween = _parent.create_tween()
	_rot_tween.tween_property(
		_parent, "rotation_degrees",
		drag_rotation_degrees, drag_rotation_tween_duration
	)
	drag_started.emit()


func _end_drag() -> void:
	is_dragging = false
	if _rot_tween and _rot_tween.is_running():
		_rot_tween.kill()
	# rotation 还原由 Card._process 中的 lerp 接管，此处无需额外 tween
	drag_ended.emit()
