extends Pickup

@export var value: int = 1


func _collect(_player_body: Node2D) -> void:
	# Bank the value, play a sound.
	GameManager.register_gold(value)
	AudioManager.play("pickup", -3.0)
