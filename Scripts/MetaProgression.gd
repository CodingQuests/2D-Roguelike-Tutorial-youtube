extends Node

const SAVE_PATH := "user://forge_save.cfg"

var total_essence: int = 0
var unlocks: Dictionary = {}

func _ready() -> void:
	# Autoload: this runs before any scene exists.
	load_game()
	
	
	
func load_game() -> void:
	# Defaults first, then try the file.
	total_essence = 0
	unlocks = {}
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return              # no save yet — defaults are correct
	# maxi so a hand-edited negative can't get in.
	total_essence = maxi(0, int(cfg.get_value("meta", "essence", 0)))
	var u = cfg.get_value("meta", "unlocks", {})
	unlocks = u if u is Dictionary else {}


func save_game() -> void:
	# One section, two keys, write.
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "essence", total_essence)
	cfg.set_value("meta", "unlocks", unlocks)
	var error := cfg.save(SAVE_PATH)
	if error != OK:
		# error_string turns the code into words you can read in the output.
		push_error("Could not save Forge progress: %s" % error_string(error))

func bank_run(essence: int) -> void:
	total_essence += maxi(0, essence)
	# Saved on the spot, so a crash after the death screen can't lose it.
	save_game()
