class_name SpellHand extends Node

signal hand_changed

@export var spell_blueprints: Array[Spell] = []
@export var copies_per_spell: int = 4
@export var hand_size: int = 3

var draw_pile: Array[Spell] = []
var hand: Array[Spell] = []
var discard_pile: Array[Spell] = []
var ready_index: int = 0

func _ready() -> void:
	start_new_deck()

func start_new_deck() -> void:
	build_draw_pile()
	draw_pile.shuffle()
	discard_pile.clear()
	hand.clear()
	refill_hand()

func build_draw_pile() -> void:
	draw_pile.clear()
	for blueprint in spell_blueprints:
		for _i in copies_per_spell:
			draw_pile.append(blueprint)

func refill_hand() -> void:
	while hand.size() < hand_size:
		var count_before := hand.size()
		draw_one()
		if hand.size() == count_before:
			return

func draw_one() -> void:
	if draw_pile.is_empty():
		reshuffle_discard_into_draw()
	if draw_pile.is_empty():
		return
	var drawn_spell: Spell = draw_pile.pop_back()
	hand.append(drawn_spell)

func reshuffle_discard_into_draw() -> void:
	draw_pile = discard_pile
	discard_pile = []
	draw_pile.shuffle()

func cast_card(index: int) -> Spell:
	var spent_spell: Spell = hand[index]
	hand.remove_at(index)
	discard_pile.append(spent_spell)
	draw_one()
	clamp_ready_index()
	hand_changed.emit()
	return spent_spell

func cycle_ready(step: int) -> void:
	if hand.is_empty():
		return
	ready_index = wrapi(ready_index + step, 0, hand.size())
	hand_changed.emit()

func ready_card() -> Spell:
	if hand.is_empty():
		return null
	return hand[ready_index]

func clamp_ready_index() -> void:
	if hand.is_empty():
		ready_index = 0
	else:
		ready_index = clampi(ready_index, 0, hand.size() - 1)
