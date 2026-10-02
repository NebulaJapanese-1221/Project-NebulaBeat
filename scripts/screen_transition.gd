extends CanvasLayer

# Full-screen scene-transition overlay, registered as an autoload so it SURVIVES
# scene changes (a per-scene node would be freed by change_scene_to_file mid-
# transition, killing the fade-in). Reach it globally by its autoload name:
#     ScreenTransition.transition_to("res://scenes/level_2.tscn")
#     await ScreenTransition.fade_out()
#     ScreenTransition.flash(Color.RED)

signal transition_finished

@export var fade_color: Color = Color(0.0196, 0.0314, 0.0863, 1.0000)
@export var default_duration: float = 0.350

var _rect: ColorRect
var _busy: bool = false


func _ready() -> void:
	# Run even while the tree is paused (so a pause menu can transition out), and
	# draw above HUDs and menus.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128
	_rect = ColorRect.new()
	_rect.color = fade_color
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	_rect.visible = false
	add_child(_rect)


# Fade to opaque, swap to scene_path, then fade back in. Awaitable.
func transition_to(scene_path: String, duration: float = -1.0) -> void:
	if _busy:
		return
	_busy = true
	await fade_out(duration)
	# A pause menu may have paused the tree; clear it so the new scene runs.
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	# Let the deferred scene swap take effect before uncovering it.
	await get_tree().process_frame
	await fade_in(duration)
	_busy = false
	transition_finished.emit()


# Cover the screen with fade_color. Awaitable: `await ScreenTransition.fade_out()`.
func fade_out(duration: float = -1.0) -> void:
	var d := default_duration if duration < 0.0 else duration
	_rect.color = fade_color
	_rect.visible = true
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 1.0, d)
	await tw.finished


# Uncover the screen. Awaitable.
func fade_in(duration: float = -1.0) -> void:
	var d := default_duration if duration < 0.0 else duration
	_rect.visible = true
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 0.0, d)
	await tw.finished
	_rect.visible = false


# Quick screen flash for a hit or pickup. Awaitable but short; restores the base
# fade color afterward so it never interferes with a fade.
func flash(color: Color = Color(1, 1, 1, 1), duration: float = 0.18) -> void:
	var prev := _rect.color
	_rect.color = color
	_rect.visible = true
	_rect.modulate.a = 0.55
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 0.0, duration)
	await tw.finished
	_rect.color = prev
	_rect.visible = false
