extends CharacterBody3D

const ACCELERATION := 24.0
const DECELERATION := 16.0
const TURN_SPEED := 2.5
const HEIGHT_ABOVE_GROUND := 0.5

@export var terrain: Node3D
@export var max_speed := 12.0

var current_speed := 0.0

func _ready() -> void:
	snap_to_terrain()

func _physics_process(delta: float) -> void:
	var forward_input := get_forward_input()
	var turn_input := get_turn_input()

	rotate_y(turn_input * TURN_SPEED * delta)

	var target_speed := max_speed * forward_input
	var rate := ACCELERATION if forward_input != 0.0 else DECELERATION
	current_speed = move_toward(current_speed, target_speed, rate * delta)

	var forward_dir := -global_transform.basis.z
	velocity = forward_dir * current_speed
	move_and_slide()

	snap_to_terrain()

func get_forward_input() -> float:
	var value := 0.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		value += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		value -= 1.0
	return value

func get_turn_input() -> float:
	var value := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		value += 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		value -= 1.0
	return value

func snap_to_terrain() -> void:
	if terrain == null:
		return
	global_position.y = terrain.get_height(global_position.x, global_position.z) + HEIGHT_ABOVE_GROUND
