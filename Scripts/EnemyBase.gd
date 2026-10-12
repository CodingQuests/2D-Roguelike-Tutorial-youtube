class_name EnemyBase
extends CharacterBody2D


enum State { IDLE, CHASE, TELEGRAPH, ATTACK, RECOVERY, DEAD }

@export var max_health: float = 50.0
@export var speed: float = 95.0
@export var attack_damage: float = 12.0
@export var attack_knockback: float = 180.0


@onready var sprite: Sprite2D = $Sprite2D
@onready var health: HealthComponent = $Health
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var attack_area: HitboxComponent = $HitboxComponent
@onready var attack_shape: CollisionShape2D = $HitboxComponent/CollisionShape2D
@onready var telegraph: Sprite2D = $Telegraph

signal defeated(enemy)

var state: int = State.IDLE
var state_timer: float = 0.0
var is_corrupted := false

var _knockback := Vector2.ZERO
var _player: Node2D = null
var _tele_elapsed := 0.0
var _hitstun := 0.0
var _spawning := false
var _base_sprite_scale := Vector2.ONE
var _circle_tele: Texture2D
var _rect_tele: Texture2D
var _burn_dps := 0.0
var _burn_time := 0.0
var _burn_tick := 0.0
var _chill_factor := 0.0
var _chill_time := 0.0


func _ready() -> void:
	health.died.connect(die)
	_on_ready()
	health.max_health = max_health
	health.current_health = max_health
	attack_area.source_node = self
	attack_area.damage = attack_damage
	attack_area.knockback_force = attack_knockback
	_disable_attack_area()
	_base_sprite_scale = sprite.scale
	_init_telegraph_textures()
	hide_telegraph()
func _on_ready() -> void:
	pass

func _ai_process(_delta: float) -> void:
	pass
	
	
func _physics_process(delta: float) -> void:
	var _ai_velocity := Vector2.ZERO
	if state == State.DEAD:
		return
	if _spawning:
		velocity = Vector2.ZERO
		if Engine.time_scale > 0.0:
			move_and_slide()
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	velocity = _ai_velocity
	_ai_process(delta)
	_ai_velocity = velocity
	_tick_status(delta)
	_tick_telegraph(delta)
	
	if state == State.DEAD:
		return
	if _hitstun > 0.0:
		_hitstun -= delta
		velocity = Vector2.ZERO
	if _player and is_instance_valid(_player):
		sprite.flip_h = _player.global_position.x < global_position.x
		
	if _chill_factor > 0.0:
		velocity *= (1.0 - _chill_factor)
	velocity += _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 1200 * delta)
	if Engine.time_scale > 0.0:
		move_and_slide()
	
func apply_knockback(direction: Vector2, force: float) -> void:
	if not (is_finite(direction.x) and is_finite(direction.y)):
		return
	_knockback = direction * force
	# Stun scales with the force, clamped so it's always brief.
	_hitstun = maxf(_hitstun, clampf(force / 1800.0, 0.08, 0.22))
	
	

func die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	
	_disable_attack_area()
	hide_telegraph()
	hurtbox.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	AudioManager.play("enemy_death")     # 2.5 promised this line a home
	defeated.emit(self)
	
	var world := get_tree().current_scene
	Juice.flash(sprite, Color.WHITE, 0.06)
	Juice.impact(world, global_position, Color(0.85, 0.2, 0.2), 12, 1.4)
	Juice.ring(world, global_position, Color(1.0, 0.5, 0.4, 0.7), 30.0, 0.3)
	Juice.set_outline(sprite, false)
	
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", scale * 1.25, 0.28)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.28)
	tw.chain().tween_callback(queue_free)
	

func player_pos() -> Vector2:
	return _player.global_position if (_player and is_instance_valid(_player)) else global_position
func has_player() -> bool:
	return _player != null and is_instance_valid(_player)

func dir_to_player() -> Vector2:
	var d := player_pos() - global_position
	return d.normalized() if d.length() > 0.001 else Vector2.RIGHT

func distance_to_player() -> float:
	return global_position.distance_to(player_pos())



func enable_attack_area(offset: Vector2, radius: float) -> void:
	(attack_shape.shape as CircleShape2D).radius = radius
	attack_shape.position = offset
	attack_area.damage = attack_damage
	attack_area.knockback_force = attack_knockback
	attack_area.reset_hits()
	attack_area.set_deferred("monitorable", true)
	attack_shape.set_deferred("disabled", false)
	
func _disable_attack_area() -> void:
	attack_area.set_deferred("monitorable", false)
	attack_shape.set_deferred("disabled", true)
	
	

