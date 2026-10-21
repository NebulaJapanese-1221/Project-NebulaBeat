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

const LEVELS_MENU_PATH: String = "res://scenes/levels_menu.tscn"
const CATALOG_SERVER_URL: String = "http://localhost:8765"

@onready var _title: Label = get_node_or_null("CenterContainer/VBox/Title")
@onready var _body: Label = get_node_or_null("CenterContainer/VBox/Body")
@onready var _refresh_button: Button = get_node_or_null("CenterContainer/VBox/RefreshButton")
@onready var _back_button: Button = get_node_or_null("CenterContainer/VBox/BackButton")
@onready var _catalog_list_request: HTTPRequest = get_node_or_null("CatalogListRequest")
@onready var _catalog_download_request: HTTPRequest = get_node_or_null("CatalogDownloadRequest")

var _catalog_charts: Array[Dictionary] = []
var _chart_buttons: Array[Button] = []


func _ready() -> void:
	Localization.apply_saved_locale()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_to_group("localizable_menu")
	_apply_layout()
	_apply_text()
	if _refresh_button != null:
		_refresh_button.pressed.connect(_refresh_catalog)
	if _back_button != null:
		_back_button.pressed.connect(_return_to_levels)
		_back_button.grab_focus()
	if _catalog_list_request != null and not _catalog_list_request.request_completed.is_connected(_on_catalog_list_completed):
		_catalog_list_request.request_completed.connect(_on_catalog_list_completed)
	if _catalog_download_request != null and not _catalog_download_request.request_completed.is_connected(_on_catalog_download_completed):
		_catalog_download_request.request_completed.connect(_on_catalog_download_completed)
	_refresh_catalog()


func _apply_layout() -> void:
	var content: VBoxContainer = get_node_or_null("CenterContainer/VBox")
	if content != null:
		var viewport_size: Vector2 = get_viewport_rect().size
		content.custom_minimum_size = Vector2(minf(maxf(viewport_size.x - 40.0, 280.0), 720.0), 0.0)
		content.custom_maximum_size = Vector2(720.0, -1.0)
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 16)
	if _title != null:
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title.add_theme_font_size_override("font_size", 30)
	if _body != null:
		_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_body.custom_minimum_size = Vector2(0.0, 108.0)
	for button: Button in [_refresh_button, _back_button]:
		if button != null:
			button.custom_minimum_size = Vector2(0.0, 52.0)


func _apply_text() -> void:
	if _title != null:
		_title.text = Localization.text("level_downloader")
	if _refresh_button != null:
		_refresh_button.text = Localization.text("refresh_catalog")
	if _back_button != null:
		_back_button.text = Localization.text("back")
	_update_body_text()


func _update_body_text() -> void:
	if _body == null:
		return
	if _catalog_charts.is_empty():
		_body.text = Localization.text("downloader_offline")
	else:
		var count: int = _catalog_charts.size()
		_body.text = "%d %s" % [count, Localization.text("catalog_charts")]


func refresh_localization() -> void:
	_apply_text()


func _refresh_catalog() -> void:
	if _catalog_list_request == null:
		_body.text = Localization.text("downloader_server_missing")
		return
	_body.text = Localization.text("downloader_refreshing")
	var result: Error = _catalog_list_request.request(CATALOG_SERVER_URL + "/api/charts", [], HTTPClient.METHOD_GET)
	if result != OK:
		_body.text = Localization.text("downloader_server_missing")


func _on_catalog_list_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		_body.text = Localization.text("downloader_server_missing")
		return
	var text: String = body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Array:
		_catalog_charts = parsed
		_update_body_text()
		_render_chart_list()
	else:
		_body.text = Localization.text("downloader_server_missing")


func _render_chart_list() -> void:
	_clear_chart_buttons()
	var content: VBoxContainer = get_node_or_null("CenterContainer/VBox")
	if content == null:
		return
	for chart: Dictionary in _catalog_charts:
		var btn: Button = Button.new()
		var title: String = String(chart.get("level_name", "Untitled"))
		var difficulty: String = String(chart.get("difficulty", "Normal"))
		var bpm: float = float(chart.get("bpm", 120))
		btn.text = "%s  [%s]  %.0f BPM" % [title, difficulty, bpm]
		btn.custom_minimum_size = Vector2(0.0, 44.0)
		btn.pressed.connect(_download_chart.bind(String(chart.get("id", ""))))
		content.add_child(btn)
		_chart_buttons.append(btn)


func _clear_chart_buttons() -> void:
	var content: VBoxContainer = get_node_or_null("CenterContainer/VBox")
	if content == null:
		return
	for btn: Button in _chart_buttons:
		content.remove_child(btn)
		btn.queue_free()
	_chart_buttons.clear()


func _download_chart(chart_id: String) -> void:
	if _catalog_download_request == null:
		_body.text = Localization.text("downloader_server_missing")
		return
	_body.text = Localization.text("downloader_downloading")
	var result: Error = _catalog_download_request.request(CATALOG_SERVER_URL + "/api/charts/%s" % chart_id, [], HTTPClient.METHOD_GET)
	if result != OK:
		_body.text = Localization.text("package_import_failed")


func _on_catalog_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		_body.text = Localization.text("package_import_failed")
		return
	var text: String = body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary and LevelState.load_nbeat_payload(parsed):
		_refresh_catalog()
		_body.text = Localization.text("chart_imported")
	else:
		_body.text = Localization.text("package_import_failed")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_return_to_levels()
		get_viewport().set_input_as_handled()


func _return_to_levels() -> void:
	get_tree().root.get_node_or_null("ScreenTransition").transition_to(LEVELS_MENU_PATH)
