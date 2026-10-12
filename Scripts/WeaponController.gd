class_name WeaponController
extends Node2D


enum State { IDLE, WINDUP, ACTIVE, RECOVERY }
const SLASH_WAVE := preload("res://Scenes/SlashWave.tscn")

@onready var weapon_sprite: Sprite2D = $WeaponSprite
@onready var attack_hitbox: HitboxComponent = $AttackHitbox
@onready var hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

var state: int = State.IDLE
var _state_timer := 0.0
var _cooldown := 0.0
var _current_is_heavy := false
var _player: PlayerController = null
const SWORD := 0
const SPEAR := 1
const DAGGERS := 2
const QUICK_HITSTOP := 0.04
const QUICK_SHAKE := 0.12
const HEAVY_HITSTOP := 0.07
const HEAVY_SHAKE := 0.5
var _base_weapon_scale := Vector2.ONE
const PROFILES := [
	{
		"name": "Corrupted Cleaver",
		"q_dmg": 20.0, "q_kb": 170.0, "q_active": 0.10, "q_cd": 0.35,
		"q_box": Vector2(46, 32), "q_off": 30.0,
		"h_dmg": 45.0, "h_kb": 290.0, "h_wind": 0.25, "h_active": 0.16, "h_cd": 0.90,
		"h_box": Vector2(64, 48), "h_off": 40.0,
	},
	{
		"name": "Cursed Pike",
		"q_dmg": 24.0, "q_kb": 160.0, "q_active": 0.10, "q_cd": 0.45,
		"q_box": Vector2(80, 18), "q_off": 48.0,
		"h_dmg": 50.0, "h_kb": 280.0, "h_wind": 0.30, "h_active": 0.16, "h_cd": 1.00,
		"h_box": Vector2(104, 24), "h_off": 60.0,
	},
	{
		"name": "Twin Fangs",
		"q_dmg": 12.0, "q_kb": 120.0, "q_active": 0.08, "q_cd": 0.18,
		"q_box": Vector2(34, 30), "q_off": 20.0,
		"h_dmg": 28.0, "h_kb": 200.0, "h_wind": 0.15, "h_active": 0.12, "h_cd": 0.60,
		"h_box": Vector2(42, 36), "h_off": 24.0,
	},
]
var available_weapons: Array = [SWORD, SPEAR]
var _slot: int = 0
var _is_whirl := false
var _base_weapon_rotation := 0.0

func _profile() -> Dictionary:
	return PROFILES[available_weapons[_slot]]
	
func swap() -> void:
	if available_weapons.size() < 2 or state != State.IDLE:
		return
	_slot = (_slot + 1) % available_weapons.size()
func _ready() -> void:
	_base_weapon_scale = weapon_sprite.scale
	_player = get_parent()
	_disable_hitbox()
	attack_hitbox.source_node = _player
	attack_hitbox.hit_landed.connect(_on_hit_landed)
	_base_weapon_rotation = weapon_sprite.rotation
func _enable_hitbox() -> void:
	attack_hitbox.monitoring = false
	attack_hitbox.set_deferred("monitorable", true)
	hitbox_shape.set_deferred("disabled", false)
	
func _disable_hitbox() -> void:
	hitbox_shape.set_deferred("disabled", true)
	attack_hitbox.set_deferred("monitorable", false)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	match state:
		State.WINDUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_begin_active()
		State.ACTIVE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_begin_recovery()
		State.RECOVERY:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.IDLE
		
func try_quick_attack() -> void:
	if state != State.IDLE or _cooldown > 0.0:
		return
	_current_is_heavy = false
	_cooldown = float(_profile()["q_cd"]) * _cd_mult()
	_begin_active()



func try_heavy_attack() -> void:
	if state != State.IDLE or _cooldown > 0.0:
		return
	_current_is_heavy = true
	var p := _profile()
	_cooldown = float(p["h_cd"]) * _cd_mult()
	state = State.WINDUP
	_state_timer = float(p["h_wind"])
		
		
func _begin_active() -> void:
	state = State.ACTIVE
	var p := _profile()
	_state_timer = float(p["h_active"]) if _current_is_heavy else float(p["q_active"])

	var size: Vector2 = p["h_box"] if _current_is_heavy else p["q_box"]
	var offset: float = float(p["h_off"]) if _current_is_heavy else float(p["q_off"])
	_is_whirl = _current_is_heavy and _player.whirlwind
	if _is_whirl:
		var d := 150.0
		size = Vector2(d, d)
		offset = 0.0
	(hitbox_shape.shape as RectangleShape2D).size = size
	hitbox_shape.position = Vector2(offset, 0)
	attack_hitbox.damage = _compute_damage()
	attack_hitbox.knockback_force = float(p["h_kb"]) if _current_is_heavy else float(p["q_kb"])
	attack_hitbox.reset_hits()
	
	var aim := global_transform.x.normalized()
	if _player and _player.has_method("lunge"):
		_player.lunge(aim, 210.0 if _current_is_heavy else 110.0)
	
	if _player.echo_level > 0:
		_throw_waves(global_transform.x.normalized())
	_enable_hitbox()
	Juice.squash(weapon_sprite, _base_weapon_scale, 0.2, 0.15)
	_animate_swing()
func _begin_recovery() -> void:
	_disable_hitbox()
	state = State.RECOVERY
	_state_timer = 0.2


func get_move_factor() -> float:
	match state:
		State.WINDUP:
			return 0.35
		State.ACTIVE:
			return 0.6 if _current_is_heavy else 0.85
		State.RECOVERY:
			return 0.8
		_:
			return 1.0
