class_name IllustrationManager
extends Node
## 立绘管理组件
## 负责立绘的显示、切换和焦点管理

## 信号
signal illustration_changed(position: int, character_name: String)
signal expression_changed(position: int, expression: String)

signal focus_changed(is_focused: bool)

## 导出变量 - 立绘节点
@export var left_illustration: HumanTexture
@export var right_illustration: HumanTexture

@export var center_illustration: HumanTexture

## 导出变量 - 焦点设置
@export_group("焦点设置")
@export var focused_scale: float = 1.0
@export var unfocused_scale: float = 0.85
@export var focused_alpha: float = 1.0
@export var unfocused_alpha: float = 0.7
@export var focus_duration: float = 0.3

## 导出变量 - 动画设置
@export_group("动画设置")
@export var fade_duration: float = 0.3

## 内部状态
var _illustration_map: Dictionary = {}
var _current_speaker: String = ""
var _current_position: int = -1

func _ready() -> void:
	_setup_illustration_map()

func _setup_illustration_map() -> void:
	if left_illustration:
		_illustration_map[IllustrationPosition.LEFT] = left_illustration
	if right_illustration:
		_illustration_map[IllustrationPosition.RIGHT] = right_illustration
	if center_illustration:
		_illustration_map[IllustrationPosition.CENTER] = center_illustration

func update_from_dialogue_line(dialogue_line: DialogueLine) -> void:
	if dialogue_line == null:
		return
	
	var character := dialogue_line.character
	
	if not character.is_empty():
		set_current_speaker("")
		_update_focus()
		return
	
	set_current_speaker(character)
	_update_focus()
	
	for tag in dialogue_line.tags:
		if tag.begins_with("expression:"):
			var parts := tag.split(":")
			if parts.size() >= 2:
				var expression := parts[1]
				var position := _get_position_from_tags(dialogue_line.tags)
				switch_expression(position, expression)
		elif tag.begins_with("position:"):
			var parts := tag.split(":")
			if parts.size() >= 2:
				var pos_str := parts[1].to_lower()
				var position := IllustrationPosition.LEFT
				if pos_str == "right":
					position = IllustrationPosition.RIGHT
				elif pos_str == "center":
					position = IllustrationPosition.CENTER
				_current_position = position

func _get_position_from_tags(tags: Array) -> int:
	for tag in tags:
		if tag.begins_with("position:"):
			var parts :Array= tag.split(":")
			if parts.size() >= 2:
				var pos_str :String= parts[1].to_lower()
				match pos_str:
					"right":
						return IllustrationPosition.RIGHT
					"center":
						return IllustrationPosition.CENTER
	return IllustrationPosition.LEFT

func set_current_speaker(character_name: String) -> void:
	_current_speaker = character_name
	_update_focus()

func _update_focus() -> void:
	for position in _illustration_map:
		var illustration: HumanTexture = _illustration_map[position]
		if illustration == null:
			continue
		
		var is_speaking := (illustration.get_character_name() == _current_speaker)
		_apply_focus_state(illustration, is_speaking)
		focus_changed.emit(is_speaking)

func _apply_focus_state(illustration: HumanTexture, is_speaking: bool) -> void:
	var target_scale := focused_scale if is_speaking else unfocused_scale
	var target_alpha := focused_alpha if is_speaking else unfocused_alpha
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(illustration, "scale", Vector2.ONE * target_scale, focus_duration)
	tween.tween_property(illustration, "modulate:a", target_alpha, focus_duration)
	
	illustration.z_index = 100 if is_speaking else 0

func switch_expression(position: int, expression: String) -> void:
	var illustration: HumanTexture = _illustration_map.get(position)
	if illustration == null:
		return
	
	illustration.switch_lihui(expression)
	expression_changed.emit(position, expression)

func switch_illustration(position: int, resource: LiHui, default_key: String = "ax") -> void:
	var illustration: HumanTexture = _illustration_map.get(position)
	if illustration == null:
		return
	
	illustration.switch_lihui_resource(resource, default_key)
	illustration_changed.emit(position, resource.character_name)

func hide_illustration(position: int, animate: bool = true) -> void:
	var illustration: HumanTexture = _illustration_map.get(position)
	if illustration == null:
		return
	
	if animate:
		var tween := create_tween()
		tween.tween_property(illustration, "modulate:a", 0.0, fade_duration)
		tween.tween_callback(illustration.hide)
	else:
		illustration.hide()

func show_illustration(position: int, animate: bool = true) -> void:
	var illustration: HumanTexture = _illustration_map.get(position)
	if illustration == null:
		return
	
	if animate:
		illustration.modulate.a = 0.0
		illustration.show()
		var tween := create_tween()
		tween.tween_property(illustration, "modulate:a", 1.0, fade_duration)
	else:
		illustration.show()

func get_illustration(position: int) -> HumanTexture:
	return _illustration_map.get(position)

func get_current_speaker() -> String:
	return _current_speaker

func get_current_position() -> int:
	return _current_position

func reset_all() -> void:
	for position in _illustration_map:
		var illustration: HumanTexture = _illustration_map[position]
		if illustration:
			illustration.reset_position()
			illustration.modulate.a = 1.0
			illustration.scale = Vector2.ONE

## 按角色名设置焦点（匹配角色名的立绘获得焦点，其余设为非焦点）
## 无匹配时所有立绘均设为非焦点
func set_focus_by_name(character_name: String) -> void:
	var found := false
	for position in _illustration_map:
		var illustration: HumanTexture = _illustration_map[position]
		if illustration == null:
			continue
		var is_speaking := (illustration.get_character_name() == character_name)
		if is_speaking:
			found = true
		_apply_focus_state(illustration, is_speaking)
	
	# 无匹配时已全部设为非焦点（循环中 is_speaking 均为 false）
	_current_speaker = character_name if found else ""

## 交换两个位置的立绘资源
func swap_illustrations(pos_a: int, pos_b: int) -> void:
	var illus_a: HumanTexture = _illustration_map.get(pos_a)
	var illus_b: HumanTexture = _illustration_map.get(pos_b)
	
	if illus_a == null or illus_b == null:
		return
	
	# 交换 lihui_resource 引用
	var res_a := illus_a.lihui_resource
	var res_b := illus_b.lihui_resource
	
	illus_a.lihui_resource = res_b
	illus_b.lihui_resource = res_a
	
	# 更新显示纹理
	if res_b != null and res_b.sprites.has(res_b.default_expression if "default_expression" in res_b else "ax"):
		illus_a.texture = res_b.sprites[res_b.get("default_expression")]
	if res_a != null and res_a.sprites.has(res_a.get("default_expression")):
		illus_b.texture = res_a.sprites[res_a.get("default_expression")]
	
	illustration_changed.emit(pos_a, illus_a.get_character_name())
	illustration_changed.emit(pos_b, illus_b.get_character_name())

## 立绘位置枚举
enum IllustrationPosition {
	LEFT,
	RIGHT,
	CENTER
}
