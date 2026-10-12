class_name PlayerController
extends CharacterBody2D

signal stats_changed
signal corruption_changed(value: float, maximum: float)

@onready var health: HealthComponent = $Health
@onready var hurtbox: HurtboxComponent = $Hurtbox
@export var move_speed: float = 180.0
@onready var sprite_2d: Sprite2D = $WeaponPivot/WeaponSprite
@onready var player_sprite: Sprite2D = $Sprite2D
@onready var hitbox: HitboxComponent = $WeaponPivot/AttackHitbox
@onready var weapon: WeaponController = $WeaponPivot



@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.6
@export var max_corruption: float = 100.0

var corruption: float = 0.0
var quick_bonus_damage: float = 0.0
var heavy_bonus_damage: float = 0.0
var move_speed_mult: float = 1.0
var attack_cooldown_mult: float = 1.0
var glass_damage_mult: float = 1.0
var glass_taken_mult: float = 1.0

var _last_good_pos := Vector2.ZERO
var _is_dashing := false
var _dash_timer := 0.0
var _dash_dir := Vector2.RIGHT
var _dash_cd_timer := 0.0
var _base_sprite_scale := Vector2.ONE
var _bob_time := 0.0
var _knockback := Vector2.ZERO
var _last_tier := "Stable"

const KNOCKBACK_DECAY := 1700.0
const KNOCKBACK_TAKEN := 0.6      # the player is shoved less than enemies are

var items: Array = []

func _ready() -> void:
	_last_good_pos = global_position
	_base_sprite_scale = player_sprite.scale
	GameManager.register_player(self)
	
func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	if delta <= 0.0 or Engine.time_scale <= 0.0:
		return
	_update_aim()
	_handle_attack_input()
	_update_dash(delta)
	_update_body_juice(delta, _get_move_input().length() > 0.1)
	if _is_dashing:
		velocity = _dash_dir * dash_speed
	else:
		velocity = _get_move_input() * move_speed * move_speed_mult * weapon.get_move_factor() + _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		
		
	if not _finite(velocity):
		velocity = Vector2.ZERO
		
	if Engine.time_scale > 0.0:
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


func has_item(id: String) -> bool:
	for it in items:
		# get("id", "") rather than ["id"], so a def with no id can't crash it.
		if it.get("id", "") == id:
			return true
	return false

func apply_upgrade(def: Dictionary) -> void:
	# Pull the Callable out of the def and call it with self, so the upgrade
	# gets the player. Then record the def and tell everyone.
	var fn: Callable = def["apply"]
	fn.call(self)
	items.append(def)
	add_corruption(float(def.get("corruption", 0)))
	
func on_stats_changed() -> void:
	hurtbox.damage_multiplier = _corruption_taken_mult() * glass_taken_mult
	stats_changed.emit()
	

func add_corruption(amount: float) -> void:
	# Clamped to zero..max: can't overflow, can't go negative. The clamp is
	# also what lets a negative amount work later.
	corruption = clampf(corruption + amount, 0.0, max_corruption)
	corruption_changed.emit(corruption, max_corruption)
	# The damage multipliers read corruption soon, so they re-run every time it moves.
	var tier := get_corruption_tier()
	if tier != _last_tier:
		_last_tier = tier
		_on_tier_changed(tier)
	on_stats_changed()

func get_corruption_tier() -> String:
	# Less-than checks from the bottom up: each elif only runs if the one above missed.
	if corruption < 25.0:
		return "Stable"
	elif corruption < 50.0:
		return "Tainted"
	elif corruption < 75.0:
		return "Corrupted"
	# The fall-through: 75 and up is Overloaded with no check at all.
	return "Overloaded"
	
func _corruption_damage_mult() -> float:
	# Top down with >=, so the highest band you've reached wins. 5%, 12%, 22% more damage.
	if corruption >= 75.0:   return 1.22
	elif corruption >= 50.0: return 1.12
	elif corruption >= 25.0: return 1.05
	return 1.0
func _corruption_taken_mult() -> float:
	# Same shape, bigger numbers: 6%, 18%, 40% more damage taken. You always
	# lose more than you gain, and that gap is on purpose.
	if corruption >= 75.0:   return 1.4
	elif corruption >= 50.0: return 1.18
	elif corruption >= 25.0: return 1.06
	return 1.0
func get_outgoing_damage_mult() -> float:
	# The one public function: corruption's multiplier times Glass Blade's.
	# The weapon is about to read this.
	return _corruption_damage_mult() * glass_damage_mult
	
func _on_tier_changed(tier: String) -> void:
	GameManager.shake_camera(0.25)
	AudioManager.play("telegraph", -2.0, 0.7)    # -2 dB, lower pitch
	# Into current_scene, not under the player, so the label stays where it
	# was born while you move on.
	var world := get_tree().current_scene
	# A violet ring out to 60 px over half a second, a burst of 22, the tier
	# name in capitals rising off the player.
	Juice.ring(world, global_position, Color(0.6, 0.1, 0.7, 0.9), 60.0, 0.5, 3.0)
	Juice.impact(world, global_position, Color(0.5, 0.1, 0.6), 22, 1.8)
	Juice.floating_text(world, global_position, tier.to_upper(), Color(0.85, 0.4, 1.0), 18)
	
	
