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
var burn_dps: float = 0.0          # Ember Brand: damage over time
var chill_factor: float = 0.0      # Frost Bite: slow on hit (0..0.85)
var chain_count: int = 0           # Storm Coil: hit arcs to N nearby enemies
var execute_threshold: float = 0.0 # Reaper's Mark: instakill below this HP ratio
var echo_level: int = 0        # Echo Blade: each swing throws a slash wave
var whirlwind: bool = false    # Maelstrom: heavy becomes a 360 spin
var twin_strike: bool = false  # Twin Fang: every hit strikes twice
var syn_plasma: bool = false       # chain bolts also ignite
var syn_glacial: bool = false      # slash waves chill hard
var syn_cyclone: bool = false      # whirlwind also throws waves outward
var syn_harvest: bool = false      # execute threshold boosted

var _dead := false
var _last_good_pos := Vector2.ZERO
var _is_dashing := false
var _dash_timer := 0.0
var _dash_dir := Vector2.RIGHT
var _dash_cd_timer := 0.0
var _base_sprite_scale := Vector2.ONE
var _bob_time := 0.0
var _knockback := Vector2.ZERO
var _last_tier := "Stable"
var active_item: String = ""
var active_name: String = ""
var active_cooldown: float = 6.0
var _active_cd_timer: float = 0.0
# For Phase Step's i-frames, later in this step.
var _phase_timer: float = 0.0

const KNOCKBACK_DECAY := 1700.0
const KNOCKBACK_TAKEN := 0.6      # the player is shoved less than enemies are

var items: Array = []

const SYNERGY_DESCS := {
	"plasma":  "Chain bolts also ignite what they arc to",
	"glacial": "Slash waves chill hard on contact",
	"cyclone": "Whirlwind heavies throw slash waves outward",
	"harvest": "Execute threshold greatly increased",
}


func _ready() -> void:
	_last_good_pos = global_position
	_base_sprite_scale = player_sprite.scale
	GameManager.register_player(self)
	hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)
	_apply_meta_unlocks()
func _physics_process(delta: float) -> void:
	if _dead:
		return
	if get_tree().paused:
		return
	if delta <= 0.0 or Engine.time_scale <= 0.0:
		return
	_phase_timer = maxf(0.0, _phase_timer - delta)
	_update_aim()
	_handle_attack_input()
	_handle_active_input(delta)
	_sync_invulnerability()
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
	_sync_invulnerability()
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
	_resolve_synergies()
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
	
	
func _resolve_synergies() -> void:
	syn_plasma  = has_item("ember_brand") and has_item("storm_coil")
	syn_glacial = has_item("echo_blade")  and has_item("frost_bite")
	syn_cyclone = has_item("echo_blade")  and has_item("whirlwind")
	syn_harvest = has_item("reapers_mark") and has_item("ember_brand")
	
func get_execute_threshold() -> float:
	# x1.6 with harvest on, x1 without, then clamped at 0.75: even the synergy
	# can't execute something with three quarters of its health left.
	return clampf(execute_threshold * (1.6 if syn_harvest else 1.0), 0.0, 0.75)
	
func set_active_item(id: String, display_name: String, cooldown: float) -> void:
	active_item = id
	active_name = display_name
	active_cooldown = cooldown
	_active_cd_timer = 0.0
	
	
func _handle_active_input(delta: float) -> void:
	if _active_cd_timer > 0.0:
		_active_cd_timer -= delta
	# Only fires with something in the slot, ready, and E down this frame. The
	# quoted "active_item" is the input action, not the field.
	if active_item != "" and _active_cd_timer <= 0.0 and Input.is_action_just_pressed("active_item"):
		use_active()

func use_active() -> void:
	# Start the cooldown, then match on the id string. One line per ability.
	_active_cd_timer = active_cooldown
	match active_item:
		"forge_pulse":  _forge_pulse()
		"phase_step":   _phase_step()
		"blood_siphon": _blood_siphon()


func _forge_pulse() -> void:
	# A ring, a shake, the heavy sound.
	var world := get_tree().current_scene
	Juice.ring(world, global_position, Color(1.0, 0.6, 0.2, 0.9), 140.0, 0.4, 4.0)
	GameManager.shake_camera(0.35)
	AudioManager.play("heavy")
	# Everything inside 140 px takes 35 via take_damage(), knocked away from you.
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < 140.0:
			if e.has_method("take_damage"):
				e.take_damage(35.0, global_position)

