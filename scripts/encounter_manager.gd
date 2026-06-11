class_name EncounterManager extends Node

signal encounter_started(hole: Hole)
signal encounter_ended

enum RunPhase {TRAVEL, ENCOUNTER}

var phase: RunPhase = RunPhase.TRAVEL

func _ready() -> void:
	wire_holes()

func wire_holes() -> void:
	for hole in get_tree().get_nodes_in_group("holes"):
		hole.zone_entered.connect(start_encounter.bind(hole))
		hole.zone_exited.connect(stop_encounter.bind(hole))

func start_encounter(body: Node3D, hole: Hole) -> void:
	if phase == RunPhase.TRAVEL:
		change_phase(RunPhase.ENCOUNTER)
		encounter_started.emit(hole)

func stop_encounter(body: Node3D, hole: Hole) -> void:
	if phase == RunPhase.ENCOUNTER:
		change_phase(RunPhase.TRAVEL)
		encounter_ended.emit()

func change_phase(new_phase: RunPhase) -> void:
	phase = new_phase
	print("New phase: ", RunPhase.keys()[phase])
