extends Area2D
## TEMPORARY. A thing that notices when it touches you, so the i-frames can be
## proved to work. This is not a damage system — that's chapter 2.
##
## Do not delete it at the end of this lesson; disable it. It becomes the
## i-frame visualiser, and it's the cheapest possible thing that lets you see
## whether the real thing works. You cannot test invincibility without something
## to be invincible *from*, and waiting for the real damage system would mean
## writing the i-frames blind.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	# As of lesson 2.2 the i-frame flag lives on the hurtbox, not the player.
	var hurtbox := body.get_node_or_null("Hurtbox")
	if hurtbox and hurtbox.invulnerable:
		return
	print("HIT")
