class_name Ball extends RigidBody3D

@export var beam: MeshInstance3D
@onready var beam_radius: Area3D = get_node("BeamRadius")

const BEAM_HALF_HEIGHT:= 20.0

@export var rest_speed_threshold: float = 0.5

var player_nearby: bool = false
var beam_locked: bool = false

func _ready() -> void:
	add_to_group("balls")
	sleeping_state_changed.connect(update_indicators)
	beam_radius.body_entered.connect(refresh_proximity)
	beam_radius.body_exited.connect(refresh_proximity)
	update_indicators()

func _physics_process(_delta: float) -> void:
	if sleeping:
		return
	if creeping_to_a_stop():
		come_to_rest()

func creeping_to_a_stop() -> bool:
	return linear_velocity.length() < rest_speed_threshold and angular_velocity.length() < rest_speed_threshold

func come_to_rest() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true

func lock_beam() -> void:
	beam_locked = true

func unlock_beam() -> void:
	beam_locked = false

func update_indicators()-> void:
	beam.visible = sleeping and not player_nearby
	if beam.visible:
		beam.global_position = global_position + Vector3.UP * BEAM_HALF_HEIGHT
		beam.global_rotation = Vector3.ZERO

static func compute_velocity(aim_direction: Vector3, power: float) -> Vector3:
	return aim_direction.normalized() * power

func launch(velocity: Vector3) -> void:
	linear_velocity = velocity
	angular_velocity = Vector3.ZERO
	
func is_at_rest() -> bool:
	return sleeping

func refresh_proximity(_body: Node3D)-> void:
	var occupied := not beam_radius.get_overlapping_bodies().is_empty()
	if beam_locked and not occupied:
		return
	player_nearby = occupied
	update_indicators()
