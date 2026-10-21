extends Control

const MAIN_MENU_PATH: String = "res://scenes/main_menu.tscn"
const SETTINGS_MENU_PATH: String = "res://scenes/settings_menu.tscn"

# Calibration parameters.
const TAP_COUNT_TARGET: int = 8          # How many taps to measure before finishing.
const METRONOME_INTERVAL: float = 0.500  # Seconds between clicks (120 BPM).
const TAP_WINDOW: float = 0.300          # Max seconds after a click to count as a tap.

@onready var _title_label: Label = get_node_or_null("CenterContainer/VBox/TitleLabel")
@onready var _instruction_label: Label = get_node_or_null("CenterContainer/VBox/InstructionLabel")
@onready var _status_label: Label = get_node_or_null("CenterContainer/VBox/StatusLabel")
@onready var _offset_label: Label = get_node_or_null("CenterContainer/VBox/OffsetLabel")
@onready var _start_button: Button = get_node_or_null("CenterContainer/VBox/StartButton")
@onready var _back_button: Button = get_node_or_null("CenterContainer/VBox/BackButton")
@onready var _metronome_click: AudioStreamPlayer = get_node_or_null("MetronomeClick")

var _state: String = "idle"   # idle | running | finished
var _taps_recorded: int = 0
var _tap_errors: Array[float] = []
var _next_click_time: float = 0.0
var _click_timer: float = 0.0
var _click_tween: Tween


func _ready() -> void:
	Localization.apply_saved_locale()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_to_group("localizable_menu")
	_apply_localized_text()
	if _start_button != null:
		_start_button.pressed.connect(_start_calibration)
	if _back_button != null:
		_back_button.pressed.connect(_return_to_settings)
	_update_ui()


func _apply_localized_text() -> void:
	if _title_label != null:
		_title_label.text = Localization.text("calibration")
	if _instruction_label != null:
		_instruction_label.text = Localization.text("calibration_hint")
	if _status_label != null:
		_status_label.text = Localization.text("calibration_idle")
	if _start_button != null:
		_start_button.text = Localization.text("calibration_start")
	if _back_button != null:
		_back_button.text = Localization.text("back")


func refresh_localization() -> void:
	_apply_localized_text()
	_update_ui()


func _update_ui() -> void:
	if _status_label == null:
		return
	var taps_left: int = maxi(0, TAP_COUNT_TARGET - _taps_recorded)
	if _state == "idle":
		_status_label.text = Localization.text("calibration_idle")
	elif _state == "running":
		_status_label.text = "%s %d/%d" % [Localization.text("calibration_taps"), _taps_recorded, TAP_COUNT_TARGET]
	else:
		_status_label.text = Localization.text("calibration_done")
	if _offset_label != null and _state == "finished" and _tap_errors.size() > 0:
		var avg_ms: int = int(roundi(_average_error() * 1000.0))
		_offset_label.text = "%s: %+d ms" % [Localization.text("calibration_offset"), avg_ms]
	else:
		_offset_label.text = ""
	if _start_button != null:
		_start_button.disabled = _state == "running"


func _start_calibration() -> void:
	_state = "running"
	_taps_recorded = 0
	_tap_errors.clear()
	_click_timer = 0.0
	_next_click_time = METRONOME_INTERVAL
	_update_ui()
	_schedule_click()


func _schedule_click() -> void:
	if _state != "running":
		return
	if _click_tween != null and _click_tween.is_running():
		_click_tween.kill()
	var duration: float = METRONOME_INTERVAL
	_click_tween = create_tween()
	_click_tween.tween_interval(duration)
	_click_tween.tween_callback(Callable(self, "_on_click_due"))
	_click_tween.start()


func _on_click_due() -> void:
	# The metronome click is now due. Record the expected time.
	_next_click_time = Time.get_ticks_msec() / 1000.0
	if _metronome_click != null:
		_metronome_click.play()
	# Re-schedule next click.
	if _state == "running":
		_click_tween = create_tween()
		_click_tween.tween_interval(METRONOME_INTERVAL)
		_click_tween.tween_callback(Callable(self, "_on_click_due"))
		_click_tween.start()


func _play_click() -> void:
	if _metronome_click != null:
		_metronome_click.play()


func _input(event: InputEvent) -> void:
	if _state != "running":
		return
	if event.is_action_pressed("ui_cancel"):
		_hide_calibration()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		_register_tap()
		get_viewport().set_input_as_handled()


func _register_tap() -> void:
	var tap_time: float = Time.get_ticks_msec() / 1000.0
	var error: float = tap_time - _next_click_time
	# Only count taps within the acceptable window.
	if abs(error) <= TAP_WINDOW:
		_tap_errors.append(error)
		_taps_recorded += 1
	_update_ui()
	if _taps_recorded >= TAP_COUNT_TARGET:
		_finish_calibration()


func _average_error() -> float:
	if _tap_errors.is_empty():
		return 0.0
	var total: float = 0.0
	for e: float in _tap_errors:
		total += e
	return total / float(_tap_errors.size())


func _finish_calibration() -> void:
	_state = "finished"
	var avg_ms: int = int(roundi(_average_error() * 1000.0))
	var profile: Node = get_tree().root.get_node_or_null("SaveManager")
	if profile != null:
		profile.call("set_value", "timing_offset_ms", avg_ms)
		profile.call("save")
	_update_ui()


func _hide_calibration() -> void:
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(SETTINGS_MENU_PATH)


func _return_to_settings() -> void:
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(SETTINGS_MENU_PATH)
