extends CanvasLayer
class_name Balloon


const DIALOGUE_PITCHES = {
	Creep = 1.1,
	Anchor = 0.9, 
	Lucien = 0.8,
	旁白 = 1.0,
}

const DIALOGUE_HEAD_POS = {
	Anchor = Vector2(4,-1),
	旁白 = Vector2(4,-1)
}

const DIALOGUE_NAME_SCALE = {
	Creep = Vector2(.9,.7)
}

const DIALOGUE_NAME_POS = {
	Anchor = Vector2(16,9),
	Lucien = Vector2(-26,6),
	Creep = Vector2(-26,12),
	旁白 = Vector2(25,11),
	"？？？" = Vector2(-14,12),
}

const DIALOGUE_TEXTURE = {
	#Anchor = {
		#BS = preload("res://assets/dialogue/Anchor.png"),
		#JY = preload("res://assets/dialogue/Anchor/Anchor_jy.png"), ##坚毅,但感觉好像没差和BS比?
		#O = preload("res://assets/dialogue/Anchor/Anchor_O.png"), ##😮
		#Wink = preload("res://assets/dialogue/Anchor/Anchor_Wink.png") ##Wink~
		#},
	#Lucien = {
		#BS = preload("res://assets/dialogue/Lucien.png"),
		#JY = preload("res://assets/dialogue/L/L_jy.png"), ##惊讶
		#KZ = preload("res://assets/dialogue/L/L_kz.png"), ##狂躁
		#SW = preload("res://assets/dialogue/L/L_sw.png"), ##失望
		#ZM = preload("res://assets/dialogue/L/L_zm.png"), ##皱眉
		#SR = preload("res://assets/dialogue/L/L_sr.png") ##释然
		#},
	#Creep = {
		#BS = preload("res://assets/dialogue/C-basic.png"),
		#SR = preload("res://assets/dialogue/C/C_sr.png"), ##释然
		#HAN = preload("res://assets/dialogue/C/C_han.png"), ##汗😓
		#HJ = preload("res://assets/dialogue/C/C_hj.png"), ##幻觉
		#ZZ = preload("res://assets/dialogue/C/C_zz.png"), ##自责
		#KX = preload("res://assets/dialogue/C/C_kx.png") ##苦笑
	#},
	#"？？？" = {
		#BS = preload("res://assets/dialogue/B/black.png")
	#},
	#旁白 = {
		#BS = preload("res://assets/dialogue/pb.png")
	#}
}
#
const DIALOGUE_BG_TEXTURE = {
	#Anchor = {
		#BG = preload("res://assets/dialogue/zhujue_duihua.png"),
		#NAME = preload("res://assets/dialogue/zhujue_mingzi.png"),
		#HEAD = preload("res://assets/dialogue/zhujue_touxiang.png")
		#},
	#旁白 = {
		#BG = preload("res://assets/dialogue/zhujue_duihua.png"),
		#NAME = preload("res://assets/dialogue/zhujue_mingzi.png"),
		#HEAD = preload("res://assets/dialogue/zhujue_touxiang.png")
	#},
	#Lucien = {
		#BG = preload("res://assets/dialogue/lucien_duihua.png"),
		#NAME = preload("res://assets/dialogue/L_mingzi.png"),
		#HEAD = preload("res://assets/dialogue/L_touxiang.png")
		#},
	#Creep = {
		#BG = preload("res://assets/dialogue/C/C_bg.png"),
		#NAME = preload("res://assets/dialogue/C/C_name.png"),
		#HEAD = preload("res://assets/dialogue/C/C_head.png")
	#},
	#"？？？" = {
		#BG = preload("res://assets/dialogue/B/B_duihua.png"),
		#NAME = preload("res://assets/dialogue/B/B_xingming.png"),
		#HEAD = preload("res://assets/dialogue/B/B_touxiang.png")
		#
	#}
}


@export var response_template: Node
@export var file_suffix: String = ""

@onready var talk_sound: AudioStreamPlayer = $TalkSound
@onready var balloon: ColorRect = $Balloon
@onready var margin: MarginContainer = $Balloon / Margin
@onready var character_portrait: TextureRect = $Balloon / Margin / HBox / Portrait / TextureRect
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: DialogueLabel = $Balloon / Margin / HBox / VBox / DialogueLabel
@onready var responses_menu: VBoxContainer = %Responses
@onready var portrait: Control = $Balloon/Margin/HBox/Portrait
@onready var h_box: HBoxContainer = $Balloon/Margin/HBox
@onready var v_box: VBoxContainer = $Balloon/Margin/HBox/VBox
@onready var temp: Control = $Balloon/Margin/HBox/Temp
@onready var bg_texture: TextureRect = $Balloon/BGtexture
@onready var head_texture: TextureRect = $Balloon/Margin/HBox/Portrait/HeadTexture
@onready var name_texture: TextureRect = $Balloon/Margin/HBox/Portrait/NameTexture
@onready var auto_button: Button = $Balloon/AutoButton


