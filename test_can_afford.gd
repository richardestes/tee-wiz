extends SceneTree

func _initialize() -> void:
	var pool := ManaPool.new()
	pool.add(ManaPool.Element.FIRE)
	pool.add(ManaPool.Element.FIRE)
	pool.add(ManaPool.Element.WATER)

	check("typed exactly met", make_spell({ManaPool.Element.FIRE: 2}), true, pool)
	check("typed short on fire", make_spell({ManaPool.Element.FIRE: 3}), false, pool)
	check("two colors both met", make_spell({ManaPool.Element.FIRE: 1, ManaPool.Element.WATER: 1}), true, pool)
	check("empty cost", make_spell({}), true, pool)

	quit()

func make_spell(typed: Dictionary) -> Spell:
	var spell := Spell.new()
	for element in typed:
		spell.typed_cost[element] = typed[element]
	return spell

func check(label: String, spell: Spell, expected: bool, pool: ManaPool) -> void:
	var actual := pool.can_afford(spell)
	var status := "PASS" if actual == expected else "FAIL"
	print(status, " | ", label, " | expected ", expected, ", got ", actual)
