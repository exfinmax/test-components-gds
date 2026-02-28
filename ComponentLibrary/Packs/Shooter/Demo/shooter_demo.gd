extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "Shooter"

func _populate_demo():
	# shooter demo can spawn a dummy projectile
	var proj = load("res://ComponentLibrary/Packs/Shooter/Demo/dummy_projectile.gd").instantiate()
	add_child(proj)
	print("Shooter demo: dummy projectile spawned; run its logic manually.")
