extends Control

const LEVELS_MENU_PATH: String = "res://scenes/levels_menu.tscn"
const GAMEPLAY_PATH: String = "res://scenes/nebula_beat.tscn"
const BEAT_COUNT: int = 16

@onready var _beat_grid: GridContainer = get_node_or_null("CenterContainer/VBox/BeatGrid")
@onready var _tempo_slider: HSlider = get_node_or_null("CenterContainer/VBox/TempoSlider")
@onready var _speed_slider: HSlider = get_node_or_null("CenterContainer/VBox/SpeedSlider")
@onready var _playtest_button: Button = get_node_or_null("CenterContainer/VBox/PlaytestButton")
@onready var _reset_button: Button = get_node_or_null("CenterContainer/VBox/ResetButton")
@onready var _back_button: Button = get_node_or_null("CenterContainer/VBox/BackButton")


func _ready() -> void:
	Localization.apply_saved_locale()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_responsive_layout()
	_apply_localized_text()
	if LevelState.custom_note_pattern.size() != BEAT_COUNT:
		LevelState.custom_note_pattern.resize(BEAT_COUNT)
		for index: int in range(BEAT_COUNT):
			LevelState.custom_note_pattern[index] = false
	if _tempo_slider != null:
		_tempo_slider.value = LevelState.custom_spawn_interval
		_tempo_slider.value_changed.connect(_on_tempo_changed)
	if _speed_slider != null:
		_speed_slider.value = LevelState.custom_speed_multiplier
		_speed_slider.value_changed.connect(_on_speed_changed)
	for index: int in range(BEAT_COUNT):
		var beat_button: CheckButton = get_node_or_null("CenterContainer/VBox/BeatGrid/Beat%02d" % (index + 1))
		if beat_button != null:
			beat_button.button_pressed = LevelState.custom_note_pattern[index]
			beat_button.toggled.connect(_on_beat_toggled.bind(index))
	if _playtest_button != null:
		_playtest_button.pressed.connect(_playtest_chart)
	if _reset_button != null:
		_reset_button.pressed.connect(_reset_chart)
	if _back_button != null:
		_back_button.pressed.connect(_return_to_levels)
	var first_beat: CheckButton = get_node_or_null("CenterContainer/VBox/BeatGrid/Beat01")
	if first_beat != null:
		first_beat.grab_focus()


func _apply_responsive_layout() -> void:
	var content: VBoxContainer = get_node_or_null("CenterContainer/VBox")
	if content != null:
		content.custom_minimum_size = Vector2(300.0, 0.0)
		content.custom_maximum_size = Vector2(640.0, -1.0)
		content.add_theme_constant_override("separation", 12)
	if _beat_grid != null:
		_beat_grid.columns = 4
		_beat_grid.add_theme_constant_override("h_separation", 12)
		_beat_grid.add_theme_constant_override("v_separation", 8)
		for beat_button: Node in _beat_grid.get_children():
			if beat_button is CheckButton:
				(beat_button as CheckButton).custom_minimum_size = Vector2(0.0, 40.0)
	for slider: HSlider in [_tempo_slider, _speed_slider]:
		if slider != null:
			slider.custom_minimum_size = Vector2(0.0, 34.0)
	for button: Button in [_playtest_button, _reset_button, _back_button]:
		if button != null:
			button.custom_minimum_size = Vector2(0.0, 48.0)


func _apply_localized_text() -> void:
	_set_label_text("CenterContainer/VBox/Title", "editor")
	_set_label_text("CenterContainer/VBox/TempoLabel", "tempo")
	_set_label_text("CenterContainer/VBox/SpeedLabel", "speed")
	_set_button_text("CenterContainer/VBox/PlaytestButton", "playtest")
	_set_button_text("CenterContainer/VBox/ResetButton", "reset")
	_set_button_text("CenterContainer/VBox/BackButton", "back")


func _set_label_text(path: String, key: String) -> void:
	var label: Label = get_node_or_null(path)
	if label != null:
		label.text = Localization.text(key)


func _set_button_text(path: String, key: String) -> void:
	var button: Button = get_node_or_null(path)
	if button != null:
		button.text = Localization.text(key)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_return_to_levels()
		get_viewport().set_input_as_handled()


func _on_beat_toggled(enabled: bool, beat_index: int) -> void:
	LevelState.custom_note_pattern[beat_index] = enabled


func _on_tempo_changed(value: float) -> void:
	LevelState.custom_spawn_interval = value


func _on_speed_changed(value: float) -> void:
	LevelState.custom_speed_multiplier = value


func _playtest_chart() -> void:
	LevelState.select_custom()
	get_tree().change_scene_to_file(GAMEPLAY_PATH)


func _reset_chart() -> void:
	LevelState.reset_custom_chart()
	LevelState.custom_note_pattern.resize(BEAT_COUNT)
	for index: int in range(BEAT_COUNT):
		LevelState.custom_note_pattern[index] = false
		var beat_button: CheckButton = get_node_or_null("CenterContainer/VBox/BeatGrid/Beat%02d" % (index + 1))
		if beat_button != null:
			beat_button.button_pressed = false
	if _tempo_slider != null:
		_tempo_slider.value = LevelState.custom_spawn_interval
	if _speed_slider != null:
		_speed_slider.value = LevelState.custom_speed_multiplier


func _return_to_levels() -> void:
	get_tree().change_scene_to_file(LEVELS_MENU_PATH)
