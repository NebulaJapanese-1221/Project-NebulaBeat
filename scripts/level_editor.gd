extends Control

const LEVELS_MENU_PATH: String = "res://scenes/levels_menu.tscn"
const GAMEPLAY_PATH: String = "res://scenes/nebula_beat.tscn"
const CHART_STEP_COUNT: int = LevelState.CHART_STEP_COUNT
const PACKAGE_DIRECTORY: String = "user://nebula_levels"
const CATALOG_SERVER_URL: String = "http://localhost:8765"

@onready var _content: VBoxContainer = get_node_or_null("CenterContainer/VBox")
@onready var _beat_grid: GridContainer = get_node_or_null("CenterContainer/VBox/BeatGrid")
@onready var _tempo_slider: HSlider = get_node_or_null("CenterContainer/VBox/TempoSlider")
@onready var _speed_slider: HSlider = get_node_or_null("CenterContainer/VBox/SpeedSlider")
@onready var _level_name_input: LineEdit = get_node_or_null("CenterContainer/VBox/LevelNameInput")
@onready var _difficulty_option: OptionButton = get_node_or_null("CenterContainer/VBox/DifficultyOption")
@onready var _bpm_slider: HSlider = get_node_or_null("CenterContainer/VBox/BpmSlider")
@onready var _long_note_mode_toggle: CheckButton = get_node_or_null("CenterContainer/VBox/LongNoteModeToggle")
@onready var _select_mp3_button: Button = get_node_or_null("CenterContainer/VBox/SelectMp3Button")
@onready var _auto_build_button: Button = get_node_or_null("CenterContainer/VBox/AutoBuildButton")
@onready var _import_package_button: Button = get_node_or_null("CenterContainer/VBox/ImportPackageButton")
@onready var _export_package_button: Button = get_node_or_null("CenterContainer/VBox/ExportPackageButton")
@onready var _playtest_button: Button = get_node_or_null("CenterContainer/VBox/PlaytestButton")
@onready var _reset_button: Button = get_node_or_null("CenterContainer/VBox/ResetButton")
@onready var _export_chart_button: Button = get_node_or_null("CenterContainer/VBox/ExportChartButton")
@onready var _import_chart_button: Button = get_node_or_null("CenterContainer/VBox/ImportChartButton")
@onready var _back_button: Button = get_node_or_null("CenterContainer/VBox/BackButton")
@onready var _status_label: Label = get_node_or_null("CenterContainer/VBox/StatusLabel")
@onready var _mp3_dialog: FileDialog = get_node_or_null("Mp3Dialog")
@onready var _import_dialog: FileDialog = get_node_or_null("ImportPackageDialog")
@onready var _chart_file_dialog: FileDialog = get_node_or_null("ChartFileDialog")
@onready var _catalog_upload_request: HTTPRequest = get_node_or_null("CatalogUploadRequest")
@onready var _catalog_download_request: HTTPRequest = get_node_or_null("CatalogDownloadRequest")
@onready var _catalog_list_request: HTTPRequest = get_node_or_null("CatalogListRequest")


func _ready() -> void:
	Localization.apply_saved_locale()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_to_group("localizable_menu")
	_ensure_beat_cells()
	_setup_controls()
	_order_editor_content()
	_apply_responsive_layout()
	_apply_localized_text()
	_refresh_editor_from_state()
	_wrap_workspace_in_scroll_view()
	var first_beat: CheckButton = _beat_button(0)
	if first_beat != null:
		first_beat.grab_focus()


func _ensure_beat_cells() -> void:
	if _beat_grid == null:
		return
	for index: int in range(CHART_STEP_COUNT):
		var button: CheckButton = _beat_button(index)
		if button == null:
			button = CheckButton.new()
			button.name = "Beat%02d" % (index + 1)
			_beat_grid.add_child(button)
		button.text = "%02d" % (index + 1)
		if not button.toggled.is_connected(_on_beat_toggled.bind(index)):
			button.toggled.connect(_on_beat_toggled.bind(index))


