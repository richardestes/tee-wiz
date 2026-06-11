class_name Player extends CharacterBody3D

@export var input: InputComponent
@export var speed: float = 5.0
@export var jump_strength: float = 5.0
@export var gravity: float = 20.0
@export var mana_pool : ManaPool
@export var spell_hand: SpellHand
@export var right_hand: RightHandController
@export var cart: Cart
@export var player_camera: Camera3D

signal entered_cart
signal exited_cart

var driving: bool = false
var swapping: bool = false

func _ready() -> void:
	player_camera.make_current()

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	apply_jump()
	apply_movement()
	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func apply_jump() -> void:
	if input.wants_jump() and is_on_floor():
		velocity.y = jump_strength

func apply_movement() -> void:
	var move := input.get_move_direction()
	var local_direction := Vector3(move.x, 0.0, -move.y)
	var world_direction := transform.basis * local_direction
	velocity.x = world_direction.x * speed
	velocity.z = world_direction.z * speed

func set_driving(value: bool) -> void:
	if swapping: return
	driving = value
	if driving:
		await enter_cart()
	else:
		await exit_cart()

func enter_cart() -> void:
	swapping = true
	right_hand.cancel_shot()
	get_tree().call_group("balls", "lock_beam")
	teleport_cart_to_player()
	cart.process_mode = Node.PROCESS_MODE_INHERIT
	cart.show()
	cart.cart_camera.make_current()
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()
	await get_tree().physics_frame
	entered_cart.emit()
	get_tree().call_group("balls", "unlock_beam")
	swapping = false

func exit_cart() -> void:
	swapping = true
	get_tree().call_group("balls", "lock_beam")
	teleport_player_to_cart()
	process_mode = Node.PROCESS_MODE_INHERIT
	show()
	player_camera.make_current()
	cart.process_mode = Node.PROCESS_MODE_DISABLED
	cart.hide()
	await get_tree().physics_frame
	exited_cart.emit()
	get_tree().call_group("balls", "unlock_beam")
	swapping = false

func teleport_cart_to_player() -> void:
	cart.global_position = global_position
	cart.global_rotation = Vector3(0.0, global_rotation.y, 0.0)
	cart.velocity = Vector3.ZERO

func teleport_player_to_cart() -> void:
	global_position = cart.global_position
	global_rotation = Vector3(0.0, cart.global_rotation.y, 0.0)
	velocity = Vector3.ZERO
