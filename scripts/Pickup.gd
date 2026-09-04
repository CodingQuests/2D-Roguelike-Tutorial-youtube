class_name Pickup
extends Area2D
## A floating collectible. Walk near it and it flies to you; touch it to collect.
## HEALTH heals; CLEANSE reduces corruption (a rare relief from the upgrade tax).
## Enemies drop these on death (see RoomController._maybe_drop). Detects the
## player body only.

enum Kind { HEALTH, CLEANSE, GOLD }

const LIGHT_TEX := preload("res://light_radial.tres")
const MAGNET_RADIUS := 70.0
const MAGNET_SPEED := 260.0

@export var kind: Kind = Kind.HEALTH
@export var amount: float = 30.0
@export var fx_color: Color = Color(0.9, 0.3, 0.3)

# The bobbing visual. Usually a "Sprite2D" (potions); the gold coin uses a
# code-drawn "Visual" node instead, so resolve whichever exists.
var sprite: Node2D = null

var _collected := false
var _time := 0.0
var _player: Node2D = null
var _toss_vel := Vector2.ZERO
var _glow: PointLight2D = null


func _ready() -> void:
	sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		sprite = get_node_or_null("Visual")
	body_entered.connect(_on_body_entered)
	_add_glow()


## Loot lights itself. Since the dungeon went dark, a potion lying outside the
## torch radius was just a dark blob — you'd walk past drops you'd earned. The
## light is tinted to the pickup type, so you can tell health from cleanse from
## gold across a room without seeing the sprite clearly.
func _add_glow() -> void:
	_glow = PointLight2D.new()
	_glow.texture = LIGHT_TEX
	_glow.texture_scale = 0.55
	_glow.energy = 0.75
	_glow.color = fx_color
	add_child(_glow)


## Burst the pickup outward (e.g. when a barrel smashes). The velocity decays in
## _process and then the magnet takes over.
func toss(velocity: Vector2) -> void:
	_toss_vel = velocity


func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta
	# Gentle bob + slow spin so it reads as a pickup (procedural, no leaking loop).
	if sprite:
		sprite.position.y = sin(_time * 3.0) * 3.0
		sprite.rotation = sin(_time * 2.0) * 0.25
	if _glow:
		_glow.energy = 0.75 + 0.18 * sin(_time * 3.0)

	# Initial toss impulse, decaying.
	if _toss_vel.length() > 1.0:
		global_position += _toss_vel * delta
		_toss_vel = _toss_vel.move_toward(Vector2.ZERO, 700.0 * delta)

	# Magnet toward the player when close.
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player and is_instance_valid(_player):
		var to := _player.global_position - global_position
		var d := to.length()
		if d < MAGNET_RADIUS and d > 0.01:
			var pull := 1.0 - d / MAGNET_RADIUS  # stronger the closer it gets
			global_position += to / d * MAGNET_SPEED * (0.3 + pull) * delta


func _on_body_entered(body: Node) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true

	var label := ""
	match kind:
		Kind.HEALTH:
			if body.has_node("Health"):
				body.get_node("Health").heal(amount)
			label = "+%d HP" % int(amount)
		Kind.CLEANSE:
			if body.has_method("add_corruption"):
				body.add_corruption(-amount)
			label = "-%d Corruption" % int(amount)
		Kind.GOLD:
			GameManager.register_gold(int(amount))
			label = "+%d Gold" % int(amount)

	AudioManager.play("pickup")
	var world := get_tree().current_scene
	Juice.impact(world, global_position, fx_color, 14, 1.2)
	Juice.ring(world, global_position, Color(fx_color.r, fx_color.g, fx_color.b, 0.8), 26.0, 0.28)
	Juice.floating_text(world, global_position, label, fx_color, 15)
	queue_free()
