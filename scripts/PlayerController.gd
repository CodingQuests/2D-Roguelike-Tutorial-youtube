class_name PlayerController
extends CharacterBody2D
## The player: top-down movement, dash, aiming, the corruption system and all
## upgrade hooks. Attacks themselves live in WeaponController (on WeaponPivot);
## this script just forwards the attack inputs and feeds it stat values.

# --- Movement tuning ---
@export var move_speed: float = 180.0
@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.6

# Knockback feel: how fast a shove decays, and how much of an incoming hit's
# knockback the player actually takes (lower = the player gets shoved less).
const KNOCKBACK_DECAY := 1700.0
const KNOCKBACK_TAKEN := 0.6

# --- Corruption ---
@export var max_corruption: float = 100.0
var corruption: float = 0.0

# --- Upgrade-driven stats (mutated by UpgradeManager) ---
var quick_bonus_damage: float = 0.0
var heavy_bonus_damage: float = 0.0
var hitbox_scale: float = 1.0
var heal_on_kill: float = 0.0
var heal_on_hit: float = 0.0
var aura_enabled: bool = false
var glass_damage_mult: float = 1.0
var glass_taken_mult: float = 1.0
var attack_cooldown_mult: float = 1.0
var move_speed_mult: float = 1.0
var berserker_enabled: bool = false

# --- Items & on-hit effects (the build) -------------------------------
## Every upgrade/item the player has picked up, kept as its def dict so the HUD
## can list the build and synergies can ask "do we own X?".
var items: Array = []
# Composable on-hit effects. Items add to these; the WeaponController reads them
# when a melee hit (or a slash wave) lands, so picking more items compounds.
var burn_dps: float = 0.0          # Ember Brand: damage over time on hit
var chill_factor: float = 0.0      # Frost Bite: slow on hit (0..0.85)
var chain_count: int = 0           # Storm Coil: hit arcs to N nearby enemies
var execute_threshold: float = 0.0 # Reaper's Mark: instakill below this HP ratio
var echo_level: int = 0            # Echo Blade: each swing throws a slash wave
var whirlwind: bool = false        # Maelstrom: heavy attack becomes a 360 spin
var twin_strike: bool = false      # Twin Fang Curse: every hit strikes twice
# Synergies resolved from the owned set; flags read by the weapon.
var syn_plasma: bool = false       # chain bolts also ignite
var syn_glacial: bool = false      # slash waves chill hard
var syn_cyclone: bool = false      # whirlwind also throws waves outward
var syn_harvest: bool = false      # execute threshold boosted
var _synergies: Array = []         # active synergy ids
var last_new_synergies: Array = [] # display names activated by the latest pick

# --- Active item (the [E] ability — one slot, Isaac-style) -------------
const PHASE_STEP_DISTANCE := 165.0
var active_item: String = ""       # "" = none; else forge_pulse / phase_step / blood_siphon
var active_name: String = ""       # display name for the HUD
var active_cooldown: float = 6.0
var _active_cd_timer: float = 0.0

const AURA_INTERVAL := 2.0
const AURA_RADIUS := 95.0
const AURA_DAMAGE := 5.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var health: HealthComponent = $Health
@onready var weapon: WeaponController = $WeaponPivot
@onready var hurtbox: HurtboxComponent = $Hurtbox

var _knockback := Vector2.ZERO
var _last_good_pos := Vector2.ZERO  # restored if a frame ever goes non-finite
var _is_dashing := false
var _dash_timer := 0.0
var _dash_cd_timer := 0.0
var _dash_dir := Vector2.RIGHT
var _aura_timer := 0.0
var _dead := false

# --- Juice state ---
var _base_sprite_scale := Vector2.ONE
var _bob_time := 0.0
var _was_moving := false
var _dash_img_timer := 0.0
var _last_tier := "Stable"

signal corruption_changed(value: float, maximum: float)
signal stats_changed


func _ready() -> void:
	GameManager.register_player(self)  # "player" group is set in Player.tscn
	_last_good_pos = global_position
	_base_sprite_scale = sprite.scale
	_last_tier = get_corruption_tier()
	health.damaged.connect(_on_health_changed)
	health.healed.connect(_on_health_changed)
	health.died.connect(_on_died)
	hurtbox.hurt.connect(_on_hurt)
	_apply_meta_unlocks()
	on_stats_changed()
	call_deferred("_refresh_hud")


