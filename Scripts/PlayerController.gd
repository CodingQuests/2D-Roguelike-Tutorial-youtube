class_name PlayerController
extends CharacterBody2D

@onready var hurtbox: HurtboxComponent = $Hurtbox
@export var move_speed: float = 180.0
@onready var sprite_2d: Sprite2D = $WeaponPivot/WeaponSprite
@onready var player_sprite: Sprite2D = $Sprite2D
@onready var hitbox: HitboxComponent = $WeaponPivot/AttackHitbox
@onready var weapon: WeaponController = $WeaponPivot


var _last_good_pos := Vector2.ZERO

@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.14

var _is_dashing := false
var _dash_timer := 0.0
var _dash_dir := Vector2.RIGHT
@export var dash_cooldown: float = 0.6

var _dash_cd_timer := 0.0

var _base_sprite_scale := Vector2.ONE
var _bob_time := 0.0

const KNOCKBACK_DECAY := 1700.0
const KNOCKBACK_TAKEN := 0.6      # the player is shoved less than enemies are

var _knockback := Vector2.ZERO

func _ready() -> void:
	_last_good_pos = global_position
	_base_sprite_scale = player_sprite.scale
	
func _physics_process(delta: float) -> void:
	_handle_attack_input()
	_update_aim()
	_update_dash(delta)
	_update_body_juice(delta, _get_move_input().length() > 0.1)
	if _is_dashing:
		velocity = _dash_dir * dash_speed
	else:
		velocity = _get_move_input() * move_speed * weapon.get_move_factor() + _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		
		
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
	weapon.rotation = to_mouse.angle()
	if absf(to_mouse.x) > 4.0:
		sprite_2d.flip_h = to_mouse.x < 0.0
	
func _finite(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)
	


func _start_dash() -> void:
	var input := _get_move_input()
	if input.length() > 0.1:
		_dash_dir = input.normalized()
	else:
		var to_mouse := get_global_mouse_position() - global_position
		_dash_dir = to_mouse.normalized() if to_mouse.length() > 0.01 else Vector2.RIGHT
	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cd_timer = dash_cooldown
	hurtbox.invulnerable = true
	sprite_2d.modulate = Color(0.7, 0.9, 1.0)
	player_sprite.modulate = Color(0.7, 0.9, 1.0)
func _end_dash() -> void:
	_is_dashing = false
	hurtbox.invulnerable = false
	sprite_2d.modulate = Color.WHITE
	player_sprite.modulate = Color.WHITE
	
func _update_dash(delta: float) -> void:
	if _dash_cd_timer > 0.0:
		_dash_cd_timer -= delta
		
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_end_dash()
		return
	if Input.is_action_just_pressed("dash") and _dash_cd_timer <= 0.0:
		_start_dash()
	
	
## 1.0 = ready, 0.0 = just used.
func get_dash_ratio() -> float:
	if dash_cooldown <= 0.0:
		return 1.0
	return clampf(1.0 - _dash_cd_timer / dash_cooldown, 0.0, 1.0)
	
	
func _update_body_juice(delta: float, moving: bool) -> void:
	if _is_dashing:
		return
	var freq := 13.0 if moving else 3.0
	var amp := 1.6 if moving else 0.8
	_bob_time += delta * freq
	player_sprite.position.y = sin(_bob_time) * amp
	
func apply_knockback(dir: Vector2, force: float) -> void:
	_knockback = dir.normalized() * force * KNOCKBACK_TAKEN
	
func _handle_attack_input() -> void:
	if Input.is_action_just_pressed("swap_weapon"):
		weapon.swap()
	if Input.is_action_just_pressed("quick_attack"):
		weapon.try_quick_attack()
	elif Input.is_action_just_pressed("heavy_attack"):
		weapon.try_heavy_attack()
	
func lunge(dir: Vector2, force: float) -> void:
	if _is_dashing or dir.length() < 0.01:
		return
	_knockback = dir.normalized() * force
