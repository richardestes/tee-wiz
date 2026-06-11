class_name ArcPreview extends MeshInstance3D

@export var color: Color = Color(1.0, 0.9, 0.2)
@export var max_points: int = 400
@export var stop_height: float = 0.0


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

func draw_arc(start: Vector3, velocity: Vector3, damp: float) -> void:
	var gravity := get_gravity_vector()
	var step := 1.0 / Engine.physics_ticks_per_second
	var point := start
	var motion := velocity

	_line.clear_surfaces()
	_line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _material)
	_line.surface_add_vertex(point)
	# Step the same way the physics engine does: accelerate by gravity, apply drag,
	# then move. Matching its integration is what makes the preview land where the ball will.
	for i in max_points:
		motion += gravity * step
		motion *= maxf(1.0 - damp * step, 0.0)
		point += motion * step
		_line.surface_add_vertex(point)
		if point.y <= stop_height:
			break
	_line.surface_end()

func draw_line(start: Vector3, direction: Vector3, length: float) -> void:
	_line.clear_surfaces()
	_line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _material)
	_line.surface_add_vertex(start)
	_line.surface_add_vertex(start + direction.normalized() * length)
	_line.surface_end()

func clear() -> void:
	_line.clear_surfaces()

func get_gravity_vector() -> Vector3:
	var strength: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var direction: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
	return direction * strength
