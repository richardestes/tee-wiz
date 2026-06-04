extends RigidBody3D

const MAX_DRAG := 20.0
const MIN_SHOT_POWER := 1.0
const MAX_IMPULSE := 90.0
const LOFT_FACTOR := 0.7
# How many world units of "pull" per pixel of mouse travel. ~300px drag = MAX_DRAG.
const PIXEL_TO_WORLD := 0.1

# Angular damping varies by terrain zone so rough actually punishes the roll.
# Friction doesn't kill a rolling ball — only a sliding one — so we use angular_damp instead.
const BASE_ANGULAR_DAMP := 2.0
const ROUGH_ANGULAR_DAMP := 5.0

# Force-sleep thresholds — trimesh terrain jitter keeps the engine from sleeping
# the ball on its own, so we put it to sleep ourselves once it's barely moving.
const REST_LINEAR_SPEED := 1.5
const REST_ANGULAR_SPEED := 7.0
const REST_DURATION := 0.15

var drag_start_screen : Vector2
var is_dragging : bool
var _rest_timer := 0.0
var starting_position: Vector3
@onready var aim_line: Node3D = get_node("AimLine")
@onready var camera: Camera3D = get_node("../Camera3D")
@export var terrain: Node3D

func _ready() -> void:
	angular_damp = BASE_ANGULAR_DAMP
	starting_position = global_position
	sleeping_state_changed.connect(_on_sleeping_state_changed)
	Events.change_state_encounter.connect(reset)

func reset() -> void:
	is_dragging = false
	aim_line.hide_aim()
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = starting_position
	sleeping = true

func _physics_process(delta: float) -> void:
	update_angular_damp()
	_try_force_sleep(delta)
	if not is_dragging: return
	var drag := get_drag_vector()
	if drag.length() < MIN_SHOT_POWER:
		aim_line.hide_aim()
		return
	var velocity := compute_velocity(drag)
	var gravity_strength : float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var gravity_vector := Vector3.DOWN * gravity_strength * gravity_scale
	aim_line.show_aim(global_position, velocity, gravity_vector, linear_damp)

func _try_force_sleep(delta: float) -> void:
	if sleeping: return
	var slow_enough := linear_velocity.length() < REST_LINEAR_SPEED \
		and angular_velocity.length() < REST_ANGULAR_SPEED
	if slow_enough:
		_rest_timer += delta
		if _rest_timer >= REST_DURATION:
			sleeping = true
			_rest_timer = 0.0
	else:
		_rest_timer = 0.0
	
func compute_velocity(drag_vector: Vector3) -> Vector3:
	var direction := drag_vector.normalized()
	var power_curve := drag_vector.length() / MAX_DRAG
	# sqrt curve: soft response at low drag, diminishing returns at high drag
	var power := sqrt(power_curve) * MAX_IMPULSE
	var loft := 0.0 if is_on_green() else power * LOFT_FACTOR
	return direction * power + Vector3.UP * loft

func is_on_green() -> bool:
	if terrain == null: return false
	return terrain.is_green(global_position.x, global_position.z)

func is_on_rough() -> bool:
	if terrain == null: return false
	return terrain.is_rough(global_position.x, global_position.z)

func update_angular_damp() -> void:
	angular_damp = ROUGH_ANGULAR_DAMP if is_on_rough() else BASE_ANGULAR_DAMP

# Screen drag → ball-relative impulse aligned to camera. Only the delta matters, not click location.
func get_drag_vector() -> Vector3:
	var screen_delta := get_viewport().get_mouse_position() - drag_start_screen

	var forward: Vector3 = camera.aim_direction
	var right := forward.cross(Vector3.UP).normalized()

	# Slingshot semantics in camera-relative space:
	#   drag DOWN on screen (+y) → shot forward (toward hole)
	#   drag RIGHT on screen (+x) → shot deflects LEFT
	var drag_world := forward * screen_delta.y * PIXEL_TO_WORLD + right * screen_delta.x * PIXEL_TO_WORLD
	return drag_world.limit_length(MAX_DRAG)

func _on_sleeping_state_changed() -> void:
	return

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	# Only allow input while ball is at rest — no mid-flight aim
	if not sleeping:
		return

	if event.pressed:
		drag_start_screen = get_viewport().get_mouse_position()
		is_dragging = true
	else:
		if not is_dragging: return
		is_dragging = false
		aim_line.hide_aim()
		var drag_vector := get_drag_vector()
		if drag_vector.length() < MIN_SHOT_POWER: return
		apply_central_impulse(compute_velocity(drag_vector))
