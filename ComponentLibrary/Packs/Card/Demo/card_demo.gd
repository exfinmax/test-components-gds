extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "Card"

func _populate_demo():
    var deck = DeckDrawComponent.new()
    deck.cards = ["A","B","C","D","E"]
    add_child(deck)
    var btn = Button.new()
    btn.text = "Draw"
    btn.rect_position = Vector2(20,20)
    btn.pressed.connect(func():
        var c = deck.draw_card()
        print("drew", c)
    )
    add_child(btn)

