class_name SlashWave
extends Area2D
## A flying crescent of energy fired by the Echo Blade item (and its synergies).
## It is a *player* hitbox (collision layer 32, the PlayerHitbox bit — set in
## SlashWave.tscn), so enemy Hurtboxes detect it while the player's own Hurtbox
## (which only masks the EnemyHitbox bit) ignores it — no friendly fire.
##
## Unlike the Caster's Projectile it PIERCES: it implements try_register_hit()
## (so each enemy is hit once and we get a hook to apply on-hit status effects)
## and deliberately omits on_hurtbox_hit(), so a Hurtbox never tells it to die.
##
## The capsule shape, crescent visual, layers and "hitbox" group live in the
## scene; this script only animates it and carries the per-cast data.

var speed: float = 430.0
var damage: float = 12.0
var knockback_force: float = 140.0
var is_crit: bool = false
var lifetime: float = 0.6
var source_node: Node = null

# Status carried onto whatever the wave cuts (mirrors the player's effects so
# Echo Blade naturally synergizes with Ember Brand / Frost Bite).
var burn_dps: float = 0.0
var chill_factor: float = 0.0

@onready var _visual: Sprite2D = $Visual

var _color := Color(0.8, 0.85, 1.0)
var _direction := Vector2.RIGHT
var _life := 0.0
var _hit: Array = []


## Configure BEFORE add_child() so _ready() can tint the visual and aim it.
func configure(direction: Vector2, dmg: float, source: Node, color: Color) -> void:
	_direction = direction.normalized()
	damage = dmg
	source_node = source
	_color = color
	rotation = _direction.angle()


func _ready() -> void:
	var mat := _visual.material as ShaderMaterial
	if mat:
		# Fresh material per instance — waves are fired in bursts and each one
		# carries its own tint, so they must not share shader parameters.
		mat = mat.duplicate()
		_visual.material = mat
		mat.set_shader_parameter("color", Color(_color.r * 1.3, _color.g * 1.3, _color.b * 1.3, 1.0))
	body_entered.connect(_on_body_entered)
	modulate.a = 0.9
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, lifetime)


func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta
	_life += delta
	if _life >= lifetime:
		queue_free()


# A Hurtbox calls this; return false to be ignored (already cut this target).
func try_register_hit(hurtbox: Node) -> bool:
	if _hit.has(hurtbox):
		return false
	_hit.append(hurtbox)
	var enemy: Node = (hurtbox as Node).get_parent()
	if enemy and is_instance_valid(enemy):
		if burn_dps > 0.0 and enemy.has_method("ignite"):
			enemy.ignite(burn_dps, 3.0)
		if chill_factor > 0.0 and enemy.has_method("chill"):
			enemy.chill(chill_factor, 2.0)
	return true


func _on_body_entered(_body: Node) -> void:
	Juice.impact(get_tree().current_scene, global_position, _color, 6, 0.9)
	queue_free()
