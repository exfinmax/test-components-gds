extends Node2D
class_name GhostReplayComponent
## 幽灵回放组件 - 显示之前/最佳一次通关的半透明影子
##
## 什么是 Ghost？
##   你玩赛车游戏时，赛道上有一辆半透明的车在跑——
##   那就是你上一次的"幽灵"。它只是回放录制的路径，
##   不参与碰撞，纯粹让你和自己赛跑。
##
##   在跑酷游戏中也一样：
##     - 显示你上一次/最佳通关的路径
##     - 激励玩家跑得更快、更流畅
##     - Speedrun 核心功能
##
## 工作原理：
##   录制阶段：每帧记录 {time, position, heading, animation}
##   回放阶段：按时间线回放这些数据，移动一个半透明 Sprite
##
## 与 TimeRewindComponent 的区别：
##   TimeRewind  = 操控游戏状态（真的改变角色位置）
##   GhostReplay = 纯视觉展示（只移动一个影子，不影响游戏）
##
## 使用方式：
##   1. 在关卡中添加 GhostReplayComponent
##   2. 关卡开始时 start_recording(player)
##   3. 关卡结束时 stop_recording() → 保存数据
##   4. 下次进入关卡时 play_ghost(saved_data)

signal recording_started
signal recording_stopped(frame_count: int)
signal playback_started
signal playback_finished

## --------- 录制设置 ---------

## 录制帧率（不必 60fps，15-30 够了，Lerp 补偿平滑度）
@export var record_fps: int = 20

## --------- 回放设置 ---------

## 幽灵 Sprite 的透明度
@export_range(0.0, 1.0, 0.01) var ghost_alpha: float = 0.35

## 幽灵颜色色调
@export var ghost_color: Color = Color(0.5, 0.8, 1.0, 0.35)

## 回放时是否循环
@export var loop_playback: bool = false

## 幽灵 Sprite 使用的 SpriteFrames（如果为空，尝试从目标角色复制）
@export var ghost_sprite_frames: SpriteFrames

## --------- 帧数据 ---------

## 单帧数据（用 Dictionary 序列化方便存盘）
class GhostFrame:
	var time: float
	var position: Vector2
	var heading: int = 1
	var animation: StringName = &""
	var frame_index: int = 0
	
	func to_dict() -> Dictionary:
		return {
			"t": time,
			"px": position.x,
			"py": position.y,
			"h": heading,
			"a": String(animation),
			"f": frame_index,
		}
	
	static func from_dict(d: Dictionary) -> GhostFrame:
		var gf := GhostFrame.new()
		gf.time = d.get("t", 0.0)
		gf.position = Vector2(d.get("px", 0.0), d.get("py", 0.0))
		gf.heading = d.get("h", 1)
		gf.animation = StringName(d.get("a", ""))
		gf.frame_index = d.get("f", 0)
		return gf

## --------- 内部状态 ---------

## 录制数据
var _recorded_frames: Array[GhostFrame] = []
var _is_recording: bool = false
var _record_timer: float = 0.0
var _record_interval: float
var _record_elapsed: float = 0.0
var _record_target: CharacterBody2D

## 回放状态
var _is_playing: bool = false
var _playback_time: float = 0.0
var _playback_index: int = 0
var _playback_data: Array[GhostFrame] = []

## 幽灵可视节点
var _ghost_sprite: AnimatedSprite2D
var _ghost_container: Node2D

func _ready() -> void:
	_record_interval = 1.0 / record_fps
	_setup_ghost_visual()

func _process(delta: float) -> void:
	if _is_recording:
		_tick_recording(delta)
	elif _is_playing:
		_tick_playback(delta)

#region 录制

## 开始录制指定角色的运动
func start_recording(target: CharacterBody2D) -> void:
	_record_target = target
	_recorded_frames.clear()
	_record_timer = 0.0
	_record_elapsed = 0.0
	_is_recording = true
	recording_started.emit()

## 停止录制
func stop_recording() -> void:
	if not _is_recording: return
	_is_recording = false
	_record_target = null
	recording_stopped.emit(_recorded_frames.size())

func _tick_recording(delta: float) -> void:
	if not is_instance_valid(_record_target): 
		stop_recording()
		return
	
	_record_elapsed += delta
	_record_timer += delta
	if _record_timer < _record_interval: return
	_record_timer -= _record_interval
	
	var gf := GhostFrame.new()
	gf.time = _record_elapsed
	gf.position = _record_target.global_position
	gf.heading = _record_target.get("heading") if "heading" in _record_target else 1
	
	# 尝试获取动画信息
	var anim_sprite := _record_target.get_node_or_null("Body/AnimatedSprite2D") as AnimatedSprite2D
	if anim_sprite:
		gf.animation = anim_sprite.animation
		gf.frame_index = anim_sprite.frame
	else:
		var anim_player := _record_target.get_node_or_null("Body/AnimationPlayer") as AnimationPlayer
		if anim_player and anim_player.is_playing():
			gf.animation = anim_player.current_animation
	
	_recorded_frames.append(gf)

