extends CharacterBody2D
## TEMPORARY. A thing to hit, so the damage system can be proved to work before
## real enemies exist.
##
## Note what isn't in this file: any health logic, and any check for whose
## attack just landed. It owns a HealthComponent and a HurtboxComponent and
## listens for one signal. Chapter 3 replaces it with EnemyBase.

const KNOCKBACK_DECAY := 1700.0

@onready var health: HealthComponent = $Health

var _knockback := Vector2.ZERO


func _ready() -> void:
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	velocity = _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	move_and_slide()


func apply_knockback(dir: Vector2, force: float) -> void:
	_knockback = dir.normalized() * force


func _on_died() -> void:
	queue_free()
