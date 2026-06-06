class_name LookComponent extends Node

@export var yaw_target: Node3D     # turned left/right — usually the body
@export var pitch_target: Node3D   # tilted up/down — usually the head
@export var sensitivity: float = 0.003
@export var pitch_limit_degrees: float = 89.0

# Running up/down angle, in radians. Stored so we can clamp it each frame
# instead of letting the head roll past straight-up or straight-down.
var pitch: float = 0.0

func _ready() -> void:
	capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		release_mouse()
	elif event is InputEventMouseButton and event.pressed:
		capture_mouse()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.relative)

# Yaw turns the whole body so movement follows your gaze; pitch only tilts the
# head, so looking up never tips the body over.
func look(mouse_motion: Vector2) -> void:
	yaw_target.rotate_y(-mouse_motion.x * sensitivity)
	pitch -= mouse_motion.y * sensitivity
	aim_pitch(pitch)
	
func aim_pitch(radians: float) -> void:
	pitch = clampf(radians, deg_to_rad(-pitch_limit_degrees), deg_to_rad(pitch_limit_degrees))
	pitch_target.rotation.x = pitch

func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
