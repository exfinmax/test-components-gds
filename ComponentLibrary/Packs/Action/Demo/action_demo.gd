extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "Action"

func _populate_demo():
	# action demo uses route_target for event callbacks
	var route = load("res://ComponentLibrary/Packs/Action/Demo/route_target.gd").instantiate()
	add_child(route)
	# you can call route.on_route({}) from the editor console to test
	print("Action demo: instantiated route_target; call on_route manually.")
