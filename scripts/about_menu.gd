# Project NebulaBeat - A low-poly rhythm action game where players slice incoming notes
# Copyright (C) 2026  NebulaJapanese-1221

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

extends Control

const MAIN_MENU_PATH: String = "res://scenes/main_menu.tscn"
const BACK_BUTTON_TEXTURE: Texture2D = preload("res://assets/sprites/ui-pack/PNG/Blue/Default/button_rectangle_depth_gloss.png")

@onready var _back_button: Button = get_node_or_null("CenterContainer/AboutPanel/AboutVBox/BackButton")
@onready var _back_skin: TextureRect = get_node_or_null("CenterContainer/AboutPanel/AboutVBox/BackButton/KenneySkin")
@onready var _menu_back: AudioStreamPlayer = get_node_or_null("MenuBack")
@onready var _license_label: Label = get_node_or_null("CenterContainer/AboutPanel/AboutVBox/LicenseLabel")


func _ready() -> void:
	Localization.apply_saved_locale()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_to_group("localizable_menu")
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
	if _license_label != null:
		_license_label.text = Localization.text("gpl_license")


func _set_label_text(path: String, key: String) -> void:
	var label: Label = get_node_or_null(path)
	if label != null:
		label.text = Localization.text(key)


func refresh_localization() -> void:
	_apply_localized_text()
	if _back_button != null:
		_back_button.text = Localization.text("back")


func _apply_responsive_layout() -> void:
	var panel: PanelContainer = get_node_or_null("CenterContainer/AboutPanel")
	if panel != null:
		var viewport_size: Vector2 = get_viewport_rect().size
		panel.custom_minimum_size = Vector2(minf(maxf(viewport_size.x - 40.0, 280.0), 560.0), 0.0)
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
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(MAIN_MENU_PATH)
