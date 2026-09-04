class_name PlayerCamera
extends Camera2D
## Follows the player smoothly, biases the view toward the aim, and shakes on
## trauma.
##
## Every ease in here uses `1.0 - exp(-rate * delta)` rather than a raw
## `rate * delta` factor, so the motion is identical at 30, 60 and 144 fps.
## Multiplying by delta *looks* framerate independent and isn't — you're
## applying a percentage repeatedly, and the number of times you apply it
## changes with the framerate.

@export var target_path: NodePath
@export var follow_lerp: float = 12.0

## How far the view biases toward the mouse (0 = none). Keeps your aim on screen.
@export var aim_lead: float = 0.16
@export var aim_lead_max: float = 56.0
## How fast the aim bias itself eases. The raw mouse position is noisy and moves
## in instant jumps; feeding it straight into the follow target makes the camera
## twitch on every flick, which reads as "not smooth" even though the follow
## itself is perfectly damped. The noise is in the target, not in the follow.
@export var aim_lead_lerp: float = 6.0

@export var max_offset: float = 14.0
@export var max_roll_degrees: float = 4.0
@export var trauma_decay: float = 1.4

var _target: Node2D
var _lead := Vector2.ZERO
var _trauma: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	make_current()
	if target_path:
		_target = get_node_or_null(target_path)
	# Start framed on the target instead of easing in from wherever the camera
	# was left sitting in the scene file. Without this, every single run opens
	# with a swoop you didn't ask for.
	if _target and is_instance_valid(_target):
		global_position = _target.global_position


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if _target and is_instance_valid(_target):
		# Two damped things, one after the other: smooth the point you're
		# aiming at, then smooth the way you get there.
		var want_lead := Vector2.ZERO
		if aim_lead > 0.0:
			want_lead = (
				(get_global_mouse_position() - _target.global_position) * aim_lead
			).limit_length(aim_lead_max)
		_lead = _lead.lerp(want_lead, 1.0 - exp(-aim_lead_lerp * delta))

		var goal := _target.global_position + _lead
		global_position = global_position.lerp(goal, 1.0 - exp(-follow_lerp * delta))

	_time += delta
	_trauma = maxf(_trauma - trauma_decay * delta, 0.0)
	# Squared is the whole trick. Trauma 0.2 squared is 0.04 — barely a wobble.
	# Trauma 1.0 squared is still 1.0 — a full kick. Small hits almost vanish
	# and big hits keep everything, which is what makes a heavy attack feel
	# heavier than a light one. Without it you get one shake at two volumes.
	var shake := _trauma * _trauma
	if shake > 0.0:
		offset = Vector2(
			max_offset * shake * _noise(_time * 30.0, 1.0),
			max_offset * shake * _noise(_time * 30.0, 13.0)
		)
		rotation_degrees = max_roll_degrees * shake * _noise(_time * 30.0, 27.0)
	else:
		offset = Vector2.ZERO
		rotation_degrees = 0.0


# Cheap pseudo-noise in -1..1 from sine waves. No resources needed.
func _noise(t: float, seed_offset: float) -> float:
	return sin(t + seed_offset) * cos(t * 0.7 + seed_offset * 2.0)
