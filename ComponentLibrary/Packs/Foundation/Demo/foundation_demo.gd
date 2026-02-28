extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "Foundation"

func _populate_demo():
    # show cooldown component: button disables for 2 seconds after press
    var btn = Button.new()
    btn.text = "Click (cooldown)"
    btn.rect_position = Vector2(50,50)
    var cd = CooldownComponent.new()
    cd.cooldown_time = 2.0
    btn.add_child(cd)
    btn.pressed.connect(func():
        if cd.can_use():
            cd.activate()
            print("Foundation demo: button used, now cooldown")
        else:
            print("On cooldown")
    )
    add_child(btn)
    # state flag demo
    var flag = StateFlagComponent.new()
    flag.flag_name = "demo"
    add_child(flag)
    print("StateFlagComponent created; call flag.toggle() in console.")

