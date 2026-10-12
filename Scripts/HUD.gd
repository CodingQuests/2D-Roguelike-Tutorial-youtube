extends CanvasLayer

const UPGRADE_CARD := preload("res://Scenes/UpgradeCard.tscn")

@onready var health_bar: StatBar = $HealthBar
@onready var dash_bar: StatBar = $DashBar
@onready var corruption_bar: StatBar = $CorruptionBar
@onready var overload_pulse: ColorRect = $OverloadPulse
@onready var status_label: Label = $StatusLabel
@onready var upgrade_panel: Control = $UpgradePanel
@onready var _card_row: HBoxContainer = $UpgradePanel/Cards
@onready var tier_label: Label = $TierLabel
@onready var gold_label: Label = $GoldLabel
@onready var game_over: Control = $GameOver
@onready var game_over_summary: Label = $GameOver/Summary
@onready var essence_label: Label = $GameOver/Essence
@onready var _pause_panel: Control = $PausePanel
@onready var _codex_panel: Control = $CodexPanel

var _player: PlayerController = null
var _status_token := 0
var _upgrade_callback: Callable
var _time: float = 0.0
var _game_over: bool = false
var _leaving: bool = false
var _codex_open: bool = false


func _skip_upgrade() -> void:
	# The card lambda with no card: same visible guard, hide the panel, then
	# call the stored callback with an empty dictionary.
	if not upgrade_panel.visible:
		return
	upgrade_panel.visible = false
	_upgrade_callback.call({})


func _unhandled_input(event: InputEvent) -> void:
	# Tab flips the panel, but not on a key repeat and not while the upgrade
	# panel is up.
	if event.is_action_pressed("codex") and not event.is_echo() and not upgrade_panel.visible:
		_toggle_codex()
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("ui_cancel"):
		if _codex_open:
			_toggle_codex()
		else:
			_toggle_pause()
		get_viewport().set_input_as_handled()
func _ready() -> void:
	GameManager.register_hud(self)
	status_label.visible = false
	upgrade_panel.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$UpgradePanel/Skip.pressed.connect(_skip_upgrade)
	$CodexPanel/Close.pressed.connect(_toggle_codex)
	$CodexPanel.visible = false
	game_over.visible = false
	_pause_panel.visible = false
	_codex_panel.visible = false
	$GameOver/Retry.pressed.connect(_on_retry)
	$GameOver/Forge.pressed.connect(_on_forge)
	$PausePanel/VBox/Resume.pressed.connect(_toggle_pause)
	$PausePanel/VBox/Restart.pressed.connect(_on_restart)
	$PausePanel/VBox/Title.pressed.connect(_on_title)
	for key in ["master", "sfx", "music"]:
		# Path built from the key, so the sliders must be named master, sfx and music.
		var slider: HSlider = get_node("PausePanel/VBox/Audio/" + key)
		# Range and step in code, so the scene can't drift from what
		# set_audio_setting clamps to.
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = MetaProgression.audio_settings[key]     # from the save, not the scene
		slider.process_mode = Node.PROCESS_MODE_ALWAYS
		# The lambda captures key: one loop wires three sliders to three settings
		# without three functions.
		slider.value_changed.connect(
			func(v: float) -> void:
				if not _leaving and not Transitions.is_busy():
					MetaProgression.set_audio_setting(key, v))
func _process(_delta: float) -> void:
	if _game_over or _leaving or get_tree().paused:
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	if _player == null:
		return
	
	
	health_bar.set_ratio(_player.health.get_ratio())
	corruption_bar.set_ratio(_player.corruption / _player.max_corruption)
	dash_bar.set_ratio(_player.get_dash_ratio())
	tier_label.text = _player.get_corruption_tier()
	gold_label.text = "%d g" % int(GameManager.run_stats.get("gold", 0))
	
	_time = Time.get_ticks_msec() / 1000.0
	var hp := _player.health.get_ratio()
	if hp < 0.3:
		# urgency is 0 at 30% health, 1 at dead. It drives both numbers below:
		# alpha 0.10 up to 0.24, sine speed 4 up to 10. Stronger and faster together.
		var urgency := 1.0 - (hp / 0.3)
		var a := (0.10 + 0.14 * urgency) * (0.5 + 0.5 * sin(_time * (4.0 + 6.0 * urgency)))
		overload_pulse.color = Color(0.7, 0.0, 0.1, a)
	else:
		# Back to zero, or the last red frame stays up after you heal.
		overload_pulse.color.a = 0.0

func _toggle_pause() -> void:
	if _game_over or _leaving or Transitions.is_busy() or upgrade_panel.visible:
		return
	# Flip the tree's paused state; the panel follows it.
	var now := not get_tree().paused
	get_tree().paused = now
	_pause_panel.visible = now
	AudioManager.play("click")

func _toggle_codex() -> void:
	if _game_over or _leaving or Transitions.is_busy() or upgrade_panel.visible or _pause_panel.visible:
		return
	_codex_open = not _codex_open
	# Refresh the build screen only when it's opening.
	if _codex_open: _refresh_codex()
	get_tree().paused = _codex_open
	_codex_panel.visible = _codex_open
	AudioManager.play("click")
