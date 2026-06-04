class_name Player extends CharacterBody3D

@export var input: InputComponent
@export var speed: float = 5.0
@export var jump_strength: float = 5.0
@export var gravity: float = 20.0

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	apply_jump()
	apply_movement()
	move_and_slide()

# Pull the body down when it isn't standing on something. is_on_floor() is
# updated by the previous move_and_slide(), so this reads last frame's result.
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func apply_jump() -> void:
	if input.wants_jump() and is_on_floor():
		velocity.y = jump_strength

func apply_movement() -> void:
	var move := input.get_move_direction()
	# Turn the flat 2D push into a direction in front of the body: forward (+y)
	# becomes -Z. Running it through the body's own rotation means "forward"
	# follows wherever the body is facing once mouse-look starts yawing it.
	var local_direction := Vector3(move.x, 0.0, -move.y)
	var world_direction := transform.basis * local_direction
	velocity.x = world_direction.x * speed
	velocity.z = world_direction.z * speed
