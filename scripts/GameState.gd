extends Node

enum State {ENCOUNTER, GAME_OVER, COLLECT_REWARD, MAP, RUN_COMPLETE}
var current_state: State = State.ENCOUNTER

var current_encounter: int = 0

func change_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.ENCOUNTER: Events.change_state_encounter.emit()
		State.GAME_OVER: Events.change_state_game_over.emit()
		State.COLLECT_REWARD: Events.change_state_collect_reward.emit()
		State.MAP: Events.change_state_map.emit()
		State.RUN_COMPLETE: Events.change_state_run_complete.emit()
		
