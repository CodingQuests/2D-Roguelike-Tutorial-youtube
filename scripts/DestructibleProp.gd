class_name DestructibleProp
extends StaticBody2D
## A barrel/crate/pot that blocks movement (cover) and can be smashed by the
## player's melee. Reuses the same Health + Hurtbox components as enemies — a
## nice teaching moment: "props are just enemies that don't fight back." Has a
## chance to drop a pickup when broken.

const HEALTH_PICKUP := preload("res://scenes/HealthPickup.tscn")
const CLEANSE_PICKUP := preload("res://scenes/CleansePickup.tscn")
const GOLD_PICKUP := preload("res://scenes/GoldPickup.tscn")

@export var max_health: float = 20.0
@export var drop_chance: float = 0.35

@onready var sprite: Sprite2D = $Sprite2D
@onready var health: HealthComponent = $Health
@onready var hurtbox: HurtboxComponent = $Hurtbox

var _broken := false


func _ready() -> void:
	health.max_health = max_health
	health.current_health = max_health
	health.died.connect(_break)
	hurtbox.hurt.connect(_on_hurt)


## Let Dungeon pick the look after instancing.
func set_texture(tex: Texture2D) -> void:
	if sprite == null:
		await ready
	sprite.texture = tex


func _on_hurt(_amount: float, _source) -> void:
	AudioManager.play("hit", -6.0)


func _break() -> void:
	if _broken:
		return
	_broken = true
	AudioManager.play("enemy_death", -5.0)
	var world := get_tree().current_scene
	# Chunky debris burst + a little shake and a scorch decal where it stood.
	Juice.impact(world, global_position, Color(0.75, 0.55, 0.32), 22, 1.5)
	Juice.ring(world, global_position, Color(0.8, 0.65, 0.4, 0.7), 26.0, 0.28)
	Juice.decal(world, global_position, Color(0.1, 0.07, 0.03, 0.35), 8.0, 4.0)
	GameManager.shake_camera(0.12)
	if randf() < drop_chance:
		_drop()
	queue_free()


func _drop() -> void:
	var container := get_tree().get_first_node_in_group("pickups")
	if container == null:
		container = get_tree().current_scene
	var roll := randf()
	var pk: Node
	if roll < 0.5:
		pk = GOLD_PICKUP.instantiate()
		pk.amount = float(randi_range(1, 4))
	elif roll < 0.85:
		pk = HEALTH_PICKUP.instantiate()
	else:
		pk = CLEANSE_PICKUP.instantiate()
		
	# Deferred: we're breaking inside a physics signal; adding an Area2D now would
	# error ("can't change monitoring while flushing queries").
	container.add_child.call_deferred(pk)
	pk.set_deferred("global_position", global_position)
	# Burst the loot outward so it pops out of the wreck (toss just sets a var).
	if pk.has_method("toss"):
		pk.toss(Vector2.RIGHT.rotated(randf() * TAU) * randf_range(90.0, 160.0))
