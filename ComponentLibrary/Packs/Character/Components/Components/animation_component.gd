extends CharacterComponentBase
class_name AnimationComponent
## 动画组件 - 管理角色动画播放，优先级系统
##
## 使用方式：
##   作为 CharacterBody2D 的子节点添加
##   自动发现同级的 AnimationPlayer/AnimatedSprite2D 和能力组件
##   监听能力组件信号，自动播放对应动画
##
## 设计理念：
##   能力组件（Jump、Dash、Move 等）完全不知道动画的存在
##   它们只管发射信号，AnimationComponent 负责将信号映射为动画
##   通过 AnimationConfig 资源实现逻辑名→实际动画名的解耦
##
## 优先级（高数字 = 高优先级）：
##   IDLE=0, MOVE=10, FALL=20, LAND=25, JUMP=30, WALL=35, DASH=40, HIT=50, DEATH=100
##
## 信号：
##   animation_started(anim_name, priority) - 播放新动画
##   animation_finished(anim_name)          - 动画播放完毕

signal animation_started(anim_name: StringName, priority: int)
signal animation_finished(anim_name: StringName)

#region 优先级常量

enum Priority {
	NONE   = -1,
	IDLE   = 0,
	MOVE   = 10,
	FALL   = 20,
	LAND   = 25,
	JUMP   = 30,
	WALL   = 35,
	DASH   = 40,
	HIT    = 50,
	DEATH  = 100,
}

#endregion

#region 导出

@export var config: AnimationConfig                 ## 动画名映射（拖入 .tres 资源）
@export var animation_player: AnimationPlayer       ## 手动指定（留空则自动发现）
@export var animated_sprite: AnimatedSprite2D       ## 或使用 AnimatedSprite2D（二选一）

@export_group("行为")
@export var auto_connect: bool = true               ## 自动连接同级能力组件信号
@export var transition_time: float = 0.05           ## 动画过渡混合时间（仅 AnimationPlayer）

#endregion

#region 运行状态

var current_animation: StringName = &""
var current_priority: int = Priority.NONE
var _queue: Array[Dictionary] = []   ## [{anim, priority}] 待播放队列
var _has_player: bool = false
var _has_sprite: bool = false

## 缓存的能力组件引用
var _jump_comp: JumpComponent
var _dash_comp: DashComponent
var _move_comp: MoveComponent
var _gravity_comp: GravityComponent
var _wall_comp: WallClimbComponent

#endregion

#region 生命周期

func _component_ready() -> void:
	if not config:
		config = AnimationConfig.new()
		push_warning("[AnimationComponent] 未设置 AnimationConfig，使用默认动画名")

	_discover_player()

	if auto_connect:
		_auto_connect_components()

func _discover_player() -> void:
	## 自动发现 AnimationPlayer 或 AnimatedSprite2D
	if animation_player:
		_has_player = true
	elif animated_sprite:
		_has_sprite = true
	else:
		# 在角色或 Body 节点下搜索
		var search_roots: Array[Node] = []
		if character:
			var body = character.get_node_or_null("%Body")
			if body:
				search_roots.append(body)
			search_roots.append(character)

		for root in search_roots:
			for child in root.get_children():
				if child is AnimationPlayer and not _has_player:
					animation_player = child as AnimationPlayer
					_has_player = true
				elif child is AnimatedSprite2D and not _has_sprite:
					animated_sprite = child as AnimatedSprite2D
					_has_sprite = true

	# 连接完成信号
	if _has_player:
		animation_player.animation_finished.connect(_on_animation_player_finished)
	elif _has_sprite:
		animated_sprite.animation_finished.connect(_on_animation_sprite_finished)

func _auto_connect_components() -> void:
	## 自动发现并连接同级能力组件的信号
	if not character: return

	# MoveComponent → idle / run
	_move_comp = find_component(MoveComponent) as MoveComponent
	if _move_comp:
		_move_comp.started_moving.connect(_on_started_moving)
		_move_comp.stopped_moving.connect(_on_stopped_moving)

	# JumpComponent → jump / land
	_jump_comp = find_component(JumpComponent) as JumpComponent
	if _jump_comp:
		_jump_comp.jumped.connect(_on_jumped)
		_jump_comp.landed.connect(_on_landed)

	# GravityComponent → fall
	_gravity_comp = find_component(GravityComponent) as GravityComponent
	if _gravity_comp:
		_gravity_comp.started_falling.connect(_on_started_falling)

	# DashComponent → dash
	_dash_comp = find_component(DashComponent) as DashComponent
	if _dash_comp:
		_dash_comp.dash_started.connect(_on_dash_started)
		_dash_comp.dash_ended.connect(_on_dash_ended)

	# WallClimbComponent → wall_slide / wall_jump
	_wall_comp = find_component(WallClimbComponent) as WallClimbComponent
	if _wall_comp:
		_wall_comp.wall_slide_started.connect(_on_wall_slide_started)
		_wall_comp.wall_slide_ended.connect(_on_wall_slide_ended)
		_wall_comp.wall_jumped.connect(_on_wall_jumped)

	# 初始状态
	play(config.idle, Priority.IDLE)

