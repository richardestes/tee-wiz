class_name WaterHazard extends Area3D

func _ready() -> void:
	body_entered.connect(swallow)

func swallow(body: Node3D)-> void:
	if body is Ball:
		body.queue_free()
