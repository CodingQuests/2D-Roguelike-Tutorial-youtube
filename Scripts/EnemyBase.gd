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

signal defeated(enemy)

var state: int = State.IDLE
var state_timer: float = 0.0
var _knockback := Vector2.ZERO
var _player: Node2D = null

func _ready() -> void:
	health.died.connect(die)
	_on_ready()
	health.max_health = max_health
	health.current_health = max_health
	attack_area.source_node = self
	attack_area.damage = attack_damage
	attack_area.knockback_force = attack_knockback
	_disable_attack_area()
	
func _on_ready() -> void:
	pass

func _ai_process(_delta: float) -> void:
	pass
	
	
func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	_ai_process(delta)
	
	if _player and is_instance_valid(_player):
		sprite.flip_h = _player.global_position.x < global_position.x
		
	velocity += _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 1200 * delta)
	move_and_slide()
	
func apply_knockback(direction: Vector2, force: float) -> void:
	_knockback = direction * force
	
	

func die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	AudioManager.play("enemy_death")     # 2.5 promised this line a home
	defeated.emit(self)
	queue_free()
	

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
	
	
	
	
