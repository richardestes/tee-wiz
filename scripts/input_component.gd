class_name InputComponent extends Node

func get_move_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_back", "move_forward")

func wants_jump() -> bool:
	return Input.is_action_just_pressed("jump")

func wants_charge_start() -> bool:
	return Input.is_action_pressed("golf_charge")

func wants_charge_stop() -> bool:
	return Input.is_action_just_released("golf_charge")

func wants_lock_on() -> bool:
	return Input.is_action_pressed("golf_lock_on")

func wants_cast() -> bool:
	return Input.is_action_just_pressed("cast_spell")

func wants_cancel_shot() -> bool:
	return Input.is_action_just_pressed("cancel_shot")

func wants_reset_ball() -> bool:
	return Input.is_action_just_pressed("reset_ball")

func cycle_spell_step() -> int:
	if Input.is_action_just_pressed("cycle_spell_next"):
		return 1
	if Input.is_action_just_pressed("cycle_spell_prev"):
		return -1
	return 0
