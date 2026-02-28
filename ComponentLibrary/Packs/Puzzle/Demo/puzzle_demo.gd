extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "Puzzle"

func _populate_demo():
    var seq = SequenceSwitchComponent.new()
    seq.sequence = [1,2,3]
    add_child(seq)
    print("Puzzle demo: call seq.try_step(value) from console to test sequence")

