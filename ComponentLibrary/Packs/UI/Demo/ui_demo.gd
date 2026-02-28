extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "UI"

@onready var trans := preload("res://ComponentLibrary/Packs/UI/Templates/Transition/TransitionScene.tscn").instance()

func _ready():
    # call parent to populate grid
    ._ready()
    # then add transition UI elements
    add_child(trans)
    trans.anchor_right = 1
    trans.anchor_bottom = 1
    print("UI-specific additions complete")

    var btn = Button.new()
    btn.text = "Play"
    btn.rect_position = Vector2(20,20)
    btn.connect("pressed", self, "_on_press")
    add_child(btn)

func _on_press():
    trans.start("")
