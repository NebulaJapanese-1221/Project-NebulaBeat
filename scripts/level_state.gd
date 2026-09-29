extends RefCounted
class_name LevelState

# Session-level selection shared by the level selector, editor, and gameplay scene.
const BUILT_IN_LEVELS: Array[Dictionary] = [
	{"id": 1, "title_key": "tutorial_1_title", "subtitle_key": "tutorial_1_subtitle", "tutorial_key": "tutorial_1_hint", "spawn_interval": 1.00, "speed_multiplier": 0.55, "long_every": 0, "target_notes": 8, "tutorial": true},
	{"id": 2, "title_key": "tutorial_2_title", "subtitle_key": "tutorial_2_subtitle", "tutorial_key": "tutorial_2_hint", "spawn_interval": 0.92, "speed_multiplier": 0.66, "long_every": 0, "target_notes": 12, "tutorial": true},
	{"id": 3, "title_key": "tutorial_3_title", "subtitle_key": "tutorial_3_subtitle", "tutorial_key": "tutorial_3_hint", "spawn_interval": 0.86, "speed_multiplier": 0.74, "long_every": 4, "target_notes": 14, "tutorial": true},
	{"id": 4, "title_key": "level_4_title", "subtitle_key": "level_4_subtitle", "spawn_interval": 0.73, "speed_multiplier": 0.90, "long_every": 5, "target_notes": 18, "tutorial": false},
	{"id": 5, "title_key": "level_5_title", "subtitle_key": "level_5_subtitle", "spawn_interval": 0.63, "speed_multiplier": 1.05, "long_every": 4, "target_notes": 22, "tutorial": false},
	{"id": 6, "title_key": "level_6_title", "subtitle_key": "level_6_subtitle", "spawn_interval": 0.55, "speed_multiplier": 1.20, "long_every": 3, "target_notes": 26, "tutorial": false},
	{"id": 7, "title_key": "level_7_title", "subtitle_key": "level_7_subtitle", "spawn_interval": 0.47, "speed_multiplier": 1.34, "long_every": 3, "target_notes": 32, "tutorial": false}
]

static var selected_level_id: int = 1
static var selected_level_title: String = "Tutorial 01 — First Slice"
static var custom_note_pattern: Array[bool] = []
static var custom_spawn_interval: float = 0.68
static var custom_speed_multiplier: float = 1.0


static func level_data_for(level_id: int) -> Dictionary:
	var index: int = clampi(level_id, 1, BUILT_IN_LEVELS.size()) - 1
	var level: Dictionary = BUILT_IN_LEVELS[index].duplicate()
	level["title"] = Localization.text(String(level["title_key"]))
	level["subtitle"] = Localization.text(String(level["subtitle_key"]))
	if level.has("tutorial_key"):
		level["tutorial_hint"] = Localization.text(String(level["tutorial_key"]))
	return level


static func select_builtin(level_id: int) -> void:
	selected_level_id = clampi(level_id, 1, BUILT_IN_LEVELS.size())
	var level: Dictionary = level_data_for(selected_level_id)
	selected_level_title = String(level["title"])


static func select_custom() -> void:
	selected_level_id = 0
	selected_level_title = Localization.text("custom_chart")


static func get_level_data() -> Dictionary:
	if selected_level_id == 0:
		var active_notes: int = maxi(custom_note_pattern.count(true), 1)
		return {
			"id": 0,
			"title": Localization.text("custom_chart"),
			"subtitle": Localization.text("custom_chart_subtitle"),
			"spawn_interval": custom_spawn_interval,
			"speed_multiplier": custom_speed_multiplier,
			"long_every": 0,
			"target_notes": active_notes,
			"tutorial": false
		}
	return level_data_for(selected_level_id)


static func is_custom_long_note(note_index: int) -> bool:
	if selected_level_id != 0 or custom_note_pattern.is_empty():
		return false
	return custom_note_pattern[note_index % custom_note_pattern.size()]


static func reset_custom_chart() -> void:
	custom_note_pattern.clear()
	custom_spawn_interval = 0.68
	custom_speed_multiplier = 1.0


static func _profile() -> Node:
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return null
	return scene_tree.root.get_node_or_null("SaveManager")


static func _profile_value(key: String, fallback: Variant) -> Variant:
	var profile: Node = _profile()
	if profile == null:
		return fallback
	return profile.call("get_value", key, fallback)


static func _set_profile_value(key: String, value: Variant) -> void:
	var profile: Node = _profile()
	if profile != null:
		profile.call("set_value", key, value)


static func is_level_unlocked(level_id: int) -> bool:
	if level_id <= 1:
		return true
	return int(_profile_value("nebula_unlocked_level", 1)) >= level_id


static func best_score(level_id: int) -> int:
	return int(_profile_value("nebula_best_score_%d" % level_id, 0))


static func best_stars(level_id: int) -> int:
	return int(_profile_value("nebula_best_stars_%d" % level_id, 0))


static func record_completion(level_id: int, score: int, stars: int) -> void:
	if level_id <= 0:
		return
	var score_key: String = "nebula_best_score_%d" % level_id
	var stars_key: String = "nebula_best_stars_%d" % level_id
	_set_profile_value(score_key, maxi(best_score(level_id), score))
	_set_profile_value(stars_key, maxi(best_stars(level_id), stars))
	var unlocked_level: int = int(_profile_value("nebula_unlocked_level", 1))
	_set_profile_value("nebula_unlocked_level", maxi(unlocked_level, mini(level_id + 1, BUILT_IN_LEVELS.size())))
	var profile: Node = _profile()
	if profile != null:
		profile.call("save")
