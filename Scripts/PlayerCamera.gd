extends Camera2D

@export var target_path: NodePath
@export var follow_lerp: float = 12.0

var _target: Node2D

## How far the view biases toward the mouse. Keeps your aim on screen.
@export var aim_lead: float = 0.16
@export var aim_lead_max: float = 56.0
## The raw mouse moves in instant jumps; damping the lead separately is what
## stops the camera twitching on every flick.
@export var aim_lead_lerp: float = 6.0

var _lead := Vector2.ZERO

@export var max_offset: float = 14.0
@export var max_roll_degrees: float = 4.0
@export var trauma_decay: float = 1.4

var _trauma: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	make_current()
	if target_path:
		_target = get_node_or_null(target_path)
	
	if _target and is_instance_valid(_target):
		global_position = _target.global_position
	GameManager.register_camera(self)
func _process(delta: float) -> void:
	
	_time += delta
	_trauma = maxf(_trauma - trauma_decay * delta, 0.0)
	var shake := _trauma * _trauma          # squared — this is the trick
	if shake > 0.0:
		offset = Vector2(
			max_offset * shake * _noise(_time * 30.0, 1.0),
			max_offset * shake * _noise(_time * 30.0, 13.0)
		)
		rotation_degrees = max_roll_degrees * shake * _noise(_time * 30.0, 27.0)
	else:
		offset = Vector2.ZERO
		rotation_degrees = 0.0
		
		
	if _target and is_instance_valid(_target):
		var want_lead := Vector2.ZERO
		if aim_lead > 0.0:
			want_lead = (
				(get_global_mouse_position() - _target.global_position) * aim_lead
			).limit_length(aim_lead_max)
		_lead = _lead.lerp(want_lead, 1.0 - exp(-aim_lead_lerp * delta))

		var goal := _target.global_position + _lead
		global_position = global_position.lerp(goal, 1.0 - exp(-follow_lerp * delta))

func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)
func _noise(t: float, seed_offset: float) -> float:
	return sin(t + seed_offset) * cos(t * 0.7 + seed_offset * 2.0)
