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
const SPLASH_DURATION: float = 2.5

var _timer: float = 0.0


func _ready() -> void:
	Localization.apply_saved_locale()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_to_group("localizable_menu")
	_apply_localized_text()


func _apply_localized_text() -> void:
	var title: Label = get_node_or_null("CenterContainer/VBox/GameTitle")
	if title != null:
		title.text = Localization.text("game_title")
	var construction: Label = get_node_or_null("CenterContainer/VBox/ConstructionLabel")
	if construction != null:
		construction.text = Localization.text("under_construction")
	var detail: Label = get_node_or_null("CenterContainer/VBox/DetailLabel")
	if detail != null:
		detail.text = Localization.text("under_construction_detail")
	var version: Label = get_node_or_null("CenterContainer/VBox/VersionLabel")
	if version != null:
		version.text = Localization.text("version")


func refresh_localization() -> void:
	_apply_localized_text()


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= SPLASH_DURATION:
		var transition: Node = get_tree().root.get_node_or_null("ScreenTransition")
		if transition != null:
			transition.transition_to(MAIN_MENU_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		var transition: Node = get_tree().root.get_node_or_null("ScreenTransition")
		if transition != null:
			transition.transition_to(MAIN_MENU_PATH)
