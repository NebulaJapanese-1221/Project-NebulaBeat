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

const MAIN_MENU_PATH: String = "res://scenes/main_menu.tscn"
const GAMEPLAY_PATH: String = "res://scenes/nebula_beat.tscn"
const LEVEL_EDITOR_PATH: String = "res://scenes/level_editor.tscn"
const LEVEL_DOWNLOADER_PATH: String = "res://scenes/level_downloader.tscn"

@onready var _button_list: VBoxContainer = get_node_or_null("CenterContainer/VBox")
@onready var _scores_button: Button = get_node_or_null("CenterContainer/VBox/ScoresButton")
@onready var _replays_button: Button = get_node_or_null("CenterContainer/VBox/ReplaysButton")
@onready var _scores_panel: PanelContainer = get_node_or_null("CenterContainer/ScoresPanel")
@onready var _scores_list: VBoxContainer = get_node_or_null("CenterContainer/ScoresPanel/ScoresVBox/ScoresList")
@onready var _scores_back_button: Button = get_node_or_null("CenterContainer/ScoresPanel/ScoresVBox/ScoresBackButton")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_localized_text()
	for level_id: int in range(1, LevelState.BUILT_IN_LEVELS.size() + 1):
		var button: Button = get_node_or_null("CenterContainer/VBox/Level%dButton" % level_id)
		if button == null:
			continue
		var unlocked: bool = LevelState.is_level_unlocked(level_id)
		button.disabled = not unlocked
		var level_data: Dictionary = LevelState.level_data_for(level_id)
		var suffix: String = ""
		if unlocked:
			var stars: int = LevelState.best_stars(level_id)
			var record: int = LevelState.best_score(level_id)
			suffix = "  %s  %06d" % ["★".repeat(stars) + "☆".repeat(3 - stars), record] if record > 0 else ""
			button.pressed.connect(_open_level.bind(level_id))
		else:
			suffix = "  •  " + Localization.text("locked")
		button.text = "%02d  %s%s" % [level_id, String(level_data["title"]), suffix]
	var editor_button: Button = get_node_or_null("CenterContainer/VBox/EditorButton")
	if editor_button != null:
		editor_button.pressed.connect(_open_editor)
	var downloader_button: Button = get_node_or_null("CenterContainer/VBox/DownloaderButton")
	if downloader_button != null:
		downloader_button.pressed.connect(_open_downloader)
	if _scores_button != null:
		_scores_button.pressed.connect(_toggle_scores_panel)
	if _scores_back_button != null:
		_scores_back_button.pressed.connect(_hide_scores_panel)
	if _replays_button != null:
		_replays_button.pressed.connect(_open_replays)
	var back_button: Button = get_node_or_null("CenterContainer/VBox/BackButton")
	if back_button != null:
		back_button.pressed.connect(_return_to_main_menu)
	var first_button: Button = get_node_or_null("CenterContainer/VBox/Level1Button")
	if first_button != null:
		first_button.grab_focus()
	_make_level_list_scrollable()


func _make_level_list_scrollable() -> void:
	if _button_list == null or _button_list.get_parent() == null:
		return
	_button_list.alignment = BoxContainer.ALIGNMENT_CENTER
	var host: CenterContainer = _button_list.get_parent() as CenterContainer
	if host == null:
		return
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var viewport_height: float = get_viewport_rect().size.y
	scroll.custom_minimum_size = Vector2(280.0, clampf(viewport_height - 72.0, 220.0, 520.0))
	scroll.custom_maximum_size = Vector2(640.0, 520.0)
	_button_list.custom_minimum_size = Vector2(280.0, 0.0)
	_button_list.custom_maximum_size = Vector2(620.0, -1.0)
	_button_list.add_theme_constant_override("separation", 10)
	for child: Node in _button_list.get_children():
		if child is Button:
			(child as Button).custom_minimum_size = Vector2(0.0, 48.0)
	host.remove_child(_button_list)
	host.add_child(scroll)
	scroll.add_child(_button_list)


