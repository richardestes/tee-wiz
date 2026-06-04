extends Node3D

const EnemyScene := preload("res://scenes/enemy.tscn")

@onready var health_bar: ProgressBar = get_node("CanvasLayer/HealthBar")
@onready var game_over_label: Label = get_node("CanvasLayer/GameOverLabel")
@onready var reward_label: Label = get_node("CanvasLayer/RewardLabel")
@onready var spawn_timer: Timer = get_node("SpawnTimer")
@onready var attack_timer: Timer = get_node("AttackTimer")
@onready var player: Player = get_tree().get_first_node_in_group("player")

var initial_wave_size: int

var number_of_enemies_to_spawn: int

func _ready() -> void:
	number_of_enemies_to_spawn = randi_range(10,15)
	initial_wave_size = number_of_enemies_to_spawn
	spawn_timer.timeout.connect(spawn_enemy)
	attack_timer.timeout.connect(attack_closest_enemy)
	var camera_area: Area3D = get_node("Camera3D/Area3D")
	camera_area.area_entered.connect(take_enemy_hit)
	player.health.died.connect(handle_player_death)
	player.health.health_changed.connect(update_health_bar)
	Events.hole_in.connect(end_encounter)
	Events.change_state_encounter.connect(enter_encounter)
	Events.change_state_game_over.connect(enter_game_over)
	Events.change_state_collect_reward.connect(enter_collect_reward)
	Events.change_state_map.connect(enter_map)
	health_bar.max_value = player.health.max_hp
	update_health_bar()

func spawn_enemy() -> void:
	spawn_timer.wait_time = randf_range(1.0,2.0)
	var enemy = EnemyScene.instantiate()
	enemy.died.connect(check_wave_clear)
	enemy.position = Vector3(randf_range(-8,8), 1, randf_range(-5,-15))
	add_child(enemy)
	enemy.movement.target = get_node("Camera3D")
	number_of_enemies_to_spawn -= 1
	if number_of_enemies_to_spawn <= 0:
		spawn_timer.stop()
	
func end_encounter() -> void:
	if GameState.current_state != GameState.State.ENCOUNTER: return
	GameState.change_state(GameState.State.COLLECT_REWARD)

func take_enemy_hit(area: Area3D) -> void:
	var enemy = area.get_parent()
	player.health.take_damage(enemy.stats.damage)
	enemy.take_damage(enemy.health.max_hp)

func check_wave_clear() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if spawn_timer.is_stopped() && enemies.size() <= 1: # accounts for dying enemy
		GameState.change_state(GameState.State.COLLECT_REWARD)

func attack_closest_enemy() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty(): return
	
	var camera: Camera3D = get_node("Camera3D")
	var closest: Node3D = enemies[0]
	var closest_distance: float = camera.global_position.distance_to(closest.global_position)
	for enemy in enemies:
		var distance: float = camera.global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest = enemy
			closest_distance = distance
	closest.take_damage(1)
	
func update_health_bar() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(health_bar, "value", player.health.current_hp, 0.3)

func enter_encounter() -> void:
	game_over_label.visible = false
	reward_label.visible = false
	number_of_enemies_to_spawn = initial_wave_size
	spawn_timer.start()
	attack_timer.start()
	get_tree().paused = false

func enter_game_over() -> void:
	halt_combat()
	game_over_label.visible = true
	get_tree().paused = true

func enter_collect_reward() -> void:
	halt_combat()
	reward_label.visible = true
	get_tree().paused = true

func halt_combat() -> void:
	clear_enemies()
	spawn_timer.stop()
	attack_timer.stop()

func clear_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()

func enter_map() -> void:
	get_tree().paused = false

func handle_player_death() -> void:
	GameState.change_state(GameState.State.GAME_OVER)
