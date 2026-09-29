extends Control

const MAIN_MENU_PATH: String = "res://scenes/main_menu.tscn"
const BACK_BUTTON_TEXTURE: Texture2D = preload("res://assets/sprites/ui-pack/PNG/Blue/Default/button_rectangle_depth_gloss.png")
const CONTENT_PATH: String = "CenterContainer/SettingsPanel/ScrollContainer/SettingsContent"

@onready var _content: VBoxContainer = get_node_or_null(CONTENT_PATH)
@onready var _master_volume_slider: HSlider = get_node_or_null(CONTENT_PATH + "/AudioGroup/MasterVolumeSlider")
@onready var _music_volume_slider: HSlider = get_node_or_null(CONTENT_PATH + "/AudioGroup/MusicVolumeSlider")
@onready var _sfx_volume_slider: HSlider = get_node_or_null(CONTENT_PATH + "/AudioGroup/SfxVolumeSlider")
@onready var _fullscreen_toggle: CheckButton = get_node_or_null(CONTENT_PATH + "/DisplayGroup/FullscreenToggle")
@onready var _reduced_motion_toggle: CheckButton = get_node_or_null(CONTENT_PATH + "/AccessibilityGroup/ReducedMotionToggle")
@onready var _haptics_toggle: CheckButton = get_node_or_null(CONTENT_PATH + "/AccessibilityGroup/HapticsToggle")
@onready var _color_safe_toggle: CheckButton = get_node_or_null(CONTENT_PATH + "/AccessibilityGroup/ColorSafeToggle")
@onready var _language_label: Label = get_node_or_null(CONTENT_PATH + "/LanguageLabel")
@onready var _language_option: OptionButton = get_node_or_null(CONTENT_PATH + "/LanguageOption")
@onready var _back_button: Button = get_node_or_null(CONTENT_PATH + "/BackButton")
@onready var _back_skin: TextureRect = get_node_or_null(CONTENT_PATH + "/BackButton/KenneySkin")
@onready var _menu_back: AudioStreamPlayer = get_node_or_null("MenuBack")