func _setup_controls() -> void:
	if _tempo_slider != null:
		_tempo_slider.min_value = 0.20
		_tempo_slider.max_value = 1.50
		_tempo_slider.step = 0.01
		if not _tempo_slider.value_changed.is_connected(_on_tempo_changed):
			_tempo_slider.value_changed.connect(_on_tempo_changed)
	if _speed_slider != null:
		_speed_slider.min_value = 0.40
		_speed_slider.max_value = 2.50
		_speed_slider.step = 0.05
		if not _speed_slider.value_changed.is_connected(_on_speed_changed):
			_speed_slider.value_changed.connect(_on_speed_changed)
	if _bpm_slider != null:
		_bpm_slider.min_value = 40.0
		_bpm_slider.max_value = 260.0
		_bpm_slider.step = 1.0
		if not _bpm_slider.value_changed.is_connected(_on_bpm_changed):
			_bpm_slider.value_changed.connect(_on_bpm_changed)
	if _level_name_input != null:
		if not _level_name_input.text_changed.is_connected(_on_level_name_changed):
			_level_name_input.text_changed.connect(_on_level_name_changed)
	if _difficulty_option != null:
		_difficulty_option.clear()
		for difficulty: String in LevelState.DIFFICULTIES:
			_difficulty_option.add_item(difficulty)
		if not _difficulty_option.item_selected.is_connected(_on_difficulty_selected):
			_difficulty_option.item_selected.connect(_on_difficulty_selected)
	if _select_mp3_button != null and not _select_mp3_button.pressed.is_connected(_open_mp3_picker):
		_select_mp3_button.pressed.connect(_open_mp3_picker)
	if _auto_build_button != null and not _auto_build_button.pressed.is_connected(_auto_build_from_mp3):
		_auto_build_button.pressed.connect(_auto_build_from_mp3)
	if _export_package_button != null and not _export_package_button.pressed.is_connected(_export_level_package):
		_export_package_button.pressed.connect(_export_level_package)
	if _import_package_button != null and not _import_package_button.pressed.is_connected(_open_import_picker):
		_import_package_button.pressed.connect(_open_import_picker)
	if _playtest_button != null and not _playtest_button.pressed.is_connected(_playtest_chart):
		_playtest_button.pressed.connect(_playtest_chart)
	if _reset_button != null and not _reset_button.pressed.is_connected(_reset_chart):
		_reset_button.pressed.connect(_reset_chart)
	if _export_chart_button != null and not _export_chart_button.pressed.is_connected(_export_chart):
		_export_chart_button.pressed.connect(_export_chart)
	if _import_chart_button != null and not _import_chart_button.pressed.is_connected(_import_chart):
		_import_chart_button.pressed.connect(_import_chart)
	if _back_button != null and not _back_button.pressed.is_connected(_return_to_levels):
		_back_button.pressed.connect(_return_to_levels)
	_setup_file_dialogs()


func _setup_file_dialogs() -> void:
	if _mp3_dialog != null:
		_mp3_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_mp3_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_mp3_dialog.filters = PackedStringArray(["*.mp3 ; MP3 audio"])
		if not _mp3_dialog.file_selected.is_connected(_on_mp3_selected):
			_mp3_dialog.file_selected.connect(_on_mp3_selected)
	if _import_dialog != null:
		_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_import_dialog.filters = PackedStringArray(["*.zip ; Nebula Beat package"])
		if not _import_dialog.file_selected.is_connected(_on_package_selected):
			_import_dialog.file_selected.connect(_on_package_selected)
	if _chart_file_dialog != null:
		_chart_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		_chart_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_chart_file_dialog.current_dir = ProjectSettings.globalize_path("user://")
		_chart_file_dialog.filters = PackedStringArray(["*.nbeat ; Nebula Beat chart"])
		if not _chart_file_dialog.file_selected.is_connected(_on_chart_file_selected):
			_chart_file_dialog.file_selected.connect(_on_chart_file_selected)
	if _catalog_upload_request != null and not _catalog_upload_request.request_completed.is_connected(_on_catalog_upload_completed):
		_catalog_upload_request.request_completed.connect(_on_catalog_upload_completed)
	if _catalog_download_request != null and not _catalog_download_request.request_completed.is_connected(_on_catalog_download_completed):
		_catalog_download_request.request_completed.connect(_on_catalog_download_completed)
	if _catalog_list_request != null and not _catalog_list_request.request_completed.is_connected(_on_catalog_list_completed):
		_catalog_list_request.request_completed.connect(_on_catalog_list_completed)