var resource: DialogueResource


var temporary_game_states: Array = []


var is_waiting_for_input: bool = false

var current_str:String

var history_line: RichTextLabel

## 当前对话行的ID（用于存档精确恢复）
var current_line_id: String = ""

## 自动对话模式
var is_auto_mode: bool = false

## 自动对话间隔时间（秒）
var auto_delay: float = 1.0

var dialogue_line: DialogueLine:
	set(next_dialogue_line):
		if not next_dialogue_line:
			queue_free()
			return

		is_waiting_for_input = false

		for child in responses_menu.get_children():
			responses_menu.remove_child(child)
			child.queue_free()

		dialogue_line = next_dialogue_line

		character_label.visible = not dialogue_line.character.is_empty()
		character_label.text = tr(dialogue_line.character, "dialogue")
		if dialogue_line.character.is_empty():
			character_portrait.texture = null
		else:
			var current_character_texture:Dictionary = DIALOGUE_TEXTURE.get(dialogue_line.character, {})
			if current_str == "":
				character_portrait.texture = current_character_texture.get("BS",null)
			else:
				character_portrait.texture = current_character_texture.get(current_str,current_character_texture.get("BS",null))

		dialogue_label.modulate.a = 0
		dialogue_label.custom_minimum_size.x = dialogue_label.get_parent().size.x - 1
		dialogue_label.dialogue_line = dialogue_line


		responses_menu.modulate.a = 0
		if dialogue_line.responses.size() > 0:
			for response in dialogue_line.responses:

				var item: RichTextLabel = response_template.duplicate(0)
				item.name = "Response%d" % responses_menu.get_child_count()
				if not response.is_allowed:
					item.name = String(item.name) + "Disallowed"
					item.modulate.a = 0.4
				item.text = response.text
				item.show()
				responses_menu.add_child(item)


		balloon.show()

		dialogue_label.modulate.a = 1
		dialogue_label.type_out()
		await dialogue_label.finished_typing

		# 对话完成后添加到历史记录
		add_to_history()

		if dialogue_line.responses.size() > 0:
			responses_menu.modulate.a = 1
			configure_menu()
		elif dialogue_line.time != "":
			var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
			await get_tree().create_timer(time).timeout
			next(dialogue_line.next_id)
		else:
			is_waiting_for_input = true
			balloon.focus_mode = Control.FOCUS_ALL
			balloon.grab_focus()
			# 自动对话模式：等待一段时间后自动推进
			if is_auto_mode:
				_auto_advance()
		
		# 发送对话行变化信号
		DialogueManager.dialogue_line_change.emit(dialogue_line)
	get:
		return dialogue_line


func _ready() -> void :
	#Global.current_balloon = self
	response_template.hide()
	balloon.hide()
	dialogue_label.meta_clicked.connect( func(meta): OS.shell_open(str(meta)))
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)
	# 通过group获取历史记录面板
	history_line = get_tree().get_first_node_in_group("history_line")
	# 绑定自动对话按钮
	auto_button.pressed.connect(_on_auto_button_pressed)


func _unhandled_input(_event: InputEvent) -> void :

	get_viewport().set_input_as_handled()



func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void :
	temporary_game_states = extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	if extra_game_states.is_empty():
		self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)
	else:
		self.dialogue_line = await DialogueManager.create_dialogue_line(resource.lines.get(temporary_game_states[0],null),temporary_game_states)
	if dialogue_line != null:
		current_line_id = dialogue_line.id  # 保存当前行ID（使用实际获取到的行ID）
		change_balloon_visual()

func change_texture(_str:String) -> void:
	current_str = _str
	var current_character_texture :Dictionary = DIALOGUE_TEXTURE.get(dialogue_line.character,{}) 
	if !current_character_texture.is_empty():
		var texture = current_character_texture.get(_str,null)
		if texture != null:
			character_portrait.texture = texture


func change_balloon_visual() -> void:
	if dialogue_line.character in ["证人","旁白"]:
		change_haeding(Vector2.RIGHT)
	else:
		change_haeding(Vector2.LEFT)
	var dic :Dictionary = DIALOGUE_BG_TEXTURE.get(dialogue_line.character,{})
	if !dic.is_empty():
		bg_texture.texture = dic.get("BG",null)
		name_texture.texture = dic.get("NAME",null)
		head_texture.texture = dic.get("HEAD",null)
	#name_texture.scale = DIALOGUE_NAME_SCALE.get(dialogue_line.character,Vector2(1.28,1.2))
	head_texture.position = DIALOGUE_HEAD_POS.get(dialogue_line.character, Vector2.ZERO)



func next(next_id: String) -> void :
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)
	if dialogue_line:
		current_line_id = dialogue_line.id  # 保存当前行ID（使用实际获取到的行ID）
	change_balloon_visual()

