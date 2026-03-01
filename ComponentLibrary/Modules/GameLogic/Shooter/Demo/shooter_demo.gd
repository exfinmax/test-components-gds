extends PackDemo

func _ready():
	pack_name = "Shooter"
	super._ready()

func _populate_demo():
	# shooter demo can spawn a dummy projectile
	var proj_script = load("res://ComponentLibrary/Packs/Shooter/Demo/dummy_projectile.gd")
	if proj_script:
		var proj = proj_script.new()
		add_child(proj)
		print("Shooter demo: dummy projectile spawned; run its logic manually.")
