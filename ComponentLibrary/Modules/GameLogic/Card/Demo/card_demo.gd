extends PackDemo

func _ready():
	pack_name = "Card"
	super._ready()

func _setup_demo() -> void:
	print("\n========== Card Demo ==========")
	var deck := DeckDrawComponent.new()
	deck.set_deck(["Fireball", "Shield", "Heal", "Arrow", "Lightning"])
	add_child(deck)

	deck.card_drawn.connect(func(card, _hand): print("  drew: %s" % str(card)))
	deck.deck_exhausted.connect(func(): print("  牌堆已空！"))

	print("  deck_size=%d  hand_size=%d" % [deck.draw_pile.size(), deck.hand.size()])

	# 摘牌
	var hand1 := deck.draw(3)
	print("  摘 3 张: %s" % str(hand1))
	print("  hand_size=%d" % deck.hand.size())

	# 弃牌并重洗
	deck.discard_from_hand(0)
	print("  弃牌后 hand_size=%d  discard_size=%d" % [deck.hand.size(), deck.discard_pile.size()])

	deck.reshuffle_discard_into_deck()
	print("  重洗后 deck_size=%d  discard_size=%d" % [deck.draw_pile.size(), deck.discard_pile.size()])

	deck.queue_free()
	print("========== Card Demo End ==========\n")
