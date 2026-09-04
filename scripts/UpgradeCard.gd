class_name UpgradeCard
extends Control
## One selectable upgrade card. Pure Godot Control nodes (Panel + VBox + Labels
## + Button) — no custom art. The HUD spawns three of these after a room clears.
## Cards fly in, lift on hover, and flash when chosen so picking an upgrade feels
## like a real decision.

@onready var title_label: Label = $Panel/VBox/Title
@onready var desc_label: Label = $Panel/VBox/Description
@onready var corruption_label: Label = $Panel/VBox/Corruption
@onready var choose_button: Button = $Panel/VBox/Choose
@onready var rarity_strip: ColorRect = $Panel/VBox/Rarity

signal chosen(def: Dictionary)

var _def: Dictionary
var _chosen := false


func _ready() -> void:
	choose_button.pressed.connect(_on_pressed)
	# Let the whole card receive hover, but keep the button clickable.
	for c in $Panel.find_children("*", "Control", true, false):
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	choose_button.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	pivot_offset = custom_minimum_size * 0.5
	_appear()


# Scale + fade in, staggered by the card's slot so they cascade.
func _appear() -> void:
	modulate.a = 0.0
	scale = Vector2(0.7, 0.7)
	var tw := create_tween()
	tw.tween_interval(get_index() * 0.07)
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)


func _on_hover(entered: bool) -> void:
	if _chosen:
		return
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.06, 1.06) if entered else Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD)


const RARITY_COLORS := {
	"common": Color(0.85, 0.88, 0.92),
	"rare": Color(0.45, 0.75, 1.0),
	"cursed": Color(1.0, 0.45, 0.5),
}

func setup(def: Dictionary) -> void:
	_def = def
	# @onready vars may not be set yet if setup() is called right after instancing.
	if title_label == null:
		await ready
	title_label.text = str(def["title"]).to_upper()
	desc_label.text = str(def["desc"])
	# Rarity reads off a colour strip along the top edge as well as the title —
	# a band of colour is legible at a glance in a row of three cards in a way
	# that coloured text alone is not.
	var rarity := str(def.get("rarity", "common"))
	var rc: Color = RARITY_COLORS.get(rarity, Color.WHITE)
	title_label.add_theme_color_override("font_color", rc)
	rarity_strip.color = rc
	if rarity != "common":
		$Panel.self_modulate = Color.WHITE.lerp(rc, 0.18)
	var c := int(def["corruption"])
	if c < 0:
		corruption_label.text = "CLEANSES %d CORRUPTION" % (-c)
		corruption_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.6))
	elif c == 0:
		corruption_label.text = "NO CORRUPTION"
		corruption_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
	else:
		corruption_label.text = "+%d CORRUPTION" % c
		# Redder as the corruption cost climbs.
		var t := clampf(c / 20.0, 0.0, 1.0)
		corruption_label.add_theme_color_override("font_color", Color(0.78, 0.45, 0.9).lerp(Color(0.95, 0.3, 0.3), t))


func _on_pressed() -> void:
	if _chosen:
		return
	_chosen = true
	# Selection flash: a white pop + scale punch before committing.
	modulate = Color(1.6, 1.6, 1.6, 1.0)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(self, "modulate", Color.WHITE, 0.12)
	tw.tween_callback(func() -> void: chosen.emit(_def))
