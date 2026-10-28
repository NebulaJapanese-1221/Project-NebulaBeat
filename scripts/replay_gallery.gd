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

const LEVELS_MENU_PATH: String = "res://scenes/levels_menu.tscn"
const GAMEPLAY_PATH: String = "res://scenes/nebula_beat.tscn"
const REPLAY_KEY_PREFIX: String = "nebula_replay_level_"
const REPLAY_META_KEY_PREFIX: String = "nebula_replay_level_"
const PLAY_REPLAY_KEY: String = "nebula_play_replay_level"

@onready var _replay_list: VBoxContainer = get_node_or_null("CenterContainer/VBox/ReplayList")
@onready var _empty_label: Label = get_node_or_null("CenterContainer/VBox/EmptyLabel")
@onready var _back_button: Button = get_node_or_null("CenterContainer/VBox/BackButton")
@onready var _menu_back: AudioStreamPlayer = get_node_or_null("MenuBack")

var _replay_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_localized_text()
	if _back_button != null:
		_back_button.pressed.connect(_return_to_levels)
		_back_button.grab_focus()
	_reload_replay_list()


func _apply_localized_text() -> void:
	var title: Label = get_node_or_null("CenterContainer/VBox/Title")
	if title != null:
		title.text = Localization.text("replay_gallery")
	var subtitle: Label = get_node_or_null("CenterContainer/VBox/Subtitle")
	if subtitle != null:
		subtitle.text = Localization.text("replay_gallery_subtitle")
	if _back_button != null:
		_back_button.text = Localization.text("back")


func refresh_localization() -> void:
	_apply_localized_text()
	_reload_replay_list()


func _profile() -> Node:
	return get_tree().root.get_node_or_null("SaveManager")


func _reload_replay_list() -> void:
	_clear_replay_buttons()
	if _replay_list == null:
		return

	var profile: Node = _profile()
	if profile == null:
		_show_empty(true)
		return

	var found_any: bool = false
	for level_id: int in range(1, LevelState.BUILT_IN_LEVELS.size() + 1):
		var key: String = REPLAY_KEY_PREFIX + str(level_id)
		var raw: Variant = profile.call("get_value", key, null)
		if raw is Array and raw.size() > 0:
			var meta_key: String = REPLAY_META_KEY_PREFIX + str(level_id) + "_meta"
			var meta_raw: Variant = profile.call("get_value", meta_key, null)
			var score: int = 0
			var stars: int = 0
			var perfect: int = 0
			var good: int = 0
			var miss: int = 0
			var max_combo: int = 0
			if meta_raw is Dictionary:
				score = int(meta_raw.get("score", 0))
				stars = int(meta_raw.get("stars", 0))
				perfect = int(meta_raw.get("perfect", 0))
				good = int(meta_raw.get("good", 0))
				miss = int(meta_raw.get("miss", 0))
				max_combo = int(meta_raw.get("combo", 0))
			_add_replay_button(level_id, score, stars, perfect, good, miss, max_combo)
			found_any = true

	_show_empty(not found_any)


func _clear_replay_buttons() -> void:
	if _replay_list == null:
		return
	for btn: Button in _replay_buttons:
		_replay_list.remove_child(btn)
		btn.queue_free()
	_replay_buttons.clear()


func _add_replay_button(level_id: int, score: int, stars: int, perfect: int, good: int, miss: int, max_combo: int) -> void:
	if _replay_list == null:
		return
	var level_data: Dictionary = LevelState.level_data_for(level_id)
	var title: String = String(level_data.get("title", "Level %d" % level_id))

	var btn: Button = Button.new()
	var star_str: String = "★".repeat(stars) + "☆".repeat(3 - stars)
	var total: int = perfect + good + miss
	var accuracy: int = 0 if total <= 0 else int(float(perfect + good) / float(total) * 100.0)
	btn.text = "%02d  %s  |  %s %06d  |  %s %d%%  |  %s %d  %s %d  %s %d  |  %s %d" % [
		level_id, title, star_str, score,
		Localization.text("accuracy"), accuracy,
		Localization.text("perfect"), perfect,
		Localization.text("good"), good,
		Localization.text("miss"), miss,
		Localization.text("combo"), max_combo
	]
	btn.custom_minimum_size = Vector2(0.0, 52.0)
	btn.pressed.connect(_play_replay.bind(level_id))
	_replay_list.add_child(btn)
	_replay_buttons.append(btn)


func _show_empty(empty: bool) -> void:
	if _empty_label != null:
		_empty_label.visible = empty


func _play_replay(level_id: int) -> void:
	var profile: Node = _profile()
	if profile == null:
		return
	profile.call("set_value", PLAY_REPLAY_KEY, level_id)
	profile.call("save")
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(GAMEPLAY_PATH)


func _return_to_levels() -> void:
	if _menu_back != null:
		_menu_back.play()
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(LEVELS_MENU_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_return_to_levels()
		get_viewport().set_input_as_handled()
