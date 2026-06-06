class_name ManaPool extends Node

enum Element {FIRE, WATER, POISON, LIGHTNING, DARK}

const MAX_PER_COLOR:= 5

signal mana_changed(element: Element, amount: int)

var held_mana:= {Element.FIRE: 0, Element.WATER: 0, Element.POISON: 0, Element.LIGHTNING: 0, Element.DARK: 0}

func add(element: Element) -> void:
	var previous_amount : int = held_mana[element]
	held_mana[element] = min(previous_amount+ 1, MAX_PER_COLOR)
	if held_mana[element] != previous_amount:
		mana_changed.emit(element, held_mana[element])

func get_mana(element: Element) -> int:
	return held_mana[element]

func get_total_mana()-> int:
	var total: int = 0
	for amount in held_mana.values():
		total += amount
	return total

func can_afford(spell: Spell) -> bool:
	var typed_total: int = 0
	for element in spell.typed_cost:
		var required: int = spell.typed_cost[element]
		var held: int = get_mana(element)
		if held < required:
			return false
		typed_total += required
	var available_generic_mana = get_total_mana() - typed_total
	return available_generic_mana >= spell.generic_cost