func _order_editor_content() -> void:
	if _content == null:
		return
	var order: Array[String] = [
		"Title", "Help", "LevelNameInput", "DifficultyOption", "BpmLabel", "BpmSlider", "TempoLabel", "TempoSlider", "SpeedLabel", "SpeedSlider", "LongNoteModeToggle", "SelectMp3Button", "AutoBuildButton", "BeatGrid", "StatusLabel", "ImportPackageButton", "ExportPackageButton", "ExportChartButton", "ImportChartButton", "PlaytestButton", "ResetButton", "BackButton"
	]
	for node_name: String in order:
		var child: Node = _content.get_node_or_null(node_name)
		if child != null:
			_content.move_child(child, -1)


func _wrap_workspace_in_scroll_view() -> void:
	if _content == null or _content.get_parent() == null:
		return
	if _content.get_parent() is ScrollContainer:
		return
	var host: CenterContainer = _content.get_parent() as CenterContainer
	if host == null:
		return
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "EditorScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var viewport_size: Vector2 = get_viewport_rect().size
	scroll.custom_minimum_size = Vector2(minf(maxf(viewport_size.x - 32.0, 320.0), 880.0), minf(maxf(viewport_size.y - 28.0, 260.0), 760.0))
	host.remove_child(_content)
	host.add_child(scroll)
	scroll.add_child(_content)


func _apply_responsive_layout() -> void:
	if _content != null:
		var viewport_size: Vector2 = get_viewport_rect().size
		_content.custom_minimum_size = Vector2(minf(maxf(viewport_size.x - 48.0, 320.0), 840.0), 0.0)
		_content.custom_maximum_size = Vector2(840.0, -1.0)
		_content.add_theme_constant_override("separation", 12)
	if _beat_grid != null:
		_beat_grid.columns = 8
		_beat_grid.add_theme_constant_override("h_separation", 8)
		_beat_grid.add_theme_constant_override("v_separation", 8)
		for beat_node: Node in _beat_grid.get_children():
			if beat_node is CheckButton:
				(beat_node as CheckButton).custom_minimum_size = Vector2(76.0, 42.0)
	for control: Control in [_level_name_input, _difficulty_option, _tempo_slider, _speed_slider, _bpm_slider, _long_note_mode_toggle, _select_mp3_button, _auto_build_button, _import_package_button, _export_package_button, _playtest_button, _reset_button, _back_button]:
		if control != null:
			control.custom_minimum_size = Vector2(0.0, 48.0)
	if _status_label != null:
		_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_status_label.custom_minimum_size = Vector2(0.0, 42.0)


func _apply_localized_text() -> void:
	_set_label_text("CenterContainer/VBox/Title", "editor")
	_set_label_text("CenterContainer/VBox/Help", "editor_help")
	_set_label_text("CenterContainer/VBox/TempoLabel", "tempo")
	_set_label_text("CenterContainer/VBox/SpeedLabel", "speed")
	_set_label_text("CenterContainer/VBox/BpmLabel", "bpm")
	_set_button_text("CenterContainer/VBox/LongNoteModeToggle", "long_note_mode")
	_set_button_text("CenterContainer/VBox/SelectMp3Button", "select_mp3")
	_set_button_text("CenterContainer/VBox/AutoBuildButton", "autobuild")
	_set_button_text("CenterContainer/VBox/ImportPackageButton", "import_package")
	_set_button_text("CenterContainer/VBox/ExportPackageButton", "export_package")
	_set_button_text("CenterContainer/VBox/PlaytestButton", "playtest")
	_set_button_text("CenterContainer/VBox/ResetButton", "reset")
	_set_button_text("CenterContainer/VBox/BackButton", "back")
	if _level_name_input != null:
		_level_name_input.placeholder_text = Localization.text("level_name")


func refresh_localization() -> void:
	_apply_localized_text()
	_refresh_editor_from_state()


