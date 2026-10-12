class_name HitboxComponent
extends Area2D

@export var hit_once_per_attack: bool = true
var _hit_this_attack: Array = []
signal hit_landed(hurtbox: Node)
@export var damage: float = 10.0
@export var knockback_force: float = 200.0

## Who owns this hitbox. Used for knockback direction and crediting kills.
var source_node: Node = null

func _ready() -> void:
	add_to_group("hitbox")
	
func reset_hits() -> void:
	_hit_this_attack.clear()
	

func try_register_hit(hurtbox: Node) -> bool:
	if hit_once_per_attack and _hit_this_attack.has(hurtbox):
		return false
	_hit_this_attack.append(hurtbox)
	return true
	
func notify_hit(hurtbox: Node) -> void:
	hit_landed.emit(hurtbox)
