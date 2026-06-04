extends Node3D

const DotScene = preload("res://scenes/dot.tscn")

var dots : Array[Node3D] = []

func _ready() -> void:
	# Pre-pool 50 dots up front, hidden — show/hide via .visible, never destroy
	for i in range(50):
		var dot := DotScene.instantiate() as Node3D
		add_child(dot)
		dots.append(dot)
		dot.visible = false

func show_aim(origin: Vector3, initial_velocity: Vector3, gravity: Vector3, damping: float) -> void:
	for dot in dots: dot.visible = false
	const SIMULATED_TIMESTEP := 0.1 # seconds between each dot
	var current_position := origin
	var velocity := initial_velocity
	
	for i in dots.size():
		current_position += velocity * SIMULATED_TIMESTEP
		velocity += gravity * SIMULATED_TIMESTEP
		velocity *= max(0.0, 1.0 - damping * SIMULATED_TIMESTEP)
		if current_position.y < 0: break # stop rendering dots once they hit ground
		dots[i].global_position = current_position
		dots[i].visible = true

func hide_aim() -> void:
	for dot in dots:
		dot.visible = false
