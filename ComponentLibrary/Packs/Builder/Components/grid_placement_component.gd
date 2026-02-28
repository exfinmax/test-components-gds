extends Node
class_name GridPlacementComponent

signal placed(cell: Vector2i, payload: Dictionary)
signal removed(cell: Vector2i)
signal place_rejected(cell: Vector2i, reason: StringName)

@export var cell_size: Vector2 = Vector2(32.0, 32.0)
@export var block_negative_coordinate: bool = false

var _occupied: Dictionary = {}

func world_to_cell(world_position: Vector2) -> Vector2i:
	var sx := maxf(cell_size.x, 1.0)
	var sy := maxf(cell_size.y, 1.0)
	return Vector2i(
		int(floor(world_position.x / sx)),
		int(floor(world_position.y / sy))
	)

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(float(cell.x) * cell_size.x, float(cell.y) * cell_size.y)

func can_place(cell: Vector2i) -> bool:
	if block_negative_coordinate and (cell.x < 0 or cell.y < 0):
		return false
	return not _occupied.has(cell)

func place(cell: Vector2i, payload: Dictionary = {}) -> bool:
	if block_negative_coordinate and (cell.x < 0 or cell.y < 0):
		place_rejected.emit(cell, &"negative_not_allowed")
		return false
	if _occupied.has(cell):
		place_rejected.emit(cell, &"occupied")
		return false
	_occupied[cell] = payload.duplicate(true)
	placed.emit(cell, _occupied[cell])
	return true

func remove(cell: Vector2i) -> bool:
	if not _occupied.has(cell):
		return false
	_occupied.erase(cell)
	removed.emit(cell)
	return true

func clear_all() -> void:
	for cell in _occupied.keys().duplicate():
		_occupied.erase(cell)
		removed.emit(cell)

func get_payload(cell: Vector2i) -> Dictionary:
	return _occupied.get(cell, {})

func get_occupied_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in _occupied.keys():
		result.append(cell)
	return result

func snap_world_position(world_position: Vector2) -> Vector2:
	return cell_to_world(world_to_cell(world_position))
