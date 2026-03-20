extends TextureRect
class_name HumanTexture

enum ActionType {
	MOVE_HORIZONTAL,# 水平移动（正数右，负数左）
	MOVE_VERTICAL,  # 竖直移动（正数下，负数上）
	JUMP,           # 跳跃
	SHAKE,          # 抖动
	SCALE,          # 放缩
	FLIP_HORIZONTAL,# 水平翻转（左右反向）
}

@export var lihui_resource: LiHui
@export_group("LiHui Settings")
@export var lihui_fade_duration: float = 0.1
@export var lihui_fade_trans: Tween.TransitionType = Tween.TRANS_SINE
@export var lihui_fade_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("Movement Settings")
@export var move_distance: float = 100.0
@export var move_duration: float = 0.3
@export var move_trans: Tween.TransitionType = Tween.TRANS_CUBIC
@export var move_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("Jump Settings")
@export var jump_height: float = 50.0
@export var jump_duration: float = 0.5
@export var jump_trans: Tween.TransitionType = Tween.TRANS_QUAD
@export var jump_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("Shake Settings")
@export var shake_distance: float = 20.0
@export var shake_duration: float = 0.5
@export var shake_frequency: int = 10

@export_group("Scale Settings")
@export var scale_factor: float = 1.2
@export var scale_duration: float = 0.3
@export var scale_trans: Tween.TransitionType = Tween.TRANS_CUBIC
@export var scale_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("Flip Settings")
@export var flip_duration: float = 0.3
@export var flip_trans: Tween.TransitionType = Tween.TRANS_CUBIC
@export var flip_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("Focus Settings")
@export var focused_scale: float = 1.1
@export var unfocused_scale: float = 0.6
@export var focused_alpha: float = 1.0
@export var unfocused_alpha: float = 0.6
@export var focus_duration: float = 0.3
@export var focus_trans: Tween.TransitionType = Tween.TRANS_CUBIC
@export var focus_ease: Tween.EaseType = Tween.EASE_OUT

var _original_position: Vector2
var _origin_scale:Vector2


func _ready() -> void:
	_origin_scale = scale
	_original_position = position
	pivot_offset = size/2
	# 监听对话行变化信号，自动更新焦点
	if lihui_resource and lihui_resource.sprites.has("ax"):
		texture = lihui_resource.sprites["ax"]


func get_character_name() -> String:
	if lihui_resource != null:
		return lihui_resource.character_name
	return ""


func play_action(action: ActionType, ...arg: Array) -> void:
	"""播放指定动作，await 等待完成
	可变参数说明：
	- MOVE_HORIZONTAL: [distance (正数右，负数左), duration, trans, ease]
	- MOVE_VERTICAL: [distance (正数下，负数上), duration, trans, ease]
	- JUMP: [height, duration, trans, ease]
	- SHAKE: [distance, duration, frequency]
	- SCALE: [factor, duration, trans, ease]
	- FLIP_HORIZONTAL: [duration, trans, ease]
	"""
	match action:
		ActionType.MOVE_HORIZONTAL:
			await _move_horizontal(arg)
		ActionType.MOVE_VERTICAL:
			await _move_vertical(arg)
		ActionType.JUMP:
			await _jump(arg)
		ActionType.SHAKE:
			await _shake(arg)
		ActionType.SCALE:
			await _scale_action(arg)
		ActionType.FLIP_HORIZONTAL:
			await _flip_horizontal(arg)


func _move_horizontal(arg: Array) -> void:
	var distance = arg[0] if arg.size() > 0 else move_distance
	var duration = arg[1] if arg.size() > 1 else move_duration
	var trans = arg[2] if arg.size() > 2 else move_trans
	var ease = arg[3] if arg.size() > 3 else move_ease
	
	var tween := create_tween()
	tween.tween_property(self, "position:x", _original_position.x + distance, duration).set_trans(trans).set_ease(ease)
	await tween.finished


func _move_vertical(arg: Array) -> void:
	var distance = arg[0] if arg.size() > 0 else move_distance
	var duration = arg[1] if arg.size() > 1 else move_duration
	var trans = arg[2] if arg.size() > 2 else move_trans
	var ease = arg[3] if arg.size() > 3 else move_ease
	
	var tween := create_tween()
	tween.tween_property(self, "position:y", _original_position.y + distance, duration).set_trans(trans).set_ease(ease)
	await tween.finished


func _jump(arg: Array) -> void:
	var height = arg[0] if arg.size() > 0 else jump_height
	var duration = arg[1] if arg.size() > 1 else jump_duration
	var trans = arg[2] if arg.size() > 2 else jump_trans
	var ease = arg[3] if arg.size() > 3 else jump_ease
	
	var tween := create_tween()
	tween.tween_property(self, "position:y", _original_position.y - height, duration / 2).set_trans(trans).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", _original_position.y, duration / 2).set_trans(trans).set_ease(Tween.EASE_IN)
	await tween.finished


func _shake(arg: Array) -> void:
	var distance = arg[0] if arg.size() > 0 else shake_distance
	var duration = arg[1] if arg.size() > 1 else shake_duration
	var frequency = arg[2] if arg.size() > 2 else shake_frequency
	
	var shake_count = int(duration * frequency)
	var single_duration = duration / shake_count
	var tween := create_tween()

	for i in shake_count:
		var offset = Vector2(randf_range(-distance, distance), randf_range(-distance, distance))
		tween.tween_property(self, "position", _original_position + offset, single_duration)
	
	tween.tween_property(self, "position", _original_position, single_duration)
	await tween.finished


