extends Node

## GameManager singleton for managing game state and flow
## Handles transitions between building, launching, and shopping modes

enum GameState {
	MAIN_MENU,
	BUILDING,
	LAUNCHING,
	FLYING,
	SHOPPING,
	STATISTICS
}

signal state_changed(new_state: GameState)

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState

func _ready():
	print("GameManager initialized")

func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return
	
	previous_state = current_state
	current_state = new_state
	state_changed.emit(new_state)
	print("Game state changed to: ", GameState.keys()[new_state])

func get_current_state() -> GameState:
	return current_state

func go_back() -> void:
	if previous_state != current_state:
		change_state(previous_state)
