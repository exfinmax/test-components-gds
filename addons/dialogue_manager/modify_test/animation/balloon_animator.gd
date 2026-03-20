class_name BalloonAnimator
extends RefCounted
## 气球动画控制器
## 支持 scale、fade、slide 四方向、pop 等动画类型

enum AnimType {
	SCALE,
	FADE,
	SLIDE_UP,
	SLIDE_DOWN,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	POP,
	NONE
}

enum AnimState {
	IDLE,
	SHOWING,
	HIDING
}

class AnimConfig extends RefCounted:
	var anim_type: int = AnimType.SCALE
	var duration: float = 0.3
	var delay: float = 0.0
	var transition_type: int = Tween.TRANS_QUAD
	var ease_type: int = Tween.EASE_OUT
	var scale_from: Vector2 = Vector2(0.0, 0.0)
	var fade_from: float = 0.0
	var fade_to: float = 1.0
	var pop_scale: float = 1.1
	var pop_bounce: float = 0.95
	var slide_distance: float = 300.0

var _state: int = AnimState.IDLE
var _tweens: Array[Tween] = []
var _nodes: Array[Control] = []

signal animation_started(anim_type: int)
signal animation_completed(anim_type: int)

func create_show_animation(nodes: Array, config: AnimConfig = null) -> void:
	if config == null:
		config = AnimConfig.new()
	
	_state = AnimState.SHOWING
	_kill_all_tweens()
	_nodes.clear()
	
	for node in nodes:
		if is_instance_valid(node) and node is Control:
			_nodes.append(node)
	
	_play_show(config)
	animation_started.emit(config.anim_type)

func create_hide_animation(nodes: Array, config: AnimConfig = null) -> void:
	if config == null:
		config = AnimConfig.new()
		config.ease_type = Tween.EASE_IN
	
	_state = AnimState.HIDING
	_kill_all_tweens()
	_nodes.clear()
	
	for node in nodes:
		if is_instance_valid(node) and node is Control:
			_nodes.append(node)
	
	_play_hide(config)
	animation_started.emit(config.anim_type)

func _play_show(config: AnimConfig) -> void:
	for i in _nodes.size():
		var node := _nodes[i]
		var tween := node.create_tween()
		_tweens.append(tween)
		
		if config.delay > 0 and i > 0:
			tween.tween_interval(config.delay * i)
		
		match config.anim_type:
			AnimType.SCALE:
				_do_scale_in(node, tween, config)
			AnimType.FADE:
				_do_fade_in(node, tween, config)
			AnimType.SLIDE_UP, AnimType.SLIDE_DOWN, AnimType.SLIDE_LEFT, AnimType.SLIDE_RIGHT:
				_do_slide_in(node, tween, config)
			AnimType.POP:
				_do_pop_in(node, tween, config)
			AnimType.NONE:
				node.show()
	
	if config.anim_type != AnimType.NONE and _tweens.size() > 0:
		await _tweens[_tweens.size() - 1].finished
	
	_state = AnimState.IDLE
	animation_completed.emit(config.anim_type)

func _play_hide(config: AnimConfig) -> void:
	for node in _nodes:
		var tween := node.create_tween()
		_tweens.append(tween)
		
		match config.anim_type:
			AnimType.SCALE:
				_do_scale_out(node, tween, config)
			AnimType.FADE:
				_do_fade_out(node, tween, config)
			AnimType.SLIDE_UP, AnimType.SLIDE_DOWN, AnimType.SLIDE_LEFT, AnimType.SLIDE_RIGHT:
				_do_slide_out(node, tween, config)
			AnimType.POP:
				_do_pop_out(node, tween, config)
			AnimType.NONE:
				node.hide()
	
	if config.anim_type != AnimType.NONE and _tweens.size() > 0:
		await _tweens[0].finished
	
	_state = AnimState.IDLE
	animation_completed.emit(config.anim_type)

func _do_scale_in(node: Control, tween: Tween, config: AnimConfig) -> void:
	_setup_pivot(node)
	node.scale = config.scale_from
	node.modulate.a = config.fade_from
	node.show()
	
	tween.set_trans(config.transition_type).set_ease(config.ease_type)
	tween.tween_property(node, "scale", Vector2.ONE, config.duration)
	tween.parallel().tween_property(node, "modulate:a", config.fade_to, config.duration)
	tween.tween_callback(func(): _reset_pivot(node))

func _do_scale_out(node: Control, tween: Tween, config: AnimConfig) -> void:
	_setup_pivot(node)
	
	tween.set_trans(config.transition_type).set_ease(config.ease_type)
	tween.tween_property(node, "scale", config.scale_from, config.duration)
	tween.parallel().tween_property(node, "modulate:a", config.fade_from, config.duration)
	tween.tween_callback(func():
		node.hide()
		node.scale = Vector2.ONE
		node.modulate.a = config.fade_to
		_reset_pivot(node)
	)

func _do_fade_in(node: Control, tween: Tween, config: AnimConfig) -> void:
	node.modulate.a = config.fade_from
	node.show()
	
	tween.set_trans(config.transition_type).set_ease(config.ease_type)
	tween.tween_property(node, "modulate:a", config.fade_to, config.duration)

