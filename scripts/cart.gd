class_name Cart extends CharacterBody3D

@export var input: InputComponent
@export var speed: float = 18.0      # top drive speed
@export var turn_speed: float = 5.0  # radians/sec the cart swings while steering
@export var gravity: float = 20.0    # keeps it planted on the ground

func _physics_process(delta: float) -> void:
	var intent := input.get_move_direction()  # y = throttle, x = steering
	steer(intent.x, delta)
	drive(intent.y)
	apply_gravity(delta)
	move_and_slide()

func steer(turn: float, delta: float) -> void:
	rotate_y(-turn * turn_speed * delta)

# Push along whatever direction the cart is now facing (-Z is forward).
func drive(throttle: float) -> void:
	var forward := -transform.basis.z
	velocity.x = forward.x * throttle * speed
	velocity.z = forward.z * throttle * speed

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