func _refresh_editor_from_state() -> void:
	if _level_name_input != null:
		_level_name_input.text = LevelState.custom_level_name
	if _difficulty_option != null:
		_difficulty_option.select(maxi(LevelState.DIFFICULTIES.find(LevelState.custom_difficulty), 0))
	if _bpm_slider != null:
		_bpm_slider.value = LevelState.custom_bpm
	if _tempo_slider != null:
		_tempo_slider.value = 60.0 / maxf(LevelState.custom_bpm, 1.0)
	if _speed_slider != null:
		_speed_slider.value = LevelState.custom_speed_multiplier
	for index: int in range(CHART_STEP_COUNT):
		var beat_button: CheckButton = _beat_button(index)
		if beat_button != null:
			var event: Dictionary = LevelState.event_at_step(index)
			beat_button.set_pressed_no_signal(not event.is_empty())
			beat_button.tooltip_text = "Step %02d%s" % [index + 1, " — long note" if bool(event.get("long", false)) else ""]
	_set_status("%s: %d  •  %s  •  %s" % [Localization.text("chart_steps"), LevelState.get_chart_events().size(), LevelState.custom_difficulty, _audio_status()])


func _on_beat_toggled(enabled: bool, beat_index: int) -> void:
	LevelState.set_step_event(beat_index, enabled, _long_note_mode_toggle != null and _long_note_mode_toggle.button_pressed)
	_refresh_editor_from_state()


func _on_tempo_changed(value: float) -> void:
	LevelState.custom_bpm = clampf(60.0 / maxf(value, 0.01), 40.0, 260.0)
	if _bpm_slider != null:
		_bpm_slider.set_value_no_signal(LevelState.custom_bpm)


func _on_speed_changed(value: float) -> void:
	LevelState.custom_speed_multiplier = value


func _on_bpm_changed(value: float) -> void:
	LevelState.custom_bpm = value
	if _tempo_slider != null:
		_tempo_slider.set_value_no_signal(60.0 / maxf(value, 1.0))


func _on_level_name_changed(value: String) -> void:
	LevelState.custom_level_name = value.strip_edges() if not value.strip_edges().is_empty() else "Untitled Nebula Chart"


func _on_difficulty_selected(index: int) -> void:
	if index >= 0 and index < LevelState.DIFFICULTIES.size():
		LevelState.custom_difficulty = LevelState.DIFFICULTIES[index]
		_refresh_editor_from_state()


func _open_mp3_picker() -> void:
	if _mp3_dialog != null:
		_mp3_dialog.popup_centered_ratio(0.8)


func _on_mp3_selected(path: String) -> void:
	LevelState.custom_audio_path = path
	_set_status("%s: %s" % [Localization.text("audio_selected"), path.get_file()])


func _auto_build_from_mp3() -> void:
	if LevelState.custom_audio_path.is_empty():
		_set_status(Localization.text("autobuild_needs_mp3"))
		return
	var file: FileAccess = FileAccess.open(LevelState.custom_audio_path, FileAccess.READ)
	if file == null:
		_set_status(Localization.text("autobuild_read_failed"))
		return
	var length: int = int(file.get_length())
	var events: Array[Dictionary] = []
	var difficulty_index: int = maxi(LevelState.DIFFICULTIES.find(LevelState.custom_difficulty), 0)
	var density_stride: int = maxi(4 - difficulty_index, 1)
	for step: int in range(CHART_STEP_COUNT):
		var offset: int = int(float(step) / float(CHART_STEP_COUNT) * float(maxi(length - 1, 0)))
		file.seek(offset)
		var energy: int = int(file.get_8())
		var threshold: int = 145 - difficulty_index * 18
		if step % density_stride == 0 or energy >= threshold:
			events.append({"step": step, "long": energy >= 220 and step % 3 == 0})
	file.close()
	if events.is_empty():
		events.append({"step": 0, "long": false})
	LevelState.set_chart_events(events)
	_set_status(Localization.text("autobuild_complete") % events.size())
	_refresh_editor_from_state()


func _export_level_package() -> void:
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PACKAGE_DIRECTORY))
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		_set_status(Localization.text("package_export_failed"))
		return
	var package_name: String = _safe_file_name(LevelState.custom_level_name)
	var package_path: String = PACKAGE_DIRECTORY.path_join(package_name + ".zip")
	var package: ZIPPacker = ZIPPacker.new()
	if package.open(package_path) != OK:
		_set_status(Localization.text("package_export_failed"))
		return
	for difficulty: String in LevelState.DIFFICULTIES:
		var json_text: String = JSON.stringify(LevelState.make_nbeat_payload(difficulty), "\t")
		if package.start_file(difficulty.to_lower() + ".nbeat") == OK:
			package.write_file(json_text.to_utf8())
			package.close_file()
	if not LevelState.custom_audio_path.is_empty():
		var audio_bytes: PackedByteArray = FileAccess.get_file_as_bytes(LevelState.custom_audio_path)
		if not audio_bytes.is_empty() and package.start_file(LevelState.custom_audio_path.get_file()) == OK:
			package.write_file(audio_bytes)
			package.close_file()
	package.close()
	_set_status("%s: %s" % [Localization.text("package_exported"), ProjectSettings.globalize_path(package_path)])


