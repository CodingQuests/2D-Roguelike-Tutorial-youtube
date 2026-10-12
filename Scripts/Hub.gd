extends Control


@onready var essence_label: Label = $Essence


func _ready() -> void:
	# Each id is also the button's node name, so "Unlocks/" + id finds it.
	# bind(id) tucks the id into the connection: one handler serves all four.
	for id in MetaProgression.COSTS:
		get_node("Unlocks/" + id).pressed.connect(_on_unlock_pressed.bind(id))
	# StartRun swaps the scene to Main. Then draw the first state.
	$StartRun.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://Main.tscn"))
	_refresh()

func _refresh() -> void:
	essence_label.text = "Essence: %d" % MetaProgression.total_essence
	for id in MetaProgression.COSTS:
		var btn: Button = get_node("Unlocks/" + id)
		# Name and price. Grey if it's owned or you can't afford it.
		btn.text = "%s  (%d)" % [MetaProgression.NAMES[id], MetaProgression.cost(id)]
		btn.disabled = MetaProgression.is_unlocked(id) or not MetaProgression.can_buy(id)
		# A tick instead of a price once it's bought.
		if MetaProgression.is_unlocked(id):
			btn.text = "%s  ✓" % MetaProgression.NAMES[id]
			


func _on_unlock_pressed(id: String) -> void:
	# buy() is true only if it went through. Sound and redraw on a real purchase.
	if MetaProgression.buy(id):
		AudioManager.play("upgrade")
		_refresh()