func _scale_action(arg: Array) -> void:
	var factor = arg[0] if arg.size() > 0 else scale_factor
	var duration = arg[1] if arg.size() > 1 else scale_duration
	var trans = arg[2] if arg.size() > 2 else scale_trans
	var ease = arg[3] if arg.size() > 3 else scale_ease

	var tween := create_tween()
	tween.tween_property(self, "scale", _origin_scale * factor, duration).set_trans(trans).set_ease(ease)
	_origin_scale = _origin_scale * factor
	await tween.finished


func _flip_horizontal(arg: Array) -> void:
	var duration = arg[0] if arg.size() > 0 else flip_duration
	var trans = arg[1] if arg.size() > 1 else flip_trans
	var ease = arg[2] if arg.size() > 2 else flip_ease
	
	var new_scale_x = -scale.x
	var tween := create_tween()
	tween.tween_property(self, "scale:x", new_scale_x, duration).set_trans(trans).set_ease(ease)
	await tween.finished




func switch_lihui_resource(new_resource: LiHui, default_key: String = "ax") -> void:
	"""切换立绘资源，淡出旧图 → 替换纹理 → 淡入新图"""
	if new_resource == null:
		return
	
	# 检查目标表情是否存在
	var target_key := default_key
	if new_resource.has_method("has_expression"):
		if not new_resource.has_expression(default_key):
			# 尝试使用资源的默认表情
			if new_resource.has_method("get") and new_resource.get("default_expression") != null:
				target_key = new_resource.default_expression
			else:
				return
	elif not new_resource.sprites.has(default_key):
		return
	
	# 淡出
	var tween_out := create_tween()
	tween_out.tween_property(self, "modulate:a", 0.0, lihui_fade_duration).set_trans(lihui_fade_trans).set_ease(lihui_fade_ease)
	await tween_out.finished

	lihui_resource = new_resource
	texture = lihui_resource.sprites[target_key]

	# 淡入
	var tween_in := create_tween()
	tween_in.tween_property(self, "modulate:a", 1.0, lihui_fade_duration).set_trans(lihui_fade_trans).set_ease(lihui_fade_ease)
	await tween_in.finished


func set_focus(is_speaking: bool, ...arg: Array) -> void:
	"""根据是否正在说话设置焦点状态（带 Tween 动画）
	is_speaking: 是否为当前说话角色
	可变参数说明：
	- [duration, trans, ease, focused_scale, unfocused_scale, focused_alpha, unfocused_alpha]
	"""
	var duration = arg[0] if arg.size() > 0 else focus_duration
	var trans = arg[1] if arg.size() > 1 else focus_trans
	var ease = arg[2] if arg.size() > 2 else focus_ease
	var f_scale = arg[3] if arg.size() > 3 else focused_scale
	var uf_scale = arg[4] if arg.size() > 4 else unfocused_scale
	var f_alpha = arg[5] if arg.size() > 5 else focused_alpha
	var uf_alpha = arg[6] if arg.size() > 6 else unfocused_alpha
	
	var tween := create_tween().set_parallel(true)
	
	if is_speaking:
		tween.tween_property(self, "scale", _origin_scale * f_scale, duration).set_trans(trans).set_ease(ease)
		tween.tween_property(self, "modulate:a", f_alpha, duration).set_trans(trans).set_ease(ease)
		z_index = 100
	else:
		tween.tween_property(self, "scale", _origin_scale * uf_scale, duration).set_trans(trans).set_ease(ease)
		tween.tween_property(self, "modulate:a", uf_alpha, duration).set_trans(trans).set_ease(ease)
		z_index = 0


func play_action_sequence(actions: Array) -> void:
	"""按顺序执行动作序列
	actions: Array[Dictionary]，每个字典包含 type (ActionType) 和 args (Array)
	示例：[{"type": ActionType.JUMP, "args": [50, 0.5]}, {"type": ActionType.SHAKE}]
	"""
	for action_dict in actions:
		var action_type: int = action_dict.get("type", ActionType.MOVE_HORIZONTAL)
		var args: Array = action_dict.get("args", [])
		await play_action(action_type, args)


func reset_all() -> void:
	"""重置位置、缩放、透明度为初始值"""
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", _original_position, move_duration).set_trans(move_trans).set_ease(move_ease)
	tween.tween_property(self, "scale", _origin_scale, scale_duration).set_trans(scale_trans).set_ease(scale_ease)
	tween.tween_property(self, "modulate:a", 1.0, focus_duration).set_trans(focus_trans).set_ease(focus_ease)
	z_index = 0
	await tween.finished




func reset_position(arg: Array = []) -> void:
	"""重置到初始位置
	可变参数说明：
	- [duration, trans, ease]
	"""
	var duration = arg[0] if arg.size() > 0 else move_duration
	var trans = arg[1] if arg.size() > 1 else move_trans
	var ease = arg[2] if arg.size() > 2 else move_ease
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:x", _original_position.x, duration).set_trans(trans).set_ease(ease)
	tween.tween_property(self, "position:y", _original_position.y, duration).set_trans(trans).set_ease(ease)
	await tween.finished
