extends Node3D

enum ZONE {FAIRWAY, ROUGH, GREEN}

const PLANE_WIDTH := 600.0
const PLANE_LENGTH := 800.0
const CELLS_X := 120
const CELLS_Z := 160

@export var tee_position: Vector2 = Vector2(0, 197)
@export var hole_position: Vector2 = Vector2(0, -145)
# Centerline gets min_bend_count..max_bend_count random bends, each offset by ±max_bend_strength.
@export var min_bend_count: int = 1
@export var max_bend_count: int = 2
@export var max_bend_strength: float = 80.0
@export var fairway_width: float = 60.0
@export var green_radius: float = 30.0
@export var green_amplitude: float = 0.0
@export var fairway_amplitude: float = 1.0
@export var rough_amplitude: float = 4.0
@export var blend_width: float = 15.0
@export var curve_smoothing: float = 1.0
@export var noise_frequency: float = 0.01

@export var hole_node: Node3D
@export var ball_node: Node3D

# Ball spawns this many world units above the terrain so it drops onto the surface,
# not into it. Matches the old hardcoded Y=1 from the flat-ground era.
const BALL_SPAWN_HEIGHT := 1.0

var noise := FastNoiseLite.new()
var _polyline: PackedVector2Array

# Background hole generation: worker thread builds the NEXT hole's meshes/shapes
# while the player is in COLLECT_REWARD/MAP, so the ENCOUNTER transition only
# pays a main-thread "assign refs" cost instead of the ~660ms full build.
var _pending_task_id: int = -1
var _pending_bundle: Dictionary = {}

func _ready() -> void:
	Events.change_state_collect_reward.connect(start_precompute)
	# GAME_OVER -> R -> ENCOUNTER (retry) also wants a fresh hole, but skips
	# COLLECT_REWARD. Precompute while the player reads "YOU DIED".
	Events.change_state_game_over.connect(start_precompute)
	Events.change_state_encounter.connect(apply_precomputed)
	# Hole #1 is built sync — no prior state to amortize against (the launch hitch
	# is acceptable, per Plan B's note). Also gives the ball a surface to rest on
	# during MAP navigation, so it doesn't freefall through nothing before the
	# first ENCOUNTER swaps the precomputed bundle in.
	apply_hole_bundle(build_hole_bundle())

# Called when the player enters COLLECT_REWARD. Kicks the next hole's compute
# onto a worker thread. By the time the player navigates reward -> map -> picks
# a node -> ENCOUNTER, the bundle is (almost certainly) already sitting in
# _pending_bundle, ready for a ms-scale apply.
func start_precompute() -> void:
	if _pending_task_id != -1:
		# Already precomputing (defensive — shouldn't happen given the state machine,
		# but means we'd leak a task if it did).
		return
	_pending_bundle = {}
	_pending_task_id = WorkerThreadPool.add_task(_precompute_worker)

# Runs on the worker thread. Writes the bundle into a member var; the main
# thread reads it back after wait_for_task_completion returns.
func _precompute_worker() -> void:
	_pending_bundle = build_hole_bundle()

# Main thread. If the worker isn't done yet (player blasted through the map),
# wait_for_task_completion blocks until it is — correctness preserved, with
# the tail-case hitch bounded by however much work was left.
func apply_precomputed() -> void:
	if _pending_task_id == -1:
		# No precompute in flight — first ENCOUNTER uses the sync build from
		# _ready, so nothing to do here. ball.reset() (also wired to this signal)
		# handles ball positioning.
		return
	WorkerThreadPool.wait_for_task_completion(_pending_task_id)
	apply_hole_bundle(_pending_bundle)
	_pending_task_id = -1
	_pending_bundle = {}

# Pure compute — no scene access. Safe to run on a WorkerThreadPool task.
# Returns everything the main thread needs to swap the next hole in.
func build_hole_bundle() -> Dictionary:
	randomize()
	noise.frequency = noise_frequency
	noise.seed = randi()
	_polyline = build_polyline(generate_waypoints())
	var meshes := build_zone_meshes()

	var zones: Dictionary = {}
	for zone: ZONE in meshes.keys():
		var mesh: ArrayMesh = meshes[zone]
		zones[zone] = {
			"mesh": mesh,
			"shape": mesh.create_trimesh_shape(),
		}

	var hole_x := hole_position.x
	var hole_z := hole_position.y
	var tee_x := tee_position.x
	var tee_z := tee_position.y
	return {
		"zones": zones,
		"hole_world_position": Vector3(hole_x, get_height(hole_x, hole_z), hole_z),
		"ball_world_position": Vector3(tee_x, get_height(tee_x, tee_z) + BALL_SPAWN_HEIGHT, tee_z),
	}

