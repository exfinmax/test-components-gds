class_name IndicatorModule
extends BalloonModule
## ════════════════════════════════════════════════════════════════
## IndicatorModule — 状态指示器模块
## ════════════════════════════════════════════════════════════════
##
## 监听 FlowControlModule 广播的事件，更新 HUD 指示器：
##   • speed_changed → 快进/慢放指示器
##   • auto_advance_changed → 自动推进指示器
## ════════════════════════════════════════════════════════════════

## 自动推进指示器标签节点引用（由场景配置）
var auto_advance_indicator: Label

## 速度指示器标签节点引用（由场景配置）
var speed_indicator: Label

# ════════════════════════════════════════════════════════════════
# 内部状态
# ════════════════════════════════════════════════════════════════

var _flow_module: FlowControlModule = null

# ════════════════════════════════════════════════════════════════
# BalloonModule 接口
# ════════════════════════════════════════════════════════════════

func get_module_name() -> String:
	return "indicator"

func on_dialogue_started(_resource: DialogueResource, _title: String) -> void:
	# 从宿主查找 FlowControlModule 并缓存引用
	if is_instance_valid(_balloon):
		_flow_module = _balloon.get_module_by_name("flow_control") as FlowControlModule
	_reset_indicators()

func on_dialogue_ended() -> void:
	_reset_indicators()

func on_module_event(event_name: String, data: Dictionary) -> void:
	match event_name:
		"speed_changed":
			_update_speed_indicator(data.get("multiplier", 1.0))
		"auto_advance_changed":
			_update_auto_advance_indicator(data.get("enabled", false))

# ════════════════════════════════════════════════════════════════
# 内部方法
# ════════════════════════════════════════════════════════════════

## 更新速度指示器
## m > 1.5 → 快进，m < 0.7 → 慢放，否则隐藏
func _update_speed_indicator(m: float) -> void:
	if not is_instance_valid(speed_indicator):
		return
	
	if m > 1.5:
		speed_indicator.text = "⏩ 快进 x%.1f" % m
		speed_indicator.show()
	elif m < 0.7:
		speed_indicator.text = "⏪ 慢放 x%.1f" % m
		speed_indicator.show()
	else:
		speed_indicator.hide()

## 更新自动推进指示器
func _update_auto_advance_indicator(enabled: bool) -> void:
	if not is_instance_valid(auto_advance_indicator):
		return
	
	auto_advance_indicator.text = "⟳ 自动" if enabled else ""
	auto_advance_indicator.visible = enabled

## 重置所有指示器到初始状态
func _reset_indicators() -> void:
	if is_instance_valid(speed_indicator):
		speed_indicator.hide()
	if is_instance_valid(auto_advance_indicator):
		auto_advance_indicator.visible = false
		auto_advance_indicator.text = ""
