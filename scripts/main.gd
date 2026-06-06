extends Node3D

@export var player: Player
@export var player_camera: Camera3D
@export var cart: Cart
@export var cart_camera: Camera3D
@export var mana_bar: ManaBar

var driving: bool = false

func _ready() -> void:
	set_driving(false)  # every run starts on foot
	wire_mana_loops()
	player.mana_pool.mana_changed.connect(mana_bar.refresh_icons)

func _unhandled_input(event: InputEvent) -> void:
	# Debug stand-in. The real trigger (sinking a hole / clearing the encounter)
	# arrives with the combat steps; for now a key flips between walking and
	# driving so the swap can be playtested on its own.
	if event.is_action_pressed("debug_toggle_cart"):
		set_driving(not driving)

func wire_mana_loops() -> void:
	for loop in get_tree().get_nodes_in_group("mana_loop"):
		loop.mana_collected.connect(player.mana_pool.add)

func log_mana(element: ManaPool.Element, amount: int) -> void:
	print(ManaPool.Element.keys()[element], " = ", amount)

func set_driving(value: bool) -> void:
	driving = value
	if driving:
		enter_cart()
	else:
		exit_cart()

# Snap the cart to the player and hand it control. Parking the whole player
# subtree via process_mode silences its movement, look, AND golf inputs in one
# move; the cart subtree wakes up the same way.
func enter_cart() -> void:
	teleport_cart_to_player()
	# The parked player still has a collision capsule sitting right where the cart
	# spawns. Drop it out of the shared collision layer so the cart doesn't jam
	# against the body it just teleported on top of.
	player.set_collision_layer_value(1, false)
	cart.process_mode = Node.PROCESS_MODE_INHERIT
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.hide()
	cart.show()
	cart_camera.make_current()

func exit_cart() -> void:
	teleport_player_to_cart()
	player.set_collision_layer_value(1, true)
	player.process_mode = Node.PROCESS_MODE_INHERIT
	cart.process_mode = Node.PROCESS_MODE_DISABLED
	cart.hide()
	player.show()
	player_camera.make_current()

# Drop the cart where the player stands, facing the same way they were, with its
# velocity wiped so it doesn't carry over a leftover shove.
func teleport_cart_to_player() -> void:
	cart.global_position = player.global_position
	cart.global_rotation = Vector3(0.0, player.global_rotation.y, 0.0)
	cart.velocity = Vector3.ZERO

func teleport_player_to_cart() -> void:
	player.global_position = cart.global_position
	player.global_rotation = Vector3(0.0, cart.global_rotation.y, 0.0)
	player.velocity = Vector3.ZERO