# Main-thread only — touches scene nodes (mesh/shape assignment, position writes).
func apply_hole_bundle(bundle: Dictionary) -> void:
	var zones: Dictionary = bundle["zones"]
	apply_body($FairwayBody, zones[ZONE.FAIRWAY], Color(0.3, 0.6, 0.2))
	apply_body($RoughBody, zones[ZONE.ROUGH], Color(0.4, 0.3, 0.1))
	apply_body($GreenBody, zones[ZONE.GREEN], Color(0.65, 1.0, 0.35))

	hole_node.position = bundle["hole_world_position"]
	var ball_world_position: Vector3 = bundle["ball_world_position"]
	ball_node.global_position = ball_world_position
	# Ball's _ready already cached an outdated starting_position from the editor transform —
	# overwrite it so reset() returns the ball to the procedurally-derived tee, not the stale one.
	ball_node.starting_position = ball_world_position

func apply_body(body: StaticBody3D, zone_data: Dictionary, color: Color) -> void:
	var mesh_instance: MeshInstance3D = body.get_node("MeshInstance3D")
	var collision_shape: CollisionShape3D = body.get_node("CollisionShape3D")
	mesh_instance.mesh = zone_data["mesh"]
	collision_shape.shape = zone_data["shape"]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.set_surface_override_material(0, mat)

func build_zone_meshes() -> Dictionary:
	var tools: Dictionary = {
		ZONE.FAIRWAY: SurfaceTool.new(),
		ZONE.ROUGH: SurfaceTool.new(),
		ZONE.GREEN: SurfaceTool.new(),
	}
	for tool: SurfaceTool in tools.values():
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var cell_size_x := PLANE_WIDTH / CELLS_X
	var cell_size_z := PLANE_LENGTH / CELLS_Z
	var half_width := PLANE_WIDTH / 2.0
	var half_length := PLANE_LENGTH / 2.0

	# Each corner is shared by up to 4 cells, but its height is the same no
	# matter which cell asks. Compute every corner's height once here, then
	# the cell loop below just looks them up — 4x fewer expensive calls.
	# PackedFloat32Array is a typed float buffer (fast). The 2D corner grid
	# is flattened into 1D: the corner at grid position (x, z) lives at
	# index `x * corner_count_z + z`.
	var corner_count_z := CELLS_Z + 1
	var corner_heights := PackedFloat32Array()
	corner_heights.resize((CELLS_X + 1) * corner_count_z)
	for corner_x in CELLS_X + 1:
		var world_x := -half_width + corner_x * cell_size_x
		for corner_z in corner_count_z:
			var world_z := -half_length + corner_z * cell_size_z
			corner_heights[corner_x * corner_count_z + corner_z] = get_height(world_x, world_z)

	for cell_x in CELLS_X:
		for cell_z in CELLS_Z:
			var left_x := -half_width + cell_x * cell_size_x
			var right_x := left_x + cell_size_x
			var near_z := -half_length + cell_z * cell_size_z
			var far_z := near_z + cell_size_z

			var near_left_height := corner_heights[cell_x * corner_count_z + cell_z]
			var near_right_height := corner_heights[(cell_x + 1) * corner_count_z + cell_z]
			var far_left_height := corner_heights[cell_x * corner_count_z + (cell_z + 1)]
			var far_right_height := corner_heights[(cell_x + 1) * corner_count_z + (cell_z + 1)]

			var near_left_corner := Vector3(left_x, near_left_height, near_z)
			var near_right_corner := Vector3(right_x, near_right_height, near_z)
			var far_left_corner := Vector3(left_x, far_left_height, far_z)
			var far_right_corner := Vector3(right_x, far_right_height, far_z)

			var center_x := (left_x + right_x) / 2
			var center_z := (near_z + far_z) / 2

			var zone := get_zone(center_x, center_z)
			var tool: SurfaceTool = tools[zone]

			# Triangle A: near_left -> near_right -> far_right (CCW from above, front faces up)
			tool.add_vertex(near_left_corner)
			tool.add_vertex(near_right_corner)
			tool.add_vertex(far_right_corner)

			# Triangle B: near_left -> far_right -> far_left (also CCW from above)
			tool.add_vertex(near_left_corner)
			tool.add_vertex(far_right_corner)
			tool.add_vertex(far_left_corner)

	var meshes: Dictionary = {}
	for zone: ZONE in tools.keys():
		var tool: SurfaceTool = tools[zone]
		tool.generate_normals()
		var mesh := ArrayMesh.new()
		tool.commit(mesh)
		meshes[zone] = mesh
	return meshes

