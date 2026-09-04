class_name WeaponController
extends Node2D
## Lives on the player's WeaponPivot. Owns the two-attack state machine (quick +
## heavy), the attack hitbox, the swing visual and the corruption look. Now
## data-driven: it holds several weapon PROFILES (sword / spear / daggers) and
## you swap between the ones you've unlocked. Each profile changes damage,
## cadence, reach and hitbox shape, so weapons feel distinct.

enum State { IDLE, WINDUP, ACTIVE, RECOVERY }

const SWORD_TEX := preload("res://Assets/Tiles/tile_0105.png")
const SPEAR_TEX := preload("res://Assets/Tiles/tile_0107.png")
const DAGGER_TEX := preload("res://Assets/Tiles/tile_0103.png")
const SLASH_WAVE_SCENE := preload("res://scenes/SlashWave.tscn")
const SLASH_SHADER := preload("res://shaders/fx_slash.gdshader")
const SLASH_QUAD := preload("res://fx_quad.tres")

# Weapon profiles. Index matches WEAPON_* ids below.
const SWORD := 0
const SPEAR := 1
const DAGGERS := 2
const PROFILES := [
	{
		"name": "Corrupted Cleaver", "tex": SWORD_TEX,
		"q_dmg": 20.0, "q_kb": 170.0, "q_active": 0.10, "q_cd": 0.35, "q_box": Vector2(46, 32), "q_off": 30.0,
		"h_dmg": 45.0, "h_kb": 290.0, "h_wind": 0.25, "h_active": 0.16, "h_cd": 0.90, "h_box": Vector2(64, 48), "h_off": 40.0,
	},
	{
		"name": "Cursed Pike", "tex": SPEAR_TEX,
		"q_dmg": 24.0, "q_kb": 160.0, "q_active": 0.10, "q_cd": 0.45, "q_box": Vector2(80, 18), "q_off": 48.0,
		"h_dmg": 50.0, "h_kb": 280.0, "h_wind": 0.30, "h_active": 0.16, "h_cd": 1.00, "h_box": Vector2(104, 24), "h_off": 60.0,
	},
	{
		"name": "Twin Fangs", "tex": DAGGER_TEX,
		"q_dmg": 12.0, "q_kb": 120.0, "q_active": 0.08, "q_cd": 0.18, "q_box": Vector2(34, 30), "q_off": 20.0,
		"h_dmg": 28.0, "h_kb": 200.0, "h_wind": 0.15, "h_active": 0.12, "h_cd": 0.60, "h_box": Vector2(42, 36), "h_off": 24.0,
	},
]

const QUICK_HITSTOP := 0.04
const QUICK_SHAKE := 0.12
const HEAVY_HITSTOP := 0.07
const HEAVY_SHAKE := 0.5

@onready var weapon_sprite: Sprite2D = $WeaponSprite
@onready var attack_hitbox: HitboxComponent = $AttackHitbox
@onready var hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var corruption_fx: CPUParticles2D = $CorruptionFX
@onready var weapon_glow: PointLight2D = $WeaponGlow

## Weapon ids the player has unlocked; swap cycles through these.
var available_weapons: Array = [SWORD, SPEAR]
var _slot: int = 0  # index into available_weapons

var state: int = State.IDLE
var _state_timer := 0.0
var _cooldown := 0.0
var _current_is_heavy := false
var _player: Node = null
var _base_sprite_rotation := 0.0
var _slash_color := Color(0.9, 0.95, 1.0)
var _corruption := 0.0
var _trail: Line2D = null
var _trail_radius := 0.0
var _is_whirl := false  # this swing is a Maelstrom whirlwind


func _ready() -> void:
	_player = get_parent()
	_base_sprite_rotation = weapon_sprite.rotation
	_disable_hitbox()
	attack_hitbox.source_node = _player
	attack_hitbox.hit_landed.connect(_on_hit_landed)
	if corruption_fx:
		corruption_fx.emitting = false
	_apply_weapon_visual()


func _profile() -> Dictionary:
	return PROFILES[available_weapons[_slot]]


func get_weapon_name() -> String:
	return _profile()["name"]