# Permanent unlocks bought in the Forge (hub) apply at the start of each run.
func _apply_meta_unlocks() -> void:
	var weapons := [WeaponController.SWORD, WeaponController.SPEAR]
	if MetaProgression.is_unlocked("daggers"):
		weapons.append(WeaponController.DAGGERS)
	weapon.set_available(weapons)
	if MetaProgression.is_unlocked("vigor"):
		health.max_health += 25.0
		health.current_health = health.max_health
	if MetaProgression.is_unlocked("honed"):
		quick_bonus_damage += 6.0
	if MetaProgression.is_unlocked("swift"):
		move_speed_mult *= 1.08


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = velocity.move_toward(Vector2.ZERO, 2000 * delta)
		move_and_slide()
		return

	_update_aim()
	_handle_attack_input()
	_handle_active_input(delta)
	_update_dash(delta)
	_update_aura(delta)

	# Never let a stray non-finite value linger in the knockback channel: it would
	# make velocity NaN and spam move_and_slide() "cannot be normalized" forever.
	if not _finite(_knockback):
		_knockback = Vector2.ZERO

	var input := Vector2.ZERO
	if _is_dashing:
		velocity = _dash_dir * dash_speed
		_emit_afterimages(delta)
	else:
		input = _get_move_input()
		var factor := weapon.get_move_factor()
		velocity = input * move_speed * move_speed_mult * factor + _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)

	if not _finite(velocity):
		velocity = Vector2.ZERO
	move_and_slide()
	# If our position ever went non-finite, snap back to the last good spot.
	if _finite(global_position):
		_last_good_pos = global_position
	else:
		global_position = _last_good_pos
		velocity = Vector2.ZERO
		_knockback = Vector2.ZERO
	_update_body_juice(delta, input.length() > 0.1)


func _finite(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)


# Walk/idle bob and a squash when you come to a stop. Pure sprite-local motion,
# no tweens to leak.
func _update_body_juice(delta: float, moving: bool) -> void:
	if _is_dashing:
		return
	# Bob faster while moving, slow breathing while idle.
	var freq := 13.0 if moving else 3.0
	var amp := 1.6 if moving else 0.8
	_bob_time += delta * freq
	sprite.position.y = sin(_bob_time) * amp
	# Squash the instant you stop, like planting your feet.
	if _was_moving and not moving:
		Juice.squash(sprite, _base_sprite_scale, 0.18, 0.2)
	_was_moving = moving


# Drop fading ghost copies along the dash path.
func _emit_afterimages(delta: float) -> void:
	_dash_img_timer -= delta
	if _dash_img_timer <= 0.0:
		_dash_img_timer = 0.025
		Juice.afterimage(get_tree().current_scene, sprite, Color(0.6, 0.85, 1.0, 0.45), 0.22)


func _get_move_input() -> Vector2:
	var v := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	return v.normalized() if v.length() > 1.0 else v


func _update_aim() -> void:
	var to_mouse := get_global_mouse_position() - global_position
	weapon.rotation = to_mouse.angle()
	# Flip the body sprite to roughly face the aim.
	if absf(to_mouse.x) > 4.0:
		sprite.flip_h = to_mouse.x < 0.0


func _handle_attack_input() -> void:
	if Input.is_action_just_pressed("quick_attack"):
		weapon.try_quick_attack()
	elif Input.is_action_just_pressed("heavy_attack"):
		weapon.try_heavy_attack()
	if Input.is_action_just_pressed("swap_weapon"):
		weapon.swap()


# --- Active item ([E] ability) -----------------------------------------
func _handle_active_input(delta: float) -> void:
	if _active_cd_timer > 0.0:
		_active_cd_timer -= delta
	if active_item != "" and _active_cd_timer <= 0.0 and Input.is_action_just_pressed("active_item"):
		use_active()


## Equip an active ability in the single slot (replaces the previous one).
func set_active_item(id: String, display_name: String, cooldown: float) -> void:
	active_item = id
	active_name = display_name
	active_cooldown = cooldown
	_active_cd_timer = 0.0  # ready to use immediately


## 1.0 = charged/ready, 0.0 = just used.
func get_active_ratio() -> float:
	if active_item == "" or active_cooldown <= 0.0:
		return 1.0
	return clampf(1.0 - _active_cd_timer / active_cooldown, 0.0, 1.0)


func use_active() -> void:
	_active_cd_timer = active_cooldown
	var world := get_tree().current_scene
	match active_item:
		"forge_pulse":
			_active_forge_pulse(world)
		"phase_step":
			_active_phase_step(world)
		"blood_siphon":
			_active_blood_siphon(world)


