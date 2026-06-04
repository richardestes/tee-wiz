extends Node3D

const X_SPACING := 20.0
const Z_SPACING := 50.0
const X_CENTER_OFFSET := (MapGenerator.COLS -1 ) * X_SPACING / 2.0

@onready var terrain := $MapTerrain
@onready var prompt := $CanvasLayer/Label
var current_node : MapNode = null
var last_activated_node : MapNode = null
var par_labels : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var nodes: Array[MapNode] = MapGenerator.generate()
	for node in nodes:
		place_cube(node)
		place_par_label(node)
		place_activation_area(node)
	draw_connections(nodes)

func place_cube(node: MapNode) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	mesh_instance.mesh = box_mesh
	mesh_instance.position = get_world_position(node) + Vector3.UP * 0.5
	var mesh_material := StandardMaterial3D.new()
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	match node.type:
		"combat":
			mesh_material.albedo_color = Color.WHITE
		"shop":
			mesh_material.albedo_color = Color.GOLD
		"boss":
			mesh_material.albedo_color = Color.RED
	mesh_instance.material_override = mesh_material
	add_child(mesh_instance)
	
func place_par_label(node: MapNode) -> void:
	var label := Label3D.new()
	label.position = get_world_position(node) + Vector3.UP * 2.0
	label.pixel_size = 0.05
	label.font_size = 32
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	if node.type == "shop":
		label.text = "Shop"
	else:
		label.text = str("Par ", node.par)
	label.modulate = Color.WHITE if is_node_legal(node) else Color(0.3, 0.3, 0.3)
	par_labels[node] = label
	add_child(label)

func draw_connections(nodes: Array[MapNode]) -> void:
	var node_by_id := {}
	for node in nodes:
		node_by_id[node.id] = node
	
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	for node in nodes:
		for connection_id in node.connections:
			var destination: MapNode = node_by_id[connection_id]
			surface_tool.add_vertex(get_world_position(node))
			surface_tool.add_vertex(get_world_position(destination))
	var line_mesh := surface_tool.commit()
	
	var line_material := StandardMaterial3D.new()
	line_material.albedo_color = Color.YELLOW
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var line_instance := MeshInstance3D.new()
	line_instance.mesh = line_mesh
	line_instance.material_override = line_material
	add_child(line_instance)

func get_world_position(node: MapNode) -> Vector3:
	var world_x := node.col * X_SPACING - X_CENTER_OFFSET
	var world_z := -node.row * Z_SPACING
	return Vector3(world_x, terrain.get_height(world_x, world_z), world_z)
	
func place_activation_area(node: MapNode) -> void:
	var area := Area3D.new()
	var collision_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	var activation_radius := 3.0
	sphere.radius = activation_radius
	collision_shape.shape = sphere
	area.position = get_world_position(node)
	area.collision_mask = 2 # cart
	area.add_child(collision_shape)
	area.body_entered.connect(on_node_entered.bind(node))
	area.body_exited.connect(on_node_exited.bind(node))
	add_child(area)

func on_node_entered(body: Node3D, node: MapNode) -> void:
	current_node = node
	update_prompt()

func on_node_exited(body: Node3D, node: MapNode) -> void:
	if current_node == node:
		current_node = null
		prompt.visible = false

func is_node_legal(node: MapNode) -> bool:
	if last_activated_node == null:
		return node.row == 0
	return node.id in last_activated_node.connections

func update_prompt() -> void:
	prompt.visible = is_node_legal(current_node)

func refresh_par_label_colors() -> void:
	for node in par_labels:
		var label: Label3D = par_labels[node]
		label.modulate = Color.WHITE if is_node_legal(node) else Color(0.3, 0.3, 0.3)

func activate() -> void:
	if current_node == null: return
	if not is_node_legal(current_node): return
	last_activated_node = current_node
	refresh_par_label_colors()
	update_prompt()
	match current_node.type:
		"combat", "boss":
			GameState.change_state(GameState.State.ENCOUNTER)
		"shop":
			print("Shop activated")
