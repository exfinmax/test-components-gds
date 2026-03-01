extends PackDemo

func _ready():
	pack_name = "UI"
	super._ready()
	# then add transition UI elements
	var trans_scene = preload("res://ComponentLibrary/Packs/UI/Templates/Transition/TransitionScene.tscn")
	var trans = trans_scene.instantiate()
	add_child(trans)
	trans.anchor_right = 1
	trans.anchor_bottom = 1
	print("UI-specific additions complete")

	var btn = Button.new()
	btn.text = "Play"
	btn.position = Vector2(20,20)
	btn.pressed.connect(_on_press.bind(trans))
	add_child(btn)

func _on_press(trans):
	trans.start("")
