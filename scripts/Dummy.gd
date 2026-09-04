extends CharacterBody2D
## TEMPORARY. A thing to hit, so the HealthComponent can be proved to work
## before a real damage system exists.
##
## Note what isn't in this file: any health logic at all. It owns a
## HealthComponent and listens for one signal. That's the whole point of the
## component — the dummy, the player and every barrel share the same fifty
## lines and none of them reimplement any of it.
##
## Lesson 2.2 replaces the click-to-damage below with a real hitbox/hurtbox.

@onready var health: HealthComponent = $Health


func _ready() -> void:
	health.died.connect(_on_died)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_attack"):
		health.damage(10.0)
		print(health.current_health)


func _on_died() -> void:
	queue_free()