func is_busy() -> bool:
	return state != State.IDLE
	
func _compute_damage() -> float:
	var p := _profile()
	# Base from the weapon profile, heavy or quick depending on which swing this is.
	var base: float = float(p["h_dmg"]) if _current_is_heavy else float(p["q_dmg"])
	# Bonus off the player, the matching one. Add them.
	var bonus: float = _player.heavy_bonus_damage if _current_is_heavy else _player.quick_bonus_damage
	return (base + bonus) * _player.get_outgoing_damage_mult()

	
func _cd_mult() -> float:
	return _player.attack_cooldown_mult
	
func _on_hit_landed(_hurtbox: Node) -> void:
	AudioManager.play("hit")
	AudioManager.play("heavy" if _current_is_heavy else "slash")
	if _current_is_heavy:
		GameManager.hit_stop(HEAVY_HITSTOP)
		GameManager.shake_camera(HEAVY_SHAKE)
	else:
		GameManager.hit_stop(QUICK_HITSTOP)
		GameManager.shake_camera(QUICK_SHAKE)
	_apply_hit_effects(_hurtbox)

func _animate_swing() -> void:
	if _is_whirl:
		weapon_sprite.rotation = _base_weapon_rotation
		var wt := weapon_sprite.create_tween()
		wt.tween_property(weapon_sprite, "rotation",
			_base_weapon_rotation + TAU, _state_timer).set_trans(Tween.TRANS_QUAD)
		wt.tween_property(weapon_sprite, "rotation", _base_weapon_rotation, 0.06)
		return
	
	var arc := deg_to_rad(120) if _current_is_heavy else deg_to_rad(90)
	var dur := _state_timer if _current_is_heavy else _state_timer + 0.08
	weapon_sprite.rotation = _base_weapon_rotation - arc * 0.5
	var tw := weapon_sprite.create_tween()
	tw.tween_property(weapon_sprite, "rotation",
		_base_weapon_rotation + arc * 0.5, dur).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(weapon_sprite, "rotation", _base_weapon_rotation, 0.1)
	
	
func _apply_hit_effects(hurtbox: Node) -> void:
	var enemy := hurtbox.get_parent()
	if enemy == null or not is_instance_valid(enemy):
		return
	if _player.burn_dps > 0.0 and enemy.has_method("ignite"):
		enemy.ignite(_player.burn_dps, 3.0)
	if _player.chill_factor > 0.0 and enemy.has_method("chill"):
		enemy.chill(_player.chill_factor, 2.0)
	if _player.execute_threshold > 0.0 and enemy is EnemyBase:
		if enemy.health.get_ratio() <= _player.get_execute_threshold():
			enemy.die()
	if _player.chain_count > 0:
		_chain_to_nearby(enemy, _player.chain_count)
	if _player.twin_strike and enemy is EnemyBase and enemy.health.is_alive():
		enemy.take_damage(_compute_damage() * 0.5, _player.global_position)
func _chain_to_nearby(origin: Node, count: int) -> void:
	var hit := {origin: true}
	var from: Node2D = origin
	for i in range(count):
		var best: Node2D = null
		var best_d := 220.0
		for e in get_tree().get_nodes_in_group("enemy"):
			if not is_instance_valid(e) or e.is_queued_for_deletion() or hit.has(e):
				continue
			if not (e is EnemyBase) or e.state == EnemyBase.State.DEAD:
				continue
			
			var d: float = from.global_position.distance_to(e.global_position)
			if d < best_d:
				best_d = d
				best = e
		if best == null:
			return
		hit[best] = true
		if best.has_method("take_damage"):
			best.take_damage(_compute_damage() * 0.5, from.global_position)
		# Plasma synergy: chain bolts also ignite what they arc to.
		if _player.syn_plasma and best.has_method("ignite"):
			best.ignite(_player.burn_dps, 3.0)
		# Next hop measures from the enemy just hit. A chain, not a burst.
		from = best

func _throw_waves(aim: Vector2) -> void:
	var count: int = _player.echo_level
	var as_ring: bool = _is_whirl and _player.syn_cyclone
	# A cyclone whirlwind bumps the count to at least eight, spread round a full
	# circle. Otherwise two or more get fanned across 36 degrees with lerpf.
	if as_ring:
		count = maxi(count * 4, 8)
	for i in range(count):
		var dir := aim
		if as_ring:
			dir = Vector2.RIGHT.rotated(TAU * float(i) / float(count))
		elif count > 1:
			dir = aim.rotated(deg_to_rad(lerpf(-18.0, 18.0, float(i) / float(count - 1))))
		# configure() first, then copy burn and chill across. Three quarters
		# damage, so the wave is a bit weaker than the sword.
		var w := SLASH_WAVE.instantiate()
		w.configure(dir, _compute_damage() * 0.75, _player)
		w.burn_dps = _player.burn_dps
		# Glacial: Echo + Frost makes the waves chill twice as hard.
		w.chill_factor = _player.chill_factor * (2.0 if _player.syn_glacial else 1.0)
		# Under the projectiles node if there is one, the current scene if not.
		var container := get_tree().get_first_node_in_group("projectiles")
		if container == null: container = get_tree().current_scene
		container.add_child(w)
		# After add_child. Out of the tree, global position means nothing.
		w.global_position = global_position
		
func set_available(list: Array) -> void:
	# A call that passes nothing can't leave the player with no weapon at all.
	if list.is_empty():
		return
	# Our own copy, so nothing still holding the original can change it under us.
	available_weapons = list.duplicate()
	_slot = 0
