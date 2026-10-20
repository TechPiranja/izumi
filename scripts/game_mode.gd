## Autoload "GameMode": which mode is played, and the switching between menu and game.
## Esc always leads back to the menu.
extends Node

enum Mode { TUTORIAL, INFINITY, DARK }

const MAIN_SCENE := "res://scenes/main.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"

var mode := Mode.INFINITY


func _ready() -> void:
	# Works while the game is paused behind the game over screen, too.
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_tutorial() -> bool:
	return mode == Mode.TUTORIAL


## Dark mode: the platforms are always hidden and there are no black orbs.
func is_dark_mode() -> bool:
	return mode == Mode.DARK


func start(new_mode: Mode) -> void:
	mode = new_mode
	_change_scene(MAIN_SCENE)


func open_menu() -> void:
	_change_scene(MENU_SCENE)


func _change_scene(path: String) -> void:
	get_tree().paused = false
	# Never take a darkness or a running vision into the next scene.
	Blackout.set_blind(false, true)
	get_tree().change_scene_to_file(path)


func _input(event: InputEvent) -> void:
	var scene := get_tree().current_scene
	if event.is_action_pressed("ui_cancel") and scene and scene.scene_file_path == MAIN_SCENE:
		open_menu()
