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

extends CanvasLayer

# Pause overlay. Esc (ui_cancel) toggles get_tree().paused; the panel is shown
# only while paused. This layer's process_mode is ALWAYS so it keeps running
# while the rest of the tree is frozen — otherwise it could pause but never
# un-pause itself. Children inherit ALWAYS, so the buttons stay clickable.

# res:// path of the menu scene "Quit to menu" loads. Empty quits the app.
@export_file("*.tscn") var menu_target: String = ""

@onready var _panel: Control = get_node_or_null("Panel")
@onready var _resume_button: Button = get_node_or_null("Panel/CenterContainer/VBox/ResumeButton")
@onready var _restart_button: Button = get_node_or_null("Panel/CenterContainer/VBox/RestartButton")
@onready var _quit_button: Button = get_node_or_null("Panel/CenterContainer/VBox/QuitButton")


func _ready() -> void:
	Localization.apply_saved_locale()
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("localizable_menu")
	_apply_responsive_layout()
	_apply_localized_text()
	add_to_group("pause_menu")
	if _panel != null:
		_panel.visible = false
	if _resume_button != null:
		_resume_button.pressed.connect(_on_resume_pressed)
	if _restart_button != null:
		_restart_button.pressed.connect(_on_restart_pressed)
	if _quit_button != null:
		_quit_button.pressed.connect(_on_quit_pressed)


func _apply_responsive_layout() -> void:
	var content: VBoxContainer = get_node_or_null("Panel/CenterContainer/VBox")
	if content != null:
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		content.custom_minimum_size = Vector2(minf(maxf(viewport_size.x - 40.0, 280.0), 520.0), 0.0)
		content.custom_maximum_size = Vector2(520.0, -1.0)
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 12)
	for button: Button in [_resume_button, _restart_button, _quit_button]:
		if button != null:
			button.custom_minimum_size = Vector2(0.0, 48.0)


func _apply_localized_text() -> void:
	_set_label_text("Panel/CenterContainer/VBox/PausedLabel", "paused")
	_set_button_text("Panel/CenterContainer/VBox/ResumeButton", "resume")
	_set_button_text("Panel/CenterContainer/VBox/RestartButton", "restart")
	_set_button_text("Panel/CenterContainer/VBox/QuitButton", "quit_to_menu")


func _set_label_text(path: String, key: String) -> void:
	var label: Label = get_node_or_null(path)
	if label != null:
		label.text = Localization.text(key)


func _set_button_text(path: String, key: String) -> void:
	var button: Button = get_node_or_null(path)
	if button != null:
		button.text = Localization.text(key)


func refresh_localization() -> void:
	_apply_localized_text()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	if _panel != null:
		_panel.visible = paused
	if paused and _resume_button != null:
		_resume_button.grab_focus()


func _on_resume_pressed() -> void:
	_set_paused(false)


func _on_restart_pressed() -> void:
	# A freshly loaded gameplay scene must not inherit the paused state.
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	# Clear pause before leaving — the next scene must not inherit a frozen tree.
	get_tree().paused = false
	if menu_target.is_empty():
		get_tree().quit()
	else:
		get_tree().root.get_node_or_null("ScreenTransition").transition_to(menu_target)
