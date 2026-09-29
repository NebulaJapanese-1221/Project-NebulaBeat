extends Control

const MAIN_MENU_PATH: String = "res://scenes/main_menu.tscn"
const BACK_BUTTON_TEXTURE: Texture2D = preload("res://assets/sprites/ui-pack/PNG/Blue/Default/button_rectangle_depth_gloss.png")

@onready var _back_button: Button = get_node_or_null("CenterContainer/AboutPanel/AboutVBox/BackButton")
@onready var _back_skin: TextureRect = get_node_or_null("CenterContainer/AboutPanel/AboutVBox/BackButton/KenneySkin")
@onready var _menu_back: AudioStreamPlayer = get_node_or_null("MenuBack")


func _ready() -> void:
	if _back_skin != null:
		_back_skin.texture = BACK_BUTTON_TEXTURE
	if _back_button != null:
		_back_button.pressed.connect(_return_to_main_menu)
		_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_return_to_main_menu()
		get_viewport().set_input_as_handled()


func _return_to_main_menu() -> void:
	if _menu_back != null:
		_menu_back.play()
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
