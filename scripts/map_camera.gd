extends Camera3D

@export var cart: Node3D
@export var distance_behind := 15.0
@export var height_above := 25.0
@export var follow_speed := 8.0

func _ready() -> void:
	snap_to_target()

func _physics_process(delta: float) -> void:
	if cart == null:
		return
	var target := get_target_position()
	global_position = global_position.lerp(target, follow_speed * delta)
	look_at(cart.global_position, Vector3.UP)

func get_target_position() -> Vector3:
	return cart.global_position + Vector3.BACK * distance_behind + Vector3.UP * height_above

func snap_to_target() -> void:
	if cart == null:
		return
	global_position = get_target_position()
	look_at(cart.global_position, Vector3.UP)
