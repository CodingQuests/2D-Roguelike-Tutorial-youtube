class_name BruteEnemy
extends EnemyBase
## Heavy tank. Slow, lots of HP, and a big slow telegraphed slam that hits hard
## and knocks you far. Punishes greed; reward is dodging the long wind-up.

@export var attack_range: float = 55.0
@export var attack_cooldown: float = 1.6
@export var telegraph_time: float = 0.6
@export var attack_active_time: float = 0.2
@export var recovery_time: float = 0.7

var _cd: float = 0.0


func _on_ready() -> void:
	max_health = 120.0
	speed = 55.0
	attack_damage = 25.0
	attack_knockback = 420.0
	health.max_health = max_health
	health.current_health = max_health
	glow_color = Color(1.0, 0.55, 0.2)
	glow_energy = 0.60
	glow_scale = 0.85
	state = State.CHASE


func _ai_process(delta: float) -> void:
	if _cd > 0.0:
		_cd -= delta

	match state:
		State.IDLE, State.CHASE:
			velocity = dir_to_player() * speed
			if has_player() and distance_to_player() <= attack_range and _cd <= 0.0:
				_enter_telegraph()
		State.TELEGRAPH:
			velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_attack()
		State.ATTACK:
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_recovery()
		State.RECOVERY:
			velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.CHASE


func _enter_telegraph() -> void:
	state = State.TELEGRAPH
	state_timer = telegraph_time
	show_telegraph_circle(attack_range, Color(1, 0.1, 0.1, 0.4))
	AudioManager.play("telegraph", -6.0)


func _enter_attack() -> void:
	hide_telegraph()
	state = State.ATTACK
	state_timer = attack_active_time
	var dir := dir_to_player()
	enable_attack_area(dir * 28.0, 32.0)
	velocity = dir * 90.0  # heavy lunge
	GameManager.shake_camera(0.28)
	AudioManager.play("heavy", -2.0)


func _enter_recovery() -> void:
	_disable_attack_area()
	state = State.RECOVERY
	state_timer = recovery_time
	_cd = attack_cooldown
