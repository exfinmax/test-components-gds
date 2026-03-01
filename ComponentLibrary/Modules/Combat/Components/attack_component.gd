extends CharacterComponentBase
class_name AttackComponent
## 攻击组件 - 管理攻击触发、连击、冷却、判定时机
##
## 为什么需要攻击组件？
##   你已经有了 HitBox（攻击箱），但 HitBox 只定义"碰到就造成伤害"
##   AttackComponent 管理的是"何时开启/关闭 HitBox"，也就是：
##     - 按下攻击键 → 播放攻击动画 → 动画第 3 帧开启 HitBox → 第 5 帧关闭
##     - 攻击冷却 0.5 秒才能再次攻击
##     - 连击：第一下→第二下→第三下，每段不同伤害和范围
##
## 对于跑酷游戏：
##   虽然不一定有复杂战斗，但"踩踏攻击""冲刺撞击"也需要攻击判定
##
## 使用方式：
##   1. 作为 CharacterBody2D 的子节点
##   2. 设置 hitbox（引用 HitBoxComponent）
##   3. 调用 start_attack() 或监听 InputComponent 信号
##
## 信号：
##   attack_started(attack_index) - 攻击开始
##   attack_hit(target)           - 命中目标
##   attack_ended                 - 攻击结束
##   combo_reset                  - 连击重置

signal attack_started(attack_index: int)
signal attack_hit(target: Node)
signal attack_ended
signal combo_reset

@export_group("攻击参数")
## 每段攻击的伤害值
@export var damage_per_hit: Array[float] = [5.0]
## 每段攻击的持续时间（HitBox 激活窗口）
@export var hit_durations: Array[float] = [0.15]
## 攻击冷却
@export var cooldown: float = 0.3
## 连击窗口时间（此时间内再次攻击视为连击）
@export var combo_window: float = 0.5

@export_group("依赖")
@export var hitbox: HitBoxComponent
@export var input_component: InputComponent
@export var animation_component: AnimationComponent

## 当前连击索引（0 = 第一段攻击）
var current_combo_index: int = 0
var is_attacking: bool = false
var _attack_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _combo_timer: float = 0.0
var _can_attack: bool = true
var _original_damage: float = 0.0

func _component_ready() -> void:
	if not hitbox:
		# 在 owner 的子节点中查找 HitBoxComponent
		for child in owner.get_children():
			if child is HitBoxComponent:
				hitbox = child as HitBoxComponent
				break
	
	if hitbox:
		hitbox.enabled = false
		_original_damage = hitbox.damage
		hitbox.hit_target.connect(_on_hit_target)
	
	if not input_component:
		input_component = find_component(InputComponent) as InputComponent

func _on_disable() -> void:
	_end_attack()
	_cooldown_timer = 0.0
	_combo_timer = 0.0
	current_combo_index = 0

func _physics_process(delta: float) -> void:
	if not self_driven: return
	physics_tick(delta)

func physics_tick(delta: float) -> void:
	if not enabled: return
	
	# 攻击计时
	if is_attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_end_attack()
	
	# 冷却计时
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_can_attack = true
	
	# 连击窗口计时
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_reset_combo()

## 开始攻击（外部调用或由 InputComponent 触发）
func start_attack() -> void:
	if not enabled or is_attacking or not _can_attack: return
	
	# 确定本次攻击的参数
	var hit_index := current_combo_index % damage_per_hit.size()
	var damage_value := damage_per_hit[hit_index]
	var duration := hit_durations[mini(hit_index, hit_durations.size() - 1)]
	
	# 激活攻击
	is_attacking = true
	_attack_timer = duration
	_can_attack = false
	
	if hitbox:
		hitbox.damage = damage_value
		hitbox.enabled = true
	
	attack_started.emit(current_combo_index)
	
	# 播放攻击动画
	if animation_component:
		animation_component.play_custom(&"attack_%d" % current_combo_index, AnimationComponent.Priority.HIT)

func _end_attack() -> void:
	if not is_attacking: return
	is_attacking = false
	
	if hitbox:
		hitbox.enabled = false
		hitbox.damage = _original_damage
	
	# 开始冷却
	_cooldown_timer = cooldown
	
	# 推进连击
	current_combo_index += 1
	_combo_timer = combo_window
	
	attack_ended.emit()

func _reset_combo() -> void:
	if current_combo_index > 0:
		current_combo_index = 0
		combo_reset.emit()

func _on_hit_target(target: Node) -> void:
	attack_hit.emit(target)

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"is_attacking": is_attacking,
		"can_attack": _can_attack,
		"current_combo_index": current_combo_index,
		"attack_timer": _attack_timer,
		"cooldown_timer": _cooldown_timer,
		"combo_timer": _combo_timer,
	}
