class_name ManaLoop extends Area3D

@export var element: ManaPool.Element
@export var mesh: MeshInstance3D

signal mana_collected(element: ManaPool.Element)

const ELEMENT_COLORS:= {
	ManaPool.Element.FIRE: Color.RED,
	ManaPool.Element.WATER: Color.BLUE,
	ManaPool.Element.POISON: Color.WEB_GREEN,
	ManaPool.Element.LIGHTNING: Color.YELLOW,
	ManaPool.Element.DARK: Color.DARK_VIOLET,
}

func _ready() -> void:
	add_to_group("mana_loop")
	body_entered.connect(catch_ball)
	paint_for_element()

func catch_ball(body: Node3D) -> void:
	if body is Ball:
		mana_collected.emit(element)

func paint_for_element() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = ELEMENT_COLORS[element]
	mesh.material_override = material
