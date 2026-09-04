extends Control
## Start screen. Start begins a fresh run; the Forge opens the upgrade hub; Quit
## exits. Polished with drifting forge-embers, a living title glow, button sounds,
## a version tag and faded scene transitions.

@onready var start_button: Button = $Center/Box/StartButton
@onready var forge_button: Button = $Center/Box/ForgeButton
@onready var quit_button: Button = $Center/Box/QuitButton
@onready var title_label: Label = $Center/Box/Title
@onready var controls_label: Label = $Center/Box/Controls

var _t := 0.0


func _ready() -> void:
	start_button.pressed.connect(_start)
	forge_button.pressed.connect(func() -> void: _go("res://Hub.tscn"))
	quit_button.pressed.connect(func() -> void:
		AudioManager.play("click")
		Transitions.fade_out_then(func() -> void: get_tree().quit()))
	for b: Button in [start_button, forge_button, quit_button]:
		b.mouse_entered.connect(func() -> void: AudioManager.play("click", -12.0, 1.3))
	start_button.grab_focus()
	controls_label.text = "WASD MOVE · LMB SLASH · RMB HEAVY · SPACE DASH · Q SWAP · E ACTIVE · TAB BUILD"
	_add_embers()
	_add_version()
	AudioManager.play_music("calm")


func _process(delta: float) -> void:
	_t += delta
	# A slow living glow + breath on the title so the screen isn't static.
	var g := 0.5 + 0.5 * sin(_t * 1.5)
	title_label.modulate = Color(1, 1, 1).lerp(Color(1.18, 0.92, 1.25), g)
	title_label.pivot_offset = title_label.size * 0.5
	var s := 1.0 + 0.012 * sin(_t * 1.5)
	title_label.scale = Vector2(s, s)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") or event.is_action_pressed("ui_accept"):
		_start()


func _go(path: String) -> void:
	AudioManager.play("click")
	Transitions.change_scene(path)


func _start() -> void:
	_go("res://Main.tscn")


# Warm embers drifting up from the bottom, like a forge below the screen.
func _add_embers() -> void:
	var vp := get_viewport_rect().size
	var p := CPUParticles2D.new()
	p.amount = 48
	p.lifetime = 7.0
	p.preprocess = 6.0
	p.position = Vector2(vp.x * 0.5, vp.y + 8.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x * 0.5, 6.0)
	p.direction = Vector2(0, -1)
	p.spread = 18.0
	p.gravity = Vector2(0, -10.0)
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 28.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.6
	p.color = Color(1.0, 0.55, 0.2, 0.5)
	p.emitting = true
	add_child(p)
	move_child(p, 1)  # behind the menu, above the background


func _add_version() -> void:
	var v := Label.new()
	v.text = "v0.6"
	v.add_theme_font_size_override("font_size", 12)
	v.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 0.6))
	v.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	v.offset_left = -90.0
	v.offset_top = -26.0
	v.offset_right = -12.0
	v.offset_bottom = -8.0
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
