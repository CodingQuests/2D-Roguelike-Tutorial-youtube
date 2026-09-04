class_name EnemyBase
extends CharacterBody2D
## Shared base for every enemy. Holds the common state machine scaffold,
## telegraph helpers, the melee AttackArea control, knockback, hit feedback and
## death. Concrete enemies (Grunt / Charger / Caster / Brute / Skitterling /
## Boss) override _ai_process() and set their stats in the inspector.

enum State { IDLE, CHASE, TELEGRAPH, ATTACK, RECOVERY, DEAD }

# Common stats (subclasses set their own values in _ready / the inspector).
@export var max_health: float = 50.0
@export var speed: float = 95.0
@export var attack_damage: float = 12.0
@export var attack_knockback: float = 180.0

# Self-light, so an enemy is never an invisible silhouette on a dark floor.
# Subclasses override these in _on_ready() before _add_menace_glow() runs.
@export var glow_color: Color = Color(1.0, 0.35, 0.3)
@export var glow_energy: float = 0.42
@export var glow_scale: float = 0.6

@onready var sprite: Sprite2D = $Sprite2D
@onready var health: HealthComponent = $Health
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var attack_area: HitboxComponent = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var telegraph: Sprite2D = $Telegraph

const LIGHT_TEX := preload("res://light_radial.tres")

var state: int = State.IDLE
var state_timer: float = 0.0
var _knockback := Vector2.ZERO
var _hitstun := 0.0  # while >0 the enemy can't move under its own power
var _player: Node2D = null
var _tele_tween: Tween = null
var _glow: PointLight2D = null
var _tele_mode := 0
var _tele_color := Color(1, 0.15, 0.15, 0.5)
var _tele_elapsed := 0.0
var is_corrupted: bool = false

# --- Juice state ---
var _base_sprite_scale := Vector2.ONE
var _bob_phase := 0.0
var _bob_time := 0.0
var _spawning := false
var _slam_cd := 0.0

# --- Status effects (driven by the player's on-hit item effects) ---
# Burn = damage over time; Chill = a movement slowdown. Both stack by taking the
# stronger value and refreshing the duration, so re-applying keeps them topped up.
var _burn_dps := 0.0
var _burn_time := 0.0
var _burn_tick := 0.0
var _chill_factor := 0.0  # 0 = full speed, 0.5 = moves at half speed
var _chill_time := 0.0

signal defeated(enemy)


func _ready() -> void:
	# "enemy" group is set on the EnemyBase.tscn root (inherited by every enemy).
	health.max_health = max_health
	health.current_health = max_health
	health.died.connect(die)
	hurtbox.hurt.connect(_on_hurt)
	attack_area.source_node = self
	attack_area.damage = attack_damage
	attack_area.knockback_force = attack_knockback
	_disable_attack_area()
	hide_telegraph()
	_on_ready()
	_base_sprite_scale = sprite.scale
	_bob_phase = randf() * TAU
	_add_menace_glow()


## A dim, close self-light on every enemy.
##
## Not decoration — a fairness fix. Once the dungeon went dark, anything outside
## the player's torch was a black silhouette on a black floor, so enemies could
## close on you completely unseen. A small glow keeps them legible at range
## while still reading as "something lurking", and subclasses tint it
## (`glow_color`) so a caster is identifiable from its light alone.
func _add_menace_glow() -> void:
	_glow = PointLight2D.new()
	_glow.texture = LIGHT_TEX
	_glow.texture_scale = glow_scale
	_glow.energy = glow_energy
	_glow.color = glow_color
	add_child(_glow)


func _on_hurt(_amount: float, _source) -> void:
	AudioManager.play("enemy_hurt")
	# Impact squash on the sprite (scale only — leaves the idle bob alone).
	Juice.squash(sprite, _base_sprite_scale, 0.32, 0.18)


