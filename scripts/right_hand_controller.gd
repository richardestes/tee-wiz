class_name RightHandController extends Node

@export var input: InputComponent
@export var aim_source: Node3D
@export var muzzle: Node3D
@export var body: Node3D
@export var look: LookComponent
@export var preview: ArcPreview

@export var ball_scene: PackedScene
@export var projectile_scene: PackedScene

@export var min_power: float = 4.0
@export var max_power: float = 30.0
@export var charge_rate: float = 9.0
@export var reset_drop_distance: float = 6.0
@export var reset_drop_height: float = 3.0
@export var ball_linear_damp: float = 0.2

@export var loft_degrees: float = 50.0
@export var max_pitch_degrees := 75.0
@export var putt_preview_scale: float = 1.0
@export var putt_power_scale: float = 0.5
@export var putt_charge_scale: float = 0.25

@export var turn_speed: float = 6.0
@export var auto_solve_locked_shot: bool = false

@export var mana_pool: ManaPool
@export var spell_hand: SpellHand

var power: float = 0.0
var shot_cancelled: bool = false
var locked_on: bool = false
var target_hole: Hole
var current_hole: Hole
var current_ball: Ball

func _physics_process(delta: float) -> void:
	update_lock_on()
	handle_spell_cycle()
	if input.wants_cast(): cast()
	if input.wants_reset_ball(): reset_ball()
	if locked_on:
		face_hole(delta)
	handle_shot(delta)

func handle_shot(delta: float) -> void:
	if input.wants_charge_start() and ready_to_shoot():
		if input.wants_cancel_shot():
			cancel_shot()
		if shot_cancelled:
			return
		if not (locked_on and auto_solve_locked_shot):
			charge(delta)
		update_preview()
	elif input.wants_charge_stop():
		if shot_cancelled:
			shot_cancelled = false
		else:
			fire()
	else:
		preview.clear()

func cancel_shot() -> void:
	power = 0.0
	preview.clear()
	shot_cancelled = input.wants_charge_start()

func enter_hole(hole: Hole) -> void:
	current_hole = hole

func exit_hole() -> void:
	current_hole = null

func update_lock_on() -> void:
	locked_on = input.wants_lock_on() and current_hole != null
	target_hole = current_hole if locked_on else null

func face_hole(delta: float) -> void:
	var to_hole := target_hole.cup_position() - body.global_position
	var distance := Vector2(to_hole.x, to_hole.z).length()
	if is_zero_approx(distance):
		return
	var aim_yaw := atan2(-to_hole.x, -to_hole.z)
	# The ball launches off to the side of the body's nose, so add asin(offset / distance)
	# to slide that side-shifted launch point onto the line to the cup.
	var correction := asin(clampf(muzzle_offset() / distance, -1.0, 1.0))
	var target_yaw := aim_yaw + correction
	var eye_to_hole := target_hole.cup_position() - aim_source.global_position
	var horizontal := Vector2(eye_to_hole.x, eye_to_hole.z).length()
	var target_pitch := atan2(eye_to_hole.y, horizontal)
	look.aim_pitch(lerpf(look.pitch, target_pitch, minf(turn_speed * delta, 1.0)))
	body.rotation.y = lerp_angle(body.rotation.y, target_yaw, minf(turn_speed * delta, 1.0))

func muzzle_offset() -> float:
	return body.to_local(muzzle.global_position).x

func charge(delta: float) -> void:
	if ball_on_a_green():
		power = clampf(power + charge_rate * putt_charge_scale * delta, min_power, max_power * putt_power_scale)
	else:
		power = clampf(power + charge_rate * delta, min_power, max_power)

func fire() -> void:
	if not ready_to_shoot(): return
	var origin := get_shot_origin()
	if current_ball == null:
		current_ball = spawn_ball()
	current_ball.global_position = origin
	current_ball.launch(Ball.compute_velocity(aim_direction(), current_power()))
	power = 0.0
	preview.clear()

func ready_to_shoot()-> bool:
	if current_ball == null: return true
	return current_ball.is_at_rest() and current_ball.player_nearby

func spawn_ball() -> Ball:
	var new_ball := ball_scene.instantiate() as Ball
	get_tree().current_scene.add_child(new_ball)
	new_ball.tree_exited.connect(forget_ball)
	return new_ball

