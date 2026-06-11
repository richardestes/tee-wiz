class_name ManaPool extends Node

enum Element {FIRE, WATER, POISON, LIGHTNING, DARK}

const MAX_PER_COLOR:= 5

signal mana_changed(element: Element, amount: int)

var held_mana:= {Element.FIRE: 0, Element.WATER: 0, Element.POISON: 0, Element.LIGHTNING: 0, Element.DARK: 0}

func add(element: Element) -> void:
	change_mana(element, 1)

func change_mana(element: Element, delta: int) -> void:
	var previous_amount: int = held_mana[element]
	held_mana[element] = clampi(previous_amount + delta, 0, MAX_PER_COLOR)
	if held_mana[element] != previous_amount:
		mana_changed.emit(element, held_mana[element])

func get_mana(element: Element) -> int:
	return held_mana[element]

func can_afford(spell: Spell) -> bool:
	for element in spell.typed_cost:
		if get_mana(element) < spell.typed_cost[element]:
			return false
	return true

func spend(spell: Spell) -> void:
	for element in spell.typed_cost:
		change_mana(element, -spell.typed_cost[element])
