class_name PlayerController
extends CharacterBody2D
## Top-down movement, mouse aiming and a dash. Aiming is deliberately
## independent of movement direction — that separation is what makes the dash
## a defensive move rather than just a faster walk.

@export var move_speed: float = 180.0

@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.6

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon: Node2D = $WeaponPivot

var _last_good_pos := Vector2.ZERO

var _is_dashing := false
var _dash_timer := 0.0
var _dash_cd_timer := 0.0
var _dash_dir := Vector2.RIGHT

## True while the dash is active. Chapter 2's damage system reads this;
## invulnerability is a controller concept, not a damage concept. The dash
## drives it and the damage system reads it — never the other way round.
var invulnerable := false


func _ready() -> void:
	_last_good_pos = global_position


func _physics_process(delta: float) -> void:
	_update_aim()
	_update_dash(delta)

	# While dashing, normal movement doesn't run at all — the dash *replaces*
	# your input rather than being added to it. That's what makes it a state
	# and not a speed modifier.
	if _is_dashing:
		velocity = _dash_dir * dash_speed
	else:
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


func _update_dash(delta: float) -> void:
	if _dash_cd_timer > 0.0:
		_dash_cd_timer -= delta

	# The early return matters: while you're dashing nothing else in here runs,
	# so you can't start a dash while you're already dashing.
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_end_dash()
		return

	if Input.is_action_just_pressed("dash") and _dash_cd_timer <= 0.0:
		_start_dash()


func _start_dash() -> void:
	# Dash the way you're moving; if you're standing still, dash toward the mouse.
	# Without the fallback, dashing from a standstill silently does nothing — and
	# the player concludes the button is broken, not that they had no direction.
	var input := _get_move_input()
	if input.length() > 0.1:
		_dash_dir = input.normalized()
	else:
		var to_mouse := get_global_mouse_position() - global_position
		_dash_dir = to_mouse.normalized() if to_mouse.length() > 0.01 else Vector2.RIGHT
	if _dash_dir == Vector2.ZERO:
		_dash_dir = Vector2.RIGHT

	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cd_timer = dash_cooldown
	invulnerable = true
	# The tell. An invisible rule is an unfair rule — if the player can't see
	# when they were safe, they can't learn to be safe on purpose.
	sprite.modulate = Color(0.7, 0.9, 1.0)


func _end_dash() -> void:
	_is_dashing = false
	invulnerable = false
	sprite.modulate = Color.WHITE


## 1.0 = ready, 0.0 = just used. A float, not a Timer — the HUD needs a
## fraction, and that's one division off a float and awkward off a Timer.
func get_dash_ratio() -> float:
	if dash_cooldown <= 0.0:
		return 1.0
	return clampf(1.0 - _dash_cd_timer / dash_cooldown, 0.0, 1.0)


func _finite(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)
