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

const SETTINGS_MENU_PATH: String = "res://scenes/settings_menu.tscn"

# Input actions that can be rebound, with their display names
const REBINDABLE_ACTIONS: Array[Dictionary] = [
	{"action": "ui_up", "name": "ui_up", "default_events": [InputEventKey.new().with_key(KEY_UP), InputEventKey.new().with_key(KEY_W)]},
	{"action": "ui_down", "name": "ui_down", "default_events": [InputEventKey.new().with_key(KEY_DOWN), InputEventKey.new().with_key(KEY_S)]},
	{"action": "ui_left", "name": "ui_left", "default_events": [InputEventKey.new().with_key(KEY_LEFT), InputEventKey.new().with_key(KEY_A)]},
	{"action": "ui_right", "name": "ui_right", "default_events": [InputEventKey.new().with_key(KEY_RIGHT), InputEventKey.new().with_key(KEY_D)]},
	{"action": "ui_accept", "name": "ui_accept", "default_events": [InputEventKey.new().with_key(KEY_ENTER), InputEventKey.new().with_key(KEY_KP_ENTER), InputEventKey.new().with_key(KEY_SPACE)]},
	{"action": "ui_cancel", "name": "ui_cancel", "default_events": [InputEventKey.new().with_key(KEY_ESCAPE), InputEventKey.new().with_key(KEY_BACKSPACE)]},
	{"action": "ui_focus_next", "name": "ui_focus_next", "default_events": [InputEventKey.new().with_key(KEY_TAB)]},
	{"action": "ui_focus_prev", "name": "ui_focus_prev", "default_events": [InputEventKey.new().with_key(KEY_TAB).with_shift(true)]},
	{"action": "ui_page_up", "name": "ui_page_up", "default_events": [InputEventKey.new().with_key(KEY_PAGE_UP)]},
	{"action": "ui_page_down", "name": "ui_page_down", "default_events": [InputEventKey.new().with_key(KEY_PAGE_DOWN)]},
	{"action": "ui_home", "name": "ui_home", "default_events": [InputEventKey.new().with_key(KEY_HOME)]},
	{"action": "ui_end", "name": "ui_end", "default_events": [InputEventKey.new().with_key(KEY_END)]},
	{"action": "ui_select", "name": "ui_select", "default_events": [InputEventKey.new().with_key(KEY_SPACE)]},
]

var _rebind_rows: Array[Dictionary] = []
var _waiting_for_input: bool = false
var _current_rebind_action: String = ""
var _current_rebind_index: int = -1
var _listen_timer: float = 0.0

@onready var _container: VBoxContainer = get_node_or_null("CenterContainer/VBox/ScrollContainer/RebindContainer")
@onready var _back_button: Button = get_node_or_null("CenterContainer/VBox/BackButton")
@onready var _reset_button: Button = get_node_or_null("CenterContainer/VBox/ResetButton")
@onready var _title: Label = get_node_or_null("CenterContainer/VBox/Title")
@onready var _subtitle: Label = get_node_or_null("CenterContainer/VBox/Subtitle")
@onready var _hint_label: Label = get_node_or_null("CenterContainer/VBox/HintLabel")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_localized_text()
	_build_rebind_ui()
	if _back_button != null:
		_back_button.text = Localization.text("back")
		_back_button.pressed.connect(_return_to_settings)
		_back_button.grab_focus()
	if _reset_button != null:
		_reset_button.text = Localization.text("rebind_reset_all")
		_reset_button.pressed.connect(_reset_to_defaults)


func _apply_localized_text() -> void:
	if _title != null:
		_title.text = Localization.text("input_rebinding")
	if _subtitle != null:
		_subtitle.text = Localization.text("input_rebinding_subtitle")
	if _hint_label != null:
		_hint_label.text = Localization.text("input_rebinding_hint")


func refresh_localization() -> void:
	_apply_localized_text()
	_rebuild_rebind_ui()


