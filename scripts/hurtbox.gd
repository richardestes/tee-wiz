class_name Hurtbox extends Area3D

@export var health: HealthComponent

func take_damage(amount: int) -> void:
	health.take_damage(amount)
