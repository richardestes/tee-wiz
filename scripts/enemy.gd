class_name Enemy extends CharacterBody3D

@export var health : HealthComponent

func _ready() -> void:
	health.died.connect(die)
	
func die() -> void:
	queue_free()
