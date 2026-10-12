class_name SkitterlingEnemy
extends EnemyBase
## Fast, fragile swarmer. Individually trivial - two of them plus anything else
## is the problem, because they take away the space you were going to dodge into.

@export var attack_range: float = 28.0
@export var attack_cooldown: float = 0.6
@export var telegraph_time: float = 0.18
@export var attack_active_time: float = 0.1
@export var recovery_time: float = 0.2
@export var weave_amount: float = 0.45

var _cd: float = 0.0
## Random starting phase. Without it a group weaves in sync and reads as one
## big organism instead of a swarm.
var _weave_phase: float = 0.0
var _weave_time: float = 0.0


func _on_ready() -> void:
	max_health = 18.0
	speed = 140.0
	attack_damage = 7.0
	attack_knockback = 120.0
	health.max_health = max_health
	health.current_health = max_health
	_weave_phase = randf() * TAU
	state = State.CHASE


func _ai_process(delta: float) -> void:
	if _cd > 0.0:
		_cd -= delta
	_weave_time += delta

	match state:
		State.IDLE, State.CHASE:
			var dir := dir_to_player()
			# Weave sideways as it closes, so it is awkward to line up a swing on.
			var wobble := dir.orthogonal() * sin(_weave_time * 7.0 + _weave_phase) * weave_amount
			velocity = (dir + wobble).normalized() * speed
			if has_player() and distance_to_player() <= attack_range and _cd <= 0.0:
				_enter_telegraph()
		State.TELEGRAPH:
			velocity = velocity.move_toward(Vector2.ZERO, 900 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_attack()
		State.ATTACK:
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_recovery()
		State.RECOVERY:
			# Backs off after biting, which is what lets a group cycle at you.
			velocity = -dir_to_player() * speed * 0.5
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.CHASE


func _enter_telegraph() -> void:
	state = State.TELEGRAPH
	state_timer = telegraph_time
	show_telegraph_circle(attack_range * 0.8, Color(0.6, 1, 0.4, 0.45))


func _enter_attack() -> void:
	hide_telegraph()
	state = State.ATTACK
	state_timer = attack_active_time
	var dir := dir_to_player()
	enable_attack_area(dir * 14.0, 13.0)
	velocity = dir * 160.0


func _enter_recovery() -> void:
	_disable_attack_area()
	state = State.RECOVERY
	state_timer = recovery_time
	_cd = attack_cooldown
