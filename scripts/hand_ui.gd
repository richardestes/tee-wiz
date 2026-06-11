class_name HandUI extends CanvasLayer

const READY_TINT := Color(1.0, 1.0, 1.0)
const RESTING_TINT := Color(0.55, 0.55, 0.55)

@export var card_size := Vector2(120, 168)
@export var card_separation := 16
@export var bottom_margin := 24.0

var spell_hand: SpellHand
var card_row: HBoxContainer

func _ready() -> void:
	ensure_card_row()

func ensure_card_row() -> void:
	if card_row:
		return
	build_card_row()

func build_card_row() -> void:
	card_row = HBoxContainer.new()
	card_row.add_theme_constant_override("separation", card_separation)
	card_row.anchor_left = 0.5
	card_row.anchor_right = 0.5
	card_row.anchor_top = 1.0
	card_row.anchor_bottom = 1.0
	card_row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card_row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	card_row.offset_bottom = -bottom_margin
	add_child(card_row)

func bind(hand: SpellHand) -> void:
	ensure_card_row()
	spell_hand = hand
	spell_hand.hand_changed.connect(refresh)
	refresh()

func refresh() -> void:
	clear_cards()
	for index in spell_hand.hand.size():
		var spell: Spell = spell_hand.hand[index]
		var is_ready: bool = index == spell_hand.ready_index
		card_row.add_child(make_card(spell, is_ready))

func clear_cards() -> void:
	for card in card_row.get_children():
		card_row.remove_child(card)
		card.queue_free()

func make_card(spell: Spell, is_ready: bool) -> TextureRect:
	var card := TextureRect.new()
	card.texture = spell.card_texture
	card.custom_minimum_size = card_size
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.modulate = READY_TINT if is_ready else RESTING_TINT
	return card
