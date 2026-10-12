class_name BruteEnemy
extends EnemyBase
## Heavy tank. Slow, lots of HP, and a big slow telegraphed slam that hits hard
## and knocks you far. Punishes greed; the reward is dodging the long wind-up.

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
			# Plants its feet harder than the grunt does - it is committing to a
			# slam, and the long stop is what makes the wind-up readable.
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
	show_telegraph_circle(attack_range * 1.05, Color(1, 0.35, 0.1, 0.5))


func _enter_attack() -> void:
	hide_telegraph()
	state = State.ATTACK
	state_timer = attack_active_time
	var dir := dir_to_player()
	# Wider and further than the grunt's swing - it is a slam, not a poke.
	enable_attack_area(dir * 28.0, 34.0)
	velocity = dir * 70.0


func _enter_recovery() -> void:
	_disable_attack_area()
	state = State.RECOVERY
	state_timer = recovery_time
	_cd = attack_cooldown