func set_available(weapons: Array) -> void:
	if weapons.is_empty():
		weapons = [SWORD]
	available_weapons = weapons
	_slot = 0
	_apply_weapon_visual()


func swap() -> void:
	if available_weapons.size() < 2 or state != State.IDLE:
		return
	_slot = (_slot + 1) % available_weapons.size()
	_apply_weapon_visual()
	AudioManager.play("dash", -4.0)


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
			_update_trail()
			if _state_timer <= 0.0:
				_begin_recovery()
		State.RECOVERY:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.IDLE


func is_busy() -> bool:
	return state != State.IDLE


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
	_cooldown = float(_profile()["h_cd"]) * _cd_mult()
	state = State.WINDUP
	_state_timer = float(_profile()["h_wind"])
	AudioManager.play("telegraph", -8.0)
	var tw := weapon_sprite.create_tween()
	tw.tween_property(weapon_sprite, "rotation", _base_sprite_rotation - deg_to_rad(70), _state_timer)


func _begin_active() -> void:
	state = State.ACTIVE
	var p := _profile()
	_state_timer = float(p["h_active"]) if _current_is_heavy else float(p["q_active"])

	var scale_factor: float = _player.hitbox_scale if ("hitbox_scale" in _player) else 1.0
	var size: Vector2 = (p["h_box"] if _current_is_heavy else p["q_box"]) * scale_factor
	var offset: float = (float(p["h_off"]) if _current_is_heavy else float(p["q_off"])) * scale_factor
	# Maelstrom: a heavy swing becomes a 360 whirlwind — a big hitbox ringing the
	# player instead of a directional arc.
	_is_whirl = _current_is_heavy and ("whirlwind" in _player) and _player.whirlwind
	if _is_whirl:
		var d := 150.0 * scale_factor
		size = Vector2(d, d)
		offset = 0.0
	(hitbox_shape.shape as RectangleShape2D).size = size
	hitbox_shape.position = Vector2(offset, 0)
	attack_hitbox.damage = _compute_damage()
	attack_hitbox.knockback_force = float(p["h_kb"]) if _current_is_heavy else float(p["q_kb"])
	# Heavy swings (and any swing while badly corrupted) read as crits.
	attack_hitbox.is_crit = _current_is_heavy or _corruption >= 50.0
	attack_hitbox.reset_hits()
	_enable_hitbox()

	# Lunge the player forward along the aim so the swing carries weight.
	var aim := global_transform.x.normalized()
	if _player and _player.has_method("lunge"):
		_player.lunge(aim, 210.0 if _current_is_heavy else 110.0)

	_trail_radius = offset + size.x * 0.5
	_start_trail()
	_spawn_slash(offset, size)
	_animate_swing(_current_is_heavy)
	_fire_echo()
	AudioManager.play("heavy" if _current_is_heavy else "slash")


func _begin_recovery() -> void:
	_disable_hitbox()
	_end_trail()
	state = State.RECOVERY
	var p := _profile()
	var spent := (float(p["h_wind"]) + float(p["h_active"])) if _current_is_heavy else float(p["q_active"])
	var total := (float(p["h_cd"]) if _current_is_heavy else float(p["q_cd"])) * _cd_mult()
	_state_timer = maxf(0.05, total - spent)


func _cd_mult() -> float:
	return _player.attack_cooldown_mult if (_player and "attack_cooldown_mult" in _player) else 1.0


func _compute_damage() -> float:
	var p := _profile()
	var base: float = float(p["h_dmg"]) if _current_is_heavy else float(p["q_dmg"])
	var bonus := 0.0
	if _current_is_heavy:
		bonus = _player.heavy_bonus_damage if ("heavy_bonus_damage" in _player) else 0.0
	else:
		bonus = _player.quick_bonus_damage if ("quick_bonus_damage" in _player) else 0.0
	var mult: float = _player.get_outgoing_damage_mult() if _player.has_method("get_outgoing_damage_mult") else 1.0
	return (base + bonus) * mult