func _open_import_picker() -> void:
	if _import_dialog != null:
		_import_dialog.popup_centered_ratio(0.8)


func _on_package_selected(path: String) -> void:
	var archive: ZIPReader = ZIPReader.new()
	if archive.open(path) != OK:
		_set_status(Localization.text("package_import_failed"))
		return
	var files: PackedStringArray = archive.get_files()
	var loaded_count: int = 0
	for entry: String in files:
		if entry.to_lower().ends_with(".nbeat"):
			var parsed: Variant = JSON.parse_string(archive.read_file(entry).get_string_from_utf8())
			if parsed is Dictionary and LevelState.load_nbeat_payload(parsed):
				loaded_count += 1
		elif entry.to_lower().ends_with(".mp3"):
			var import_directory: String = PACKAGE_DIRECTORY.path_join("imported").path_join(_safe_file_name(path.get_file().get_basename()))
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(import_directory))
			var extracted_path: String = import_directory.path_join(entry.get_file())
			var extracted_audio: FileAccess = FileAccess.open(extracted_path, FileAccess.WRITE)
			if extracted_audio != null:
				extracted_audio.store_buffer(archive.read_file(entry))
				extracted_audio.close()
				LevelState.custom_audio_path = extracted_path
	archive.close()
	if loaded_count > 0:
		LevelState.custom_difficulty = "Normal" if not LevelState.get_chart_events("Normal").is_empty() else "Easy"
		_refresh_editor_from_state()
		_set_status(Localization.text("package_imported") % loaded_count)
	else:
		_set_status(Localization.text("package_import_failed"))


func _export_chart() -> void:
	var difficulty: String = LevelState.custom_difficulty
	var payload: Dictionary = LevelState.make_nbeat_payload(difficulty)
	var file_name: String = "%s_%s.nbeat" % [LevelState.custom_level_name.strip_edges().replace(" ", "_"), difficulty.to_lower()]
	var save_dir: String = ProjectSettings.globalize_path("user://nebula_exports")
	var dir_err: Error = DirAccess.make_dir_recursive_absolute(save_dir)
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		_set_status(Localization.text("package_export_failed"))
		return
	var file_path: String = save_dir.path_join(file_name)
	var f := FileAccess.open(file_path, FileAccess.WRITE)
	if f == null:
		_set_status(Localization.text("package_export_failed"))
		return
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	_set_status("%s: %s" % [Localization.text("chart_exported"), file_path])
	if _catalog_upload_request != null:
		_upload_chart_to_catalog()


func _import_chart() -> void:
	if _chart_file_dialog != null:
		_chart_file_dialog.current_dir = ProjectSettings.globalize_path("user://nebula_exports")
		_chart_file_dialog.popup_centered_ratio(0.8)


