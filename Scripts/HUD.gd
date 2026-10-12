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

var _player: PlayerController = null
var _status_token := 0
var _upgrade_callback: Callable
var _time: float = 0.0
var _game_over: bool = false
var _leaving: bool = false
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
		var opened = not $CodexPanel.visible
		# Rebuild the text only on the way open, then pause the tree with it.
		if opened:
			_refresh_codex()
		$CodexPanel.visible = opened
		get_tree().paused = opened
		
		
func _ready() -> void:
	GameManager.register_hud(self)
	status_label.visible = false
	upgrade_panel.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$UpgradePanel/Skip.pressed.connect(_skip_upgrade)
	$CodexPanel/Close.pressed.connect(_close_codex)
	$CodexPanel.visible = false
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
	
	
func _close_codex() -> void:
	$CodexPanel.visible = false
	get_tree().paused = false