func show_status(text: String, auto_hide: float = 1.5) -> void:
	_status_token += 1
	var token := _status_token
	status_label.text = text
	status_label.visible = true
	if auto_hide > 0.0:
		var t := get_tree().create_timer(auto_hide)
		await t.timeout
		if token == _status_token:
			status_label.visible = false
			
			
func show_upgrades(choices: Array, on_chosen: Callable) -> void:
	# Clear last room's cards. remove_child then queue_free, so the row is
	# empty right now rather than at the end of the frame.
	_upgrade_callback = on_chosen
	for old in _card_row.get_children():
		_card_row.remove_child(old)
		old.queue_free()
	for def in choices:
		var card := UPGRADE_CARD.instantiate()
		_card_row.add_child(card)
		card.setup(def)
		# The inline function remembers on_chosen, so each card carries the room's
		# callback with it. Hide the panel BEFORE calling back, or a fast second
		# click picks twice.
		card.chosen.connect(func(d: Dictionary) -> void:
			if not upgrade_panel.visible:
				return
			upgrade_panel.visible = false
			on_chosen.call(d))
	# Pause the whole tree. The cards still work while paused because of the
	# two lines in _ready() coming next.
	upgrade_panel.visible = true
	get_tree().paused = true

func _refresh_codex() -> void:
	var p: PlayerController = GameManager.player
	if not is_instance_valid(p):
		return
	var lines: PackedStringArray = ["OWNED ITEMS"]
	# One line per owned item, title and description.
	for item in p.items:
		lines.append("%s — %s" % [item["title"], item["desc"]])
	# Then a blank line and the synergies. p.get("syn_" + id) reads a property
	# by name, so the four booleans don't need four ifs.
	lines.append("\nSYNERGIES")
	for id in PlayerController.SYNERGY_DESCS:
		if bool(p.get("syn_" + id)):
			lines.append("%s — %s" % [id.to_upper(), PlayerController.SYNERGY_DESCS[id]])
	$CodexPanel/BuildText.text = "\n".join(lines)
	
	

func _format_time(seconds: float) -> String:
	var t := int(seconds)
	# Minutes, then the remainder. %02d pads the seconds: 2:04, not 2:4.
	return "%d:%02d" % [t / 60, t % 60]
	
	


func show_game_over(immediate_pause: bool = false) -> void:
	# Same latch as die(): a second call in the same frame bails.
	if _game_over:
		return
	_game_over = true
	MetaProgression.bank_run(int(GameManager.run_stats["essence"]))
	var s: Dictionary = GameManager.run_stats
	# One label, one line per stat.
	game_over_summary.text = "\n".join([
		"Floor reached: %d" % s["floor"],
		"Rooms cleared: %d" % s["rooms_cleared"],
		"Enemies killed: %d" % s["enemies_killed"],
		"Best combo: %d" % s["max_combo"],
		"Time: %s" % _format_time(GameManager.get_run_time()),
		# A blank line, so there's a gap above the essence.
		"",
	])
	_count_up(essence_label, int(s["essence"]), "Essence banked: ")
	# Step 7 replaces that line with a counting animation.

	# Nothing else may be on screen or clickable over a death screen.
	upgrade_panel.visible = false
	$CodexPanel.visible = false
	game_over.visible = true

	# Victory in 7.3 uses this path without starting a death-beat timer.
	if immediate_pause:
		get_tree().paused = true
		return
	# Let the death beat play, then freeze the world behind the summary.
	# false, false, true: not while paused, not on the physics clock, ignore time
	# scale. 1.2 real seconds even with the world at quarter speed under it.
	await get_tree().create_timer(1.2, false, false, true).timeout
	if _game_over and not _leaving and is_inside_tree():
		get_tree().paused = true
		
func _on_retry() -> void:
	if _leaving or Transitions.is_busy():
		return
	_leaving = true
	if not await Transitions.reload_scene():
		_leaving = false


func _count_up(label: Label, target: int, prefix: String) -> void:
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # also completes on 7.3's paused victory screen
	# Runs the lambda every frame with a value sliding from 0 to target over 0.6 s.
	tw.tween_method(
		# int(v), so it never shows a decimal on the way up.
		func(v: float) -> void: label.text = "%s%d" % [prefix, int(v)],
		0.0, float(target), 0.6
	)

func _on_forge() -> void:
	if _leaving or Transitions.is_busy():
		return
	_leaving = true
	if not await Transitions.change_scene("res://Hub.tscn"):
		_leaving = false
func _on_restart() -> void:
	if _leaving or Transitions.is_busy():
		return
	_leaving = true
	if not await Transitions.reload_scene():
		_leaving = false


func _on_title() -> void:
	if _leaving or Transitions.is_busy():
		return
	_leaving = true
	if not await Transitions.change_scene("res://Scenes/TitleScreen.tscn"):
		_leaving = false

