extends PackDemo

func _ready():
	pack_name = "Action"
	super._ready()

func _setup_demo():
	# action demo uses route_target for event callbacks
	var rt_script = load("res://ComponentLibrary/Modules/GameLogic/Action/Demo/route_target.gd")
	if rt_script:
		var route = rt_script.new()
		add_child(route)
		print("Action demo: instantiated route_target; call on_route manually.")