# Nova blast: damage and knock back every enemy in range.
func _active_forge_pulse(world: Node) -> void:
	var radius := 150.0
	var dmg := 40.0 * get_outgoing_damage_mult()
	AudioManager.thump(-2.0)
	GameManager.shake_camera(0.4)
	GameManager.zoom_punch(0.07)
	GameManager.screen_impact(0.5)
	Juice.ring(world, global_position, Color(1.0, 0.7, 0.3, 0.9), radius, 0.4, 4.0)
	Juice.impact(world, global_position, Color(1.0, 0.6, 0.25), 26, 2.0)
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= radius and e.has_method("take_damage"):
			e.take_damage(dmg, global_position)
			var kdir: Vector2 = e.global_position - global_position
			if kdir.length() > 0.01 and e.has_method("apply_knockback"):
				e.apply_knockback(kdir.normalized(), 360.0)


# Blink toward the aim with brief i-frames.
func _active_phase_step(world: Node) -> void:
	var dir := (get_global_mouse_position() - global_position)
	dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	var target := _safe_blink(dir, PHASE_STEP_DISTANCE)
	for i in 5:
		Juice.afterimage(world, sprite, Color(0.7, 0.5, 1.0, 0.5), 0.3)
	global_position = target
	_last_good_pos = target
	_knockback = Vector2.ZERO
	hurtbox.invulnerable = true
	Juice.ring(world, global_position, Color(0.7, 0.5, 1.0, 0.8), 30.0, 0.3)
	AudioManager.play("dash", 2.0)
	await get_tree().create_timer(0.18, true, false, true).timeout
	if not _is_dashing:  # don't clobber a dash that started meanwhile
		hurtbox.invulnerable = false


## How far the player can actually blink along `dir` before hitting geometry.
##
## Phase Step used to do `global_position += dir * 165`, which is a teleport
## with no collision test at all — you could land inside a wall, inside a locked
## door, or straight out of the dungeon into the void. This sweeps the player's
## own collision shape along the path and returns the last safe point.
##
## Masks world geometry ONLY (layer bit 1), so the ability keeps its identity:
## you still phase through enemies, you just can't phase through walls. That
## also stops it skipping the locked gates that hold you in a combat room.
func _safe_blink(dir: Vector2, distance: float) -> Vector2:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return global_position
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape_node.shape
	params.transform = Transform2D(0.0, global_position)
	params.motion = dir * distance
	params.collision_mask = 1
	params.exclude = [get_rid()]
	params.margin = 0.5
	var fractions := get_world_2d().direct_space_state.cast_motion(params)
	# cast_motion returns [safe_fraction, unsafe_fraction]; empty means no room
	# to move at all (already overlapping something).
	if fractions.size() < 1:
		return global_position
	var landed := global_position + dir * distance * fractions[0]
	return landed if _finite(landed) else global_position


# Vampiric nova: drain nearby enemies to heal.
func _active_blood_siphon(world: Node) -> void:
	var radius := 130.0
	var dmg := 22.0 * get_outgoing_damage_mult()
	var healed := 0.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= radius and e.has_method("take_damage"):
			e.take_damage(dmg, global_position)
			healed += dmg * 0.3
	if healed > 0.0:
		health.heal(healed)
	GameManager.screen_impact(0.4)
	Juice.ring(world, global_position, Color(0.7, 0.1, 0.2, 0.9), radius, 0.4, 4.0)
	Juice.impact(world, global_position, Color(0.7, 0.1, 0.2), 22, 1.8)
	AudioManager.play("heavy", -2.0)


# --- Dash --------------------------------------------------------------
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


func _start_dash() -> void:
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
	_dash_img_timer = 0.0
	_knockback = Vector2.ZERO
	hurtbox.invulnerable = true  # i-frames during the dash
	sprite.modulate = Color(0.7, 0.9, 1.0)
	# Anticipation stretch along the dash, a dust kick behind, and a ground ring.
	Juice.stretch(sprite, _base_sprite_scale, 0.25, 0.16)
	var world := get_tree().current_scene
	Juice.spark(world, global_position, -_dash_dir, Color(0.8, 0.85, 0.95, 0.8), 8, 0.7)
	Juice.ring(world, global_position, Color(0.7, 0.9, 1.0, 0.7), 26.0, 0.3)
	AudioManager.play("dash")


