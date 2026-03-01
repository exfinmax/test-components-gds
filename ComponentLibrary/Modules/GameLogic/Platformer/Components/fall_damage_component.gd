

extends CharacterComponentBase
class_name FallDamageComponent
## 跌落伤害组件（Gameplay/Platformer 层）
## 作用：记录离地后最大下落速度，落地时按阈值计算伤害。

signal fall_damaged(damage: float, peak_speed: float)

@export var health_component: HealthComponent
@export var min_damage_speed: float = 650.0
@export var max_damage_speed: float = 1200.0
@export var min_damage: float = 1.0
@export var max_damage: float = 12.0

var _was_on_floor: bool = true
var _peak_fall_speed: float = 0.0

func _component_ready() -> void:
	if not health_component:
		health_component = character.get_node_or_null("%HealthComponent") as HealthComponent if character else null
	_was_on_floor = true

func _physics_process(_delta: float) -> void:
	if not self_driven:
		return
	physics_tick(_delta)

func physics_tick(_delta: float) -> void:
	if not enabled or not character:
		return
	var on_floor := character.is_on_floor()
	if not on_floor and character.velocity.y > _peak_fall_speed:
		_peak_fall_speed = character.velocity.y
	if not _was_on_floor and on_floor:
		_apply_fall_damage_if_needed()
		_peak_fall_speed = 0.0
	_was_on_floor = on_floor

func _apply_fall_damage_if_needed() -> void:
	if not health_component:
		return
	if _peak_fall_speed < min_damage_speed:
		return
	var t := inverse_lerp(min_damage_speed, max_damage_speed, _peak_fall_speed)
	t = clampf(t, 0.0, 1.0)
	var dmg := lerpf(min_damage, max_damage, t)
	health_component.damage(dmg)
	fall_damaged.emit(dmg, _peak_fall_speed)

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"peak_fall_speed": _peak_fall_speed,
		"min_damage_speed": min_damage_speed,
		"max_damage_speed": max_damage_speed,
		"has_health_component": health_component != null,
	}
