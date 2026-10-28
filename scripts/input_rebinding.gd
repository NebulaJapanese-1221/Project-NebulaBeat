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

extends MenuBase

const SETTINGS_MENU_PATH: String = "res://scenes/settings_menu.tscn"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_localized_text()
	var back_button: Button = get_node_or_null("CenterContainer/VBox/BackButton")
	if back_button != null:
		back_button.text = Localization.text("back")
		back_button.pressed.connect(_return_to_settings)
		back_button.grab_focus()


func _apply_localized_text() -> void:
	var title: Label = get_node_or_null("CenterContainer/VBox/Title")
	if title != null:
		title.text = Localization.text("input_rebinding")
	var subtitle: Label = get_node_or_null("CenterContainer/VBox/Subtitle")
	if subtitle != null:
		subtitle.text = Localization.text("input_rebinding_subtitle")


func refresh_localization() -> void:
	_apply_localized_text()


func _return_to_settings() -> void:
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(SETTINGS_MENU_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_return_to_settings()
		get_viewport().set_input_as_handled()