#endregion

#region 回放

## 用录制好的数据开始播放幽灵
func play_ghost(data: Array[GhostFrame] = []) -> void:
	if data.is_empty():
		_playback_data = _recorded_frames
	else:
		_playback_data = data
	
	if _playback_data.is_empty():
		push_warning("[GhostReplayComponent] 没有数据可回放")
		return
	
	_playback_time = 0.0
	_playback_index = 0
	_is_playing = true
	_show_ghost(true)
	playback_started.emit()

## 停止回放
func stop_playback() -> void:
	_is_playing = false
	_show_ghost(false)

func _tick_playback(delta: float) -> void:
	_playback_time += delta
	
	if _playback_data.is_empty(): return
	
	var total_time := _playback_data[-1].time
	
	# 检查是否播完
	if _playback_time >= total_time:
		if loop_playback:
			_playback_time = fmod(_playback_time, total_time)
			_playback_index = 0
		else:
			_is_playing = false
			_show_ghost(false)
			playback_finished.emit()
			return
	
	# 找到当前时间对应的两帧（二分或线性推进）
	while _playback_index < _playback_data.size() - 1 and _playback_data[_playback_index + 1].time <= _playback_time:
		_playback_index += 1
	
	var frame_a := _playback_data[_playback_index]
	var frame_b: GhostFrame
	if _playback_index + 1 < _playback_data.size():
		frame_b = _playback_data[_playback_index + 1]
	else:
		frame_b = frame_a
	
	# 两帧之间 Lerp 插值（平滑补偿低录制帧率）
	var t := 0.0
	var dt := frame_b.time - frame_a.time
	if dt > 0.001:
		t = clampf((_playback_time - frame_a.time) / dt, 0.0, 1.0)
	
	# 应用位置
	if _ghost_container:
		_ghost_container.global_position = frame_a.position.lerp(frame_b.position, t)
		
		# 朝向
		var h := frame_b.heading if t > 0.5 else frame_a.heading
		_ghost_container.scale.x = absf(_ghost_container.scale.x) * signf(float(h)) if h != 0 else 1.0
	
	# 应用动画（如果有 AnimatedSprite2D）
	if _ghost_sprite and frame_a.animation != &"":
		var target_anim := frame_b.animation if t > 0.5 else frame_a.animation
		if _ghost_sprite.sprite_frames and _ghost_sprite.sprite_frames.has_animation(target_anim):
			if _ghost_sprite.animation != target_anim:
				_ghost_sprite.play(target_anim)

#endregion

#region 序列化（存盘/读盘）

## 将录制数据导出为 Dictionary（可以存到 SaveSystem）
func export_data() -> Dictionary:
	var frames := []
	for gf in _recorded_frames:
		frames.append(gf.to_dict())
	return {
		"version": 1,
		"record_fps": record_fps,
		"frames": frames,
	}

## 从 Dictionary 导入数据
func import_data(data: Dictionary) -> Array[GhostFrame]:
	var frames: Array[GhostFrame] = []
	var raw: Array = data.get("frames", [])
	for d in raw:
		frames.append(GhostFrame.from_dict(d))
	return frames

## 从文件加载并播放
func load_and_play(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		push_warning("[GhostReplayComponent] 文件不存在: %s" % file_path)
		return
	var file := FileAccess.open(file_path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data := import_data(json.data)
		play_ghost(data)

## 保存录制数据到文件
func save_to_file(file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_warning("[GhostReplayComponent] 无法写入: %s" % file_path)
		return
	file.store_string(JSON.stringify(export_data()))

#endregion

#region 幽灵可视化

func _setup_ghost_visual() -> void:
	_ghost_container = Node2D.new()
	_ghost_container.name = "GhostContainer"
	add_child(_ghost_container)
	
	_ghost_sprite = AnimatedSprite2D.new()
	_ghost_sprite.name = "GhostSprite"
	_ghost_sprite.modulate = ghost_color
	if ghost_sprite_frames:
		_ghost_sprite.sprite_frames = ghost_sprite_frames
	_ghost_container.add_child(_ghost_sprite)
	
	_show_ghost(false)

func _show_ghost(visible_flag: bool) -> void:
	if _ghost_container:
		_ghost_container.visible = visible_flag

## 运行时设置幽灵的 SpriteFrames（从玩家角色复制）
func copy_sprite_from(target: CharacterBody2D) -> void:
	var source := target.get_node_or_null("Body/AnimatedSprite2D") as AnimatedSprite2D
	if source and source.sprite_frames:
		_ghost_sprite.sprite_frames = source.sprite_frames

#endregion

#region 自省

func get_component_data() -> Dictionary:
	return {
		"is_recording": _is_recording,
		"is_playing": _is_playing,
		"recorded_frames": _recorded_frames.size(),
		"recorded_duration": _recorded_frames[-1].time if _recorded_frames.size() > 0 else 0.0,
		"playback_time": _playback_time,
		"ghost_alpha": ghost_alpha,
	}

#endregion
