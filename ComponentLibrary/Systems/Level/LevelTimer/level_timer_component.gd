extends Node
class_name LevelTimerComponent
## 关卡计时器组件 - Speedrun 计时 + 分段计时
##
## 有什么用？
##   跑酷的核心魅力之一就是"追求速度"。
##   计时器让玩家知道：
##     - 这关我跑了多久
##     - 每一段分别花了多少时间（Split）
##     - 和上次比快了还是慢了
##   
##   这是 Speedrun 社区的标配功能。
##   即使不是硬核 Speedrunner，看到自己一次比一次快也会很爽。
##
## 什么是 Split（分段）？
##   一个关卡分成多段（检查点之间就是一段）：
##     起点 → 第1段 → 检查点1 → 第2段 → 检查点2 → 终点
##   
##   Split 记录每段的耗时，方便分析"哪段慢了"。
##
## 使用方式：
##   1. 添加为场景节点
##   2. 关卡开始时 start()
##   3. 到达检查点时 split("checkpoint_1")
##   4. 通关时 stop()
##   5. 查询 get_total_time(), get_splits(), get_best_time()
##
## 与时间操控的关系：
##   计时器使用**真实时间**（不受 Engine.time_scale 影响）
##   玩家用时间慢放通关 → 真实时间不变，公平！

signal timer_started
signal timer_stopped(total_time: float)
signal timer_paused
signal timer_resumed
signal split_recorded(split_name: StringName, split_time: float, total_time: float)
signal new_best_time(time: float)

## 是否使用真实时间（不受 time_scale 影响）
@export var use_real_time: bool = true

## 是否自动监听 EventBus 的 level_started/level_completed
@export var auto_listen_events: bool = true

## 是否多次 start 时自动重置
@export var auto_reset_on_start: bool = true

## --------- 状态 ---------

var is_running: bool = false
var is_paused: bool = false

## 当前计时（秒）
var elapsed_time: float = 0.0

## 分段数据
class SplitData:
	var name: StringName
	var time_at_split: float  ## 分段时的总时间
	var segment_time: float   ## 本段耗时

var _splits: Array[SplitData] = []
var _last_split_time: float = 0.0

## 最佳记录
var best_time: float = -1.0
var best_splits: Array[SplitData] = []

func _ready() -> void:
	if auto_listen_events:
		_connect_events.call_deferred()

func _process(delta: float) -> void:
	if not is_running or is_paused: return
	
	if use_real_time:
		# 使用真实 delta（补偿 time_scale）
		var ts := Engine.time_scale
		if ts > 0:
			elapsed_time += delta / ts
		else:
			# time_scale = 0 时用固定值
			elapsed_time += 1.0 / 60.0
	else:
		elapsed_time += delta

#region 基本控制

## 开始计时
func start() -> void:
	if auto_reset_on_start:
		reset()
	is_running = true
	is_paused = false
	timer_started.emit()

## 停止计时
func stop() -> void:
	if not is_running: return
	is_running = false
	
	timer_stopped.emit(elapsed_time)
	
	# 检查最佳记录
	if best_time < 0 or elapsed_time < best_time:
		best_time = elapsed_time
		best_splits = _splits.duplicate()
		new_best_time.emit(elapsed_time)

## 暂停
func pause() -> void:
	is_paused = true
	timer_paused.emit()

## 恢复
func resume() -> void:
	is_paused = false
	timer_resumed.emit()

## 重置
func reset() -> void:
	elapsed_time = 0.0
	is_running = false
	is_paused = false
	_splits.clear()
	_last_split_time = 0.0

#endregion

#region Split 分段

## 记录一个分段
func split(split_name: StringName = &"") -> SplitData:
	if not is_running: return null
	
	if split_name == &"":
		split_name = "split_%d" % (_splits.size() + 1)
	
	var sd := SplitData.new()
	sd.name = split_name
	sd.time_at_split = elapsed_time
	sd.segment_time = elapsed_time - _last_split_time
	
	_splits.append(sd)
	_last_split_time = elapsed_time
	
	split_recorded.emit(split_name, sd.segment_time, elapsed_time)
	
	return sd

## 获取所有分段
func get_splits() -> Array[SplitData]:
	return _splits

## 获取最近一个分段
func get_last_split() -> SplitData:
	if _splits.is_empty(): return null
	return _splits[-1]

## 与最佳记录对比指定分段的差值（正 = 慢了，负 = 快了）
func get_split_delta(index: int) -> float:
	if index >= _splits.size() or index >= best_splits.size():
		return 0.0
	return _splits[index].time_at_split - best_splits[index].time_at_split

#endregion

#region 格式化

## 格式化时间为 "MM:SS.mmm"
static func format_time(time_sec: float) -> String:
	if time_sec < 0: return "--:--.---"
	var minutes := int(time_sec) / 60
	var seconds := fmod(time_sec, 60.0)
	return "%02d:%06.3f" % [minutes, seconds]

## 格式化 delta（+1.234 / -0.567）
static func format_delta(delta_sec: float) -> String:
	var sign_str := "+" if delta_sec >= 0 else ""
	return "%s%.3f" % [sign_str, delta_sec]

#endregion

#region EventBus

func _connect_events() -> void:
	if not EventBus: return
	EventBus.level_started.connect(func(_name): start())
	EventBus.level_completed.connect(func(_name): stop())
	EventBus.player_checkpoint_reached.connect(func(data):
		var cp_name: StringName = data.get("checkpoint_name", &"")
		split(cp_name)
	)

#endregion

#region 自省

func get_component_data() -> Dictionary:
	return {
		"is_running": is_running,
		"is_paused": is_paused,
		"elapsed_time": elapsed_time,
		"formatted_time": format_time(elapsed_time),
		"splits_count": _splits.size(),
		"best_time": best_time,
		"formatted_best": format_time(best_time),
	}

#endregion
