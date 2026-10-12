extends CanvasLayer


@onready var health_bar: StatBar = $HealthBar
@onready var dash_bar: StatBar = $DashBar
@onready var status_label: Label = $StatusLabel

var _player: PlayerController = null
var _status_token := 0


func _ready() -> void:
	GameManager.register_hud(self)
	status_label.visible = false

func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	health_bar.set_ratio(_player.health.get_ratio())
	dash_bar.set_ratio(_player.get_dash_ratio())

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
			
			
