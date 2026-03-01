extends Area2D
class_name EchoTriggerPlateComponent
## 回声压板组件（Gameplay/Time 层）
## 作用：检测回声或玩家站立，输出激活状态。

signal activated_changed(active: bool)

@export var accept_player: bool = true
@export var accept_echo: bool = true
@export var echo_tag: StringName = &"echo"
@export var player_group: StringName = &"player"

var _active_count: int = 0
var is_active: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_area_entered(area: Area2D) -> void:
	if _match_target(area):
		_set_count(_active_count + 1)

func _on_area_exited(area: Area2D) -> void:
	if _match_target(area):
		_set_count(_active_count - 1)

func _on_body_entered(body: Node) -> void:
	if _match_target(body):
		_set_count(_active_count + 1)

func _on_body_exited(body: Node) -> void:
	if _match_target(body):
		_set_count(_active_count - 1)

func _match_target(node: Node) -> bool:
	if node == null:
		return false
	if accept_player and node.is_in_group(player_group):
		return true
	if accept_echo:
		var tag_comp := node.get_node_or_null("TagComponent") as TagComponent
		if tag_comp and tag_comp.has_tag(echo_tag):
			return true
	return false

func _set_count(v: int) -> void:
	_active_count = maxi(0, v)
	var next_active := _active_count > 0
	if next_active != is_active:
		is_active = next_active
		activated_changed.emit(is_active)

func get_component_data() -> Dictionary:
	return {
		"is_active": is_active,
		"active_count": _active_count,
		"accept_player": accept_player,
		"accept_echo": accept_echo,
	}
