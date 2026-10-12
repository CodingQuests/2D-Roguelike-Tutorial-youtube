class_name HurtboxComponent
extends Area2D

signal hurt(amount: float, source)

@export var damage_multiplier: float = 1.0
@export var invulnerable: bool = false

var health: HealthComponent
var _body: Node
## Visual feedback options.
@export var flash_color: Color = Color(1, 1, 1, 1)
@export var impact_color: Color = Color(1, 0.85, 0.85)
@export var show_damage_numbers: bool = true

var _sprite: CanvasItem

func _ready() -> void:
	_body = get_parent()
	health = _body.get_node_or_null("Health")
	area_entered.connect(_on_area_entered)
	_sprite = _body.get_node_or_null("Sprite2D")
	if _sprite and _sprite.material == null:
		_sprite.material = Juice.make_flash_material()
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
		Juice.flash(_sprite, flash_color, 0.09)
		var world := get_tree().current_scene
		Juice.impact(world, global_position, impact_color, 8, 1.0)
		if show_damage_numbers:
			Juice.damage_number(world, global_position, incoming, flash_color)
	hurt.emit(incoming, area.source_node)
	if _body.has_method("apply_knockback"):
		
		var from: Vector2 = area.global_position
		var dir: Vector2 = _body.global_position - from
		if dir.length() < 0.01:
			dir = Vector2.RIGHT.rotated(randf() * TAU)
		_body.apply_knockback(dir.normalized(), area.knockback_force)
	
	
