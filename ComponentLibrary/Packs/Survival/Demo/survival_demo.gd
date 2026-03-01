extends PackDemo

func _ready():
	pack_name = "Survival"
	super._ready()

func _populate_demo():
	var se = StatusEffectComponent.new()
	add_child(se)
	print("Survival demo: apply effects via se.apply_effect('burn',2) etc.")