func _end_dash() -> void:
	_is_dashing = false
	hurtbox.invulnerable = false
	sprite.modulate = Color.WHITE
	# Plant the landing.
	Juice.squash(sprite, _base_sprite_scale, 0.2, 0.22)


## Shove the player a short distance toward `dir` (called by WeaponController on
## attack so swings feel like they have weight). Implemented via the knockback
## channel so it integrates with movement and decays.
func lunge(dir: Vector2, force: float) -> void:
	if _is_dashing or dir.length() < 0.01:
		return
	_knockback = dir.normalized() * force


func get_dash_ratio() -> float:
	# 1.0 = ready, 0.0 = just used.
	if dash_cooldown <= 0.0:
		return 1.0
	return clampf(1.0 - _dash_cd_timer / dash_cooldown, 0.0, 1.0)


# --- Corrupted Aura upgrade -------------------------------------------
func _update_aura(delta: float) -> void:
	if not aura_enabled:
		return
	_aura_timer += delta
	if _aura_timer < AURA_INTERVAL:
		return
	_aura_timer = 0.0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= AURA_RADIUS and enemy.has_method("take_damage"):
			enemy.take_damage(AURA_DAMAGE, global_position)
	Juice.impact(get_tree().current_scene, global_position, Color(0.5, 0.1, 0.6), 16, 1.6)


# --- Corruption --------------------------------------------------------
func add_corruption(amount: float) -> void:
	corruption = clampf(corruption + amount, 0.0, max_corruption)
	on_stats_changed()
	corruption_changed.emit(corruption, max_corruption)
	# Crossing into a worse tier is a moment — flash, sting, particles.
	var tier := get_corruption_tier()
	if tier != _last_tier and amount > 0.0:
		_on_tier_up(tier)
	_last_tier = tier


func _on_tier_up(tier: String) -> void:
	GameManager.screen_impact(0.6)
	GameManager.shake_camera(0.25)
	AudioManager.play("telegraph", -2.0, 0.7)
	var world := get_tree().current_scene
	Juice.ring(world, global_position, Color(0.6, 0.1, 0.7, 0.9), 60.0, 0.5, 3.0)
	Juice.impact(world, global_position, Color(0.5, 0.1, 0.6), 22, 1.8)
	Juice.floating_text(world, global_position, tier.to_upper(), Color(0.85, 0.4, 1.0), 18)


func get_corruption_tier() -> String:
	if corruption < 25.0:
		return "Stable"
	elif corruption < 50.0:
		return "Tainted"
	elif corruption < 75.0:
		return "Corrupted"
	return "Overloaded"


# Corruption is a knife's edge: it pays more damage the deeper you go, but the
# damage you TAKE climbs faster than the damage you deal — so Overloaded is a
# genuine gamble, not a free buff. (Corrupted-elite spawn chance also scales.)
func _corruption_damage_mult() -> float:
	if corruption >= 75.0:
		return 1.22
	elif corruption >= 50.0:
		return 1.12
	elif corruption >= 25.0:
		return 1.05
	return 1.0


func _corruption_taken_mult() -> float:
	if corruption >= 75.0:
		return 1.4
	elif corruption >= 50.0:
		return 1.18
	elif corruption >= 25.0:
		return 1.06
	return 1.0


func get_outgoing_damage_mult() -> float:
	var m := _corruption_damage_mult() * glass_damage_mult
	# Berserker upgrade: extra damage while badly wounded.
	if berserker_enabled and health and health.get_ratio() < 0.4:
		m *= 1.3
	return m


## Recompute everything that depends on corruption / upgrades. Safe to call
## any time a stat changes.
func on_stats_changed() -> void:
	hurtbox.damage_multiplier = _corruption_taken_mult() * glass_taken_mult
	if weapon:
		weapon.set_corruption_level(corruption)
	# The HUD used to refresh only from _on_health_changed, so the corruption
	# meter sat at its last value until the player happened to take damage —
	# taking an upgrade visibly charged you nothing until your next hit.
	_refresh_hud()
	stats_changed.emit()


func on_enemy_killed() -> void:
	if heal_on_kill > 0.0:
		health.heal(heal_on_kill)


# --- Items & synergies -------------------------------------------------
## Record an owned item and recompute synergies. `last_new_synergies` is filled
## with the display names of any synergy that just turned on (for a HUD toast).
func add_item(def: Dictionary) -> void:
	items.append(def)
	var before := _synergies.duplicate()
	_resolve_synergies()
	last_new_synergies = []
	for s in _synergies:
		if not before.has(s):
			last_new_synergies.append(SYNERGY_NAMES.get(s, s))


