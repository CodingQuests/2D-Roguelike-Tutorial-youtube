extends Node
## Autoload ("MetaProgression"). Persistent between-run progress: banked essence
## and permanent unlocks, saved to user:// with ConfigFile. The Forge (hub) lets
## you spend essence; PlayerController applies the unlocks at the start of a run.

const SAVE_PATH := "user://forge_save.cfg"

# Unlock id -> cost, and id -> display text.
const COSTS := {"daggers": 60, "vigor": 40, "honed": 35, "swift": 30}
const NAMES := {
	"daggers": "Twin Fangs — unlock a 3rd weapon",
	"vigor": "Vigor — start with +25 max HP",
	"honed": "Honed Edge — start with +6 quick damage",
	"swift": "Fleet Boots — start +8% movement speed",
}

# Player-facing volume sliders, 0..1. 1.0 means "the level the game was mixed
# at" (see AudioManager.BUS_BASE_DB), not 0 dB.
const DEFAULT_VOLUMES := {"master": 0.9, "sfx": 0.9, "music": 0.55}

var total_essence: int = 0
var unlocks: Dictionary = {}
var volumes: Dictionary = DEFAULT_VOLUMES.duplicate()


func _ready() -> void:
	load_game()
	# AudioManager is registered before this autoload, so it can't read the saved
	# volumes itself — push them once they're loaded.
	AudioManager.apply_volume_settings()


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	total_essence = int(cfg.get_value("meta", "essence", 0))
	var u = cfg.get_value("meta", "unlocks", {})
	unlocks = u if u is Dictionary else {}
	for key in DEFAULT_VOLUMES:
		volumes[key] = clampf(float(cfg.get_value("audio", key, DEFAULT_VOLUMES[key])), 0.0, 1.0)


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "essence", total_essence)
	cfg.set_value("meta", "unlocks", unlocks)
	for key in volumes:
		cfg.set_value("audio", key, volumes[key])
	cfg.save(SAVE_PATH)


func get_volume(key: String) -> float:
	return clampf(float(volumes.get(key, DEFAULT_VOLUMES.get(key, 1.0))), 0.0, 1.0)


func set_volume(key: String, value: float) -> void:
	volumes[key] = clampf(value, 0.0, 1.0)
	AudioManager.apply_volume_settings()


func ids() -> Array:
	return COSTS.keys()


func display_name(id: String) -> String:
	return NAMES.get(id, id)


func cost(id: String) -> int:
	return int(COSTS.get(id, 9999))


func is_unlocked(id: String) -> bool:
	return bool(unlocks.get(id, false))


func can_buy(id: String) -> bool:
	return not is_unlocked(id) and total_essence >= cost(id)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	total_essence -= cost(id)
	unlocks[id] = true
	save_game()
	return true


## Add a finished run's essence to the bank.
func bank_run(essence: int) -> void:
	total_essence += essence
	save_game()
