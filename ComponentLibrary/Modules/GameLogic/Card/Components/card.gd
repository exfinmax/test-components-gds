class_name Card
extends Panel

const SIZE := Vector2(100, 140)

@export var text: String = ""
## 鼠标悬停时卡牌上升的像素距离
@export var hover_lift: float = 30.0
## 跟随 CardPoint 位置/旋转的 lerp 系数（帧率无关，follow_speed * delta）
@export var follow_speed: float = 15.0
## 拖拽时的 z_index（覆盖默认值，使卡牌渲染在最顶层）
@export var drag_z_index: int = 100
## 拖拽时的旋转角度（转发给 DragMoveComponent）
@export var drag_rotation_degrees: float = 8.0

@onready var label: Label = $Label

## 所属手牌区域（由 Hand.draw() 注入，用于判断松手后归还 or 丢弃）
var hand: Hand = null
## 分配的手牌槽位锚点（由 Hand 管理）
var target_point: CardPoint = null

var is_hovered: bool = false
var is_dragging: bool = false

var _base_z_index: int = 0
var _drag_comp: DragMoveComponent


func _ready() -> void:
	label.text = text
	_base_z_index = z_index

	# 动态创建并配置拖拽组件
	_drag_comp = DragMoveComponent.new()
	_drag_comp.drag_rotation_degrees = drag_rotation_degrees
	add_child(_drag_comp)
	_drag_comp.drag_started.connect(_on_drag_started)
	_drag_comp.drag_ended.connect(_on_drag_ended)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _process(delta: float) -> void:
	# 拖拽中：每帧触发实时重排检测（O(1)，只与相邻槽位比较）
	if is_dragging:
		if hand != null:
			hand.reorder_dragging_card(self)
		return

	if target_point == null:
		return

	# 悬停时向上偏移
	var hover_offset := Vector2(0.0, -hover_lift) if is_hovered else Vector2.ZERO

	# 平滑跟随 CardPoint 的世界位置 + 悬停偏移
	var target_pos := target_point.global_position + hover_offset
	global_position = global_position.lerp(target_pos, minf(follow_speed * delta, 1.0))

	# 平滑还原/跟随手牌旋转（拖拽结束后由此接管还原）
	rotation_degrees = lerpf(
		rotation_degrees,
		target_point.target_rotation_degrees,
		minf(follow_speed * delta, 1.0)
	)


# ── 鼠标悬停 ──────────────────────────────────────────────────────────────────

func _on_mouse_entered() -> void:
	if is_dragging:
		return
	is_hovered = true


func _on_mouse_exited() -> void:
	if is_dragging:
		return
	is_hovered = false


# ── 拖拽生命周期 ──────────────────────────────────────────────────────────────

func _on_drag_started() -> void:
	is_dragging = true
	is_hovered = false
	z_index = drag_z_index


func _on_drag_ended() -> void:
	is_dragging = false
	z_index = _base_z_index

	# 拖拽中已通过实时重排维护好索引，松手后直接 lerp 回当前槽位
	var card_center := global_position + SIZE * 0.5
	if hand == null or not hand.get_global_rect().has_point(card_center):
		discard_animated()


## 播放淡出动画并销毁，同时通知 Hand 更新布局（公开，Hand.discard() 也可调用）
func discard_animated() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if hand != null:
		hand.remove_card(self)   # 立即更新手牌布局，此后 target_point = null
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.4)
	t.tween_callback(queue_free)
