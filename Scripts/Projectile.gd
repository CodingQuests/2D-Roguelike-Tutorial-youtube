class_name Projectile
extends Area2D


@export var speed: float = 230.0
@export var damage: float = 10.0
@export var knockback_force: float = 140.0
@export var lifetime: float = 4.0

var source_node: Node = null

var _direction := Vector2.RIGHT
var _life := 0.0

func _ready() -> void:
	add_to_group("hitbox")
	body_entered.connect(_on_body_entered)

func setup(direction: Vector2, dmg: float, source: Node) -> void:
	_direction = direction.normalized()
	damage = dmg
	source_node = source
	rotation = _direction.angle()

func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta
	# A bolt that misses everything must still die, or a long run accumulates
	# hundreds of them flying off into nothing.
	_life += delta
	if _life >= lifetime:
		queue_free()
		
		
func _on_body_entered(_body: Node) -> void:
	_pop()

func on_hurtbox_hit() -> void:
	_pop()

func _pop() -> void:
	Juice.impact(get_tree().current_scene, global_position, Color(0.72, 0.42, 1.0), 8, 0.9)
	queue_free()
