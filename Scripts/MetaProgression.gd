extends Node

const SAVE_PATH := "user://forge_save.cfg"

var total_essence: int = 0
var unlocks: Dictionary = {}

const COSTS := {"daggers": 60, "vigor": 40, "honed": 35, "swift": 30}
const NAMES := {
	"daggers": "Twin Fangs — unlock a 3rd weapon",
	"vigor":   "Vigor — start with +25 max HP",
	"honed":   "Honed Edge — start with +6 quick damage",
	"swift":   "Fleet Boots — start +8% movement speed",
}

var audio_settings := {"master": 0.9, "sfx": 0.9, "music": 0.55}

func _ready() -> void:
	# Autoload: this runs before any scene exists.
	load_game()
	AudioManager.apply_mix(audio_settings)
	
	
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
	for key in audio_settings:
		audio_settings[key] = clampf(float(cfg.get_value("audio", key, audio_settings[key])), 0.0, 1.0)

func save_game() -> void:
	# One section, two keys, write.
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "essence", total_essence)
	cfg.set_value("meta", "unlocks", unlocks)
	for key in audio_settings:
		cfg.set_value("audio", key, audio_settings[key])
	var error := cfg.save(SAVE_PATH)
	if error != OK:
		# error_string turns the code into words you can read in the output.
		push_error("Could not save Forge progress: %s" % error_string(error))
func bank_run(essence: int) -> void:
	total_essence += maxi(0, essence)
	# Saved on the spot, so a crash after the death screen can't lose it.
	save_game()

func cost(id: String) -> int:
	# 999999 for an id that isn't in the table: a typo is unaffordable, not free.
	return int(COSTS.get(id, 999999))
	
func is_unlocked(id: String) -> bool:
	# Reads the saved dictionary. false if that key has never been written.
	return bool(unlocks.get(id, false))

func can_buy(id: String) -> bool:
	# Three checks: a real id, not already owned, and you can afford it.
	return COSTS.has(id) and not is_unlocked(id) and total_essence >= cost(id)

func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	# Subtract, mark it owned, save straight away.
	total_essence -= cost(id)
	unlocks[id] = true
	save_game()
	# Whether it happened, so the Hub knows whether to play the sound.
	return true
	
func set_audio_setting(key: String, value: float) -> void:
	if not audio_settings.has(key):
		return
	audio_settings[key] = clampf(value, 0.0, 1.0)
	AudioManager.apply_mix(audio_settings)
	save_game()
