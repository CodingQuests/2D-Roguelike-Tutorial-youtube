extends CanvasLayer


var _rect: ColorRect          # the rect we fade
var _fade_tween: Tween        # the tween that owns it
var _busy := false            # so two scene changes can't overlap



func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The ColorRect is built in code: near-black, anchored to fill the screen.
	_rect = ColorRect.new()
	_rect.color = Color(0.03, 0.02, 0.04, 1.0)
	_rect.anchor_right = 1.0
	_rect.anchor_bottom = 1.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_fade(0.0, 0.5) 


func _fade(target_a: float, dur: float) -> Tween:
	if is_instance_valid(_fade_tween): _fade_tween.kill()
	var tw := create_tween()
	_fade_tween = tw
	tw.set_ignore_time_scale(true)
	tw.tween_property(_rect, "color:a", target_a, dur).set_trans(Tween.TRANS_SINE)
	# Hand the tween back, so callers await its finished signal instead of
	# guessing a duration.
	return tw

func is_busy() -> bool:
	return _busy

func change_scene(path: String, dur: float = 0.35) -> bool:
	# Freeze the outgoing world during the fade; UI checks is_busy().
	if _busy:
		return false
	_busy = true
	var was_paused := get_tree().paused
	get_tree().paused = true
	await _fade(1.0, dur).finished
	Engine.time_scale = 1.0
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(path)
	# A failed load: log it, fade back up, release _busy. A bad path must not
	# leave you on a black screen forever.
	if error != OK:
		push_error("Scene change failed: %s" % path)
		get_tree().paused = was_paused
		await _fade(0.0, dur).finished
		_busy = false
		return false
	await get_tree().scene_changed
	await _fade(0.0, dur).finished
	_busy = false
	return true

func reload_scene(dur: float = 0.35) -> bool:
	# The current scene's own path, sent through change_scene. Same fade,
	# same cleanup, no second code path.
	var scene := get_tree().current_scene
	if scene and scene.scene_file_path != "":
		return await change_scene(scene.scene_file_path, dur)
	return false
	

func fade_out_then(cb: Callable, dur: float = 0.35) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = true
	await _fade(1.0, dur).finished
	# Never clears _busy: nothing comes back from a quit.
	cb.call()
