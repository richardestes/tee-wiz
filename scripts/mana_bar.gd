class_name ManaBar extends CanvasLayer

const PIP_FILLED:=Color(1.0,1.0,1.0)
const PIP_EMPTY:=Color(0.2,0.2,0.2)

@export var element_icons: Array[Texture2D]

@onready var rows: VBoxContainer = get_node("Rows")
var icons_by_element := {}

func _ready() -> void:
	build_icons()

func build_icons() -> void:
	for element in ManaPool.Element.values():
		var row := HBoxContainer.new()
		
		var icons: Array[TextureRect] = []
		for icon_index in ManaPool.MAX_PER_COLOR:
			var icon:= TextureRect.new()
			icon.texture = element_icons[element]
			icon.custom_minimum_size = Vector2(32,32)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.visible = false
			row.add_child(icon)
			icons.append(icon)
		
		rows.add_child(row)
		icons_by_element[element] = icons
		

func refresh_icons(element: ManaPool.Element, amount: int) -> void:
	var icon_array: Array = icons_by_element[element]
	for icon_index in icon_array.size():
		var icon: TextureRect = icon_array[icon_index]
		icon.visible = icon_index < amount