func _on_chart_file_selected(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_set_status(Localization.text("package_import_failed"))
		return
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary and LevelState.load_nbeat_payload(parsed):
		_refresh_editor_from_state()
		_set_status(Localization.text("chart_imported"))
	else:
		_set_status(Localization.text("package_import_failed"))


# ── Online chart sharing ──────────────────────────────────────────────────

func _upload_chart_to_catalog() -> void:
	if _catalog_upload_request == null:
		_set_status("Catalog server not configured")
		return
	var payload: Dictionary = LevelState.make_nbeat_payload(LevelState.custom_difficulty)
	payload["level_name"] = LevelState.custom_level_name
	var json_bytes: PackedByteArray = JSON.stringify(payload, "\t").to_utf8()

	# Build multipart/form-data body manually.
	var boundary: String = "----NebulaBeatBoundary" + str(Time.get_ticks_msec())
	var body: PackedByteArray = PackedByteArray()
	var headers: PackedStringArray = [
		"Content-Type: multipart/form-data; boundary=%s" % boundary,
	]

	body.append_array(("--%s\r\n" % boundary).to_utf8())
	body.append_array('Content-Disposition: form-data; name="chart"\r\n\r\n'.to_utf8())
	body.append_array(json_bytes)
	body.append_array(("\r\n--%s--\r\n" % boundary).to_utf8())

	var audio_path: String = LevelState.custom_audio_path
	if not audio_path.is_empty() and FileAccess.file_exists(audio_path):
		var audio_file := FileAccess.open(audio_path, FileAccess.READ)
		var audio_data: PackedByteArray = audio_file.get_buffer(audio_file.get_length())
		audio_file.close()
		body.append_array(("--%s\r\n" % boundary).to_utf8())
		body.append_array(('Content-Disposition: form-data; name="audio"; filename="%s"\r\n' % audio_path.get_file()).to_utf8())
		body.append_array("Content-Type: audio/mpeg\r\n\r\n".to_utf8())
		body.append_array(audio_data)
		body.append_array(("\r\n--%s--\r\n" % boundary).to_utf8())

	var result: Error = _catalog_upload_request.request(CATALOG_SERVER_URL + "/api/charts", headers, HTTPClient.METHOD_POST, body)
	if result != OK:
		_set_status(Localization.text("package_export_failed"))


func _download_chart_from_catalog(chart_id: String) -> void:
	if _catalog_download_request == null:
		_set_status("Catalog server not configured")
		return
	var result: Error = _catalog_download_request.request(CATALOG_SERVER_URL + "/api/charts/%s" % chart_id, [], HTTPClient.METHOD_GET)
	if result != OK:
		_set_status(Localization.text("package_import_failed"))


func _list_catalog_charts() -> void:
	if _catalog_list_request == null:
		_set_status("Catalog server not configured")
		return
	var result: Error = _catalog_list_request.request(CATALOG_SERVER_URL + "/api/charts", [], HTTPClient.METHOD_GET)
	if result != OK:
		_set_status(Localization.text("package_import_failed"))


func _on_catalog_upload_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK:
		_set_status(Localization.text("package_export_failed"))
		return
	var response: String = body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(response)
	if parsed is Dictionary and parsed.has("id"):
		_set_status("%s: %s" % [Localization.text("chart_uploaded"), String(parsed.get("id"))])
	else:
		_set_status(Localization.text("package_export_failed"))


func _on_catalog_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		_set_status(Localization.text("package_import_failed"))
		return
	var text: String = body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary and LevelState.load_nbeat_payload(parsed):
		_refresh_editor_from_state()
		_set_status(Localization.text("chart_imported"))
	else:
		_set_status(Localization.text("package_import_failed"))


func _on_catalog_list_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		_set_status(Localization.text("package_import_failed"))
		return
	var text: String = body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Array:
		_set_status("%s: %d charts available" % [Localization.text("catalog_charts"), parsed.size()])
		# Store for UI display
		_catalog_charts = parsed
	else:
		_set_status(Localization.text("package_import_failed"))


var _catalog_charts: Array[Dictionary] = []


func _playtest_chart() -> void:
	LevelState.select_custom()
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(GAMEPLAY_PATH)


func _reset_chart() -> void:
	LevelState.reset_custom_chart()
	_refresh_editor_from_state()
	_set_status(Localization.text("chart_reset"))


func _beat_button(index: int) -> CheckButton:
	return get_node_or_null("CenterContainer/VBox/BeatGrid/Beat%02d" % (index + 1)) as CheckButton


func _safe_file_name(source: String) -> String:
	var safe: String = source.strip_edges()
	for character: String in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		safe = safe.replace(character, "_")
	return safe if not safe.is_empty() else "Untitled_Nebula_Chart"


func _audio_status() -> String:
	return LevelState.custom_audio_path.get_file() if not LevelState.custom_audio_path.is_empty() else Localization.text("no_mp3_selected")


func _set_status(message: String) -> void:
	if _status_label != null:
		_status_label.text = message


func _set_label_text(path: String, key: String) -> void:
	var label: Label = get_node_or_null(path)
	if label != null:
		label.text = Localization.text(key)


func _set_button_text(path: String, key: String) -> void:
	var button: Button = get_node_or_null(path)
	if button != null:
		button.text = Localization.text(key)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_return_to_levels()
		get_viewport().set_input_as_handled()


func _return_to_levels() -> void:
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(LEVELS_MENU_PATH)
