extends CharacterComponent
class_name EnemyComponent
## 组件版回放敌人 - 薄编排层
##
## 职责：配置 RecordComponent/ReplayComponent 的接线 + 死亡处理
## 回放生命周期（延迟、外观淡入、帧消费）全部由 ReplayComponent 管理
##
## 场景结构：
##   CharacterBody2D (enemy_component.gd)
##     ├── Body (%Body)
##     │   ├── Sprite2D
##     │   └── HealthComponent (%HealthComponent)
##     ├── CollisionShape2D
##     ├── AnimationPlayer
##     ├── InputComponent       (self_driven=false, source=AI)
##     ├── GravityComponent     (self_driven=false)
##     ├── MoveComponent        (self_driven=false)
##     ├── JumpComponent        (self_driven=false)
##     ├── DashComponent        (self_driven=false)
##     ├── AnimationComponent   (self_driven=false)
##     ├── RecordComponent      (录制目标玩家)
##     └── ReplayComponent      (回放驱动自身，自管理延迟/外观)

signal died
signal replay_started
signal replay_finished

@export_category("回放设置")
@export var player_target: CharacterBody2D            ## 录制目标（拖入玩家）
@export var auto_start: bool = false                  ## 是否自动开始

@onready var canying_component: CanyingComponent = get_node_or_null("%CanyingComponent")

var is_dead: bool = false

## 缓存组件引用
var _record_comp: RecordComponent
var _replay_comp: ReplayComponent
var _input_comp: InputComponent

func _ready() -> void:
	# 缓存组件
	_input_comp = get_component(InputComponent) as InputComponent
	if _input_comp:
		_input_comp.input_source = InputComponent.InputSource.AI

	_record_comp = get_node_or_null("%RecordComponent")
	_replay_comp = get_node_or_null("%ReplayComponent")

	# 配置 RecordComponent
	if _record_comp and player_target:
		_record_comp.target = player_target

	# 转发 ReplayComponent 信号
	if _replay_comp:
		_replay_comp.replay_started.connect(func(): replay_started.emit())
		_replay_comp.replay_ended.connect(func(): replay_finished.emit())
		_replay_comp.about_to_appear.connect(_on_about_to_appear)
	
	# 残影连接到 ReplayComponent 的动作信号（INPUT / PATH 模式通用）
	if canying_component and _replay_comp:
		_replay_comp.action_dash_started.connect(_on_dash_start)
		_replay_comp.action_dash_ended.connect(_on_dash_end)
	
	# 连接 HealthComponent
	var health := get_node_or_null("%HealthComponent") as HealthComponent
	if health:
		health.died.connect(_on_died)

	if auto_start:
		start()

func _on_dash_start(_dash_direction: Vector2) -> void:
	canying_component.set_enable(true)

func _on_dash_end() -> void:
	canying_component.set_enable(false)

func start() -> void:
	## 开始录制 — ReplayComponent 自动在 delay_seconds 后开始消费帧并出现
	if _record_comp:
		_record_comp.start_recording()

func _on_about_to_appear() -> void:
	## 出现时从玩家当前位置出生
	if player_target:
		global_position = player_target.global_position

func stop() -> void:
	if _record_comp:
		_record_comp.stop_recording()
	if _replay_comp:
		_replay_comp.enabled = false

#region 死亡

func _on_died() -> void:
	if is_dead: return
	is_dead = true
	stop()
	freeze()
	died.emit()

func die() -> void:
	var health := get_node_or_null("%HealthComponent") as HealthComponent
	if health:
		health.damage(health.max_health)
	else:
		_on_died()

#endregion

func get_component_data() -> Dictionary:
	return get_all_component_data().merged({
		"is_dead": is_dead,
		"heading": heading,
		"velocity": velocity,
	})