func add_to_history() -> void:
	if history_line == null:
		return
	
	var character = dialogue_line.character if not dialogue_line.character.is_empty() else ""
	var text = dialogue_line.text
	
	# 构建BBCode格式的对话历史
	var history_entry = ""
	if not character.is_empty():
		history_entry = "[b]%s[/b]\n     %s\n" % [character, text]
	else:
		history_entry = "%s\n" % text
	
	# 添加到历史记录
	history_line.text += history_entry
	


func change_haeding(heading: Vector2) -> void:
	if heading == Vector2.RIGHT:
		#character_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		#dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		# 这段代码示例要求当前脚本扩展的是 MarginContainer。
		margin.add_theme_constant_override("margin_left", 0)
		margin.add_theme_constant_override("margin_right", 40)
		if name_texture.scale.x < 0:
			name_texture.scale.x = -name_texture.scale.x
			name_texture.position.x += 150
		responses_menu.alignment = BoxContainer.ALIGNMENT_BEGIN
		v_box.reparent(temp)
		v_box.reparent(h_box,false)
	elif heading == Vector2.LEFT:
		#character_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		#dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		margin.add_theme_constant_override("margin_left", 40)
		margin.add_theme_constant_override("margin_right", 0)
		if name_texture.scale.x > 0:
			name_texture.scale.x = -name_texture.scale.x
			name_texture.position.x -= 150
		responses_menu.alignment = BoxContainer.ALIGNMENT_END
		portrait.reparent(temp)
		portrait.reparent(h_box,false)



func configure_menu() -> void :
	balloon.focus_mode = Control.FOCUS_NONE

	var items = get_responses()
	for i in items.size():
		var item: Control = items[i]

		item.focus_mode = Control.FOCUS_ALL

		item.focus_neighbor_left = item.get_path()
		item.focus_neighbor_right = item.get_path()

		if i == 0:
			item.focus_neighbor_top = item.get_path()
			item.focus_previous = item.get_path()
		else:
			item.focus_neighbor_top = items[i - 1].get_path()
			item.focus_previous = items[i - 1].get_path()

		if i == items.size() - 1:
			item.focus_neighbor_bottom = item.get_path()
			item.focus_next = item.get_path()
		else:
			item.focus_neighbor_bottom = items[i + 1].get_path()
			item.focus_next = items[i + 1].get_path()

		item.mouse_entered.connect(_on_response_mouse_entered.bind(item))
		item.gui_input.connect(_on_response_gui_input.bind(item))

	items[0].grab_focus()



func get_responses() -> Array:
	var items: Array = []
	for child in responses_menu.get_children():
		if "Disallowed" in child.name: continue
		items.append(child)

	return items


func handle_resize() -> void :
	if not is_instance_valid(margin):
		call_deferred("handle_resize")
		return

	balloon.custom_minimum_size.y = margin.size.y
	balloon.size.y = 0
	var viewport_size = balloon.get_viewport_rect().size
	balloon.global_position = Vector2((viewport_size.x - balloon.size.x) * 0.5, viewport_size.y - balloon.size.y)





func _on_mutated(_mutation: Dictionary) -> void :
	is_waiting_for_input = false
	balloon.hide()


func _on_response_mouse_entered(item: Control) -> void :
	if "Disallowed" in item.name: return

	item.grab_focus()


func _on_response_gui_input(event: InputEvent, item: Control) -> void :
	if "Disallowed" in item.name: return

	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		next(dialogue_line.responses[item.get_index()].next_id)
	elif event.is_action_pressed("interact") and item in get_responses():
		next(dialogue_line.responses[item.get_index()].next_id)


func _on_balloon_gui_input(event: InputEvent) -> void :
	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return


	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		next(dialogue_line.next_id)
	elif event.is_action_pressed("interact") and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_margin_resized() -> void :
	handle_resize()


func _on_dialogue_label_spoke(letter: String, letter_index: int, speed: float) -> void :
	if not letter in [" ", "."]:
		var actual_speed: int = 4 if speed >= 1 else 2
		if letter_index % actual_speed == 0:
			talk_sound.play()
			var pitch = DIALOGUE_PITCHES.get(dialogue_line.character, 1)
			talk_sound.pitch_scale = randf_range(pitch - 0.1, pitch + 0.1)


## 切换自动对话模式
func _on_auto_button_pressed() -> void:
	is_auto_mode = !is_auto_mode
	# 更新按钮视觉状态
	auto_button.modulate = Color(1, 1, 0.5) if is_auto_mode else Color(1, 1, 1)
	# 如果正在等待输入且刚开启自动模式，立即开始自动推进
	if is_auto_mode and is_waiting_for_input and dialogue_line.responses.size() == 0:
		_auto_advance()


## 自动推进对话
func _auto_advance() -> void:
	# 根据文本长度计算等待时间，最少1秒
	var wait_time = max(auto_delay, dialogue_line.text.length() * 0.03)
	await get_tree().create_timer(wait_time).timeout
	# 再次检查状态（可能在等待期间被手动点击或关闭自动模式）
	if is_auto_mode and is_waiting_for_input and dialogue_line.responses.size() == 0:
		next(dialogue_line.next_id)
