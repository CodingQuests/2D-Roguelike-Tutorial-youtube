extends Control
## "The Forge" — the between-runs hub. Spend banked essence on permanent
## unlocks, then start a run. Buttons are built from MetaProgression's data.

@onready var essence_label: Label = $Center/Box/Essence
@onready var list: VBoxContainer = $Center/Box/List
@onready var start_button: Button = $Center/Box/Buttons/StartButton
@onready var back_button: Button = $Center/Box/Buttons/BackButton

var _buttons: Dictionary = {}


func _ready() -> void:
	for id in MetaProgression.ids():
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.custom_minimum_size = Vector2(560, 40)
		list.add_child(b)
		b.pressed.connect(_on_buy.bind(id))
		_buttons[id] = b
	start_button.pressed.connect(func() -> void: AudioManager.play("click"); Transitions.change_scene("res://Main.tscn"))
	back_button.pressed.connect(func() -> void: AudioManager.play("click"); Transitions.change_scene("res://TitleScreen.tscn"))
	for b: Button in [start_button, back_button]:
		b.mouse_entered.connect(func() -> void: AudioManager.play("click", -12.0, 1.3))
	_add_embers()
	AudioManager.play_music("calm")
	_refresh()


# Warm forge embers drifting up behind the menu — fits "The Forge".
func _add_embers() -> void:
	var vp := get_viewport_rect().size
	var p := CPUParticles2D.new()
	p.amount = 52
	p.lifetime = 7.0
	p.preprocess = 6.0
	p.position = Vector2(vp.x * 0.5, vp.y + 8.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x * 0.5, 6.0)
	p.direction = Vector2(0, -1)
	p.spread = 20.0
	p.gravity = Vector2(0, -12.0)
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 32.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.8
	p.color = Color(1.0, 0.5, 0.18, 0.55)
	p.emitting = true
	add_child(p)
	move_child(p, 1)


func _on_buy(id: String) -> void:
	if MetaProgression.buy(id):
		AudioManager.play("upgrade")
	else:
		AudioManager.play("player_hurt", -8.0)
	_refresh()


func _refresh() -> void:
	essence_label.text = "ESSENCE %d" % MetaProgression.total_essence
	for id in _buttons:
		var b: Button = _buttons[id]
		var nm: String = MetaProgression.display_name(id)
		if MetaProgression.is_unlocked(id):
			b.text = "[OWNED]  " + nm
			b.disabled = true
		else:
			b.text = "%s   (%d essence)" % [nm, MetaProgression.cost(id)]
			b.disabled = not MetaProgression.can_buy(id)
