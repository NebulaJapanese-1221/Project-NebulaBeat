extends Control

const MAIN_MENU_PATH: String = "res://scenes/main_menu.tscn"
const BACK_BUTTON_TEXTURE: Texture2D = preload("res://assets/sprites/ui-pack/PNG/Blue/Default/button_rectangle_depth_gloss.png")

@onready var _back_button: Button = get_node_or_null("CenterContainer/AboutPanel/AboutVBox/BackButton")
@onready var _back_skin: TextureRect = get_node_or_null("CenterContainer/AboutPanel/AboutVBox/BackButton/KenneySkin")
@onready var _menu_back: AudioStreamPlayer = get_node_or_null("MenuBack")


func _ready() -> void:
	Localization.apply_saved_locale()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_responsive_layout()
	_apply_localized_text()
	if _back_skin != null:
		_back_skin.texture = BACK_BUTTON_TEXTURE
	if _back_button != null:
		_back_button.text = Localization.text("back")
	if _back_button != null:
		_back_button.pressed.connect(_return_to_main_menu)
		_back_button.grab_focus()


func _apply_localized_text() -> void:
	_set_label_text("CenterContainer/AboutPanel/AboutVBox/AboutTitle", "about")
	_set_label_text("CenterContainer/AboutPanel/AboutVBox/AboutBody", "about_body")
	_set_label_text("CenterContainer/AboutPanel/AboutVBox/CreatedByLabel", "about_credit")


func _set_label_text(path: String, key: String) -> void:
	var label: Label = get_node_or_null(path)
	if label != null:
		label.text = Localization.text(key)


func _apply_responsive_layout() -> void:
	var panel: PanelContainer = get_node_or_null("CenterContainer/AboutPanel")
	if panel != null:
		panel.custom_minimum_size = Vector2(280.0, 0.0)
		panel.custom_maximum_size = Vector2(560.0, -1.0)
	var content: VBoxContainer = get_node_or_null("CenterContainer/AboutPanel/AboutVBox")
	if content != null:
		content.add_theme_constant_override("separation", 14)
	if _back_button != null:
		_back_button.custom_minimum_size = Vector2(0.0, 48.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_return_to_main_menu()
		get_viewport().set_input_as_handled()


func _return_to_main_menu() -> void:
	if _menu_back != null:
		_menu_back.play()
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
