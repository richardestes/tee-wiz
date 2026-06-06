extends SceneTree

# Throwaway headless check for ManaPool.can_afford. Run with:
#   godot --headless --path . --script res://test_can_afford.gd
# Delete once a real test setup exists.

func _initialize() -> void:
	var pool := ManaPool.new()
	# Stock the pool with 2 fire, 1 water (3 total).
	pool.add(ManaPool.Element.FIRE)
	pool.add(ManaPool.Element.FIRE)
	pool.add(ManaPool.Element.WATER)

	# typed cost exactly met, no generic -> affordable
	check("typed exactly met", make_spell({ManaPool.Element.FIRE: 2}, 0), true, pool)
	# typed cost wants more fire than we hold -> not affordable
	check("typed short on fire", make_spell({ManaPool.Element.FIRE: 3}, 0), false, pool)
	# THE TELLING ONE: 2 fire is all spent on the typed part, leaving only 1 water
	# for a generic cost of 2. Correct answer is NO. The bug says yes.
	check("generic must exclude typed mana", make_spell({ManaPool.Element.FIRE: 2}, 2), false, pool)
	# pure generic of 3, paid by the full pool of 3 -> affordable
	check("generic within leftover", make_spell({}, 3), true, pool)

	quit()

func make_spell(typed: Dictionary, generic: int) -> Spell:
	var spell := Spell.new()
	# Copy entries one at a time so the typed Dictionary stays typed.
	for element in typed:
		spell.typed_cost[element] = typed[element]
	spell.generic_cost = generic
	return spell

func check(label: String, spell: Spell, expected: bool, pool: ManaPool) -> void:
	var actual := pool.can_afford(spell)
	var status := "PASS" if actual == expected else "FAIL"
	print(status, " | ", label, " | expected ", expected, ", got ", actual)
