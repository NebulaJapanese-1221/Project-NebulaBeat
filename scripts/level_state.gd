extends RefCounted
class_name LevelState

# Built-in content is deliberately limited to onboarding. Community/authored
# packages are kept separate and can supply any number of difficulty charts.
const BUILT_IN_LEVELS: Array[Dictionary] = [
	{"id": 1, "title_key": "tutorial_1_title", "subtitle_key": "tutorial_1_subtitle", "tutorial_key": "tutorial_1_hint", "spawn_interval": 1.00, "speed_multiplier": 0.55, "long_every": 0, "target_notes": 8, "tutorial": true},
	{"id": 2, "title_key": "tutorial_2_title", "subtitle_key": "tutorial_2_subtitle", "tutorial_key": "tutorial_2_hint", "spawn_interval": 0.92, "speed_multiplier": 0.66, "long_every": 0, "target_notes": 12, "tutorial": true},
	{"id": 3, "title_key": "tutorial_3_title", "subtitle_key": "tutorial_3_subtitle", "tutorial_key": "tutorial_3_hint", "spawn_interval": 0.86, "speed_multiplier": 0.74, "long_every": 4, "target_notes": 14, "tutorial": true}
]
const DIFFICULTIES: Array[String] = ["Easy", "Normal", "Hard"]
const CHART_STEP_COUNT: int = 64
const NBEAT_FORMAT: String = "nebula_beat_chart"
const NBEAT_VERSION: int = 1

static var selected_level_id: int = 1
static var selected_level_title: String = "Tutorial 01 — First Slice"
static var custom_level_name: String = "Untitled Nebula Chart"
static var custom_audio_path: String = ""
static var custom_bpm: float = 120.0
static var custom_speed_multiplier: float = 1.0
static var custom_difficulty: String = "Normal"
static var custom_charts: Dictionary = {"Easy": [], "Normal": [], "Hard": []}


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


static func select_custom(difficulty: String = "") -> void:
	if not difficulty.is_empty() and difficulty in DIFFICULTIES:
		custom_difficulty = difficulty
	selected_level_id = 0
	selected_level_title = "%s — %s" % [custom_level_name, custom_difficulty]


static func get_chart_events(difficulty: String = "") -> Array[Dictionary]:
	var selected_difficulty: String = difficulty if difficulty in DIFFICULTIES else custom_difficulty
	var stored: Variant = custom_charts.get(selected_difficulty, [])
	var events: Array[Dictionary] = []
	if stored is Array:
		for raw_event: Variant in stored:
			if raw_event is Dictionary:
				events.append((raw_event as Dictionary).duplicate())
	return events


static func set_chart_events(events: Array, difficulty: String = "") -> void:
	var selected_difficulty: String = difficulty if difficulty in DIFFICULTIES else custom_difficulty
	var normalised: Array[Dictionary] = []
	var seen_steps: Dictionary = {}
	for raw_event: Variant in events:
		if not raw_event is Dictionary:
			continue
		var source: Dictionary = raw_event
		var step: int = clampi(int(source.get("step", 0)), 0, CHART_STEP_COUNT - 1)
		if seen_steps.has(step):
			continue
		seen_steps[step] = true
		normalised.append({"step": step, "long": bool(source.get("long", false))})
	normalised.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["step"]) < int(b["step"]))
	custom_charts[selected_difficulty] = normalised


static func event_at_step(step: int, difficulty: String = "") -> Dictionary:
	for event: Dictionary in get_chart_events(difficulty):
		if int(event.get("step", -1)) == step:
			return event
	return {}


static func set_step_event(step: int, enabled: bool, is_long: bool, difficulty: String = "") -> void:
	var events: Array[Dictionary] = get_chart_events(difficulty)
	var found_index: int = -1
	for index: int in range(events.size()):
		if int(events[index].get("step", -1)) == step:
			found_index = index
			break
	if enabled:
		var event: Dictionary = {"step": clampi(step, 0, CHART_STEP_COUNT - 1), "long": is_long}
		if found_index >= 0:
			events[found_index] = event
		else:
			events.append(event)
	elif found_index >= 0:
		events.remove_at(found_index)
	set_chart_events(events, difficulty)


static func get_level_data() -> Dictionary:
	if selected_level_id == 0:
		var events: Array[Dictionary] = get_chart_events()
		if events.is_empty():
			events.append({"step": 0, "long": false})
		return {
			"id": 0,
			"title": "%s — %s" % [custom_level_name, custom_difficulty],
			"subtitle": "Authored .nbeat chart",
			"spawn_interval": 60.0 / maxf(custom_bpm, 1.0),
			"speed_multiplier": custom_speed_multiplier,
			"target_notes": events.size(),
			"chart_events": events,
			"audio_path": custom_audio_path,
			"tutorial": false
		}
	return level_data_for(selected_level_id)


static func is_custom_long_note(note_index: int) -> bool:
	var events: Array[Dictionary] = get_chart_events()
	return note_index >= 0 and note_index < events.size() and bool(events[note_index].get("long", false))


static func custom_event_time(note_index: int) -> float:
	var events: Array[Dictionary] = get_chart_events()
	if note_index < 0 or note_index >= events.size():
		return float(note_index) * 60.0 / maxf(custom_bpm, 1.0)
	return float(int(events[note_index].get("step", 0))) * (60.0 / maxf(custom_bpm, 1.0)) * 0.25


static func make_nbeat_payload(difficulty: String = "") -> Dictionary:
	var selected_difficulty: String = difficulty if difficulty in DIFFICULTIES else custom_difficulty
	return {
		"format": NBEAT_FORMAT,
		"version": NBEAT_VERSION,
		"level_name": custom_level_name,
		"difficulty": selected_difficulty,
		"bpm": custom_bpm,
		"speed_multiplier": custom_speed_multiplier,
		"audio_filename": custom_audio_path.get_file(),
		"events": get_chart_events(selected_difficulty)
	}


static func load_nbeat_payload(payload: Dictionary) -> bool:
	if String(payload.get("format", "")) != NBEAT_FORMAT:
		return false
	var difficulty: String = String(payload.get("difficulty", "Normal"))
	if not difficulty in DIFFICULTIES:
		difficulty = "Normal"
	custom_level_name = String(payload.get("level_name", custom_level_name)).strip_edges()
	if custom_level_name.is_empty():
		custom_level_name = "Untitled Nebula Chart"
	custom_bpm = clampf(float(payload.get("bpm", custom_bpm)), 40.0, 260.0)
	custom_speed_multiplier = clampf(float(payload.get("speed_multiplier", custom_speed_multiplier)), 0.4, 2.5)
	set_chart_events(Array(payload.get("events", [])), difficulty)
	custom_difficulty = difficulty
	return true


static func reset_custom_chart() -> void:
	custom_level_name = "Untitled Nebula Chart"
	custom_audio_path = ""
	custom_bpm = 120.0
	custom_speed_multiplier = 1.0
	custom_difficulty = "Normal"
	custom_charts = {"Easy": [], "Normal": [], "Hard": []}


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
	return level_id >= 1 and level_id <= BUILT_IN_LEVELS.size()


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
	var profile: Node = _profile()
	if profile != null:
		profile.call("save")
