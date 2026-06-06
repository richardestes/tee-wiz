class_name InputComponent extends Node

# Convention: +y means "forward". Locomotion translates that into -Z later.
func get_move_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_back", "move_forward")

# True only on the single frame the jump key goes down
func wants_jump() -> bool:
	return Input.is_action_just_pressed("jump")

func is_charging() -> bool:
	return Input.is_action_pressed("golf_charge")

# True only on the frame the button is let go
func wants_release() -> bool:
	return Input.is_action_just_released("golf_charge")

func is_locking_on() -> bool:
	return Input.is_action_pressed("golf_lock_on")

func wants_cast() -> bool:
	return Input.is_action_just_pressed("cast_spell")
