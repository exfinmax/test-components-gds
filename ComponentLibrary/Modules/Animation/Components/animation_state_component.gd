## AnimationStateComponent — 动画状态机组件
## 
## 将 AnimationPlayer 封装成状态机，管理动画状态转换、过渡和事件。
## 可独立于 CharacterBody2D 使用，适合任何带 AnimationPlayer 的场景节点。
## 
## 特性：
## - 注册具名动画状态（支持循环/单次）
## - 条件驱动的自动状态转换
## - 状态进入/退出信号
## - 可选硬切换或过渡（blend_time）
## 
## 使用示例：
##   var asc = AnimationStateComponent.new()
##   asc.register_state(&"idle",  "idle_anim",  true)
##   asc.register_state(&"run",   "run_anim",   true)
##   asc.add_auto_transition(&"idle", &"run",  func(): return speed > 10.0)
##   asc.add_auto_transition(&"run",  &"idle", func(): return speed <= 10.0)
##   asc.animation_player = $AnimationPlayer
##   asc.start(&"idle")

extends Node
class_name AnimationStateComponent

# ── 信号 ─────────────────────────────────────────────────────────────
signal state_changed(old_state: StringName, new_state: StringName)
signal animation_finished(state_id: StringName)

# ── 内嵌数据类 ────────────────────────────────────────────────────────
class AnimState:
	var id:       StringName
	var anim:     StringName
	var loop:     bool
	func _init(p_id: StringName, p_anim: StringName, p_loop: bool) -> void:
		id   = p_id
		anim = p_anim
		loop = p_loop

class AutoTransition:
	var from:      StringName
	var to:        StringName
	var condition: Callable
	func _init(p_from: StringName, p_to: StringName, p_cond: Callable) -> void:
		from      = p_from
		to        = p_to
		condition = p_cond

# ── 导出属性 ──────────────────────────────────────────────────────────
## AnimationPlayer 节点路径（可选；若未设置则只做状态追踪，不实际播放动画）
@export var animation_player_path: NodePath = NodePath("")
## 状态切换时使用的默认过渡时长（秒）
@export var default_blend_time: float = 0.1

# ── 内部状态 ──────────────────────────────────────────────────────────
var _states:       Dictionary = {}        ## StringName → AnimState
var _transitions:  Array      = []        ## Array[AutoTransition]
var _current:      StringName = &""
var _player:       AnimationPlayer        = null
var _check_auto:   bool       = false

# ── 生命周期 ──────────────────────────────────────────────────────────
func _ready() -> void:
	if animation_player_path and not animation_player_path.is_empty():
		_player = get_node_or_null(animation_player_path)
		if _player:
			_player.animation_finished.connect(_on_anim_finished)

func _process(_delta: float) -> void:
	if not _check_auto:
		return
	for t: AutoTransition in _transitions:
		if t.from == _current and t.condition.call():
			transition_to(t.to)
			break

# ── 公共 API ──────────────────────────────────────────────────────────

## 注册一个动画状态
## @param state_id   状态唯一标识
## @param anim_name  对应 AnimationPlayer 中的动画名称
## @param loop       是否循环
func register_state(state_id: StringName, anim_name: StringName, loop: bool = true) -> void:
	_states[state_id] = AnimState.new(state_id, anim_name, loop)

## 添加自动转换规则（每帧检查 condition）
func add_auto_transition(from: StringName, to: StringName, condition: Callable) -> void:
	_transitions.append(AutoTransition.new(from, to, condition))

## 启动状态机并进入初始状态
func start(initial_state: StringName) -> void:
	_check_auto = true
	transition_to(initial_state, 0.0)

## 停止自动检测（冻结当前状态）
func stop() -> void:
	_check_auto = false

## 强制切换到指定状态
## @param blend   覆盖 default_blend_time；传 -1 使用默认值
func transition_to(state_id: StringName, blend: float = -1.0) -> void:
	if not _states.has(state_id):
		push_warning("AnimationStateComponent: unknown state '%s'" % state_id)
		return
	if state_id == _current:
		return

	var old := _current
	_current           = state_id
	var st: AnimState  = _states[state_id]
	state_changed.emit(old, state_id)

	if _player:
		var bt := default_blend_time if blend < 0.0 else blend
		if st.loop:
			_player.play(st.anim, bt)
		else:
			_player.play(st.anim, bt)

## 返回当前状态 ID
func get_current_state() -> StringName:
	return _current

## 查询某状态是否已注册
func has_state(state_id: StringName) -> bool:
	return _states.has(state_id)

# ── 私有回调 ────────────────────────────────────────────────────────
func _on_anim_finished(anim_name: StringName) -> void:
	for st: AnimState in _states.values():
		if st.anim == anim_name:
			animation_finished.emit(st.id)
			break
