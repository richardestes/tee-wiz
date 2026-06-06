class_name Ball extends RigidBody3D

static func compute_velocity(aim_direction: Vector3, power: float) -> Vector3:
	return aim_direction.normalized() * power

func launch(velocity: Vector3) -> void:
	linear_velocity = velocity
	angular_velocity = Vector3.ZERO