func show_telegraph_circle(radius: float, color := Color(1, 0.15, 0.15, 0.5)) -> void:
	if not telegraph.visible:
		_tele_elapsed = 0.0 
		AudioManager.play("telegraph", -4.0)
	telegraph.position = Vector2.ZERO
	telegraph.texture = _circle_tele
	telegraph.rotation = 0.0
	telegraph.scale = Vector2.ONE * (radius * 2.0 / 64.0)
	telegraph.modulate = color
	telegraph.visible = true

func hide_telegraph() -> void:
	telegraph.visible = false
	telegraph.position = Vector2.ZERO
	Juice.set_outline(sprite, false)


func show_telegraph_rect(length: float, width: float, direction: Vector2,
		color := Color(1, 0.2, 0.2, 0.55)) -> void:
	if not telegraph.visible:
		_tele_elapsed = 0.0
		AudioManager.play("telegraph", -4.0)
		
	telegraph.texture = _rect_tele
	telegraph.rotation = direction.angle()
	telegraph.scale = Vector2(length / 64.0, width / 64.0)
	# The quad is centred, but the beam starts at the enemy — shift it forward.
	telegraph.position = Vector2(length * 0.5, 0).rotated(direction.angle())
	telegraph.modulate = color
	telegraph.visible = true
func _tick_telegraph(delta: float) -> void:
	if not telegraph.visible:
		return
	_tele_elapsed += delta
	var total := maxf(_tele_elapsed + maxf(state_timer, 0.0), 0.001)
	var fill := clampf(_tele_elapsed / total, 0.0, 1.0)
	telegraph.modulate.a = lerpf(0.25, 0.75, fill)
	

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
	tw.tween_property(sprite, "scale", _base_sprite_scale, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "modulate:a", keep.a, 0.25)
	tw.chain().tween_callback(func() -> void: _spawning = false)
	
	
func _init_telegraph_textures() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.96, Color.WHITE)
	var circle := GradientTexture2D.new()
	circle.width = 64
	circle.height = 64
	circle.gradient = gradient
	circle.fill = GradientTexture2D.FILL_RADIAL
	circle.fill_from = Vector2(0.5, 0.5)
	circle.fill_to = Vector2(1.0, 0.5)
	_circle_tele = circle
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_rect_tele = ImageTexture.create_from_image(img)

func show_charge_warning(travel: float, radius: float, direction: Vector2) -> void:
	show_telegraph_rect(travel + radius * 2.0, radius * 2.0, direction)
	telegraph.position = direction * travel * 0.5
	
func make_corrupted() -> void:
	# These are all multiplies, so calling it twice would make a double elite.
	if is_corrupted:
		return
	is_corrupted = true
	# Push the new max into the health component, max and current. This runs
	# before spawn_in, so it appears at full elite health, not healing up to it.
	max_health *= 1.6
	health.max_health = max_health
	health.current_health = max_health
	speed *= 1.15
	attack_damage *= 1.3
	# attack_area.damage is the thing that actually hits you. The enemy's own
	# field is just where it's kept.
	attack_area.damage = attack_damage
	# Violet tint and a pulsing violet outline. Never guess which one's the elite.
	sprite.modulate = Color(0.75, 0.45, 1.0)
	Juice.set_outline(sprite, true, Color(0.7, 0.2, 1.0), 1.0, true)

func take_damage(amount: float, from_pos: Vector2) -> void:
	if state == State.DEAD:
		return
	health.damage(amount)
	Juice.flash(sprite, Color.WHITE, 0.08)
	Juice.damage_number(get_tree().current_scene, global_position, amount, Color(1, 1, 1))
	apply_knockback((global_position - from_pos).normalized(), 70.0)
	
func ignite(dps: float, dur: float) -> void:
	if state == State.DEAD:
		return
	_burn_dps = maxf(_burn_dps, dps)
	_burn_time = maxf(_burn_time, dur)

func chill(factor: float, dur: float) -> void:
	if state == State.DEAD:
		return
	# Same shape as ignite, plus the 0.85 clamp again. Even fed a huge number,
	# the enemy still moves.
	_chill_factor = clampf(maxf(_chill_factor, factor), 0.0, 0.85)
	_chill_time = maxf(_chill_time, dur)
func _tick_status(delta: float) -> void:
	# Burn counts down every frame but only deals damage every quarter second.
	# A quarter of _burn_dps four times a second is the dps on the label.
	if _burn_time > 0.0:
		_burn_time -= delta
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick = 0.25
			health.damage(_burn_dps * 0.25)
		# Timer out: zero the strength so the next ignite starts clean.
		if _burn_time <= 0.0:
			_burn_dps = 0.0
	# Chill is just a timer here. The actual slow happens in _physics_process.
	if _chill_time > 0.0:
		_chill_time -= delta
		if _chill_time <= 0.0:
			_chill_factor = 0.0
			
