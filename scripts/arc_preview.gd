# Draws the golf shot's flight path as one solid line.
class_name ArcPreview extends MeshInstance3D

@export var color: Color = Color(1.0, 0.9, 0.2)
@export var max_points: int = 400
@export var stop_height: float = 0.0	# quit tracing once the arc reaches the ground


var _line: ImmediateMesh
var _material: StandardMaterial3D

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY

	_line = ImmediateMesh.new()
	mesh = _line

	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = color

func draw_arc(start: Vector3, velocity: Vector3) -> void:
	var gravity := get_gravity_vector()
	var step := 1.0 / Engine.physics_ticks_per_second
	var point := start
	var motion := velocity

	_line.clear_surfaces()
	_line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _material)
	_line.surface_add_vertex(point)
	for i in max_points:
		motion += gravity * step   # velocity updated before position — same order as the engine
		point += motion * step
		_line.surface_add_vertex(point)
		if point.y <= stop_height:
			break
	_line.surface_end()

func clear() -> void:
	_line.clear_surfaces()

func get_gravity_vector() -> Vector3:
	var strength: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var direction: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
	return direction * strength
