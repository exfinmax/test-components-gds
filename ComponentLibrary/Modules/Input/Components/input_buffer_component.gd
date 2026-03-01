## InputBufferComponent — 输入缓冲组件
## 
## 在时间窗口内缓存玩家输入，用于连招检测、输入宽容（土狼时间）、指令缓冲等。
## 完全独立于 CharacterBody2D，可附加到任何节点。
## 
## 特性：
## - 记录最近 N 次输入及其时间戳
## - is_buffered(action) — 判断 action 是否在缓冲窗口内
## - consume(action)      — 消耗一次缓冲的 action，防止重复触发
## - has_sequence(seq)    — 检测连招序列（按顺序）
## - clear()              — 手动清空缓冲
## 
## 使用示例：
##   func _unhandled_input(event):
##       if event.is_action_pressed("jump"):
##           input_buffer.buffer_action(&"jump")
##   func _physics_process(_delta):
##       if input_buffer.consume(&"jump"):
##           do_jump()

extends Node
class_name InputBufferComponent

# ── 信号 ─────────────────────────────────────────────────────────────
signal action_buffered(action: StringName)
signal sequence_detected(sequence: Array)

# ── 导出属性 ──────────────────────────────────────────────────────────
## 输入缓冲有效时间窗口（秒）
@export var buffer_window: float = 0.2
## 最多保存的历史输入数量
@export var max_buffer_size: int = 16
## 是否自动监听 Input._unhandled_input，需要父节点启用 set_process_unhandled_input(true)
@export var auto_listen: bool = false

# ── 内嵌结构 ─────────────────────────────────────────────────────────
class BufferedInput:
	var action:    StringName
	var timestamp: float
	var consumed:  bool = false
	func _init(a: StringName, t: float) -> void:
		action    = a
		timestamp = t

# ── 内部状态 ──────────────────────────────────────────────────────────
var _buffer: Array = []  # Array[BufferedInput]

# ── 生命周期 ──────────────────────────────────────────────────────────
func _ready() -> void:
	if auto_listen:
		set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if not auto_listen:
		return
	for action in InputMap.get_actions():
		if event.is_action_pressed(action):
			buffer_action(action)

func _process(_delta: float) -> void:
	_evict_expired()

# ── 公共 API ──────────────────────────────────────────────────────────

## 手动记录一次输入
func buffer_action(action: StringName) -> void:
	_evict_expired()
	var entry := BufferedInput.new(action, Time.get_ticks_msec() / 1000.0)
	_buffer.append(entry)
	if _buffer.size() > max_buffer_size:
		_buffer.pop_front()
	action_buffered.emit(action)

## 检查 action 是否在缓冲窗口内（不消耗）
func is_buffered(action: StringName) -> bool:
	_evict_expired()
	for e in _buffer:
		var bi := e as BufferedInput
		if bi.action == action and not bi.consumed:
			return true
	return false

## 消耗一次缓冲的 action（返回 true 表示成功消耗）
func consume(action: StringName) -> bool:
	_evict_expired()
	for e in _buffer:
		var bi := e as BufferedInput
		if bi.action == action and not bi.consumed:
			bi.consumed = true
			return true
	return false

## 获取最近 count 个未消耗输入（按时间顺序）
func get_recent(count: int = 4) -> Array[StringName]:
	_evict_expired()
	var result: Array[StringName] = []
	var valid: Array = _buffer.filter(func(e): return not (e as BufferedInput).consumed)
	var start: int  = max(0, valid.size() - count)
	for i in range(start, valid.size()):
		result.append((valid[i] as BufferedInput).action)
	return result

## 检查近期输入中是否包含指定顺序的连招序列
func has_sequence(seq: Array[StringName]) -> bool:
	if seq.is_empty():
		return false
	_evict_expired()
	var valid: Array = _buffer.filter(func(e): return not (e as BufferedInput).consumed)
	var si: int = 0
	for e in valid:
		if (e as BufferedInput).action == seq[si]:
			si += 1
			if si >= seq.size():
				return true
	return false

## 清空全部缓冲
func clear() -> void:
	_buffer.clear()

## 缓冲中的未消耗条目数量
func get_pending_count() -> int:
	_evict_expired()
	var count: int = 0
	for e in _buffer:
		if not (e as BufferedInput).consumed:
			count += 1
	return count

# ── 私有 ─────────────────────────────────────────────────────────────
func _evict_expired() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	_buffer = _buffer.filter(func(e): return (now - (e as BufferedInput).timestamp) <= buffer_window)
