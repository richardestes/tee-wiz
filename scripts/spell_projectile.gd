class_name SpellProjectile extends Area3D

@export var speed: float = 20.0
@export var lifetime: float = 4.0
@export var damage: int = 25

var velocity : Vector3

func _ready() -> void:
	area_entered.connect(hit)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func launch(direction: Vector3) -> void:
	velocity = direction.normalized() * speed

func hit(hurtbox: Area3D) -> void:
	if hurtbox is Hurtbox:
		hurtbox.take_damage(damage)
	queue_free()