func has_item(id: String) -> bool:
	for d in items:
		if d.get("id", "") == id:
			return true
	return false


# Pairs of owned items fuse into an emergent bonus (Vampire-Survivors style).
const SYNERGY_NAMES := {
	"plasma": "Plasma Arc", "glacial": "Glacial Echo",
	"cyclone": "Cyclone", "harvest": "Soul Harvest",
}

## What each synergy actually does, for the [Tab] build screen. Without this the
## synergy toast names a thing you own and never explains it.
const SYNERGY_DESCS := {
	"plasma": "Chain bolts also ignite what they arc to",
	"glacial": "Slash waves chill hard on contact",
	"cyclone": "Whirlwind heavies throw slash waves outward",
	"harvest": "Execute threshold greatly increased",
}

## Descriptions for the single [E] ability slot, keyed by active_item id.
const ACTIVE_DESCS := {
	"forge_pulse": "Nova blast: damages and knocks back everything nearby",
	"phase_step": "Blink toward your aim with brief invulnerability",
	"blood_siphon": "Drain nearby enemies to heal yourself",
}


## Display names of every currently-active synergy — read by the build screen.
func synergy_names() -> Array:
	var out: Array = []
	for s in _synergies:
		out.append(SYNERGY_NAMES.get(s, s))
	return out


## [[name, description], ...] for every active synergy.
func synergy_entries() -> Array:
	var out: Array = []
	for s in _synergies:
		out.append([String(SYNERGY_NAMES.get(s, s)), String(SYNERGY_DESCS.get(s, ""))])
	return out


func active_description() -> String:
	return String(ACTIVE_DESCS.get(active_item, ""))

func _resolve_synergies() -> void:
	_synergies.clear()
	syn_plasma = has_item("ember_brand") and has_item("storm_coil")
	syn_glacial = has_item("echo_blade") and has_item("frost_bite")
	syn_cyclone = has_item("echo_blade") and has_item("whirlwind")
	syn_harvest = has_item("reapers_mark") and has_item("ember_brand")
	if syn_plasma: _synergies.append("plasma")
	if syn_glacial: _synergies.append("glacial")
	if syn_cyclone: _synergies.append("cyclone")
	if syn_harvest: _synergies.append("harvest")


## Effective execute HP ratio (Soul Harvest raises the threshold).
func get_execute_threshold() -> float:
	return execute_threshold * (1.6 if syn_harvest else 1.0)


# --- Knockback (called by HurtboxComponent) ---------------------------
func apply_knockback(direction: Vector2, force: float) -> void:
	if _is_dashing or not _finite(direction):
		return
	_knockback = direction * force * KNOCKBACK_TAKEN


# --- Feedback / HUD ----------------------------------------------------
func _on_hurt(_amount: float, source) -> void:
	GameManager.shake_camera(0.18)
	GameManager.screen_damage()
	# Kick the camera away from whatever hit us.
	if source != null and is_instance_valid(source) and source is Node2D:
		var away := (global_position - (source as Node2D).global_position)
		GameManager.camera_kick(away, 6.0)
	AudioManager.play("player_hurt")
	GameManager.break_combo()
	_refresh_hud()


func _on_health_changed(_a: float, _current: float, _max: float) -> void:
	_refresh_hud()


func _refresh_hud() -> void:
	if GameManager.hud and GameManager.hud.has_method("update_player_status"):
		GameManager.hud.update_player_status(self)


func _on_died() -> void:
	if _dead:
		return
	_dead = true
	hurtbox.invulnerable = true
	GameManager.shake_camera(0.6)
	GameManager.zoom_punch(0.12)
	GameManager.screen_impact(0.5)
	AudioManager.play("game_over")
	var world := get_tree().current_scene
	Juice.impact(world, global_position, Color(0.6, 0.1, 0.15), 26, 1.8)
	# A slow, desaturating fade on the body before the game-over screen.
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(0.4, 0.4, 0.45), 0.5)
	# Brief slow-mo to let the death land, then show the summary.
	GameManager.slow_mo(0.25, 0.7)
	await get_tree().create_timer(0.85, true, false, true).timeout
	if GameManager.hud and GameManager.hud.has_method("show_game_over"):
		GameManager.hud.show_game_over()


func _unhandled_input(event: InputEvent) -> void:
	# Allow a quick retry after death.
	if _dead and event.is_action_pressed("dash"):
		GameManager.restart_game()
