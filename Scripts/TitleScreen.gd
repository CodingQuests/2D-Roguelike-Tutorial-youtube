extends Control

@onready var title: Label = $Center/VBox/Title

var _time := 0.0



func _ready() -> void:
	# Wires the two buttons to two functions, nothing else.
	# Add AudioManager.play_music("calm") after completing 7.2.
	$Center/VBox/StartButton.pressed.connect(_on_start)
	$Center/VBox/QuitButton.pressed.connect(_on_quit)

func _process(delta: float) -> void:
	_time += delta
	# Living glow — procedural, so nothing to spawn and nothing to free.
	# Lerp white to warm orange. sin() runs -1..1; 0.5 + 0.5 * sin makes it 0..1,
	# and that's the blend amount.
	title.modulate = Color(1, 1, 1).lerp(Color(1.0, 0.6, 0.35), 0.5 + 0.5 * sin(_time * 1.4))

func _on_start() -> void:
	# Hands off to Transitions, so the title never hard-cuts into a run.
	Transitions.change_scene("res://Scenes/CombatRoom.tscn")


func _on_quit() -> void:
	# Fade to black first, quit inside the callback. Quitting on the click
	# would cut the fade off.
	Transitions.fade_out_then(func() -> void: get_tree().quit())
	
