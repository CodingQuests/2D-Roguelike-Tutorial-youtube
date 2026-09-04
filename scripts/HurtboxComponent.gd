class_name HurtboxComponent
extends Area2D
## An Area2D that *receives* damage. This is the active detector: it watches for
## overlapping HitboxComponents, applies the result to its sibling Health node,
## and knocks its parent body back.
##
## The rule this whole file exists to enforce:
##   the thing that can be hurt does the checking.
##   the thing that hurts you just sits there carrying a number.
##
## Expected layout (sibling nodes under the same body):
##   Body (CharacterBody2D)
##     Sprite2D
##     Health         (HealthComponent)
##     Hurtbox        (this)

signal hurt(amount: float, source)

## Multiplies all incoming damage. Chapter 5 raises this with corruption.
@export var damage_multiplier: float = 1.0
@export var invulnerable: bool = false

var health: HealthComponent
var _body: Node


func _ready() -> void:
	_body = get_parent()
	health = _body.get_node_or_null("Health")
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if invulnerable:
		return
	if not area.is_in_group("hitbox"):
		return

	# Make sure a single swing only hits us once. Note we don't ask what the
	# area *is* — just whether it has the method. That keeps the two components
	# decoupled.
	if area.has_method("try_register_hit"):
		if not area.try_register_hit(self):
			return

	var incoming: float = area.damage * damage_multiplier
	if health:
		health.damage(incoming)

	# Knock the body away from the hit source. The random fallback is for when
	# something spawns exactly on top of you: the direction is zero, you can't
	# normalize a zero vector, and you'd get NaN — which is precisely the crash
	# the _finite() guard in lesson 1.1 was put there to catch.
	if _body.has_method("apply_knockback"):
		var from: Vector2 = area.global_position
		var dir: Vector2 = _body.global_position - from
		if dir.length() < 0.01:
			dir = Vector2.RIGHT.rotated(randf() * TAU)
		_body.apply_knockback(dir.normalized(), area.knockback_force)

	hurt.emit(incoming, area.source_node)
