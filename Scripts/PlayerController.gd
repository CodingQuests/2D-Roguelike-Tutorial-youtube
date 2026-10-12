extends CharacterBody2D


@export var move_speed: float = 180.0
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var sprite_2d: Sprite2D = $WeaponPivot/Sprite2D

var _last_good_pos := Vector2.ZERO
func _ready() -> void:
	_last_good_pos = global_position
	
func _physics_process(delta: float) -> void:
	_update_aim()
	velocity = _get_move_input() * move_speed
	if not _finite(velocity):
		velocity = Vector2.ZERO
		
	move_and_slide()
	if _finite(global_position):
		_last_good_pos = global_position
	else:
		global_position = _last_good_pos
		velocity = Vector2.ZERO

func _get_move_input() -> Vector2:
	var v:= Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	return v.normalized() if v.length() > 1.0 else v

func _update_aim() -> void:
	var to_mouse := get_global_mouse_position() - global_position
	weapon_pivot.rotation = to_mouse.angle()
	if absf(to_mouse.x) > 4.0:
		sprite_2d.flip_h = to_mouse.x < 0.0
	
func _finite(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)
	
