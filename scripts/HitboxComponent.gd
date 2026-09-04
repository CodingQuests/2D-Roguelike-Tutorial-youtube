class_name HitboxComponent
extends Area2D
## An Area2D that *deals* damage. Put it on a player's AttackHitbox or an
## enemy's AttackArea. It stays passive — it never reads overlaps itself.
## Instead a HurtboxComponent detects it and pulls these values off it.
##
## `hit_once_per_attack` makes a single swing hit each target only once, even
## if the hitbox overlaps it for several frames.

@export var damage: float = 10.0
@export var knockback_force: float = 200.0
@export var hit_once_per_attack: bool = true

## Who owns this hitbox (the player or an enemy). Used for knockback direction
## and to credit kills. Set by the owner in code.
var source_node: Node = null

# Targets already hit during the current swing.
var _hit_this_attack: Array = []

signal hit_landed(hurtbox: Node)


func _ready() -> void:
	# A group set in code, which chapter 1 said belongs in the scene. The
	# exception is a *reusable component*: it's identical for every instance, so
	# setting it once here is DRY. Duplicating it across forty scene instances
	# would be worse.
	add_to_group("hitbox")


## Call at the start of every new swing so old targets can be hit again.
func reset_hits() -> void:
	_hit_this_attack.clear()


## A HurtboxComponent calls this when it overlaps us. Returns false if this
## hurtbox was already hit by the current swing (so it should be ignored).
func try_register_hit(hurtbox: Node) -> bool:
	if hit_once_per_attack and _hit_this_attack.has(hurtbox):
		return false
	_hit_this_attack.append(hurtbox)
	hit_landed.emit(hurtbox)
	return true
