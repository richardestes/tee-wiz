class_name RightHandController extends Node
#
# The player's right hand. For now it only knows "club mode": hold the right
# mouse button to wind up a shot, release to launch the ball. While winding up,
# it traces a preview line showing exactly where the shot will go. A "cursor
# mode" for aiming and casting spells gets added later as a second state, once
# there's actually a spell to cast.
#
# It can also lock onto a hole (hold the lock-on key while standing near one).
# Locking swings the body so the launch point lines up on the cup — it takes
# the aim off your hands, but you still judge and charge the power yourself,
# which is the whole sport of it. (auto_solve_locked_shot also solves the power
# for you, but that trades the challenge away; off by default.) Lock only holds
# while you're within lock_on_radius of the hole.

@export var input: InputComponent
@export var aim_source: Node3D           # the camera — its forward is the line of sight
@export var muzzle: Node3D               # the right arm — where the ball launches from
@export var preview: ArcPreview          # the line that traces the upcoming shot
@export var body: Node3D                 # the player body — yawed to face the flag while locked
@export var ball_scene: PackedScene      # spawned once, reused for every shot while iterating
@export var min_power: float = 4.0       # a quick tap still sends the ball somewhere
@export var max_power: float = 30.0      # holding longer can't push past this
@export var charge_rate: float = 9.0    # power gained per second while the button is held
@export var loft_degrees: float = 50.0   # tilt the shot up off the sightline so its arc is readable
@export var lock_on_radius: float = 25.0 # must be at least this close to a hole to lock onto it
@export var turn_speed: float = 6.0     # how briskly the body swings to face the flag while locking
@export var auto_solve_locked_shot: bool = false
@export var max_pitch_degrees := 75.0
@export var look: LookComponent
@export var mana_pool : ManaPool
@export var active_spell: Spell
@export var projectile_scene: PackedScene

var power: float = 0.0
var locked_on: bool = false
var target_hole: Node3D

func _physics_process(delta: float) -> void:
	update_lock_on()
	if input.wants_cast(): cast()
	if locked_on:
		face_hole(delta)
	if input.is_charging():
		if not (locked_on and auto_solve_locked_shot):
			charge(delta)   # a locked shot's power is solved, not charged
		update_preview()
	elif input.wants_release():
		fire()
	else:
		preview.clear()

# Lock holds only while the key is held and there's a hole within lock_on_radius.
# Letting go — or walking out of range — drops the lock back to free aim.
func update_lock_on() -> void:
	if input.is_locking_on():
		target_hole = nearest_hole_in_range()
		locked_on = target_hole != null
	else:
		locked_on = false
		target_hole = null

# Swing the body around to line the shot up on the flag. Only yaw is touched —
# the head keeps whatever pitch the mouse set, so you can still glance up and
# down while locked. lerp_angle takes the short way around, so it never spins
# the long way to face a hole just behind you.
func face_hole(delta: float) -> void:
	var to_hole := target_hole.global_position - body.global_position
	var distance := Vector2(to_hole.x, to_hole.z).length()
	if is_zero_approx(distance):
		return
	# The ball launches from the right arm, off to the side of the body's nose.
	# Pointing the nose dead at the cup would send that side-shifted shot wide,
	# so swing a touch further to slide the launch point onto the line instead.
	# asin(offset / distance) is that extra angle; clamp guards a hole closer
	# than the offset itself, where asin would otherwise go NaN.
	var aim_yaw := atan2(-to_hole.x, -to_hole.z)
	var correction := asin(clampf(muzzle_offset() / distance, -1.0, 1.0))
	var target_yaw := aim_yaw + correction
	var eye_to_hole := target_hole.global_position - aim_source.global_position
	var horizontal := Vector2(eye_to_hole.x, eye_to_hole.z).length()
	var target_pitch := atan2(eye_to_hole.y, horizontal)
	look.aim_pitch(lerpf(look.pitch, target_pitch, minf(turn_speed * delta, 1.0)))
	look.aim_pitch(lerpf(look.pitch, target_pitch, minf(turn_speed * delta, 1.0)))
	body.rotation.y = lerp_angle(body.rotation.y, target_yaw, minf(turn_speed * delta, 1.0))

# How far the launch point sits to the side of the body's yaw axis. Reading it
# from the muzzle's body-local position keeps it honest if the arm ever moves.
func muzzle_offset() -> float:
	return body.to_local(muzzle.global_position).x

# Ramp the power while the button is held. The lower clamp means even the very
# first frame of a press starts at min_power instead of a dead zero.
func charge(delta: float) -> void:
	power = clampf(power + charge_rate * delta, min_power, max_power)

func fire() -> void:
	var ball := ball_scene.instantiate() as Ball
	get_tree().current_scene.add_child(ball)
	ball.global_position = muzzle_position()
	ball.launch(Ball.compute_velocity(aim_direction(), current_power()))
	power = 0.0
	preview.clear()
	
func cast()-> void:
	if not mana_pool.can_afford(active_spell): return
	var projectile := projectile_scene.instantiate() as SpellProjectile
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle_position()
	projectile.launch(cast_direction())

func cast_direction() -> Vector3:
	return -aim_source.global_transform.basis.z

func update_preview() -> void:
	preview.draw_arc(muzzle_position(), Ball.compute_velocity(aim_direction(), current_power()))

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
	var sightline_pitch := asin(forward.y)
	var lofted_pitch := minf(sightline_pitch + deg_to_rad(loft_degrees), deg_to_rad(max_pitch_degrees))
	var heading := Vector3(forward.x, 0.0, forward.z).normalized()
	var right := aim_source.global_transform.basis.x
	return heading * cos(lofted_pitch) + Vector3.UP * sin(lofted_pitch)

func lock_on_direction() -> Vector3:
	var to_hole := target_hole.global_position - muzzle_position()
	var flat := Vector3(to_hole.x, 0.0, to_hole.z).normalized()
	var theta := deg_to_rad(loft_degrees)
	return flat * cos(theta) + Vector3.UP * sin(theta)

# Solve for the launch speed that drops the ball into the hole at the fixed loft
# angle. This is the inverse of the arc preview: the preview goes launch → landing,
# this goes landing → launch. Starting from the projectile range relation
#   h = d*tan(θ) − g*d² / (2*v²*cos²θ)
# and rearranging for v, where d is the flat distance to the cup and h its height
# above the muzzle. If the angle physically can't reach the cup (denominator ≤ 0),
# just send it full power.
func solved_power() -> float:
	var to_hole := target_hole.global_position - muzzle_position()
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

# The nearest hole within lock-on range, or null if none qualifies. Looking holes
# up by group keeps this decoupled from where they live in the scene tree — the
# hole sits in main.tscn while this controller is buried inside the Player.
func nearest_hole_in_range() -> Node3D:
	var best: Node3D = null
	var best_distance := lock_on_radius
	for node in get_tree().get_nodes_in_group("holes"):
		var hole := node as Node3D
		var distance := muzzle_position().distance_to(hole.global_position)
		if distance <= best_distance:
			best = hole
			best_distance = distance
	return best

func hole_in_range(hole: Node3D) -> bool:
	return hole != null and muzzle_position().distance_to(hole.global_position) <= lock_on_radius

# Read gravity from project settings so the solve can't drift from the gravity
# the ball actually falls under.
func gravity_magnitude() -> float:
	return ProjectSettings.get_setting("physics/3d/default_gravity")
	
