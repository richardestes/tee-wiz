extends Node3D

@export var player_scene: PackedScene
@export var cart_scene: PackedScene
@export var spawn_point: Node3D
@export var entity_parent: Node3D
@export var encounter_manager: EncounterManager
@export var mana_bar: ManaBar
@export var hand_ui: HandUI

var player: Player
var cart: Cart

func _ready() -> void:
	spawn_player()
	wire_mana_loops()
	player.mana_pool.mana_changed.connect(mana_bar.refresh_icons)
	hand_ui.bind(player.spell_hand)
	encounter_manager.encounter_started.connect(player.right_hand.enter_hole)
	encounter_manager.encounter_ended.connect(player.right_hand.exit_hole)

func spawn_player() -> void:
	player = player_scene.instantiate()
	cart = cart_scene.instantiate()
	entity_parent.add_child(player)
	entity_parent.add_child(cart)
	player.cart = cart
	player.global_transform = spawn_point.global_transform
	cart.global_transform = spawn_point.global_transform
	hide_cart()

func hide_cart() -> void:
	cart.hide()
	cart.process_mode = Node.PROCESS_MODE_DISABLED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_cart"):
		player.set_driving(not player.driving)

func wire_mana_loops() -> void:
	for loop in get_tree().get_nodes_in_group("mana_loop"):
		loop.mana_collected.connect(player.mana_pool.add)
