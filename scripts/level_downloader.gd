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

const LEVELS_MENU_PATH: String = "res://scenes/levels_menu.tscn"

@onready var _title: Label = get_node_or_null("CenterContainer/VBox/Title")
@onready var _body: Label = get_node_or_null("CenterContainer/VBox/Body")
@onready var _refresh_button: Button = get_node_or_null("CenterContainer/VBox/RefreshButton")
@onready var _back_button: Button = get_node_or_null("CenterContainer/VBox/BackButton")


func _ready() -> void:
	Localization.apply_saved_locale()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_to_group("localizable_menu")
	_apply_layout()
	_apply_text()
	if _refresh_button != null:
		_refresh_button.pressed.connect(_show_offline_status)
	if _back_button != null:
		_back_button.pressed.connect(_return_to_levels)
		_back_button.grab_focus()


func _apply_layout() -> void:
	var content: VBoxContainer = get_node_or_null("CenterContainer/VBox")
	if content != null:
		var viewport_size: Vector2 = get_viewport_rect().size
		content.custom_minimum_size = Vector2(minf(maxf(viewport_size.x - 40.0, 280.0), 720.0), 0.0)
		content.custom_maximum_size = Vector2(720.0, -1.0)
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 16)
	if _title != null:
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title.add_theme_font_size_override("font_size", 30)
	if _body != null:
		_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_body.custom_minimum_size = Vector2(0.0, 108.0)
	for button: Button in [_refresh_button, _back_button]:
		if button != null:
			button.custom_minimum_size = Vector2(0.0, 52.0)


func _apply_text() -> void:
	if _title != null:
		_title.text = Localization.text("level_downloader")
	if _body != null:
		_body.text = Localization.text("downloader_offline")
	if _refresh_button != null:
		_refresh_button.text = Localization.text("refresh_catalog")
	if _back_button != null:
		_back_button.text = Localization.text("back")


func refresh_localization() -> void:
	_apply_text()


func _show_offline_status() -> void:
	if _body != null:
		_body.text = Localization.text("downloader_server_missing")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_return_to_levels()
		get_viewport().set_input_as_handled()


func _return_to_levels() -> void:
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(LEVELS_MENU_PATH)
