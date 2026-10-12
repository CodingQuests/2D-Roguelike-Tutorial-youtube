class_name ItemPedestal
extends Area2D

signal chosen(pedestal: ItemPedestal, def: Dictionary)

var def: Dictionary = {}
var price: int = 0          # gold cost (shops)
var hp_cost: int = 0        # max-HP cost (altar)
var reroll: bool = false
# Which room this belongs to, so the room can find its siblings later.
var room: int = -1
@onready var _prompt: Label = $Prompt

var _busy := false
var _player_here := false


func configure(item_def: Dictionary, gold_price: int, is_reroll: bool = false) -> void:
	def = item_def
	price = gold_price
	reroll = is_reroll

func _ready() -> void:
	# Connect enter and exit, hide the prompt, then build the orb and the text.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_prompt.visible = false
	_build_visual()

func _build_visual() -> void:
	# Nothing to show, return.
	if def.is_empty() and not reroll:
		return
	# A four-point diamond, coloured by rarity, sitting above the plinth.
	var orb := Polygon2D.new()
	orb.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(7, 0), Vector2(0, 8), Vector2(-7, 0)
	])
	orb.color = _rarity_colour(String(def.get("rarity", "common")))
	orb.position = Vector2(0, -22)
	add_child(orb)

	# The title, with the price tacked on after it in gold or HP, whichever is set.
	var label := Label.new()
	label.text = "REROLL" if reroll else String(def.get("title", ""))
	if price > 0:
		label.text += "  %dg" % price
	elif hp_cost > 0:
		label.text += "  %d HP" % hp_cost
	label.position = Vector2(-40, 6)
	add_child(label)
	
func _rarity_colour(rarity: String) -> Color:
	match rarity:
		"cursed": return Color(0.85, 0.35, 1.0)
		"rare":   return Color(0.4, 0.75, 1.0)
		_:        return Color(0.85, 0.85, 0.85)
		
		

func _process(_delta: float) -> void:
	# In range and not mid-buy: pulse the prompt with a sine on the clock, and
	# if F went down this frame, _take().
	if _player_here and not _busy:
		_prompt.modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() / 160.0)
		if Input.is_action_just_pressed("interact"):
			_take()
		
		
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_here = true
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_here = false
		_prompt.visible = false


func _take() -> void:
	if _busy:
		return
	# Latch and emit. This doesn't decide anything, the room does.
	_busy = true
	_prompt.visible = false
	chosen.emit(self, def)
	
func refuse() -> void:
	# Unlatch, bring the prompt back, and say NOT ENOUGH in red.
	_busy = false
	_prompt.visible = _player_here
	Juice.floating_text(get_tree().current_scene, global_position,
		"NOT ENOUGH", Color(1.0, 0.4, 0.35), 12)
	AudioManager.play("click", -4.0, 0.7)

func consume() -> void:
	Juice.impact(get_tree().current_scene, global_position,
		Color(1.0, 0.9, 0.6), 14, 1.2)
	AudioManager.play("upgrade")
	queue_free()
