extends CharacterComponentBase
class_name WallClimbComponent
## 爬墙/滑墙组件 - 管理贴墙滑行和蹬墙跳
##
## 使用方式：
##   作为 CharacterBody2D 的子节点添加
##   需要 InputComponent、GravityComponent、JumpComponent
##   角色需要有墙壁碰撞检测（is_on_wall）
##
## 信号：
##   wall_slide_started - 开始贴墙滑行
##   wall_slide_ended - 结束贴墙滑行
##   wall_jumped(direction) - 蹬墙跳

signal wall_slide_started
signal wall_slide_ended
signal wall_jumped(direction: Vector2)

@export_group("滑墙参数")
@export var wall_slide_speed: float = 80.0     ## 贴墙下滑速度
@export var wall_slide_gravity: float = 200.0  ## 贴墙时的重力

@export_group("蹬墙跳参数")
@export var wall_jump_speed: Vector2 = Vector2(350.0, 450.0)  ## (水平速度, 垂直速度)
@export var wall_jump_lock_time: float = 0.15  ## 蹬墙跳后锁定输入的时间

@export_group("依赖")
@export var input_component: InputComponent
@export var gravity_component: GravityComponent
@export var move_component: MoveComponent

## 状态
var is_wall_sliding: bool = false
var wall_normal: Vector2 = Vector2.ZERO
var _wall_jump_lock_timer: float = 0.0

func _component_ready() -> void:
	if not input_component:
		input_component = find_component(InputComponent) as InputComponent
	if not gravity_component:
		gravity_component = find_component(GravityComponent) as GravityComponent
	if not move_component:
		move_component = find_component(MoveComponent) as MoveComponent

	if input_component:
		input_component.jump_pressed.connect(_on_jump_pressed)

func _on_disable() -> void:
	# 禁用时如果正在贴墙，结束滑墙状态
	if is_wall_sliding:
		is_wall_sliding = false
		wall_slide_ended.emit()
	# 清理蹬墙跳锁定，恢复移动组件
	if _wall_jump_lock_timer > 0.0:
		_wall_jump_lock_timer = 0.0
		if move_component:
			move_component.enabled = true

func _on_enable() -> void:
	wall_normal = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not self_driven: return
	physics_tick(delta)

func physics_tick(delta: float) -> void:
	if not enabled or not character: return

	# 蹬墙跳输入锁定倒计时
	if _wall_jump_lock_timer > 0.0:
		_wall_jump_lock_timer -= delta
		if _wall_jump_lock_timer <= 0.0 and move_component:
			move_component.enabled = true

	var was_sliding := is_wall_sliding
	is_wall_sliding = _check_wall_slide()

	if is_wall_sliding:
		_apply_wall_slide(delta)
		if not was_sliding:
			wall_slide_started.emit()
	elif was_sliding:
		wall_slide_ended.emit()

func _check_wall_slide() -> bool:
	if not character.is_on_wall(): return false
	if character.is_on_floor(): return false
	if character.velocity.y < 0: return false  # 上升中不贴墙

	# 检查玩家是否朝墙壁方向输入
	if input_component:
		wall_normal = character.get_wall_normal()
		var input_dir := input_component.get_direction()
		# 输入方向与墙壁法线相反（朝墙推）才触发
		if input_dir.dot(wall_normal) < -0.1:
			return true
	return false

func _apply_wall_slide(delta: float) -> void:
	# 贴墙滑行：降低下落速度
	character.velocity.y = minf(character.velocity.y + wall_slide_gravity * delta, wall_slide_speed)

	# 覆盖重力组件的效果
	if gravity_component:
		# 不需要完全禁用，只是限制了最大下落速度
		pass

func _on_jump_pressed() -> void:
	if not enabled or not is_wall_sliding: return
	_execute_wall_jump()

func _execute_wall_jump() -> void:
	is_wall_sliding = false
	wall_slide_ended.emit()

	# 蹬墙跳：沿墙壁法线方向弹出
	character.velocity.x = wall_normal.x * wall_jump_speed.x
	character.velocity.y = -wall_jump_speed.y

	# 锁定移动输入，防止立即贴回墙上
	if move_component:
		move_component.enabled = false
	_wall_jump_lock_timer = wall_jump_lock_time

	wall_jumped.emit(wall_normal)

	if input_component:
		input_component.consume_buffered_input("jump")

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"is_wall_sliding": is_wall_sliding,
		"wall_normal": wall_normal,
		"wall_slide_speed": wall_slide_speed,
		"wall_jump_speed": wall_jump_speed,
		"wall_jump_lock_remaining": _wall_jump_lock_timer,
	}