func _apply_localized_text() -> void:
	_set_label_text("CenterContainer/VBox/Title", "levels")
	_set_label_text("CenterContainer/VBox/Subtitle", "levels_subtitle")
	_set_button_text("CenterContainer/VBox/EditorButton", "editor")
	_set_button_text("CenterContainer/VBox/DownloaderButton", "downloader")
	_set_button_text("CenterContainer/VBox/BackButton", "back")
	if _scores_button != null:
		_scores_button.text = Localization.text("scores")
	if _scores_back_button != null:
		_scores_back_button.text = Localization.text("back")
	if _replays_button != null:
		_replays_button.text = Localization.text("replays")


func refresh_localization() -> void:
	_apply_localized_text()
	for level_id: int in range(1, LevelState.BUILT_IN_LEVELS.size() + 1):
		var button: Button = get_node_or_null("CenterContainer/VBox/Level%dButton" % level_id)
		if button != null:
			var unlocked: bool = LevelState.is_level_unlocked(level_id)
			var level_data: Dictionary = LevelState.level_data_for(level_id)
			var suffix: String = "  •  " + Localization.text("locked") if not unlocked else ""
			button.text = "%02d  %s%s" % [level_id, String(level_data["title"]), suffix]
	if _scores_panel != null and _scores_panel.visible:
		_populate_scores()


func _toggle_scores_panel() -> void:
	if _scores_panel == null:
		return
	if _scores_panel.visible:
		_hide_scores_panel()
	else:
		_show_scores_panel()


func _show_scores_panel() -> void:
	if _scores_panel == null:
		return
	_scores_panel.visible = true
	_populate_scores()
	if _scores_back_button != null:
		_scores_back_button.grab_focus()


func _hide_scores_panel() -> void:
	if _scores_panel == null:
		return
	_scores_panel.visible = false
	_clear_scores_list()
	if _scores_button != null:
		_scores_button.grab_focus()


func _clear_scores_list() -> void:
	if _scores_list == null:
		return
	for child: Node in _scores_list.get_children():
		child.queue_free()


func _populate_scores() -> void:
	if _scores_list == null:
		return
	_clear_scores_list()
	for level_id: int in range(1, LevelState.BUILT_IN_LEVELS.size() + 1):
		var level_data: Dictionary = LevelState.level_data_for(level_id)
		var title: String = String(level_data.get("title", "Level %d" % level_id))
		var entries: Array[Dictionary] = LevelState.leaderboard(level_id)
		var header: Label = Label.new()
		header.text = "%02d  %s" % [level_id, title]
		header.add_theme_font_size_override("font_size", 18)
		header.add_theme_color_override("font_color", Color(0.63, 0.9, 1.0))
		_scores_list.add_child(header)
		if entries.is_empty():
			var empty: Label = Label.new()
			empty.text = "  -- no scores yet --"
			empty.add_theme_font_size_override("font_size", 14)
			empty.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
			_scores_list.add_child(empty)
		else:
			for index: int in range(entries.size()):
				var entry: Dictionary = entries[index]
				var score: int = int(entry.get("score", 0))
				var stars: int = int(entry.get("stars", 0))
				var star_str: String = "★".repeat(stars) + "☆".repeat(3 - stars)
				var row: Label = Label.new()
				row.text = "  #%d  %06d  %s" % [index + 1, score, star_str]
				row.add_theme_font_size_override("font_size", 14)
				row.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
				_scores_list.add_child(row)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if _scores_panel != null and _scores_panel.visible:
			_hide_scores_panel()
			get_viewport().set_input_as_handled()
			return
		_return_to_main_menu()
		get_viewport().set_input_as_handled()


func _open_level(level_id: int) -> void:
	if not LevelState.is_level_unlocked(level_id):
		return
	LevelState.select_builtin(level_id)
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(GAMEPLAY_PATH)


func _open_editor() -> void:
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(LEVEL_EDITOR_PATH)


func _open_downloader() -> void:
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(LEVEL_DOWNLOADER_PATH)


func _return_to_main_menu() -> void:
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(MAIN_MENU_PATH)


func _open_replays() -> void:
	get_tree().root.get_node_or_null("ScreenTransition").transition_to("res://scenes/replay_gallery.tscn")
