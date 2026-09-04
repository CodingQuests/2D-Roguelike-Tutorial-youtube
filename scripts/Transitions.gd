extends CanvasLayer
## Autoload ("Transitions"). A full-screen fade-to-black used for every scene
## change so the game never hard-cuts. Sits above everything and keeps animating
## while the tree is paused or time-scaled (process_mode ALWAYS + ignore_time_scale
## tweens), so it works from the pause menu and the slow-mo death beat alike.

var _rect: ColorRect
var _busy := false


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.03, 0.02, 0.04, 1.0)
	_rect.anchor_right = 1.0
	_rect.anchor_bottom = 1.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	# Fade up from black on first launch.
	_fade(0.0, 0.5)


func _fade(target_a: float, dur: float) -> Tween:
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(_rect, "color:a", target_a, dur).set_trans(Tween.TRANS_SINE)
	return tw


## Fade to black, swap to `path`, fade back in. Clears pause/time-scale first.
func change_scene(path: String, dur: float = 0.35) -> void:
	if _busy:
		return
	_busy = true
	await _fade(1.0, dur).finished
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await _fade(0.0, dur).finished
	_busy = false


## Reload the current scene (fresh run / retry).
func reload_scene(dur: float = 0.35) -> void:
	var scene := get_tree().current_scene
	if scene and scene.scene_file_path != "":
		change_scene(scene.scene_file_path, dur)


## Fade to black, then run `cb` (e.g. quit the game) without fading back.
func fade_out_then(cb: Callable, dur: float = 0.35) -> void:
	if _busy:
		return
	_busy = true
	await _fade(1.0, dur).finished
	cb.call()
