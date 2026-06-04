extends Control

@onready var map_world: Node3D = $VBoxContainer/MapContainer/SubViewport/MapWorld
@onready var combat_container: SubViewportContainer
@onready var golf_container: SubViewportContainer
@onready var map_container: SubViewportContainer
@onready var player: Player = get_node("Player")

func _ready() -> void:
	combat_container = $VBoxContainer/CombatContainer
	golf_container = $VBoxContainer/GolfContainer
	map_container = $VBoxContainer/MapContainer
	Events.change_state_encounter.connect(show_encounter)
	Events.change_state_game_over.connect(show_encounter)
	Events.change_state_collect_reward.connect(show_encounter)
	Events.change_state_map.connect(show_map)
	GameState.change_state(GameState.State.MAP)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_R:
			if GameState.current_state == GameState.State.GAME_OVER:
				player.health.heal(player.health.max_hp)
				GameState.change_state(GameState.State.ENCOUNTER)
		KEY_N:
			if GameState.current_state == GameState.State.COLLECT_REWARD:
				GameState.change_state(GameState.State.MAP)
		KEY_E:
			if GameState.current_state == GameState.State.MAP:
				map_world.activate()

func show_encounter() -> void:
	map_container.visible = false
	combat_container.visible = true
	golf_container.visible = true

func show_map() -> void:
	combat_container.visible = false
	golf_container.visible = false
	map_container.visible = true
	