func get_height(world_x: float, world_z: float) -> float:
	return noise.get_noise_2d(world_x, world_z) * get_amplitude(world_x, world_z)

func get_amplitude(world_x: float, world_z: float) -> float:
	var point := Vector2(world_x, world_z)

	# Blend 1: fairway -> rough as we move away from the centerline.
	var dist_to_centerline := get_distance_to_centerline(world_x, world_z)
	var fairway_edge := fairway_width / 2.0
	var t_rough := clampf((dist_to_centerline - fairway_edge) / blend_width, 0.0, 1.0)
	var fairway_or_rough := lerpf(fairway_amplitude, rough_amplitude, t_rough)

	# Blend 2: green pulls amplitude down toward green_amplitude near the hole.
	var dist_to_hole := point.distance_to(hole_position)
	var t_green := clampf((dist_to_hole - green_radius) / blend_width, 0.0, 1.0)
	return lerpf(green_amplitude, fairway_or_rough, t_green)

func get_distance_to_centerline(world_x: float, world_z: float) -> float:
	# Distance-to-segment math, inlined. It used to live in a helper function
	# (cleaner to read), but this loop runs millions of times per hole and
	# GDScript function-call overhead was the bottleneck. Also tracking
	# squared distance and taking sqrt once at the end (instead of ~70
	# sqrts per call) is a small bonus win.
	var point := Vector2(world_x, world_z)
	var min_distance_squared := INF
	for i in _polyline.size() - 1:
		var segment_start := _polyline[i]
		var segment := _polyline[i + 1] - segment_start
		var to_point := point - segment_start
		var t := clampf(to_point.dot(segment) / segment.length_squared(), 0.0, 1.0)
		var closest := segment_start + segment * t
		var distance_squared := point.distance_squared_to(closest)
		if distance_squared < min_distance_squared:
			min_distance_squared = distance_squared
	return sqrt(min_distance_squared)

func generate_waypoints() -> PackedVector2Array:
	var count := randi_range(min_bend_count, max_bend_count)
	var generated := PackedVector2Array()
	for i in count:
		var t := (i + 1.0) / (count + 1.0)
		var z := lerpf(tee_position.y, hole_position.y, t)
		var x_offset := randf_range(-max_bend_strength, max_bend_strength)
		generated.append(Vector2(x_offset, z))
	return generated

func build_polyline(waypoints: PackedVector2Array) -> PackedVector2Array:
	if waypoints.is_empty():
		return PackedVector2Array([tee_position, hole_position])

	var curve := Curve2D.new()
	curve.bake_interval = 5.0
	curve.add_point(tee_position)
	for waypoint in waypoints:
		curve.add_point(waypoint)
	curve.add_point(hole_position)

	# Catmull-Rom-style tangents at each interior waypoint: handle length proportional to
	# the chord between its neighbors, which produces a smooth bezier through all points.
	for i in range(1, curve.point_count - 1):
		var prev_point := curve.get_point_position(i - 1)
		var next_point := curve.get_point_position(i + 1)
		var tangent_handle := (next_point - prev_point) * curve_smoothing / 3.0
		curve.set_point_in(i, -tangent_handle)
		curve.set_point_out(i, tangent_handle)

	return curve.get_baked_points()

func get_zone(world_x: float, world_z: float) -> ZONE:
	var point := Vector2(world_x, world_z)
	if point.distance_to(hole_position) < green_radius:
		return ZONE.GREEN
	if get_distance_to_centerline(world_x, world_z) < fairway_width / 2:
		return ZONE.FAIRWAY
	return ZONE.ROUGH

func is_green(world_x: float, world_z: float) -> bool:
	return get_zone(world_x, world_z) == ZONE.GREEN

func is_rough(world_x: float, world_z: float) -> bool:
	return get_zone(world_x, world_z) == ZONE.ROUGH
