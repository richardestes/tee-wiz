extends Sprite3D

signal died

@export var stats: EnemyStats

@export var health: HealthComponent
@export var movement: MovementComponent

func _ready() -> void:
	health.max_hp = stats.max_hp
	health.current_hp = stats.max_hp
	health.died.connect(handle_death)
	add_to_group("enemies")

func take_damage(amount: int) -> void:
	health.take_damage(amount)

func handle_death() -> void:
	died.emit()
	queue_free()