func _ready() -> void:
	Localization.apply_saved_locale()
	_order_content()
	_apply_mobile_presentation()
	_apply_localized_text()
	_setup_language_option()
	if _back_skin != null:
		_back_skin.texture = BACK_BUTTON_TEXTURE
	_setup_slider(_master_volume_slider, "master_volume", _on_master_volume_changed)
	_setup_slider(_music_volume_slider, "music_volume", _on_music_volume_changed)
	_setup_slider(_sfx_volume_slider, "sfx_volume", _on_sfx_volume_changed)
	_setup_toggle(_fullscreen_toggle, "fullscreen", _on_fullscreen_toggled, DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	_setup_toggle(_reduced_motion_toggle, "reduced_motion", _on_reduced_motion_toggled, false)
	_setup_toggle(_haptics_toggle, "haptics", _on_haptics_toggled, true)
	_setup_toggle(_color_safe_toggle, "color_safe", _on_color_safe_toggled, false)
	if _back_button != null:
		_back_button.pressed.connect(_return_to_main_menu)
		_back_button.grab_focus()
	_apply_saved_audio()


func _order_content() -> void:
	if _content == null:
		return
	var order: Array[String] = [
		"SettingsTitle", "AudioSection", "AudioGroup", "DisplaySection", "DisplayGroup",
		"AccessibilitySection", "AccessibilityGroup", "LanguageLabel", "LanguageOption", "BackButton"
	]
	for child_name: String in order:
		var child: Node = _content.get_node_or_null(child_name)
		if child != null:
			_content.move_child(child, -1)


func _apply_mobile_presentation() -> void:
	for heading_name: String in ["SettingsTitle", "AudioSection", "DisplaySection", "AccessibilitySection"]:
		var heading: Label = get_node_or_null(CONTENT_PATH + "/" + heading_name)
		if heading != null:
			heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			heading.add_theme_font_size_override("font_size", 28 if heading_name == "SettingsTitle" else 18)
			heading.add_theme_color_override("font_color", Color("8fdcff"))
	for group_name: String in ["AudioGroup", "DisplayGroup", "AccessibilityGroup"]:
		var group: VBoxContainer = get_node_or_null(CONTENT_PATH + "/" + group_name)
		if group != null:
			group.add_theme_constant_override("separation", 10)
	for control: Control in [_master_volume_slider, _music_volume_slider, _sfx_volume_slider, _fullscreen_toggle, _reduced_motion_toggle, _haptics_toggle, _color_safe_toggle, _language_option, _back_button]:
		if control != null:
			control.custom_minimum_size = Vector2(0.0, 46.0)


func _apply_localized_text() -> void:
	_set_label_text(CONTENT_PATH + "/SettingsTitle", "settings")
	_set_label_text(CONTENT_PATH + "/AudioSection", "audio")
	_set_label_text(CONTENT_PATH + "/DisplaySection", "display")
	_set_label_text(CONTENT_PATH + "/AccessibilitySection", "accessibility")
	_set_label_text(CONTENT_PATH + "/AudioGroup/VolumeLabel", "master_volume")
	_set_label_text(CONTENT_PATH + "/AudioGroup/MusicVolumeLabel", "music_volume")
	_set_label_text(CONTENT_PATH + "/AudioGroup/SfxVolumeLabel", "sfx_volume")
	_set_button_text(CONTENT_PATH + "/DisplayGroup/FullscreenToggle", "fullscreen")
	_set_button_text(CONTENT_PATH + "/AccessibilityGroup/ReducedMotionToggle", "reduced_motion")
	_set_button_text(CONTENT_PATH + "/AccessibilityGroup/HapticsToggle", "haptics")
	_set_button_text(CONTENT_PATH + "/AccessibilityGroup/ColorSafeToggle", "color_safe")
	_set_button_text(CONTENT_PATH + "/BackButton", "back")
	if _language_label != null:
		_language_label.text = Localization.text("language")


func _set_label_text(path: String, key: String) -> void:
	var label: Label = get_node_or_null(path)
	if label != null:
		label.text = Localization.text(key)


func _set_button_text(path: String, key: String) -> void:
	var button: Button = get_node_or_null(path)
	if button != null:
		button.text = Localization.text(key)


func _setup_language_option() -> void:
	if _language_option == null:
		return
	_language_option.clear()
	_language_option.add_item(Localization.text("english"))
	_language_option.add_item(Localization.text("french"))
	_language_option.add_item(Localization.text("japanese"))
	_language_option.select(Localization.locale_index(Localization.current_locale()))
	if not _language_option.item_selected.is_connected(_on_language_selected):
		_language_option.item_selected.connect(_on_language_selected)


func _on_language_selected(index: int) -> void:
	Localization.set_locale(Localization.locale_from_index(index))
	_apply_localized_text()
	_setup_language_option()


func _profile() -> Node:
	return get_tree().root.get_node_or_null("SaveManager")


func _saved_value(key: String, fallback: Variant) -> Variant:
	var profile: Node = _profile()
	if profile == null:
		return fallback
	return profile.call("get_value", key, fallback)


func _setup_slider(slider: HSlider, key: String, callback: Callable) -> void:
	if slider == null:
		return
	slider.value = float(_saved_value(key, slider.value))
	slider.value_changed.connect(callback)


func _setup_toggle(toggle: CheckButton, key: String, callback: Callable, fallback: bool) -> void:
	if toggle == null:
		return
	toggle.button_pressed = bool(_saved_value(key, fallback))
	toggle.toggled.connect(callback)


func _set_saved(key: String, value: Variant) -> void:
	var profile: Node = _profile()
	if profile == null:
		return
	profile.call("set_value", key, value)
	profile.call("save")


func _apply_saved_audio() -> void:
	_set_bus_volume(&"Master", float(_saved_value("master_volume", 100.0)))
	_set_bus_volume(&"Music", float(_saved_value("music_volume", 80.0)))
	_set_bus_volume(&"SFX", float(_saved_value("sfx_volume", 90.0)))


func _set_bus_volume(bus_name: StringName, percentage: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(percentage / 100.0, 0.0001)))


func _on_master_volume_changed(value: float) -> void:
	_set_bus_volume(&"Master", value)
	_set_saved("master_volume", value)


func _on_music_volume_changed(value: float) -> void:
	_set_bus_volume(&"Music", value)
	_set_saved("music_volume", value)


func _on_sfx_volume_changed(value: float) -> void:
	_set_bus_volume(&"SFX", value)
	_set_saved("sfx_volume", value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	_set_saved("fullscreen", enabled)


func _on_reduced_motion_toggled(enabled: bool) -> void:
	_set_saved("reduced_motion", enabled)


func _on_haptics_toggled(enabled: bool) -> void:
	_set_saved("haptics", enabled)


func _on_color_safe_toggled(enabled: bool) -> void:
	_set_saved("color_safe", enabled)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_return_to_main_menu()
		get_viewport().set_input_as_handled()


func _return_to_main_menu() -> void:
	if _menu_back != null:
		_menu_back.play()
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
