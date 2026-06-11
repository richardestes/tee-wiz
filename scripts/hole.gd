class_name Hole extends Node3D

@export var putt_radius: float = 10.0

@onready var zone: Area3D = $Area3D
@onready var cup: MeshInstance3D = $Cup

signal zone_entered(body: Node3D)
signal zone_exited(body: Node3D)

func _ready() -> void:
	add_to_group("holes")
	zone.body_entered.connect(enter_zone)
	zone.body_exited.connect(exit_zone)

func enter_zone(body: Node3D)-> void:
	zone_entered.emit(body)

func exit_zone(body: Node3D)-> void:
	zone_exited.emit(body)

func cup_position()-> Vector3:
	return cup.global_position

func within_putt_range(point: Vector3) -> bool:
	var to_cup := cup.global_position - point
	return Vector2(to_cup.x, to_cup.z).length() <= putt_radius