func _do_fade_out(node: Control, tween: Tween, config: AnimConfig) -> void:
	tween.set_trans(config.transition_type).set_ease(config.ease_type)
	tween.tween_property(node, "modulate:a", config.fade_from, config.duration)
	tween.tween_callback(func():
		node.hide()
		node.modulate.a = config.fade_to
	)

func _do_slide_in(node: Control, tween: Tween, config: AnimConfig) -> void:
	var offset := _get_slide_offset(config.anim_type, config.slide_distance, true)
	
	node.modulate.a = config.fade_from
	node.offset_left = offset.x
	node.offset_top = offset.y
	node.show()
	
	tween.set_trans(config.transition_type).set_ease(config.ease_type)
	if offset.x != 0:
		tween.tween_property(node, "offset_left", 0.0, config.duration)
	if offset.y != 0:
		tween.parallel().tween_property(node, "offset_top", 0.0, config.duration)
	tween.parallel().tween_property(node, "modulate:a", config.fade_to, config.duration)

func _do_slide_out(node: Control, tween: Tween, config: AnimConfig) -> void:
	var offset := _get_slide_offset(config.anim_type, config.slide_distance, false)
	
	tween.set_trans(config.transition_type).set_ease(config.ease_type)
	if offset.x != 0:
		tween.tween_property(node, "offset_left", offset.x, config.duration)
	if offset.y != 0:
		tween.parallel().tween_property(node, "offset_top", offset.y, config.duration)
	tween.parallel().tween_property(node, "modulate:a", config.fade_from, config.duration)
	tween.tween_callback(func():
		node.hide()
		node.offset_left = 0.0
		node.offset_top = 0.0
		node.modulate.a = config.fade_to
	)

func _get_slide_offset(anim_type: int, distance: float, is_in: bool) -> Vector2:
	var offset := Vector2.ZERO
	var dir := 1.0 if is_in else -1.0
	
	match anim_type:
		AnimType.SLIDE_UP:
			offset.y = distance * dir
		AnimType.SLIDE_DOWN:
			offset.y = -distance * dir
		AnimType.SLIDE_LEFT:
			offset.x = distance * dir
		AnimType.SLIDE_RIGHT:
			offset.x = -distance * dir
	
	return offset

func _do_pop_in(node: Control, tween: Tween, config: AnimConfig) -> void:
	_setup_pivot(node)
	node.scale = config.scale_from
	node.modulate.a = config.fade_from
	node.show()
	
	var pop_scale := Vector2.ONE * config.pop_scale
	var bounce_scale := Vector2.ONE * config.pop_bounce
	
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", pop_scale, config.duration * 0.6)
	tween.parallel().tween_property(node, "modulate:a", config.fade_to, config.duration * 0.3)
	tween.tween_property(node, "scale", bounce_scale, config.duration * 0.2)
	tween.tween_property(node, "scale", Vector2.ONE, config.duration * 0.2)
	tween.tween_callback(func(): _reset_pivot(node))

func _do_pop_out(node: Control, tween: Tween, config: AnimConfig) -> void:
	_setup_pivot(node)
	var shrink_scale := Vector2.ONE * 0.9
	
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "scale", shrink_scale, config.duration * 0.2)
	tween.parallel().tween_property(node, "modulate:a", 0.5, config.duration * 0.2)
	tween.tween_property(node, "scale", config.scale_from, config.duration * 0.3)
	tween.parallel().tween_property(node, "modulate:a", config.fade_from, config.duration * 0.3)
	tween.tween_callback(func():
		node.hide()
		node.scale = Vector2.ONE
		node.modulate.a = config.fade_to
		_reset_pivot(node)
	)

func _setup_pivot(node: Control) -> void:
	var size := node.size
	if size.x > 0 and size.y > 0:
		node.pivot_offset = Vector2(size.x / 2.0, size.y / 2.0)

func _reset_pivot(node: Control) -> void:
	node.pivot_offset = Vector2.ZERO

func _kill_all_tweens() -> void:
	for tween in _tweens:
		if tween and tween.is_valid():
			tween.kill()
	_tweens.clear()

func stop_animation() -> void:
	_kill_all_tweens()
	for node in _nodes:
		if is_instance_valid(node):
			node.scale = Vector2.ONE
			node.modulate.a = 1.0
			node.offset_left = 0.0
			node.offset_top = 0.0
			node.pivot_offset = Vector2.ZERO
	_nodes.clear()
	_state = AnimState.IDLE

func is_animating() -> bool:
	return _state != AnimState.IDLE

func get_state() -> int:
	return _state

static func create_default_show_config() -> AnimConfig:
	var config := AnimConfig.new()
	config.anim_type = AnimType.SCALE
	config.duration = 0.25
	config.transition_type = Tween.TRANS_QUAD
	config.ease_type = Tween.EASE_OUT
	return config

static func create_default_hide_config() -> AnimConfig:
	var config := AnimConfig.new()
	config.anim_type = AnimType.SCALE
	config.duration = 0.2
	config.transition_type = Tween.TRANS_QUAD
	config.ease_type = Tween.EASE_IN
	return config
