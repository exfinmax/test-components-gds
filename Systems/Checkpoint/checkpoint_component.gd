extends Area2D
class_name CheckpointComponent
## 检查点组件 - 跑酷游戏的存档点/重生点
##
## 为什么需要检查点？
##   跑酷游戏最核心的循环：
##     跑 → 死 → 从检查点重生 → 再跑
##   没有检查点，死了就要从头开始，玩家会摔手柄
##
##   检查点本质上就是"记录一个安全位置"
##   当玩家死亡时，传送回这个位置
##
## 使用方式：
##   1. 创建 Area2D 场景，添加 CollisionShape2D
##   2. 挂载此脚本
##   3. 玩家进入区域时自动激活（或手动调用 activate）
##   4. 通过 EventBus 或 CheckpointManager 查询最新检查点
##
## 信号：
##   activated(checkpoint) - 此检查点被激活
##   
## 全局查询：
##   CheckpointComponent.last_checkpoint  → 最新激活的检查点
##   CheckpointComponent.respawn_position → 重生位置

signal activated(checkpoint: CheckpointComponent)

## 重生位置（相对于检查点的偏移）
@export var respawn_offset: Vector2 = Vector2(0, -16)

## 是否自动激活（玩家进入区域时）
@export var auto_activate: bool = true

## 激活后的视觉反馈
@export var activate_animation: String = ""
@export var activate_color: Color = Color.GREEN

## 是否已激活
var is_activated: bool = false

## 激活顺序（用于确定最新检查点）
var activation_order: int = 0

## ——— 静态全局状态 ———
## 最后激活的检查点
static var last_checkpoint: CheckpointComponent = null
## 全局激活计数器
static var _global_order: int = 0

## 获取重生位置
static var respawn_position: Vector2:
	get:
		if last_checkpoint:
			return last_checkpoint.global_position + last_checkpoint.respawn_offset
		return Vector2.ZERO

## 所有已注册的检查点
static var _all_checkpoints: Array[CheckpointComponent] = []

func _ready() -> void:
	_all_checkpoints.append(self)
	
	# 设置碰撞
	monitoring = true
	monitorable = false
	
	if auto_activate:
		body_entered.connect(_on_body_entered)

func _exit_tree() -> void:
	_all_checkpoints.erase(self)
	if last_checkpoint == self:
		last_checkpoint = null

#region 激活

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not is_activated:
		activate()

## 手动激活此检查点
func activate() -> void:
	if is_activated: return
	
	is_activated = true
	_global_order += 1
	activation_order = _global_order
	last_checkpoint = self
	
	# 视觉反馈
	modulate = activate_color
	if activate_animation != "" and has_node("AnimationPlayer"):
		get_node("AnimationPlayer").play(activate_animation)
	
	activated.emit(self)
	
	# 通知 EventBus（如果存在）
	if Engine.has_singleton("EventBus") or has_node("/root/EventBus"):
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.player_checkpoint_reached.emit({
				"position": global_position,
				"respawn_position": global_position + respawn_offset,
				"checkpoint": self,
			})

## 重置此检查点
func deactivate() -> void:
	is_activated = false
	modulate = Color.WHITE

#endregion

#region 静态工具方法

## 重置所有检查点
static func reset_all() -> void:
	for cp in _all_checkpoints:
		if is_instance_valid(cp):
			cp.deactivate()
	last_checkpoint = null
	_global_order = 0

## 获取所有已激活的检查点
static func get_activated_checkpoints() -> Array[CheckpointComponent]:
	var result: Array[CheckpointComponent] = []
	for cp in _all_checkpoints:
		if is_instance_valid(cp) and cp.is_activated:
			result.append(cp)
	return result

#endregion

#region 调试

func get_component_data() -> Dictionary:
	return {
		"type": "CheckpointComponent",
		"is_activated": is_activated,
		"activation_order": activation_order,
		"respawn_position": global_position + respawn_offset,
		"is_last": last_checkpoint == self,
	}

#endregion
