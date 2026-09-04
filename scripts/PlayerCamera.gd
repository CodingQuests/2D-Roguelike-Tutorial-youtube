class_name PlayerCamera
extends Camera2D
## Follows a target (the player) smoothly and supports trauma-based screen
## shake. Shake uses trauma^2 so small hits barely wobble while heavy hits
## kick hard, and it decays automatically every frame. On top of the random
## shake it layers a directional "kick" (a punch along the swing direction),
## a zoom-punch, and a small lead toward the aim so you see where you strike.

@export var target_path: NodePath
@export var follow_lerp: float = 12.0
@export var max_offset: float = 14.0
@export var max_roll_degrees: float = 4.0
@export var trauma_decay: float = 1.4

## How far the view biases toward the mouse (0 = none). Keeps the aim on screen.
@export var aim_lead: float = 0.16
@export var aim_lead_max: float = 56.0
## How fast the aim bias itself eases. The raw mouse position is noisy and moves
## in instant jumps; feeding it straight into the follow target makes the camera
## twitch on every flick, which reads as "not smooth" even though the follow
## itself is damped. Damping the lead separately fixes that.
@export var aim_lead_lerp: float = 6.0
@export var kick_decay: float = 12.0
@export var zoom_punch_decay: float = 6.0
@export var roll_return_lerp: float = 14.0

var _target: Node2D
var _trauma: float = 0.0
var _time: float = 0.0
var _kick := Vector2.ZERO
var _zoom_punch: float = 0.0
var _base_zoom := Vector2.ONE
var _lead := Vector2.ZERO


func _ready() -> void:
	make_current()
	if target_path:
		_target = get_node_or_null(target_path)
	_base_zoom = zoom
	# Start framed on the target instead of easing in from wherever the camera
	# was left in the scene file.
	if _target and is_instance_valid(_target):
		global_position = _target.global_position
	GameManager.register_camera(self)


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


## A one-shot directional shove of the view along `dir`.
func add_kick(dir: Vector2, amount: float) -> void:
	if dir.length() > 0.001:
		_kick += dir.normalized() * amount


## Pop the zoom in by `amount` (e.g. 0.06 = +6%), then ease back to base.
func add_zoom_punch(amount: float) -> void:
	_zoom_punch = maxf(_zoom_punch, amount)


func _process(delta: float) -> void:
	# Every easing below uses `1 - exp(-rate * delta)` rather than a raw
	# per-frame factor, so the motion is identical at 60 and 144 fps.
	if _target and is_instance_valid(_target):
		# Ease the aim bias first, then follow the biased point.
		var want_lead := Vector2.ZERO
		if aim_lead > 0.0:
			want_lead = ((get_global_mouse_position() - _target.global_position) * aim_lead
				).limit_length(aim_lead_max)
		_lead = _lead.lerp(want_lead, 1.0 - exp(-aim_lead_lerp * delta))
		var goal := _target.global_position + _lead
		global_position = global_position.lerp(goal, 1.0 - exp(-follow_lerp * delta))

	# Decay the directional kick and zoom punch.
	_kick = _kick.lerp(Vector2.ZERO, 1.0 - exp(-kick_decay * delta))
	if _kick.length() < 0.05:
		_kick = Vector2.ZERO
	_zoom_punch = _zoom_punch * exp(-zoom_punch_decay * delta)
	if _zoom_punch < 0.0005:
		_zoom_punch = 0.0
	zoom = _base_zoom * (1.0 + _zoom_punch)

	# Decay and apply shake, on top of the kick.
	_time += delta
	_trauma = maxf(_trauma - trauma_decay * delta, 0.0)
	var shake := _trauma * _trauma
	if shake > 0.0:
		var nx := _noise(_time * 30.0, 1.0)
		var ny := _noise(_time * 30.0, 13.0)
		var nr := _noise(_time * 30.0, 27.0)
		offset = _kick + Vector2(max_offset * shake * nx, max_offset * shake * ny)
		rotation_degrees = max_roll_degrees * shake * nr
	else:
		# No random shake: the offset is just the (decaying) directional kick.
		offset = _kick
		rotation_degrees = lerpf(rotation_degrees, 0.0, 1.0 - exp(-roll_return_lerp * delta))


# Cheap pseudo-noise in -1..1 from sine waves (no resources needed).
func _noise(t: float, seed_offset: float) -> float:
	return sin(t + seed_offset) * cos(t * 0.7 + seed_offset * 2.0)
