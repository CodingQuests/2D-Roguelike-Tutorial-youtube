class_name DestructibleProp
extends StaticBody2D



@onready var health: HealthComponent = $Health
@onready var sprite: Sprite2D = $Sprite2D



func _ready() -> void:
	health.max_health = 1.0
	health.current_health = 1.0
	health.died.connect(_break)


func _break() -> void:
	var world := get_tree().current_scene
	Juice.impact(world, global_position, Color(0.6, 0.45, 0.25), 12, 1.2)
	AudioManager.play("enemy_death", -5.0)
	queue_free()