## Turn this enemy into a "corrupted" elite: tougher, faster, hits harder, and
## visibly glowing. Called by RoomController based on the player's corruption.
func make_corrupted() -> void:
	if is_corrupted:
		return
	is_corrupted = true
	max_health *= 1.6
	speed *= 1.25
	attack_damage *= 1.4
	health.max_health = max_health
	health.current_health = max_health
	attack_area.damage = attack_damage
	scale *= 1.15
	# Over 1.0 so the elite blooms under the WorldEnvironment glow, and a
	# permanent violet rim so it's identifiable at a glance in a dark room.
	sprite.modulate = Color(1.5, 0.7, 1.7)
	Juice.set_outline(sprite, true, Color(0.85, 0.35, 1.0), 1.0, true)
	if _glow:
		_glow.color = Color(0.7, 0.25, 1.0)
		_glow.energy = glow_energy * 2.1
		_glow.texture_scale = glow_scale * 1.4

	var aura := CPUParticles2D.new()
	aura.amount = 14
	aura.lifetime = 0.7
	aura.spread = 180.0
	aura.gravity = Vector2.ZERO
	aura.initial_velocity_min = 6.0
	aura.initial_velocity_max = 18.0
	aura.scale_amount_min = 1.0
	aura.scale_amount_max = 2.5
	aura.color = Color(0.6, 0.1, 0.8, 0.7)
	aura.emitting = true
	add_child(aura)


# --- Status effects ----------------------------------------------------
## Set the enemy on fire: `dps` damage per second for `dur` seconds. Stacks by
## keeping the stronger burn and refreshing the timer. Called by item effects.
func ignite(dps: float, dur: float) -> void:
	if state == State.DEAD:
		return
	_burn_dps = maxf(_burn_dps, dps)
	_burn_time = maxf(_burn_time, dur)


## Slow the enemy: move at `(1 - factor)` speed for `dur` seconds.
func chill(factor: float, dur: float) -> void:
	if state == State.DEAD:
		return
	var was_chilled := _chill_factor > 0.0
	_chill_factor = clampf(maxf(_chill_factor, factor), 0.0, 0.85)
	_chill_time = maxf(_chill_time, dur)
	if not was_chilled:
		Juice.impact(get_tree().current_scene, global_position, Color(0.6, 0.85, 1.0), 8, 1.0)


func _tick_status(delta: float) -> void:
	if _burn_time > 0.0:
		_burn_time -= delta
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick = 0.25
			health.damage(_burn_dps * 0.25)
			Juice.spark(get_tree().current_scene, global_position, Vector2.UP, Color(1.0, 0.55, 0.15), 4, 0.8)
		if _burn_time <= 0.0:
			_burn_dps = 0.0
	if _chill_time > 0.0:
		_chill_time -= delta
		if _chill_time <= 0.0:
			_chill_factor = 0.0


# Override points for subclasses.
func _on_ready() -> void:
	pass


func _ai_process(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	# While fading/scaling in, hold still and don't act.
	if _spawning:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	_ai_process(delta)
	_tick_status(delta)
	_tick_telegraph(delta)

	# Hit-stun: a struck enemy stops acting under its own power for a beat, so a
	# hit lands as a clean knockback instead of adding to an in-progress charge.
	if _hitstun > 0.0:
		_hitstun -= delta
		velocity = Vector2.ZERO

	# Face the player.
	if _player and is_instance_valid(_player):
		sprite.flip_h = _player.global_position.x < global_position.x

	# Chill scales locomotion (set by the AI) but never the knockback impulse.
	if _chill_factor > 0.0:
		velocity *= (1.0 - _chill_factor)

	if not (is_finite(_knockback.x) and is_finite(_knockback.y)):
		_knockback = Vector2.ZERO
	var pre_knockback := _knockback.length()
	velocity += _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 1200 * delta)
	move_and_slide()

	# Idle bob so the enemy feels alive between actions.
	_bob_time += delta * 8.0
	sprite.position.y = sin(_bob_time + _bob_phase) * 1.3

	# Wall slam: getting knocked hard into geometry sparks and shakes.
	if _slam_cd > 0.0:
		_slam_cd -= delta
	elif pre_knockback > 200.0 and get_slide_collision_count() > 0:
		var col := get_last_slide_collision()
		if col:
			_slam_cd = 0.3
			Juice.spark(get_tree().current_scene, col.get_position(), col.get_normal(), Color(0.9, 0.8, 0.7), 8, 1.2)
			GameManager.shake_camera(0.12)
			_knockback *= 0.3


