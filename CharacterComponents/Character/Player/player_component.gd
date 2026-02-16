extends CharacterComponent
class_name PlayerComponent
## 组件版玩家 - 使用 CharacterComponents 系统
##
## 与状态机版的区别：
##   - 没有 StateMachine，所有能力由独立组件实现
##   - 组件 self_driven=false，由 Character 统一驱动 delta
##   - 支持时间免疫：重写 _get_physics_delta 传入补偿 delta
##
## 场景结构：
##   CharacterBody2D (player_component.gd)
##     ├── Body (%Body)
##     │   ├── Sprite2D
##     │   ├── HealthComponent (%HealthComponent)
##     │   └── HurtboxComponent
##     ├── CollisionShape2D
##     ├── AnimationPlayer
##     ├── InputComponent       (self_driven=false)
##     ├── GravityComponent     (self_driven=false)
##     ├── MoveComponent        (self_driven=false)
##     ├── JumpComponent        (self_driven=false)
##     ├── DashComponent        (self_driven=false)
##     ├── WallClimbComponent   (self_driven=false)
##     └── AnimationComponent   (self_driven=false)

signal died

@onready var canying_component: CanyingComponent = get_node_or_null("%CanyingComponent")
## 是否已死亡
var is_dead: bool = false

#region 生命周期

func _ready() -> void:
	if canying_component:
		var dash_component = get_component(DashComponent) as DashComponent
		dash_component.dash_started.connect(_on_dash_start)
		dash_component.dash_ended.connect(_on_dash_end)
	
	# 连接 HealthComponent 死亡信号
	var health := get_node_or_null("%HealthComponent") as HealthComponent
	if health:
		health.died.connect(_on_died)

#endregion

func _on_dash_start(_dash_direction: Vector2) -> void:
	canying_component.set_enable(true)

func _on_dash_end() -> void:
	canying_component.set_enable(false)

#region 死亡

func _on_died() -> void:
	if is_dead: return
	is_dead = true
	freeze()
	died.emit()

func die() -> void:
	## 外部调用死亡（如掉入深渊）
	var health := get_node_or_null("%HealthComponent") as HealthComponent
	if health:
		health.damage(health.max_health)
	else:
		_on_died()

func reset_death() -> void:
	is_dead = false
	set_paused(false)

#endregion

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_1 && event.pressed && event.is_echo() == false:
			if TimeController.engine_time_scale == 2:
				TimeController.engine_time_scale = 1
				print(Engine.time_scale)
			else:
				TimeController.engine_time_scale = 2
				print(Engine.time_scale)

func get_component_data() -> Dictionary:
	return get_all_component_data().merged({
		"is_dead": is_dead,
		"time_immune": time_immune,
		"heading": heading,
		"velocity": velocity,
		"is_on_floor": is_on_floor(),
	})
