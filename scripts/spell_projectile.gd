class_name SpellProjectile extends Area3D

@export var speed: float = 20.0
@export var lifetime: float = 4.0

var velocity : Vector3

func launch(direction: Vector3) -> void:
	velocity = direction.normalized() * speed
	
func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	

	
