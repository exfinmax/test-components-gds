extends Node
class_name ComboTimerComponent
## 连击/连锁计时器组件 - 跑酷游戏的风格分数系统
##
## 什么是 Combo 系统？
##   在跑酷游戏中，玩家做出各种"酷"的动作：
##     蹬墙跳 → 空中冲刺 → 踩敌人 → 二段跳 → 冲刺过刺...
##   
##   如果这些动作在短时间内连续发生，就形成了 "Combo（连击链）"。
##   Combo 越长、越花哨 → 得分越高、奖励越好。
##   
##   这个组件负责：
##     - 追踪连击数（combo_count）
##     - 管理连击时间窗（combo_timer，到了就断）
##     - 计算分数倍率（combo 越高倍率越大）
##     - 统计总分和最高连击
##
## 使用方式：
##   combo_component.register_action("wall_jump", 50)      # 注册：蹬墙跳 = 50分
##   combo_component.register_action("air_dash", 30)       # 空中冲刺 = 30分
##   combo_component.trigger_action("wall_jump")           # 触发动作
##   combo_component.trigger_action("air_dash")            # 在时间窗内触发 → combo!
##
## 信号触发方式（推荐）：
##   在组件信号处调用 trigger_action：
##     jump_comp.jumped.connect(func(): combo_comp.trigger_action("jump"))
##     dash_comp.dash_started.connect(func(_d): combo_comp.trigger_action("dash"))

signal combo_started
signal combo_increased(count: int, multiplier: float)
signal combo_ended(final_count: int, total_score: int)
signal score_changed(score: int)
signal new_high_combo(count: int)

## 连击时间窗（秒）—— 在此时间内不触发新动作就断连击
@export var combo_window: float = 2.0

## 每次连击延长时间窗（秒）—— 连击越多容错越大
@export var combo_window_extension: float = 0.1

## 最大时间窗
@export var max_combo_window: float = 4.0

## 分数倍率增长方式
enum MultiplierMode { LINEAR, LOGARITHMIC, STEP }
@export var multiplier_mode: MultiplierMode = MultiplierMode.STEP

## 线性模式：每次连击增加的倍率
@export var multiplier_per_combo: float = 0.1

## 阶梯模式：倍率阶梯 [combo阈值, 倍率]
## 例如 [5, 1.5, 10, 2.0, 20, 3.0] → 5连=1.5x, 10连=2.0x, 20连=3.0x
@export var multiplier_steps: Array[float] = [5.0, 1.5, 10.0, 2.0, 20.0, 3.0, 50.0, 5.0]

## 已注册的动作及其基础分值 {action_name: base_score}
var _action_scores: Dictionary = {}

## 当前状态
var combo_count: int = 0
var combo_timer: float = 0.0
var current_multiplier: float = 1.0
var total_score: int = 0
var current_combo_score: int = 0  # 当前连击链的分数
var highest_combo: int = 0
var is_in_combo: bool = false

## 最近的动作记录（用于判断多样性加分）
var _recent_actions: Array[StringName] = []
var _diversity_bonus: float = 1.0

func _process(delta: float) -> void:
	if not is_in_combo: return
	
	combo_timer -= delta
	if combo_timer <= 0:
		_end_combo()

#region 注册和触发

## 注册一个动作及其基础分值
func register_action(action_name: StringName, base_score: int = 10) -> void:
	_action_scores[action_name] = base_score

## 触发一个动作（获得分数、刷新/开始连击）
func trigger_action(action_name: StringName, override_score: int = -1) -> void:
	var base: int = override_score if override_score >= 0 else _action_scores.get(action_name, 10)
	
	if not is_in_combo:
		# 开始新连击
		is_in_combo = true
		combo_count = 0
		current_combo_score = 0
		_recent_actions.clear()
		_diversity_bonus = 1.0
		combo_started.emit()
	
	# 增加连击
	combo_count += 1
	
	# 计算多样性加分（不重复动作加分更多）
	if action_name not in _recent_actions:
		_diversity_bonus += 0.1
		_recent_actions.append(action_name)
	
	# 计算倍率
	current_multiplier = _calculate_multiplier()
	
	# 计算本次分数
	var action_score := int(base * current_multiplier * _diversity_bonus)
	current_combo_score += action_score
	total_score += action_score
	
	# 刷新时间窗
	var window := minf(combo_window + combo_window_extension * combo_count, max_combo_window)
	combo_timer = window
	
	# 通知
	combo_increased.emit(combo_count, current_multiplier)
	score_changed.emit(total_score)
	
	# 最高连击记录
	if combo_count > highest_combo:
		highest_combo = combo_count
		new_high_combo.emit(highest_combo)
	
	# 通知 EventBus
	if EventBus:
		EventBus.score_changed.emit(total_score)

#endregion

#region 倍率计算

func _calculate_multiplier() -> float:
	match multiplier_mode:
		MultiplierMode.LINEAR:
			return 1.0 + (combo_count - 1) * multiplier_per_combo
		
		MultiplierMode.LOGARITHMIC:
			return 1.0 + log(float(combo_count)) * 0.5
		
		MultiplierMode.STEP:
			var result := 1.0
			var i := 0
			while i < multiplier_steps.size() - 1:
				var threshold := int(multiplier_steps[i])
				var mult := multiplier_steps[i + 1]
				if combo_count >= threshold:
					result = mult
				else:
					break
				i += 2
			return result
	
	return 1.0

#endregion

#region 连击结束

func _end_combo() -> void:
	if not is_in_combo: return
	
	var final_count := combo_count
	var final_score := current_combo_score
	
	is_in_combo = false
	combo_count = 0
	combo_timer = 0.0
	current_multiplier = 1.0
	current_combo_score = 0
	_recent_actions.clear()
	_diversity_bonus = 1.0
	
	combo_ended.emit(final_count, final_score)

## 手动断连击（被击中时等）
func break_combo() -> void:
	_end_combo()

#endregion

#region API

## 重置所有分数
func reset_all() -> void:
	_end_combo()
	total_score = 0
	highest_combo = 0
	score_changed.emit(0)

## 获取当前连击在总窗口中的剩余比例 (0-1)
func get_timer_ratio() -> float:
	if not is_in_combo: return 0.0
	var window := minf(combo_window + combo_window_extension * combo_count, max_combo_window)
	return combo_timer / window

#endregion

#region 自省

func get_component_data() -> Dictionary:
	return {
		"combo_count": combo_count,
		"current_multiplier": current_multiplier,
		"total_score": total_score,
		"highest_combo": highest_combo,
		"is_in_combo": is_in_combo,
		"timer_ratio": get_timer_ratio(),
		"diversity_bonus": _diversity_bonus,
	}

#endregion
