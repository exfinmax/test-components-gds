extends Resource
class_name AnimationConfig
## 动画配置资源 - 定义逻辑动画名到实际动画名的映射
##
## 使用方式：
##   1. 创建 AnimationConfig 资源（.tres）
##   2. 在 Inspector 中填写动画名映射
##   3. 将资源拖到 AnimationComponent 的 config 字段
##
## 不同角色可使用不同的 AnimationConfig，实现相同逻辑、不同动画名

## ──────── 基础动画 ────────

@export_group("基础")
@export var idle: StringName = &"idle"
@export var move: StringName = &"run"

## ──────── 跳跃动画 ────────

@export_group("跳跃")
@export var jump_start: StringName = &"jump_start"       ## 起跳准备（可选，没有则直接 jump_rise）
@export var jump_rise: StringName = &"jump_rise"          ## 上升
@export var jump_apex: StringName = &"jump_apex"          ## 最高点过渡（可选）
@export var fall: StringName = &"fall"                    ## 下落
@export var land: StringName = &"land"                    ## 落地（可选，没有则直接回 idle/move）

## ──────── 冲刺动画 ────────

@export_group("冲刺")
@export var dash_begin: StringName = &"dash_begin"        ## 冲刺准备（可选）
@export var dash: StringName = &"dash"                    ## 冲刺中
@export var dash_end: StringName = &"dash_end"            ## 冲刺结束（可选）
@export var dash_up: StringName = &""                     ## 向上冲刺（为空则用 dash）
@export var dash_down: StringName = &""                   ## 向下冲刺（为空则用 dash）

## ──────── 滑墙动画 ────────

@export_group("滑墙")
@export var wall_slide: StringName = &"wall_slide"
@export var wall_jump: StringName = &"wall_jump"          ## 蹬墙跳（可选，没有则用 jump_start）

## ──────── 受击/死亡 ────────

@export_group("受击")
@export var hit: StringName = &"hit"
@export var death: StringName = &"death"

## 获取冲刺方向对应的动画名
func get_dash_anim(direction: Vector2) -> StringName:
	# 向上冲刺
	if direction.y < -0.5 and dash_up != &"":
		return dash_up
	# 向下冲刺
	if direction.y > 0.5 and dash_down != &"":
		return dash_down
	return dash

## 检查某个动画名是否已配置（非空）
func has_anim(anim_name: StringName) -> bool:
	return anim_name != &"" and anim_name != &"<empty>"
