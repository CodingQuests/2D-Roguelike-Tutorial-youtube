extends CanvasLayer

const UPGRADE_CARD := preload("res://Scenes/UpgradeCard.tscn")

@onready var health_bar: StatBar = $HealthBar
@onready var dash_bar: StatBar = $DashBar
@onready var corruption_bar: StatBar = $CorruptionBar

@onready var status_label: Label = $StatusLabel
@onready var upgrade_panel: Control = $UpgradePanel
@onready var _card_row: HBoxContainer = $UpgradePanel/Cards
@onready var tier_label: Label = $TierLabel

var _player: PlayerController = null
var _status_token := 0
var _upgrade_callback: Callable

func _skip_upgrade() -> void:
	# The card lambda with no card: same visible guard, hide the panel, then
	# call the stored callback with an empty dictionary.
	if not upgrade_panel.visible:
		return
	upgrade_panel.visible = false
	_upgrade_callback.call({})
	
func _ready() -> void:
	GameManager.register_hud(self)
	status_label.visible = false
	upgrade_panel.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$UpgradePanel/Skip.pressed.connect(_skip_upgrade)
func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	health_bar.set_ratio(_player.health.get_ratio())
	corruption_bar.set_ratio(_player.corruption / _player.max_corruption)
	dash_bar.set_ratio(_player.get_dash_ratio())
	tier_label.text = _player.get_corruption_tier()

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
