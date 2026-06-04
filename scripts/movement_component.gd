class_name MovementComponent extends Node

@export var speed: float = 1.5
@export var target: Node3D
@export var subject: Node3D

func _process(delta: float) -> void:
	if target == null:
		return
	move_toward_target(delta)

func move_toward_target(delta: float) -> void:
	var to_target: Vector3 = target.global_position - subject.global_position
	to_target.y = 0
	var direction: Vector3 = to_target.normalized()
	subject.global_position += direction * speed * delta
