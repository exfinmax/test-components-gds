extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "Survival"

func _populate_demo():
    var se = StatusEffectComponent.new()
    add_child(se)
    print("Survival demo: apply effects via se.apply_effect('burn',2) etc.")

