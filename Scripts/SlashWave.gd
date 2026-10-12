class_name SlashWave
extends Area2D


var speed: float = 430.0
var damage: float = 12.0
var knockback_force: float = 140.0
var lifetime: float = 0.6
var source_node: Node = null


var burn_dps: float = 0.0
var chill_factor: float = 0.0

var _direction := Vector2.RIGHT
var _life := 0.0
var _hit: Array = []

func configure(direction: Vector2, dmg: float, source: Node) -> void:
	_direction = direction.normalized()
	damage = dmg
	source_node = source
	# Turned to face the direction it flies.
	rotation = _direction.angle()
	
func _ready() -> void:
	add_to_group("hitbox")
	# body_entered with mask 1 means walls. Hit one and die.
	body_entered.connect(_on_body_entered)
	# A fade on modulate:a that lasts exactly the lifetime.
	create_tween().tween_property(self, "modulate:a", 0.0, lifetime)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		return
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta
	_life += delta
	# Freed at end of life, so the fade and the despawn land on the same frame.
	if _life >= lifetime:
		queue_free()
		
		
func try_register_hit(hurtbox: Node) -> bool:
	if _hit.has(hurtbox):
		return false
	_hit.append(hurtbox)
	# Remember it, hand burn and chill onto the enemy, say yes. No on_hurtbox_hit()
	# anywhere, so nothing can tell it to die early. That's the pierce.
	var enemy: Node = hurtbox.get_parent()
	if enemy and is_instance_valid(enemy):
		if burn_dps > 0.0 and enemy.has_method("ignite"):
			enemy.ignite(burn_dps, 3.0)
		if chill_factor > 0.0 and enemy.has_method("chill"):
			enemy.chill(chill_factor, 2.0)
	return true
