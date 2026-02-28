extends Area2D
class_name TimeFragmentPickupComponent
## 时间碎片拾取组件（Gameplay/Time 层）
## 作用：角色触碰后恢复时间能量，可用于关卡资源补给点。

signal picked(picker: Node, amount: float)

@export var enabled: bool = true
@export var energy_amount: float = 20.0
@export var one_shot: bool = true

func _ready() -> void:
	monitoring = enabled
	monitorable = enabled
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area2D) -> void:
	_try_pick(area)

func _on_body_entered(body: Node) -> void:
	_try_pick(body)

func _try_pick(node: Node) -> void:
	if not enabled:
		return
	var energy := _find_time_energy(node)
	if not energy:
		return
	energy.refill(energy_amount)
	picked.emit(node, energy_amount)
	if one_shot:
		enabled = false
		queue_free()

func _find_time_energy(node: Node) -> TimeEnergyComponent:
	if node is TimeEnergyComponent:
		return node
	for child in node.get_children():
		if child is TimeEnergyComponent:
			return child
	return null
