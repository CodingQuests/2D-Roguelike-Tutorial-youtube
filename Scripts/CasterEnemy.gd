class_name CasterEnemy
extends EnemyBase

@export var preferred_distance: float = 180.0
@export var fire_cooldown: float = 1.5
@export var telegraph_time: float = 0.45
@export var recovery_time: float = 0.4
@export var projectile_damage: float = 10.0

const PROJECTILE_SCENE := preload("res://Scenes/Projectile.tscn")

var _cd: float = 0.0
var _aim_dir := Vector2.RIGHT


func _on_ready() -> void:
	max_health = 35.0
	speed = 80.0
	health.max_health = max_health
	health.current_health = max_health
	state = State.CHASE
	
	
func _ai_process(delta: float) -> void:
	if _cd > 0.0:
		_cd -= delta
	match state:
		State.IDLE, State.CHASE:
			_kite()
			if has_player() and _cd <= 0.0 and distance_to_player() <= preferred_distance + 140.0:
				_enter_telegraph()
		State.TELEGRAPH:
			velocity = velocity.move_toward(Vector2.ZERO, 600 * delta)
			_aim_dir = dir_to_player()
			# Keep the aim line tracking during the wind-up.
			show_telegraph_rect(minf(distance_to_player(), 280.0), 6.0, _aim_dir,
				Color(1, 0.2, 0.2, 0.5))
			state_timer -= delta
			if state_timer <= 0.0:
				_fire()
		State.RECOVERY:
			_kite()
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.CHASE

func _kite() -> void:
	if not has_player():
		velocity = Vector2.ZERO
		return
	var d := distance_to_player()
	var dir := dir_to_player()
	if d < preferred_distance - 30.0:
		velocity = -dir * speed
	elif d > preferred_distance + 30.0:
		velocity = dir * speed * 0.85
	else:
		velocity = dir.orthogonal() * speed * 0.5
		



func _enter_telegraph() -> void:
	state = State.TELEGRAPH
	state_timer = telegraph_time
	_cd = fire_cooldown
	
	
func hide_telegraph() -> void:
	telegraph.visible = false
	telegraph.position = Vector2.ZERO
	Juice.set_outline(sprite, false)
	
func _fire() -> void:
	hide_telegraph()
	state = State.RECOVERY
	state_timer = recovery_time
	_aim_dir = dir_to_player()
	var proj := PROJECTILE_SCENE.instantiate()
	var container := get_tree().get_first_node_in_group("projectiles")
	if container == null:
		container = get_tree().current_scene
	container.add_child(proj)
	proj.global_position = global_position + _aim_dir * 12.0
	proj.setup(_aim_dir, projectile_damage, self)
