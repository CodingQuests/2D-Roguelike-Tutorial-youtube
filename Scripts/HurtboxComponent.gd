class_name HurtboxComponent
extends Area2D

signal hurt(amount: float, source)

@export var damage_multiplier: float = 1.0
@export var invulnerable: bool = false

var health: HealthComponent
var _body: Node

func _ready() -> void:
	_body = get_parent()
	health = _body.get_node_or_null("Health")
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	print("entered: ", area.name)
	if invulnerable:
		return
	if not area.is_in_group("hitbox"):
		return
	if area.has_method("try_register_hit"):
		if not area.try_register_hit(self):
			return
	var incoming: float = area.damage * damage_multiplier
	if health:
		health.damage(incoming)
	
	hurt.emit(incoming, area.source_node)
	if _body.has_method("apply_knockback"):
		var from: Vector2 = area.global_position
		var dir: Vector2 = _body.global_position - from
		if dir.length() < 0.01:
			dir = Vector2.RIGHT.rotated(randf() * TAU)
		_body.apply_knockback(dir.normalized(), area.knockback_force)
	
	
