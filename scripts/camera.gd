extends Camera3D

@onready var ball: RigidBody3D = get_node("../Ball")
@onready var hole: Node3D = get_node("../Hole")

@export var distance_behind: float = 5.0
@export var height_above: float = 2.0
@export var pitch_degrees: float = -15.0
@export var follow_speed_start: float = 0.3
@export var follow_speed_end: float = 3.0
@export var ramp_duration: float = 2.5
@export var orbit_sensitivity: float = 0.01

var aim_direction: Vector3
var is_orbiting: bool = false
var time_since_shot: float = INF
var starting_position: Vector3
var starting_aim_direction: Vector3

func _ready() -> void:
	var to_hole := hole.global_position - ball.global_position
	to_hole.y = 0
	aim_direction = to_hole.normalized()

	global_position = ball.global_position - aim_direction * distance_behind + Vector3.UP * height_above
	_update_look_target()

	starting_position = global_position
	starting_aim_direction = aim_direction

	ball.sleeping_state_changed.connect(_on_ball_sleeping_changed)
	Events.change_state_encounter.connect(reset)

func reset() -> void:
	aim_direction = starting_aim_direction
	global_position = starting_position
	is_orbiting = false
	time_since_shot = INF
	_update_look_target()

func _on_ball_sleeping_changed() -> void:
	if not ball.sleeping:
		time_since_shot = 0.0

func _physics_process(delta: float) -> void:
	time_since_shot += delta
	var target_position := ball.global_position - aim_direction * distance_behind + Vector3.UP * height_above
	if is_orbiting:
		global_position = target_position
	else:
		var t := clampf(time_since_shot / ramp_duration, 0.0, 1.0)
		var follow_speed := lerpf(follow_speed_start, follow_speed_end, t)
		global_position = global_position.lerp(target_position, follow_speed * delta)
	_update_look_target()

func _update_look_target() -> void:
	var look_distance := 10.0
	var vertical_drop := look_distance * tan(deg_to_rad(pitch_degrees))
	var look_target := global_position + aim_direction * look_distance + Vector3.UP * vertical_drop
	look_at(look_target, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if not ball.sleeping:
		is_orbiting = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		is_orbiting = event.pressed
	elif event is InputEventMouseMotion and is_orbiting:
		var motion := event as InputEventMouseMotion
		var yaw_delta := -motion.relative.x * orbit_sensitivity
		aim_direction = aim_direction.rotated(Vector3.UP, yaw_delta)