# --- Helpers for subclasses -------------------------------------------
func player_pos() -> Vector2:
	return _player.global_position if (_player and is_instance_valid(_player)) else global_position


func has_player() -> bool:
	return _player != null and is_instance_valid(_player)


func dir_to_player() -> Vector2:
	var d := player_pos() - global_position
	return d.normalized() if d.length() > 0.001 else Vector2.RIGHT


func distance_to_player() -> float:
	return global_position.distance_to(player_pos())


# --- Telegraphs --------------------------------------------------------
# The danger marker is a shader quad, not a flat polygon. Two reasons: it FILLS
# UP over the wind-up, so the zone doubles as a countdown you can read without
# watching the enemy's animation; and its animated rim stays legible over a
# dark, torch-lit floor where a 35%-alpha red shape simply disappeared.
func show_telegraph_circle(radius: float, color := Color(1, 0.15, 0.15, 0.5)) -> void:
	var was_visible := telegraph.visible
	telegraph.rotation = 0.0
	telegraph.scale = Vector2.ONE * (radius * 2.0 / 64.0)
	_tele_mode = 0
	_tele_color = color
	telegraph.visible = true
	if not was_visible:
		_tele_elapsed = 0.0
		_pulse_telegraph()
	_apply_telegraph_params()


func show_telegraph_rect(length: float, width: float, direction: Vector2, color := Color(1, 0.2, 0.2, 0.55)) -> void:
	var was_visible := telegraph.visible
	telegraph.rotation = direction.angle()
	# The shader's rect mode spans the quad, so scale x/y to the beam and shift
	# the quad forward by half its length (the quad is centred, the beam starts
	# at the enemy).
	telegraph.scale = Vector2(length / 64.0, width / 64.0)
	telegraph.position = Vector2(length * 0.5, 0).rotated(direction.angle())
	_tele_mode = 1
	_tele_color = color
	telegraph.visible = true
	if not was_visible:
		_tele_elapsed = 0.0
		_pulse_telegraph()
	_apply_telegraph_params()


func hide_telegraph() -> void:
	telegraph.visible = false
	telegraph.position = Vector2.ZERO
	# Elites keep their permanent violet rim; everyone else loses it.
	if not is_corrupted:
		Juice.set_outline(sprite, false)
	if _tele_tween and _tele_tween.is_valid():
		_tele_tween.kill()


func _apply_telegraph_params() -> void:
	var mat := telegraph.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("mode", _tele_mode)
	mat.set_shader_parameter("color", _tele_color)


# Drive the telegraph's fill from how far through the wind-up we are, and rim
# the enemy itself so the attacker is readable wherever they're standing.
func _pulse_telegraph() -> void:
	if _tele_tween and _tele_tween.is_valid():
		_tele_tween.kill()
	if not is_corrupted:
		Juice.set_outline(sprite, true, Color(1.0, 0.3, 0.25), 1.0, true)


func _tick_telegraph(delta: float) -> void:
	if not telegraph.visible:
		return
	_tele_elapsed += delta
	var mat := telegraph.material as ShaderMaterial
	if mat == null:
		return
	# state_timer counts DOWN over the wind-up, so fill = how much has elapsed.
	var total := maxf(_tele_elapsed + maxf(state_timer, 0.0), 0.001)
	mat.set_shader_parameter("fill", clampf(_tele_elapsed / total, 0.0, 1.0))
	mat.set_shader_parameter("time_s", _tele_elapsed)


