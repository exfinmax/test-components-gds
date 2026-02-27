extends ComponentBase
class_name InvincibilityComponent
## 鏃犳晫绐楀彛缁勪欢锛圙ameplay/Common 灞傦級
## 浣滅敤锛氱鐞嗙煭鏆傛棤鏁岀姸鎬侊紙渚嬪鍙楀嚮淇濇姢銆侀棯閬垮抚锛夈€?## 璁捐锛氬彧绠＄悊鈥滄椂闂寸獥鍙ｂ€濓紝涓嶇洿鎺ュ鐞嗗彈鍑婚€昏緫锛屼究浜庝笌 Health/HurtBox 瑙ｈ€︺€?
signal invincibility_started(duration: float)
signal invincibility_ended

@export var self_driven: bool = true

var is_invincible: bool = false
var _remaining: float = 0.0

func _ready() -> void:
	if not self_driven:
		set_process(false)
	_component_ready()

func _process(delta: float) -> void:
	if not self_driven:
		return
	tick(delta)

func tick(delta: float) -> void:
	if not enabled or not is_invincible:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		is_invincible = false
		_remaining = 0.0
		invincibility_ended.emit()

func trigger(duration: float) -> void:
	if duration <= 0.0:
		clear()
		return
	is_invincible = true
	_remaining = maxf(_remaining, duration)
	invincibility_started.emit(_remaining)

func clear() -> void:
	if not is_invincible:
		return
	is_invincible = false
	_remaining = 0.0
	invincibility_ended.emit()

func can_take_hit() -> bool:
	return enabled and not is_invincible

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"is_invincible": is_invincible,
		"remaining": _remaining,
	}

