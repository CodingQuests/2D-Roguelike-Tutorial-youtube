class_name Projectile
extends Area2D
## A simple straight-flying projectile fired by the Caster. It behaves as a
## "hitbox": the player's Hurtbox detects it, reads damage/knockback, then calls
## on_hurtbox_hit() so it despawns. It also despawns on walls and after a timeout.

@export var speed: float = 230.0
@export var damage: float = 10.0
@export var knockback_force: float = 140.0
@export var lifetime: float = 4.0

var source_node: Node = null
var _direction := Vector2.RIGHT
var _life := 0.0


const LIGHT_TEX := preload("res://light_radial.tres")
const BOLT_COLOR := Color(0.72, 0.42, 1.0)


func _ready() -> void:
	add_to_group("hitbox")
	body_entered.connect(_on_body_entered)
	# An incoming bolt is the one thing you must not miss in a dark room, so it
	# carries its own light. It also lets you track a shot fired from off-screen
	# by the glow arriving before the sprite does.
	var glow := PointLight2D.new()
	glow.texture = LIGHT_TEX
	glow.texture_scale = 0.45
	glow.energy = 0.95
	glow.color = BOLT_COLOR
	add_child(glow)


## Called by the Caster right after instancing.
func setup(direction: Vector2, dmg: float, source: Node) -> void:
	_direction = direction.normalized()
	damage = dmg
	source_node = source
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta
	_life += delta
	if _life >= lifetime:
		queue_free()


func _on_body_entered(_body: Node) -> void:
	# Hit a wall (the only bodies on our mask). Pop and disappear.
	_pop()


## The player's Hurtbox calls this after taking the hit.
func on_hurtbox_hit() -> void:
	_pop()


func _pop() -> void:
	var world := get_tree().current_scene
	Juice.impact(world, global_position, BOLT_COLOR, 8, 0.9)
	Juice.light_flash(world, global_position, BOLT_COLOR, 0.9, 0.6, 0.14)
	queue_free()
