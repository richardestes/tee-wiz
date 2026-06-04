class_name HealthComponent extends Node

signal died
signal health_changed(current_hp: int, max_hp: int)

@export var max_hp: int = 100
var current_hp: int

func _ready() -> void:
	current_hp = max_hp
	
func take_damage(amount: int) -> void:
	if current_hp <= 0: return
	var new_hp := current_hp - amount
	current_hp = clampi(new_hp, 0, max_hp)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		died.emit()

func heal(amount: int) -> void:
	var new_hp := current_hp + amount
	current_hp = clampi(new_hp, 0, max_hp)
	health_changed.emit(current_hp, max_hp)
	
func increase_max_hp(amount: int) -> void:
	max_hp += amount
	current_hp += amount
	health_changed.emit(current_hp, max_hp)