func _on_hit_landed(hurtbox: Node) -> void:
	# Combo pitch ramp: chained kills push the hit sound higher.
	var pitch := 1.0 + minf(GameManager.combo, 10) * 0.03
	AudioManager.play("hit", 0.0, pitch)
	if _player and "heal_on_hit" in _player and _player.heal_on_hit > 0.0:
		_player.health.heal(_player.heal_on_hit)

	var aim := global_transform.x.normalized()
	# Sparks fly off the contact point along the swing.
	var contact: Vector2 = (hurtbox as Node2D).global_position if hurtbox is Node2D else global_position
	Juice.spark(get_tree().current_scene, contact, aim, _slash_color, 6 if not _current_is_heavy else 10, 1.0 if not _current_is_heavy else 1.4)
	# Every hit briefly lights the point of contact. In a torch-lit room this
	# does more for impact than another handful of particles.
	Juice.light_flash(get_tree().current_scene, contact, _slash_color,
		1.0 if _current_is_heavy else 0.6,
		0.8 if _current_is_heavy else 0.5,
		0.18 if _current_is_heavy else 0.12)

	# Item-driven on-hit effects (burn / chill / chain / execute / twin strike).
	_apply_hit_effects(hurtbox)

	if _current_is_heavy:
		GameManager.hit_stop(HEAVY_HITSTOP)
		GameManager.shake_camera(HEAVY_SHAKE)
		GameManager.camera_kick(aim, 7.0)
		GameManager.zoom_punch(0.05)
		GameManager.screen_impact(0.35)
		GameManager.shockwave(contact, 1.0)
		AudioManager.thump(-4.0)
	else:
		GameManager.hit_stop(QUICK_HITSTOP)
		GameManager.shake_camera(QUICK_SHAKE)
		GameManager.camera_kick(aim, 3.0)


# --- Hitbox enable/disable --------------------------------------------
func _enable_hitbox() -> void:
	attack_hitbox.monitoring = false
	attack_hitbox.set_deferred("monitorable", true)
	hitbox_shape.set_deferred("disabled", false)


func _disable_hitbox() -> void:
	hitbox_shape.set_deferred("disabled", true)
	attack_hitbox.set_deferred("monitorable", false)


# --- Visuals -----------------------------------------------------------
func _apply_weapon_visual() -> void:
	weapon_sprite.texture = _profile()["tex"]
	set_corruption_level(_corruption)


func _animate_swing(is_heavy: bool) -> void:
	var p := _profile()
	# Whirlwind: spin the blade a full turn and ring the player.
	if _is_whirl:
		weapon_sprite.rotation = _base_sprite_rotation
		var wt := weapon_sprite.create_tween()
		wt.tween_property(weapon_sprite, "rotation", _base_sprite_rotation + TAU, float(p["h_active"])).set_trans(Tween.TRANS_QUAD)
		wt.tween_property(weapon_sprite, "rotation", _base_sprite_rotation, 0.06)
		if _player:
			Juice.ring(get_tree().current_scene, _player.global_position, _slash_color, 80.0, 0.3, 4.0)
		return
	var arc := deg_to_rad(120) if is_heavy else deg_to_rad(90)
	weapon_sprite.rotation = _base_sprite_rotation - arc * 0.5
	var dur := float(p["h_active"]) if is_heavy else float(p["q_active"]) + 0.08
	var tw := weapon_sprite.create_tween()
	tw.tween_property(weapon_sprite, "rotation", _base_sprite_rotation + arc * 0.5, dur).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(weapon_sprite, "rotation", _base_sprite_rotation, 0.1)


