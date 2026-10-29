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

# Base class for all NebulaBeat menu screens. Provides shared localization,
# responsive layout helpers, and standard button/label setters so concrete
# menu scripts stay focused on their own UI logic.


func _apply_localized_text() -> void:
	# Override in concrete menu subclasses to apply localized text.


func _ready() -> void:
	Localization.apply_saved_locale()
	add_to_group("localizable_menu")
	_apply_localized_text()


func refresh_localization() -> void:
	_apply_localized_text()


func _set_label_text(path: String, key: String) -> void:
	var label: Label = get_node_or_null(path)
	if label != null:
		label.text = Localization.text(key)


func _set_button_text(path: String, key: String) -> void:
	var button: Button = get_node_or_null(path)
	if button != null:
		button.text = Localization.text(key)


func _apply_responsive_layout(container: Control, min_width: float = 280.0, max_width: float = 560.0, separation: float = 14.0) -> void:
	if container == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	container.custom_minimum_size = Vector2(minf(maxf(viewport_size.x - 40.0, min_width), max_width), 0.0)
	container.custom_maximum_size = Vector2(max_width, -1.0)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", separation)


func _apply_button_size(button: Button, min_height: float = 56.0) -> void:
	if button != null:
		button.custom_minimum_size = Vector2(0.0, min_height)
