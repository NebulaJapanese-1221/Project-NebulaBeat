extends Control

const MAIN_MENU_PATH: String = "res://scenes/main_menu.tscn"
const GAMEPLAY_PATH: String = "res://scenes/nebula_beat.tscn"
const LEVEL_EDITOR_PATH: String = "res://scenes/level_editor.tscn"

@onready var _button_list: VBoxContainer = get_node_or_null("CenterContainer/VBox")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for level_id: int in range(1, LevelState.BUILT_IN_LEVELS.size() + 1):
		var button: Button = get_node_or_null("CenterContainer/VBox/Level%dButton" % level_id)
		if button == null:
			continue
		var unlocked: bool = LevelState.is_level_unlocked(level_id)
		button.disabled = not unlocked
		if unlocked:
			var stars: int = LevelState.best_stars(level_id)
			var record: int = LevelState.best_score(level_id)
			var suffix: String = "  %s  %06d" % ["★".repeat(stars) + "☆".repeat(3 - stars), record] if record > 0 else ""
			button.text = "%02d  %s%s" % [level_id, String(LevelState.BUILT_IN_LEVELS[level_id - 1]["title"]), suffix]
			button.pressed.connect(_open_level.bind(level_id))
	var editor_button: Button = get_node_or_null("CenterContainer/VBox/EditorButton")
	if editor_button != null:
		editor_button.pressed.connect(_open_editor)
	var back_button: Button = get_node_or_null("CenterContainer/VBox/BackButton")
	if back_button != null:
		back_button.pressed.connect(_return_to_main_menu)
	var first_button: Button = get_node_or_null("CenterContainer/VBox/Level1Button")
	if first_button != null:
		first_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_return_to_main_menu()
		get_viewport().set_input_as_handled()


func _open_level(level_id: int) -> void:
	if not LevelState.is_level_unlocked(level_id):
		return
	LevelState.select_builtin(level_id)
	get_tree().change_scene_to_file(GAMEPLAY_PATH)


func _open_editor() -> void:
	get_tree().change_scene_to_file(LEVEL_EDITOR_PATH)


func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
