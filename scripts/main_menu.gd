extends Control

# Title-screen controller. Play loads the gameplay scene; Quit exits. Buttons are
# wired by node lookup in _ready so there's no reliance on editor connections that
# break when the tree is edited. play_target is exported so it shows in the
# inspector and can be repointed without touching code.

# res:// path of the gameplay scene Play loads.
@export_file("*.tscn") var play_target: String = ""

@onready var _play_button: Button = get_node_or_null("CenterContainer/VBox/PlayButton")
@onready var _quit_button: Button = get_node_or_null("CenterContainer/VBox/QuitButton")


func _ready() -> void:
	if _play_button != null:
		_play_button.pressed.connect(_on_play_pressed)
		_play_button.grab_focus()
	if _quit_button != null:
		_quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	if play_target.is_empty():
		push_warning("MainMenu: play_target is not set — nothing to load. Set it in the inspector or re-run create_main_menu with play_target.")
		return
	get_tree().change_scene_to_file(play_target)


func _on_quit_pressed() -> void:
	get_tree().quit()
