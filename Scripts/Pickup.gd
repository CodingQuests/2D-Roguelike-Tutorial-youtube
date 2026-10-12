class_name Pickup
extends Area2D



@export var magnet_radius: float = 70.0
@export var magnet_speed: float = 420.0

var _velocity := Vector2.ZERO
var _player: Node2D = null
var _collected := false


func _ready() -> void:
	# Without this the Area2D never reports anything and the coin is scenery.
	# Forgetting it looks exactly like the mask bug: a coin that sits there forever.
	body_entered.connect(_on_body_entered)
	
func toss(velocity: Vector2) -> void:
	_velocity = velocity
	
func _physics_process(delta: float) -> void:
	# Find the player once, if we haven't got one.
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	# Slow the toss at 900 a second, so the burst dies off.
	_velocity = _velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	# Inside the radius, pull the velocity toward the player. The exp inside the
	# lerp keeps the pull the same per second whatever the frame rate.
	if _player and global_position.distance_to(_player.global_position) < magnet_radius:
		var to_p := (_player.global_position - global_position).normalized()
		_velocity = _velocity.lerp(to_p * magnet_speed, 1.0 - exp(-8.0 * delta))
	global_position += _velocity * delta
	
func _on_body_entered(body: Node2D) -> void:
	# Latch _collected so two frames of overlap can't pay twice.
	if body.is_in_group("player") and not _collected:
		_collected = true
		_collect(body)
		queue_free()

func _collect(_player_body: Node2D) -> void:
	pass
