class_name Hand
extends ColorRect

const CARD = preload("res://ComponentLibrary/Modules/GameLogic/Card/Components/card.tscn")

@export var hand_curve: Curve
@export var rotation_curve: Curve

@export var max_rotation_degrees: float = 10.0
@export var x_sep: float = 20.0
@export var y_min: float = 50.0
@export var y_max: float = -50.0

## 手牌槽位锚点列表（与 _cards 严格一一对应）
var _card_points: Array[CardPoint] = []
## 当前手牌列表
var _cards: Array[Card] = []


# ── 外部接口 ──────────────────────────────────────────────────────────────────

## 摸一张牌并加入手牌区域
func draw() -> void:
	# 创建新槽位锚点
	var point := CardPoint.new()
	_card_points.append(point)
	add_child(point)

	# 实例化卡牌
	var new_card: Card = CARD.instantiate()
	new_card.text = "Card %d" % (_cards.size() + 1)
	new_card.hand = self
	_cards.append(new_card)
	add_child(new_card)

	# 刷新所有槽位位置/旋转
	_update_points()
	# 绑定并令卡牌瞬间定位（避免第一帧从 (0,0) lerp 过来）
	new_card.target_point = point
	new_card.global_position = point.global_position


## 弃掉最后一张牌（带淡出动画）
func discard() -> void:
	if _cards.is_empty():
		return
	_cards[-1].discard_animated()


## 拖拽中实时重排：若被拖拽卡牌的 X 轴越过相邻槽位中心则立即交换，每帧只交换一次
## 由 Card._process 在 is_dragging 时调用，无需在松手时再做最近点查找
func reorder_dragging_card(card: Card) -> void:
	var idx := _cards.find(card)
	if idx < 0:
		return
	var card_x := card.global_position.x
	# 越过右侧槽位中心 → 与右侧交换
	if idx < _card_points.size() - 1:
		if card_x > _card_points[idx + 1].global_position.x:
			_swap_cards(idx, idx + 1)
			return  # 每帧最多交换一次，下帧继续级联检测
	# 越过左侧槽位中心 → 与左侧交换
	if idx > 0:
		if card_x < _card_points[idx - 1].global_position.x:
			_swap_cards(idx, idx - 1)


## Card.discard_animated() 开始时调用：立即从跟踪列表移除并刷新布局
## （卡牌节点本身继续存在，直到淡出动画结束后 queue_free）
func remove_card(card: Card) -> void:
	var idx := _cards.find(card)
	if idx < 0:
		return
	_cards.remove_at(idx)
	_card_points[idx].queue_free()
	_card_points.remove_at(idx)
	card.target_point = null
	_update_points()
	_rebind_cards()


## 将 card 移到指定槽位（保留为公开接口，一般由外部逻辑调用）
func reassign_card_to_index(card: Card, target_idx: int) -> void:
	var old_idx := _cards.find(card)
	if old_idx < 0:
		return
	if old_idx == target_idx:
		return

	_cards.remove_at(old_idx)
	var insert_idx: int = target_idx if old_idx > target_idx else (target_idx - 1)
	insert_idx = clampi(insert_idx, 0, _cards.size())
	_cards.insert(insert_idx, card)

	_update_points()
	_rebind_cards()


# ── 私有方法 ──────────────────────────────────────────────────────────────────

## 根据当前卡牌数量刷新所有 CardPoint 的 position 和 target_rotation_degrees
func _update_points() -> void:
	var count := _card_points.size()
	if count == 0:
		return

	var all_w := Card.SIZE.x * count + x_sep * (count - 1)
	var sep := x_sep
	if all_w > size.x:
		sep = (size.x - Card.SIZE.x * count) / float(count - 1)
		all_w = size.x
	var offset := (size.x - all_w) / 2.0

	for i in count:
		var y_mult := 0.0
		var rot_mult := 0.0
		if count > 1:
			var t := float(i) / float(count - 1)
			y_mult = hand_curve.sample(t)
			rot_mult = rotation_curve.sample(t)

		_card_points[i].position = Vector2(
			offset + (Card.SIZE.x + sep) * i,
			y_min + y_max * y_mult
		)
		_card_points[i].target_rotation_degrees = max_rotation_degrees * rot_mult


## 交换 _cards 中两个索引的卡牌并重新绑定（槽位位置不变，其余牌自动 lerp 过去）
func _swap_cards(a: int, b: int) -> void:
	var tmp := _cards[a]
	_cards[a] = _cards[b]
	_cards[b] = tmp
	_rebind_cards()


## 将所有卡牌重新绑定到对应索引的 CardPoint（重排后调用）
func _rebind_cards() -> void:
	for i in _cards.size():
		_cards[i].target_point = _card_points[i]