# --- Item on-hit effects ----------------------------------------------
func _apply_hit_effects(hurtbox: Node) -> void:
	var enemy: Node = (hurtbox as Node).get_parent() if hurtbox else null
	if enemy == null or not is_instance_valid(enemy):
		return
	var p := _player
	if p == null:
		return
	if ("burn_dps" in p) and p.burn_dps > 0.0 and enemy.has_method("ignite"):
		enemy.ignite(p.burn_dps, 3.0)
	if ("chill_factor" in p) and p.chill_factor > 0.0 and enemy.has_method("chill"):
		enemy.chill(p.chill_factor, 2.0)
	# Execute: finish off low-health enemies outright.
	if p.has_method("get_execute_threshold") and ("health" in enemy) and enemy.health:
		var thr: float = p.get_execute_threshold()
		if thr > 0.0 and enemy.health.is_alive() and enemy.health.get_ratio() < thr:
			Juice.floating_text(get_tree().current_scene, enemy.global_position, "EXECUTE", Color(1, 0.3, 0.3), 16)
			GameManager.hit_stop(0.05)
			enemy.health.damage(enemy.health.current_health + 1.0)
			return
	# Chain lightning: arc to nearby enemies.
	if ("chain_count" in p) and p.chain_count > 0:
		_chain_from(enemy, p.chain_count)
	# Twin strike: a quick second blow on the same target.
	if ("twin_strike" in p) and p.twin_strike and enemy.has_method("take_damage"):
		_second_hit(enemy, _compute_damage() * 0.55)


func _chain_from(primary: Node, count: int) -> void:
	var origin: Vector2 = (primary as Node2D).global_position
	var dmg := _compute_damage() * 0.4
	var ignite_too: bool = ("syn_plasma" in _player) and _player.syn_plasma
	var pool: Array = []
	for e in get_tree().get_nodes_in_group("enemy"):
		if e == primary or not is_instance_valid(e) or not e.has_method("take_damage"):
			continue
		var d: float = origin.distance_to((e as Node2D).global_position)
		if d < 190.0:
			pool.append([d, e])
	pool.sort_custom(func(a, b): return a[0] < b[0])
	for i in mini(count, pool.size()):
		var e = pool[i][1]
		var pos: Vector2 = (e as Node2D).global_position
		e.take_damage(dmg, origin)
		_bolt(origin, pos)
		if ignite_too and e.has_method("ignite"):
			e.ignite(_player.burn_dps if ("burn_dps" in _player) else 6.0, 2.0)
		origin = pos


func _bolt(a: Vector2, b: Vector2) -> void:
	var line := Line2D.new()
	line.width = 2.5
	line.default_color = Color(0.7, 0.9, 1.0, 0.9)
	line.add_point(a)
	line.add_point(b)
	line.z_index = 6
	get_tree().current_scene.add_child(line)
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.18)
	tw.tween_callback(line.queue_free)


func _second_hit(enemy: Node, dmg: float) -> void:
	await get_tree().create_timer(0.07).timeout
	if is_instance_valid(enemy) and enemy.has_method("take_damage"):
		enemy.take_damage(dmg, global_position)


# --- Echo Blade: throw slash waves on every swing ----------------------
func _fire_echo() -> void:
	if not ("echo_level" in _player) or _player.echo_level <= 0:
		return
	var aim := global_transform.x.normalized()
	var dmg := _compute_damage() * 0.55
	var dirs: Array = []
	if _is_whirl and ("syn_cyclone" in _player) and _player.syn_cyclone:
		for i in 8:
			dirs.append(Vector2.RIGHT.rotated(TAU * i / 8.0))
	else:
		var n: int = _player.echo_level
		var spread := deg_to_rad(15)
		for i in n:
			var t := 0.0 if n <= 1 else lerpf(-1.0, 1.0, float(i) / float(n - 1))
			dirs.append(aim.rotated(spread * t))
	for d in dirs:
		_spawn_wave(d, dmg)


func _spawn_wave(dir: Vector2, dmg: float) -> void:
	var w: SlashWave = SLASH_WAVE_SCENE.instantiate()
	w.configure(dir, dmg, _player, _slash_color)
	w.is_crit = _current_is_heavy
	if "burn_dps" in _player:
		w.burn_dps = _player.burn_dps
	var chill: float = _player.chill_factor if ("chill_factor" in _player) else 0.0
	if ("syn_glacial" in _player) and _player.syn_glacial:
		chill = maxf(chill, 0.55)
	w.chill_factor = chill
	get_tree().current_scene.add_child(w)
	w.global_position = _player.global_position + dir * 18.0


