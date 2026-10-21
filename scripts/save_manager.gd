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

extends Node

# Global save/load service, registered as an autoload so every scene can reach it
# by name. Persists a flat key/value store as JSON under user:// — the only
# writable, per-user, cross-platform location (res:// is read-only in an exported
# game). Reach it globally by its autoload name:
#     SaveManager.set_value("coins", 42)
#     var coins = SaveManager.get_value("coins", 0)
#     SaveManager.save()
#
# Store JSON-native values (int, float, bool, String, Array, Dictionary). Engine
# types like Vector2/Color are NOT JSON-native — persist them as components
# (e.g. set_value("pos_x", pos.x)) or an array [x, y].

signal saved     # emitted after a successful save()
signal loaded    # emitted after load_data() reads an existing file

## Auto-save on quit (and on app-pause on mobile) so progress is never dropped.
@export var autosave: bool = true
## Which save slot is active. Each slot is a separate file. Use set_slot() to switch.
@export var slot: int = 0

var _data: Dictionary = {}


func _ready() -> void:
	# An autoload keeps running even when the tree is paused (e.g. a pause menu),
	# so a save triggered from a paused state still works.
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_data()
	Localization.apply_saved_locale()
	if OS.get_name() == "Android":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.screen_set_keep_on(true)


func _notification(what: int) -> void:
	if not autosave:
		return
	# Save on window close (desktop) and on app going to background (mobile),
	# the two moments a session can end without an explicit save() call.
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save()


# ── Key/value access ─────────────────────────────────────────────────────────

func set_value(key: String, value) -> void:
	_data[key] = value


func get_value(key: String, default_value = null):
	return _data.get(key, default_value)


func has_key(key: String) -> bool:
	return _data.has(key)


func erase_key(key: String) -> void:
	_data.erase(key)


func clear() -> void:
	_data.clear()


# ── Leaderboard ──────────────────────────────────────────────────────────────

## Record a score for a level, keeping only the top MAX_LEADERBOARD_ENTRIES
## sorted by score desc. Returns the 1-based rank (0 if not in top N).
const MAX_LEADERBOARD_ENTRIES: int = 5

func leaderboard_key(level_id: int) -> String:
	return "nebula_leaderboard_%d" % level_id


func add_leaderboard_score(level_id: int, score: int, stars: int) -> int:
	var key: String = leaderboard_key(level_id)
	var entries: Array[Dictionary] = get_leaderboard(level_id)
	var entry: Dictionary = {"score": score, "stars": stars}
	entries.append(entry)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0)))
	if entries.size() > MAX_LEADERBOARD_ENTRIES:
		entries.resize(MAX_LEADERBOARD_ENTRIES)
	set_value(key, entries)
	save()
	var rank: int = 0
	for index: int in range(entries.size()):
		if entries[index].get("score", 0) == score:
			rank = index + 1
			break
	return rank


func get_leaderboard(level_id: int) -> Array[Dictionary]:
	var key: String = leaderboard_key(level_id)
	var raw: Variant = get_value(key, [])
	if raw is Array:
		return raw
	return []


# ── Persistence ──────────────────────────────────────────────────────────────

func _path() -> String:
	return "user://savegame_%d.json" % slot


# Write the current data to disk as JSON. Returns true on success.
func save() -> bool:
	var f := FileAccess.open(_path(), FileAccess.WRITE)
	if f == null:
		push_error("[SaveManager] Could not open '%s' for writing (error %d)" % [_path(), FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(_data, "\t"))
	f.close()
	saved.emit()
	return true


# Load data from disk into memory. Missing file → start empty (not an error).
# Corrupt file → warn and start empty rather than crash. Returns true if an
# existing, valid save was read.
func load_data() -> bool:
	if not has_save():
		_data = {}
		return false
	var f := FileAccess.open(_path(), FileAccess.READ)
	if f == null:
		push_error("[SaveManager] Could not open '%s' for reading (error %d)" % [_path(), FileAccess.get_open_error()])
		return false
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		_data = parsed
		loaded.emit()
		return true
	push_warning("[SaveManager] Save file '%s' is corrupt or not a JSON object; starting empty." % _path())
	_data = {}
	return false


func has_save() -> bool:
	return FileAccess.file_exists(_path())


# Delete the current slot's save file and clear in-memory data. Returns true if a
# file was removed.
func delete_save() -> bool:
	_data.clear()
	if not has_save():
		return false
	var abs := ProjectSettings.globalize_path(_path())
	var err := DirAccess.remove_absolute(abs)
	return err == OK


# Switch to a different save slot and load its data (if any). Useful for a
# multiple-save-file UI.
func set_slot(new_slot: int) -> void:
	slot = new_slot
	load_data()
