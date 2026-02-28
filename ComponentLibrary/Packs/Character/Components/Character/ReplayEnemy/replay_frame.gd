extends RefCounted
class_name ReplayFrame
## 回放帧数据 - 记录单帧的角色状态
##
## 用于 RecordComponent 录制和 ReplayComponent 回放

## 时间戳（录制时的本地累计时间）
var time: float = 0.0

## 位置（PATH 模式核心数据）
var position: Vector2 = Vector2.ZERO

## 速度（INPUT 模式核心数据）
var velocity: Vector2 = Vector2.ZERO

## 输入方向
var input_direction: Vector2 = Vector2.ZERO

## 动作标记
var actions: Dictionary = {}  # {"jump": true, "dash": true, ...}

## 动画名称
var animation_name: String = ""

## 朝向
var heading: Vector2 = Vector2.RIGHT

## 额外数据（组件可自行附加）
var extra: Dictionary = {}

func _to_string() -> String:
	return "ReplayFrame(t=%.2f, pos=%s, vel=%s)" % [time, position, velocity]