func _build_rebind_ui() -> void:
	if _container == null:
		return
	_rebind_rows.clear()
	for child in _container.get_children():
		child.queue_free()
	
	for i: int in REBINDABLE_ACTIONS.size():
		var action_info: Dictionary = REBINDABLE_ACTIONS[i]
		var action_name: String = action_info["action"]
		var display_name: String = action_info["name"]
		
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		
		var label: Label = Label.new()
		label.text = Localization.text(display_name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.custom_minimum_size = Vector2(180, 44)
		label.add_theme_font_size_override("font_size", 18)
		hbox.add_child(label)
		
		var key_display: Label = Label.new()
		key_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_display.custom_minimum_size = Vector2(200, 44)
		key_display.add_theme_font_size_override("font_size", 16)
		key_display.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
		key_display.mouse_filter = Control.MOUSE_FILTER_STOP
		hbox.add_child(key_display)
		
		var rebind_btn: Button = Button.new()
		rebind_btn.text = Localization.text("rebind")
		rebind_btn.custom_minimum_size = Vector2(120, 44)
		rebind_btn.pressed.connect(Callable(self, "_start_rebind").bind(i))
		hbox.add_child(rebind_btn)
		
		var reset_btn: Button = Button.new()
		reset_btn.text = Localization.text("rebind_reset")
		reset_btn.custom_minimum_size = Vector2(80, 44)
		reset_btn.pressed.connect(Callable(self, "_reset_action").bind(i))
		hbox.add_child(reset_btn)
		
		_container.add_child(hbox)
		
		_rebind_rows.append({
			"action": action_name,
			"display_name": display_name,
			"hbox": hbox,
			"key_display": key_display,
			"rebind_btn": rebind_btn,
			"reset_btn": reset_btn,
			"default_events": action_info["default_events"]
		})
	
	_update_key_displays()


func _rebuild_rebind_ui() -> void:
	_build_rebind_ui()


func _update_key_displays() -> void:
	for row in _rebind_rows:
		var action: String = row["action"]
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		var display_text: String = ""
		if events.is_empty():
			display_text = Localization.text("unbound")
		else:
			var parts: Array[String] = []
			for event in events:
				if event is InputEventKey:
					parts.append(_key_to_string(event))
				elif event is InputEventMouseButton:
					parts.append("Mouse %d" % event.button_index)
				elif event is InputEventJoypadButton:
					parts.append("Joy %d" % event.button_index)
				elif event is InputEventJoypadMotion:
					parts.append("Joy Axis %d" % event.axis)
				elif event is InputEventScreenTouch:
					parts.append("Touch")
				elif event is InputEventScreenDrag:
					parts.append("Drag")
			display_text = ", ".join(parts)
		row["key_display"].text = display_text
		row["key_display"].add_theme_color_override("font_color", Color(0.8, 0.9, 1.0) if not events.is_empty() else Color(0.6, 0.6, 0.6))


func _key_to_string(event: InputEventKey) -> String:
	if event.keycode == KEY_NONE:
		return ""
	var mods: Array[String] = []
	if event.ctrl_pressed:
		mods.append("Ctrl")
	if event.alt_pressed:
		mods.append("Alt")
	if event.shift_pressed:
		mods.append("Shift")
	if event.meta_pressed:
		mods.append("Meta")
	var key_name: String = OS.get_scancode_string(event.physical_keycode)
	if key_name.is_empty():
		key_name = OS.get_scancode_string(event.keycode)
	if key_name.is_empty():
		key_name = "Key%d" % event.keycode
	return "%s%s" % [", ".join(mods) + ("+" if not mods.is_empty() else ""), key_name]


func _start_rebind(index: int) -> void:
	if index < 0 or index >= _rebind_rows.size():
		return
	_waiting_for_input = true
	_current_rebind_index = index
	_current_rebind_action = _rebind_rows[index]["action"]
	
	var row: Dictionary = _rebind_rows[index]
	row["key_display"].text = Localization.text("press_key")
	row["key_display"].add_theme_color_override("font_color", Color(1.0, 0.82, 0.30))
	row["rebind_btn"].disabled = true
	row["rebind_btn"].text = Localization.text("listening")
	
	_listen_timer = 0.5


func _reset_action(index: int) -> void:
	if index < 0 or index >= _rebind_rows.size():
		return
	var action: String = _rebind_rows[index]["action"]
	var default_events: Array = _rebind_rows[index]["default_events"]
	
	InputMap.action_erase_events(action)
	for event in default_events:
		InputMap.action_add_event(action, event)
	
	_update_key_displays()
	ProjectSettings.save()


func _reset_to_defaults() -> void:
	for row in _rebind_rows:
		var action: String = row["action"]
		var default_events: Array = row["default_events"]
		InputMap.action_erase_events(action)
		for event in default_events:
			InputMap.action_add_event(action, event)
	ProjectSettings.save()
	_update_key_displays()


func _process(delta: float) -> void:
	if _waiting_for_input:
		_listen_timer -= delta
		if _listen_timer <= 0.0:
			# Check for any input
			var events: Array[InputEvent] = Input.get_joypad_events()
		if _listen_timer < 0.0:
			# After initial delay, accept any input
			pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _waiting_for_input:
			_cancel_rebind()
		else:
			_return_to_settings()
		get_viewport().set_input_as_handled()
		return
	
	if _waiting_for_input and _listen_timer <= 0.0:
		# Ignore modifier-only events
		if event is InputEventKey and event.keycode in [KEY_SHIFT, KEY_CONTROL, KEY_ALT, KEY_META, KEY_CAPSLOCK]:
			return
		if event is InputEventMouseMotion:
			return
		if event is InputEventScreenDrag:
			return
		
		_apply_rebind(event)


func _apply_rebind(event: InputEvent) -> void:
	if _current_rebind_action.is_empty():
		_waiting_for_input = false
		return
	
	# Erase existing events for this action
	InputMap.action_erase_events(_current_rebind_action)
	
	# Add the new event
	InputMap.action_add_event(_current_rebind_action, event)
	ProjectSettings.save()
	
	_waiting_for_input = false
	_current_rebind_action = ""
	_current_rebind_index = -1
	
	_update_key_displays()


func _cancel_rebind() -> void:
	_waiting_for_input = false
	_current_rebind_action = ""
	if _current_rebind_index >= 0 and _current_rebind_index < _rebind_rows.size():
		var row: Dictionary = _rebind_rows[_current_rebind_index]
		row["rebind_btn"].disabled = false
		row["rebind_btn"].text = Localization.text("rebind")
	_current_rebind_index = -1
	_update_key_displays()


func _return_to_settings() -> void:
	ScreenTransition.transition_to(SETTINGS_MENU_PATH)