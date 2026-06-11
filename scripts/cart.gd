class_name Cart extends CharacterBody3D

@export var input: InputComponent
@export var cart_camera: Camera3D
@export var speed: float = 18.0
@export var turn_speed: float = 5.0
@export var gravity: float = 20.0

func _physics_process(delta: float) -> void:
	var intent := input.get_move_direction()
	steer(intent.x, delta)
	drive(intent.y)
	apply_gravity(delta)
	move_and_slide()

func steer(turn: float, delta: float) -> void:
	rotate_y(-turn * turn_speed * delta)

func drive(throttle: float) -> void:
	var forward := -transform.basis.z
	velocity.x = forward.x * throttle * speed
	velocity.z = forward.z * throttle * speed

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