func _phase_step() -> void:
	# Aim at the mouse. Vector2.RIGHT if the mouse is basically on top of you.
	var to_mouse := get_global_mouse_position() - global_position
	var dir := to_mouse.normalized() if to_mouse.length() > 1.0 else Vector2.RIGHT
	var motion := dir * 130.0
	var collision := KinematicCollision2D.new()
	# test_move sweeps the player's actual body along the motion. Adding 130px
	# directly would teleport straight through walls and locked gates.
	if test_move(global_transform, motion, collision):
		motion = collision.get_travel()
	global_position += motion
	# So _last_good_pos agrees with where you are now.
	_last_good_pos = global_position
	# 0.15 s of i-frames, then sync the flag.
	_phase_timer = 0.15
	_sync_invulnerability()
	AudioManager.play("dash")

func _sync_invulnerability() -> void:
	hurtbox.invulnerable = not health.is_alive() or _is_dashing or _phase_timer > 0.0

func _blood_siphon() -> void:
	# Nearest living enemy inside 220. Same search as the chain.
	var best: Node2D = null
	var best_d := 220.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e) or e.is_queued_for_deletion() or not e.health.is_alive():
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	# No target: give the cooldown back and say so. A wasted panic button is
	# a death.
	if best == null:
		_active_cd_timer = 0.0
		Juice.floating_text(get_tree().current_scene, global_position, "NO TARGET")
		return
	# 40 damage to them, 25 heal to you. The number on screen is what you
	# actually healed, not 25, because heal() caps at max.
	if best.has_method("take_damage"):
		best.take_damage(40.0, global_position)
	var before := health.current_health
	health.heal(25.0)
	Juice.floating_text(get_tree().current_scene, global_position,
		"+%d" % int(health.current_health - before), Color(0.4, 1.0, 0.5), 14)
	
func _on_hurt(_amount: float, _source) -> void:
	GameManager.break_combo()
	
func reset_floor_motion() -> void:
	_is_dashing = false
	_dash_timer = 0.0
	_phase_timer = 0.0
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	_last_good_pos = global_position
	_sync_invulnerability()
	sprite_2d.modulate = Color.WHITE
	player_sprite.modulate = Color.WHITE
	
	
func _on_died() -> void:
	# Same latch the enemies have. died can arrive twice in a frame; the second bails.
	if _dead:
		return
	_dead = true
	# Stop the body where it is instead of sliding on.
	_is_dashing = false
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	# Nothing can hurt it again.
	hurtbox.invulnerable = true
	# Weapon off, so a swing that was mid-air can't still land.
	weapon.set_process(false)  # WeaponController advances attacks in _process, not physics.
	weapon.set_physics_process(false)
	weapon.state = WeaponController.State.IDLE
	weapon._disable_hitbox()
	# Quarter speed for 1.2 s. Same length as the HUD's timer, so the world
	# freezes right as the slow-mo would have ended.
	GameManager.slow_mo(0.25, 1.2)
	AudioManager.duck_music(-14.0, 2.5)
	# A HUD without the death screen yet gets skipped, not a crash.
	if GameManager.hud and GameManager.hud.has_method("show_game_over"):
		GameManager.hud.show_game_over()


func _apply_meta_unlocks() -> void:
	# The base list. Daggers only if owned.
	var weapons := [WeaponController.SWORD, WeaponController.SPEAR]
	if MetaProgression.is_unlocked("daggers"):
		weapons.append(WeaponController.DAGGERS)
	# Resets the slot, so you always start on the sword.
	weapon.set_available(weapons)
	if MetaProgression.is_unlocked("vigor"):
		# Raise the max, then fill current to match. Otherwise you start at
		# 100 of 125 and the bar reads as damaged.
		health.set_max_health(health.max_health + 25.0)
		health.heal(25.0)
	if MetaProgression.is_unlocked("honed"):
		# Six flat on quick damage.
		quick_bonus_damage += 6.0
	if MetaProgression.is_unlocked("swift"):
		# Multiply, not add: 8% of whatever the speed already is, not a fixed number.
		move_speed_mult *= 1.08
	on_stats_changed()
	
	
