class_name HealthComponent extends Node

signal health_changed
signal died

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health = clampi(current_health-amount, 0, max_health)
	health_changed.emit(current_health)
	if current_health <= 0:
		died.emit()