func forget_ball()-> void:
	current_ball = null

func reset_ball() -> void:
	if current_ball != null:
		current_ball.tree_exited.disconnect(forget_ball)
		current_ball.queue_free()
	current_ball = spawn_ball()
	current_ball.global_position = reset_drop_position()

func reset_heading() -> Vector3:
	var forward := -aim_source.global_transform.basis.z
	return Vector3(forward.x, 0.0, forward.z).normalized()

func reset_drop_position() -> Vector3:
	var ground_spot := body.global_position + reset_heading() * reset_drop_distance
	return ground_spot + Vector3.UP * reset_drop_height

func get_shot_origin()-> Vector3:
	if current_ball != null:
		return current_ball.global_position
	return muzzle_position()

func handle_spell_cycle() -> void:
	var step := input.cycle_spell_step()
	if step != 0:
		spell_hand.cycle_ready(step)

func cast() -> void:
	var spell := spell_hand.ready_card()
	if spell == null: return
	if not mana_pool.can_afford(spell): return
	mana_pool.spend(spell)
	spawn_projectile()
	spell_hand.cast_card(spell_hand.ready_index)

func spawn_projectile() -> void:
	var projectile := projectile_scene.instantiate() as SpellProjectile
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle_position()
	projectile.launch(cast_direction())

func cast_direction() -> Vector3:
	return -aim_source.global_transform.basis.z

func update_preview() -> void:
	var velocity := Ball.compute_velocity(aim_direction(), current_power())
	if ball_on_a_green():
		preview.draw_line(get_shot_origin(), velocity, (current_power() - min_power) * putt_preview_scale)
	else:
		preview.draw_arc(get_shot_origin(), velocity, get_damp())

func get_damp() -> float:
	if current_ball != null:
		return current_ball.linear_damp
	return ball_linear_damp

func current_power() -> float:
	if locked_on and auto_solve_locked_shot:
		return solved_power()
	return power

func aim_direction() -> Vector3:
	if locked_on and auto_solve_locked_shot:
		return lock_on_direction()
	return free_aim_direction()

func free_aim_direction() -> Vector3:
	var forward := -aim_source.global_transform.basis.z
	var heading := Vector3(forward.x, 0.0, forward.z).normalized()
	if ball_on_a_green():
		return heading
	# Tilt the sightline up by the loft angle, then split that pitch into a flat
	# component (cos) and a vertical one (sin) to build the launch direction.
	var sightline_pitch := asin(forward.y)
	var lofted_pitch := minf(sightline_pitch + deg_to_rad(loft_degrees), deg_to_rad(max_pitch_degrees))
	return heading * cos(lofted_pitch) + Vector3.UP * sin(lofted_pitch)

func ball_on_a_green() -> bool:
	var origin := get_shot_origin()
	for hole in get_tree().get_nodes_in_group("holes"):
		if (hole as Hole).within_putt_range(origin):
			return true
	return false

func lock_on_direction() -> Vector3:
	var to_hole := target_hole.cup_position() - muzzle_position()
	var flat := Vector3(to_hole.x, 0.0, to_hole.z).normalized()
	var theta := deg_to_rad(loft_degrees)
	# Split the fixed loft angle into flat (cos) and vertical (sin) parts.
	return flat * cos(theta) + Vector3.UP * sin(theta)

# Inverse of the arc: solve for the launch speed that drops the ball into the cup
# at the fixed loft angle. From the projectile range relation
#   h = d*tan(θ) − g*d² / (2*v²*cos²θ)
# rearranged for v, where d is the flat distance to the cup and h its height above
# the muzzle. If the angle can't physically reach the cup (denominator ≤ 0), send it
# full power.
func solved_power() -> float:
	var to_hole := target_hole.cup_position() - muzzle_position()
	var d := Vector2(to_hole.x, to_hole.z).length()
	var h := to_hole.y
	var theta := deg_to_rad(loft_degrees)
	var denominator := 2.0 * cos(theta) * cos(theta) * (d * tan(theta) - h)
	if denominator <= 0.0:
		return max_power
	var speed := sqrt(gravity_magnitude() * d * d / denominator)
	return clampf(speed, min_power, max_power)

func muzzle_position() -> Vector3:
	return muzzle.global_position

func gravity_magnitude() -> float:
	return ProjectSettings.get_setting("physics/3d/default_gravity")
