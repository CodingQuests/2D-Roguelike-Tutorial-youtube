class_name ItemPedestal
extends Area2D
## A walk-up stand that offers one item. Used in Treasure rooms (free), Shops
## (priced) and the Forge Altar (max-HP cost). Stand on it and press the interact
## key (F) to take/buy — a floating prompt appears while you're in range.
##
## The static structure (Area2D + collision shape + layers, shadow, stone base,
## the prompt Label) lives in ItemPedestal.tscn; this script only builds the
## DATA-DRIVEN bits (the rarity-coloured orb and the name/price labels) and wires
## the interaction. A special "reroll" pedestal carries no item and re-stocks the
## shop instead.

signal chosen(pedestal: ItemPedestal, def: Dictionary)

const LIGHT_TEX := preload("res://light_radial.tres")
var def: Dictionary = {}
var price: int = 0          # gold cost (shops)
var hp_cost: int = 0        # max-HP cost (forge altar deals)
var reroll: bool = false
var room: int = -1          # which dungeon room this pedestal belongs to

@onready var _prompt: Label = $Prompt

var _orb: Polygon2D
var _light: PointLight2D = null
var _time := 0.0
var _busy := false
var _player_here := false


func configure(item_def: Dictionary, gold_price: int, is_reroll: bool = false) -> void:
	def = item_def
	price = gold_price
	reroll = is_reroll


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()


func _process(delta: float) -> void:
	_time += delta
	if _orb:
		_orb.position.y = -22.0 + sin(_time * 3.0) * 1.8
	if _light:
		# Breathes gently, then flares while you're standing in range.
		var target := 1.05 if (_player_here and not _busy) else 0.55
		_light.energy = lerpf(_light.energy, target, 1.0 - exp(-6.0 * delta))
		_light.energy *= 1.0 + 0.08 * sin(_time * 2.4)
	# Pulse the prompt and take the interact press while the player is on us.
	if _player_here and not _busy:
		_prompt.modulate.a = 0.7 + 0.3 * sin(_time * 6.0)
		if Input.is_action_just_pressed("interact"):
			chosen.emit(self, def)


# Builds only the data-driven visuals; the plinth/shadow/prompt are in the scene.
func _build_visual() -> void:
	var rc: Color = Color(0.8, 0.85, 0.5) if reroll else _rarity_color(str(def.get("rarity", "common")))

	# The orb is a real light source, so a pedestal is visible across a dark room
	# and brightens as you approach. Rarity tints the light, which means you can
	# tell a cursed offer from a common one from the doorway.
	_light = PointLight2D.new()
	_light.texture = LIGHT_TEX
	_light.texture_scale = 1.1
	_light.energy = 0.55
	_light.color = rc
	_light.position = Vector2(0, -22)
	add_child(_light)

	# Glow + rimmed orb floating above the plinth, with a shine highlight.
	var glow := Polygon2D.new()
	glow.color = Color(rc.r, rc.g, rc.b, 0.28)
	glow.position = Vector2(0, -22)
	glow.polygon = Juice._circle_points(13.0, 14)
	add_child(glow)

	var rim := Polygon2D.new()
	rim.color = rc.darkened(0.45)
	rim.position = Vector2(0, -22)
	rim.polygon = Juice._circle_points(8.0, 14)
	add_child(rim)

	_orb = Polygon2D.new()
	_orb.color = rc
	_orb.position = Vector2(0, -22)
	_orb.polygon = Juice._circle_points(6.5, 14)
	add_child(_orb)

	var shine := Polygon2D.new()
	shine.color = Color(1, 1, 1, 0.7)
	shine.position = Vector2(-2, -2)
	shine.polygon = Juice._circle_points(2.0, 14)
	_orb.add_child(shine)

	# Item name ABOVE the orb (the reroll stand has no name up top).
	if not reroll:
		_add_label(str(def.get("title", "?")), -54, rc)

	# Price/label BELOW the base: blood (altar) / gold (shop) / FREE / REROLL.
	var tag_text := ""
	var tag_col := Color(1, 0.82, 0.25)
	if reroll:
		tag_text = "REROLL"
		tag_col = Color(0.85, 0.9, 0.5)
	elif hp_cost > 0:
		tag_text = "-%d Max HP" % hp_cost
		tag_col = Color(0.95, 0.25, 0.3)
	elif price > 0:
		tag_text = "%d Gold" % price
	else:
		tag_text = "FREE"
	_add_label(tag_text, 11, tag_col)

	_prompt.text = _prompt_text()


func _prompt_text() -> String:
	if reroll:
		return "Press F — Reroll"
	if hp_cost > 0:
		return "Press F — Offer"
	if price > 0:
		return "Press F — Buy"
	return "Press F — Take"


# A centered, outlined world-space label fixed to a wide box so text of any
# length stays centered on the pedestal.
func _add_label(text: String, y: float, col: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.custom_minimum_size = Vector2(170, 18)
	lbl.size = Vector2(170, 18)
	lbl.position = Vector2(-85, y)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)


func _on_body_entered(body: Node) -> void:
	if _busy or not body.is_in_group("player"):
		return
	_player_here = true
	_prompt.visible = true


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_here = false
	_prompt.visible = false


## Pop + fade out when taken/bought, then free.
func consume() -> void:
	_busy = true
	_player_here = false
	_prompt.visible = false
	set_deferred("monitoring", false)
	Juice.ring(get_tree().current_scene, global_position - Vector2(0, 22), Color(1, 0.9, 0.5, 0.8), 30.0, 0.35, 3.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)


## Shake/flash when the player can't afford it.
func deny(reason: String = "Not enough gold") -> void:
	AudioManager.play("telegraph", -6.0, 0.7)
	Juice.floating_text(get_tree().current_scene, global_position - Vector2(0, 36), reason, Color(1, 0.4, 0.4), 13)


func _rarity_color(rarity: String) -> Color:
	return UpgradeCard.RARITY_COLORS.get(rarity, Color(0.85, 0.88, 0.92))