# --- Blade-tip motion trail -------------------------------------------
func _start_trail() -> void:
	_trail = Line2D.new()
	_trail.width = 7.0
	_trail.default_color = Color(_slash_color.r * 1.2, _slash_color.g * 1.2, _slash_color.b * 1.2, 0.85)
	# A blade trail should be widest and brightest at the tip and taper to
	# nothing at the oldest point. A uniform-width Line2D reads as a drawn
	# stroke; this reads as motion.
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.05))
	curve.add_point(Vector2(0.65, 0.55))
	curve.add_point(Vector2(1.0, 1.0))
	_trail.width_curve = curve
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([
		Color(_slash_color.r, _slash_color.g, _slash_color.b, 0.0),
		Color(_slash_color.r, _slash_color.g, _slash_color.b, 0.5),
		Color(1.0, 1.0, 1.0, 0.95),
	])
	_trail.gradient = grad
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.light_mask = 0
	_trail.z_index = 4
	add_child(_trail)


func _update_trail() -> void:
	if _trail == null:
		return
	var sweep := weapon_sprite.rotation - _base_sprite_rotation
	_trail.add_point(Vector2(cos(sweep), sin(sweep)) * _trail_radius)
	if _trail.get_point_count() > 12:
		_trail.remove_point(0)


func _end_trail() -> void:
	if _trail == null:
		return
	var t := _trail
	_trail = null
	var tw := t.create_tween()
	tw.tween_property(t, "modulate:a", 0.0, 0.16)
	tw.tween_callback(t.queue_free)


## The swing arc — the most-seen effect in the game, so it gets a real shader
## rather than a flat translucent wedge.
##
## The quad is parented to the weapon pivot (so it inherits the aim rotation)
## and the shader SWEEPS the crescent across the arc over the swing's duration,
## with a hot leading edge and a fading trail. That travel is what sells "the
## blade went through here"; a polygon that simply appears never can.
func _spawn_slash(offset: float, size: Vector2) -> void:
	var reach := offset + size.x
	var fx := Sprite2D.new()
	fx.texture = SLASH_QUAD
	fx.z_index = 5
	fx.light_mask = 0
	fx.scale = Vector2.ONE * (reach * 2.0 / 64.0)
	var mat := ShaderMaterial.new()
	mat.shader = SLASH_SHADER
	# Brighter than the art so the WorldEnvironment glow catches the edge.
	mat.set_shader_parameter("color", Color(_slash_color.r * 1.35, _slash_color.g * 1.35, _slash_color.b * 1.35, 0.9))
	mat.set_shader_parameter("arc", 2.5 if _is_whirl else (2.0 if _current_is_heavy else 1.5))
	mat.set_shader_parameter("inner", clampf(offset / maxf(reach, 1.0), 0.05, 0.8))
	mat.set_shader_parameter("outer", 0.94)
	mat.set_shader_parameter("trail", 0.7 if _current_is_heavy else 0.5)
	mat.set_shader_parameter("progress", 0.0)
	fx.material = mat
	add_child(fx)
	var dur := 0.22 if _current_is_heavy else 0.16
	var tw := fx.create_tween()
	tw.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("progress", v),
		0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(fx.queue_free)




func set_corruption_level(corruption: float) -> void:
	_corruption = corruption
	var t := clampf(corruption / 100.0, 0.0, 1.0)
	weapon_sprite.modulate = Color(1, 1, 1).lerp(Color(0.55, 0.35, 0.75), t)
	if corruption < 50.0:
		_slash_color = Color(0.9, 0.95, 1.0).lerp(Color(0.7, 0.5, 1.0), corruption / 50.0)
	else:
		_slash_color = Color(0.7, 0.5, 1.0).lerp(Color(1.0, 0.25, 0.25), (corruption - 50.0) / 50.0)
	if corruption_fx:
		if corruption >= 25.0:
			corruption_fx.emitting = true
			corruption_fx.amount = int(lerpf(6, 22, t))
			corruption_fx.color = Color(0.4, 0.1, 0.5, 0.7)
		else:
			corruption_fx.emitting = false
	# The blade itself starts to glow as it corrupts — the clearest possible
	# read on "this thing is changing you", and it lights the floor around you.
	if weapon_glow:
		weapon_glow.energy = lerpf(0.0, 0.9, smoothstep(0.15, 1.0, t))
		weapon_glow.color = _slash_color
