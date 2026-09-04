class_name PlayerController
extends CharacterBody2D
## Top-down movement and mouse aiming. Aiming is deliberately independent of
## movement direction — that separation is what makes the dash defensive later.

@export var move_speed: float = 180.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon: Node2D = $WeaponPivot

var _last_good_pos := Vector2.ZERO


func _ready() -> void:
	_last_good_pos = global_position


func _physics_process(_delta: float) -> void:
	_update_aim()

	velocity = _get_move_input() * move_speed

	# Guard against a non-finite velocity: move_and_slide() would spam
	# "Vector2 cannot be normalized" forever with no stack trace.
	if not _finite(velocity):
		velocity = Vector2.ZERO
	move_and_slide()

	if _finite(global_position):
		_last_good_pos = global_position
	else:
		global_position = _last_good_pos
		velocity = Vector2.ZERO


## Input as a vector. Only normalize when it's longer than 1, so a half-pushed
## analog stick stays at half speed instead of being stretched to full.
func _get_move_input() -> Vector2:
	var v := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	return v.normalized() if v.length() > 1.0 else v


## Point the weapon pivot at the cursor and flip the body to roughly face it.
func _update_aim() -> void:
	var to_mouse := get_global_mouse_position() - global_position
	weapon.rotation = to_mouse.angle()
	# 4px deadzone, or he strobes when the mouse sits on his centre.
	if absf(to_mouse.x) > 4.0:
		sprite.flip_h = to_mouse.x < 0.0


func _finite(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)
