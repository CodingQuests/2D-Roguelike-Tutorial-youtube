class_name UpgradeCard
extends PanelContainer

signal chosen(def: Dictionary)

var _def: Dictionary

func _ready() -> void:
	# Wires the TAKE button.
	$VBox/Choose.pressed.connect(_on_choose_pressed)


func setup(def: Dictionary) -> void:
	# Store the def, fill the two labels, tint the title by rarity.
	_def = def
	$VBox/Title.text = def["title"]
	$VBox/Desc.text = def["desc"]
	$VBox/Title.add_theme_color_override("font_color", _rarity_colour(def["rarity"]))
	
func _rarity_colour(rarity: String) -> Color:
	# Violet for cursed, blue for rare. The underscore is the default: light grey.
	match rarity:
		"cursed": return Color(0.85, 0.35, 1.0)
		"rare":   return Color(0.4, 0.75, 1.0)
		_:        return Color(0.85, 0.85, 0.85)
		
		
func _on_choose_pressed() -> void:
	# Disable before emitting, so a second click on the same card can't fire twice.
	$VBox/Choose.disabled = true
	chosen.emit(_def)