func _on_disable() -> void:
	# 禁用时停止动画并清空队列
	current_priority = Priority.NONE
	_queue.clear()

func _on_enable() -> void:
	# 重新启用时回退到当前合适的默认动画
	current_priority = Priority.NONE
	current_animation = &""
	_queue.clear()
	_resolve_default_animation()

func _physics_process(delta: float) -> void:
	if not self_driven: return
	physics_tick(delta)

func physics_tick(_delta: float) -> void:
	if not enabled: return
	_update_airborne_transition()

#endregion

#region 核心播放 API

## 请求播放动画（仅当优先级 >= 当前优先级时才会播放）
func play(anim_name: StringName, priority: int = Priority.IDLE, force: bool = false) -> bool:
	if not enabled: return false
	if anim_name == &"" or anim_name == &"<empty>": return false

	# 优先级不够且非强制
	if not force and priority < current_priority:
		return false

	# 相同动画且正在播放
	if anim_name == current_animation and _is_playing():
		if not force:
			return false

	# 检查动画是否存在
	if not _animation_exists(anim_name):
		return false

	_play_internal(anim_name, priority)
	return true

## 播放动画链：按顺序播放一组动画（相同优先级）
## 例如：play_chain([config.dash_begin, config.dash], Priority.DASH)
func play_chain(anim_names: Array[StringName], priority: int) -> bool:
	if anim_names.is_empty(): return false

	# 过滤掉不存在的动画
	var valid: Array[StringName] = []
	for anim in anim_names:
		if anim != &"" and _animation_exists(anim):
			valid.append(anim)

	if valid.is_empty(): return false

	# 播放第一个
	_queue.clear()
	if not play(valid[0], priority):
		return false

	# 后续入队
	for i in range(1, valid.size()):
		_queue.append({"anim": valid[i], "priority": priority})

	return true

## 强制放弃当前优先级，让低优先级动画接管
func release_priority(released_priority: int = -1) -> void:
	if released_priority < 0:
		released_priority = current_priority
	if current_priority <= released_priority:
		current_priority = Priority.NONE
		_resolve_default_animation()

## 立即停止当前动画
func stop() -> void:
	current_priority = Priority.NONE
	current_animation = &""
	_queue.clear()
	if _has_player:
		animation_player.stop()
	elif _has_sprite:
		animated_sprite.stop()

#endregion

#region 能力信号回调

func _on_started_moving() -> void:
	play(config.move, Priority.MOVE)

func _on_stopped_moving() -> void:
	if current_priority <= Priority.MOVE:
		play(config.idle, Priority.IDLE, true)

func _on_jumped() -> void:
	if config.has_anim(config.jump_start):
		play_chain([config.jump_start, config.jump_rise], Priority.JUMP)
	else:
		play(config.jump_rise, Priority.JUMP)

func _on_landed() -> void:
	if config.has_anim(config.land):
		# 落地动画播放完后自动回到 idle/move
		play(config.land, Priority.LAND, true)
	else:
		release_priority(Priority.JUMP)

func _on_started_falling() -> void:
	# 仅当不在更高优先级动画时才播放下落
	if current_priority <= Priority.FALL:
		play(config.fall, Priority.FALL)

func _on_dash_started(direction: Vector2) -> void:
	var dash_anim := config.get_dash_anim(direction)
	if config.has_anim(config.dash_begin):
		play_chain([config.dash_begin, dash_anim], Priority.DASH)
	else:
		play(dash_anim, Priority.DASH)

func _on_dash_ended() -> void:
	if config.has_anim(config.dash_end):
		play(config.dash_end, Priority.DASH)
		# dash_end 播放完后 _on_animation_finished 会 release
	else:
		release_priority(Priority.DASH)

