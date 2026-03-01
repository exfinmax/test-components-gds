extends Node
class_name DeckDrawComponent

signal deck_shuffled(deck_size: int)
signal card_drawn(card: Variant, hand_size: int, remain_size: int)
signal draw_failed

@export var draw_pile: Array = []
@export var hand: Array = []
@export var discard_pile: Array = []
@export var auto_shuffle_on_empty: bool = true
@export var broadcast_on_event_bus: bool = false
@export var draw_event_name: StringName = &"card.drawn"

func set_deck(cards: Array, do_shuffle: bool = true) -> void:
	draw_pile = cards.duplicate(true)
	hand.clear()
	discard_pile.clear()
	if do_shuffle:
		shuffle_deck()

func shuffle_deck() -> void:
	draw_pile.shuffle()
	deck_shuffled.emit(draw_pile.size())

func draw(count: int = 1) -> Array:
	var results: Array = []
	for _i in range(maxi(count, 0)):
		var card = _draw_one()
		if card == null:
			break
		results.append(card)
	return results

func discard_from_hand(index: int) -> bool:
	if index < 0 or index >= hand.size():
		return false
	discard_pile.append(hand[index])
	hand.remove_at(index)
	return true

func discard_card(card: Variant) -> void:
	discard_pile.append(card)

func reshuffle_discard_into_deck() -> void:
	if discard_pile.is_empty():
		return
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle_deck()

func _draw_one() -> Variant:
	if draw_pile.is_empty():
		if auto_shuffle_on_empty and not discard_pile.is_empty():
			reshuffle_discard_into_deck()
		else:
			draw_failed.emit()
			return null

	var card = draw_pile.pop_back()
	hand.append(card)
	card_drawn.emit(card, hand.size(), draw_pile.size())
	_broadcast_draw(card)
	return card

func _broadcast_draw(card: Variant) -> void:
	if not broadcast_on_event_bus:
		return
	var bus := get_node_or_null("/root/EventBus")
	if bus == null or not bus.has_method("emit_event"):
		return
	bus.call(
		"emit_event",
		draw_event_name,
		{
			"card": card,
			"hand_size": hand.size(),
			"remain_size": draw_pile.size(),
		}
	)