# --- Melee attack area -------------------------------------------------
func enable_attack_area(offset: Vector2, radius: float) -> void:
	(attack_shape.shape as CircleShape2D).radius = radius
	attack_shape.position = offset
	attack_area.damage = attack_damage
	attack_area.knockback_force = attack_knockback
	attack_area.reset_hits()
	# Deferred: these may be toggled from inside a physics in/out signal.
	attack_area.set_deferred("monitorable", true)
	attack_shape.set_deferred("disabled", false)


func _disable_attack_area() -> void:
	attack_area.set_deferred("monitorable", false)
	attack_shape.set_deferred("disabled", true)


# --- Damage taken directly (e.g. Corrupted Aura) -----------------------
func take_damage(amount: float, from_pos: Vector2) -> void:
	if state == State.DEAD:
		return
	health.damage(amount)
	Juice.flash(sprite, Color.WHITE, 0.08)
	Juice.squash(sprite, _base_sprite_scale, 0.28, 0.18)
	Juice.damage_number(get_tree().current_scene, global_position, amount, Color(1, 1, 1))
	apply_knockback((global_position - from_pos).normalized(), 70.0)


## Fade + scale up from nothing with a ground ring + dust. Called by the room
## right after the enemy is placed so it doesn't pop into existence.
func spawn_in() -> void:
	_spawning = true
	var world := get_tree().current_scene
	Juice.ring(world, global_position, Color(0.9, 0.3, 0.3, 0.8), 30.0, 0.32)
	Juice.impact(world, global_position, Color(0.5, 0.2, 0.2), 8, 0.8)
	var keep := sprite.modulate
	sprite.scale = _base_sprite_scale * 0.1
	sprite.modulate = Color(keep.r, keep.g, keep.b, 0.0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", _base_sprite_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "modulate:a", keep.a, 0.25)
	tw.chain().tween_callback(func() -> void: _spawning = false)


func apply_knockback(direction: Vector2, force: float) -> void:
	if not (is_finite(direction.x) and is_finite(direction.y)):
		return
	_knockback = direction * force
	# Hit-stun the enemy for a moment so the knockback replaces its current motion
	# instead of stacking on top of an attack lunge (which used to fling chargers).
	_hitstun = maxf(_hitstun, clampf(force / 1800.0, 0.08, 0.22))


# --- Death -------------------------------------------------------------
func die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	_disable_attack_area()
	hide_telegraph()
	# All physics-state changes deferred: die() can run inside an area signal.
	hurtbox.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	defeated.emit(self)
	AudioManager.play("enemy_death")
	var world := get_tree().current_scene
	# One-frame white silhouette "pop" before the dissolve.
	Juice.flash(sprite, Color.WHITE, 0.06)
	# Gibs fly along the killing blow; a little radial spray fills it out.
	var gib_dir := _knockback.normalized() if _knockback.length() > 5.0 else Vector2.RIGHT.rotated(randf() * TAU)
	Juice.spark(world, global_position, gib_dir, Color(0.85, 0.2, 0.2), 14, 1.7)
	Juice.impact(world, global_position, Color(0.85, 0.2, 0.2), 12, 1.4)
	Juice.ring(world, global_position, Color(1.0, 0.5, 0.4, 0.7), 30.0, 0.3)
	# A corpse splat left behind so cleared rooms feel earned.
	Juice.decal(world, global_position, Color(0.06, 0.0, 0.02, 0.4), 9.0)
	# A dying enemy briefly lights the room — much more readable in a torch-lit
	# dungeon than another particle burst.
	Juice.light_flash(world, global_position, Color(1.0, 0.45, 0.3), 1.2, 0.9, 0.22)
	# Burn away rather than fade out: the dissolve's hot leading edge sells the
	# kill, and it fits a game about a corrupted forge.
	Juice.set_outline(sprite, false)
	Juice.dissolve(sprite, 0.30, Color(1.8, 0.9, 0.35))
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", scale * 1.2, 0.30)
	tw.chain().tween_callback(queue_free)