func _on_wall_slide_started() -> void:
	play(config.wall_slide, Priority.WALL)

func _on_wall_slide_ended() -> void:
	release_priority(Priority.WALL)

func _on_wall_jumped(_direction: Vector2) -> void:
	var anim := config.wall_jump if config.has_anim(config.wall_jump) else config.jump_start
	play(anim, Priority.WALL, true)

#endregion

#region 空中状态自动过渡

func _update_airborne_transition() -> void:
	if not character: return

	# 跳跃上升 → 最高点 → 下落 的自动过渡
	if current_priority == Priority.JUMP and current_animation == config.jump_rise:
		if character.velocity.y >= 0:
			# 到达最高点，过渡到 apex 或 fall
			if config.has_anim(config.jump_apex):
				play(config.jump_apex, Priority.JUMP, true)
			else:
				play(config.fall, Priority.FALL, true)

	# apex → fall
	if current_animation == config.jump_apex:
		if character.velocity.y > 50:
			play(config.fall, Priority.FALL, true)

#endregion

#region 动画完成回调

func _on_animation_player_finished(anim_name: StringName) -> void:
	_handle_animation_finished(anim_name)

func _on_animation_sprite_finished() -> void:
	_handle_animation_finished(current_animation)

func _handle_animation_finished(anim_name: StringName) -> void:
	animation_finished.emit(anim_name)

	# 队列中有待播放动画
	if not _queue.is_empty():
		var next: Dictionary = _queue.pop_front()
		_play_internal(next["anim"], next["priority"])
		return

	# 一次性动画完成后回退
	if anim_name == config.land:
		release_priority(Priority.LAND)
	elif anim_name == config.dash_end:
		release_priority(Priority.DASH)
	elif anim_name == config.hit:
		release_priority(Priority.HIT)
	elif anim_name == config.wall_jump:
		release_priority(Priority.WALL)

#endregion

#region 内部方法

func _play_internal(anim_name: StringName, priority: int) -> void:
	current_animation = anim_name
	current_priority = priority

	if _has_player:
		if transition_time > 0 and animation_player.is_playing():
			animation_player.play(anim_name, transition_time)
		else:
			animation_player.play(anim_name)
	elif _has_sprite:
		animated_sprite.play(anim_name)

	animation_started.emit(anim_name, priority)

func _animation_exists(anim_name: StringName) -> bool:
	if _has_player:
		return animation_player.has_animation(anim_name)
	elif _has_sprite:
		return animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name)
	return false

func _is_playing() -> bool:
	if _has_player:
		return animation_player.is_playing()
	elif _has_sprite:
		return animated_sprite.is_playing()
	return false

## 根据当前角色状态回退到合适的默认动画
func _resolve_default_animation() -> void:
	if not character: return

	# 空中
	if not character.is_on_floor():
		if character.velocity.y < 0:
			play(config.jump_rise, Priority.JUMP)
		else:
			play(config.fall, Priority.FALL)
		return

	# 地面
	if _move_comp and _move_comp.is_moving:
		play(config.move, Priority.MOVE)
	else:
		play(config.idle, Priority.IDLE)

#endregion

#region 外部控制 API（给非能力组件使用，如受击、死亡）

## 播放受击动画
func play_hit() -> void:
	play(config.hit, Priority.HIT, true)

## 播放死亡动画
func play_death() -> void:
	play(config.death, Priority.DEATH, true)

## 播放自定义动画（直接指定动画名和优先级）
func play_custom(anim_name: StringName, priority: int = Priority.HIT) -> bool:
	return play(anim_name, priority, true)

#endregion

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"current_animation": current_animation,
		"current_priority": Priority.keys()[clampi(current_priority + 1, 0, Priority.size() - 1)] if current_priority >= 0 else "NONE",
		"current_priority_value": current_priority,
		"is_playing": _is_playing(),
		"queue_size": _queue.size(),
		"has_animation_player": _has_player,
		"has_animated_sprite": _has_sprite,
		"auto_connect": auto_connect,
		"connected_components": _get_connected_component_names(),
	}

func _get_connected_component_names() -> Array[String]:
	var names: Array[String] = []
	if _move_comp: names.append("MoveComponent")
	if _jump_comp: names.append("JumpComponent")
	if _gravity_comp: names.append("GravityComponent")
	if _dash_comp: names.append("DashComponent")
	if _wall_comp: names.append("WallClimbComponent")
	return names
