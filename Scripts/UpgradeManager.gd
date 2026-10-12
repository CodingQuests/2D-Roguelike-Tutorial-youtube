class_name UpgradeManager
extends Node


# rarity: "common" | "rare" | "cursed"
var _defs: Array = []
const RARITY_WEIGHT := {"common": 3.0, "rare": 1.6, "cursed": 1.0}
const CLEANSE_MIN_CORRUPTION := 12.0

func _ready() -> void:
	# One dictionary per upgrade, five fields each. "apply" is the function itself,
	# not a string with its name in it: no lookup table, no match.
	_defs = [
		{"id": "sharpened", "title": "Sharpened Edge", "rarity": "common",
			"desc": "+8 quick slash damage", "corruption": 5, "apply": _apply_sharpened},
		{"id": "heavy_soul", "title": "Heavy Soul", "rarity": "common",
			"desc": "+12 heavy attack damage", "corruption": 8, "apply": _apply_heavy_soul},
		{"id": "bulwark", "title": "Bulwark", "rarity": "common",
			"desc": "+25 max HP (and heal 25)", "corruption": 8, "apply": _apply_bulwark},
		{"id": "swift_boots", "title": "Swift Boots", "rarity": "common",
			"desc": "+12% movement speed", "corruption": 6, "apply": _apply_swift_boots},
		{"id": "rapid_edge", "title": "Rapid Edge", "rarity": "common",
			"desc": "-20% attack cooldowns", "corruption": 10, "apply": _apply_rapid_edge},
		{"id": "glass_blade", "title": "Glass Blade", "rarity": "cursed",
		"desc": "+25% damage, but take +15% damage", "corruption": 15, "apply": _apply_glass},
		{"id": "cleansing_light", "title": "Cleansing Light", "rarity": "common",
			"desc": "Purge 25 corruption from your weapon", "corruption": -25,
			"apply": _apply_noop},
		{"id": "ember_brand", "title": "Ember Brand", "rarity": "rare",
		"desc": "Hits set enemies on fire (+6 burn/sec)", "corruption": 12, "apply": _apply_ember},
		{"id": "frost_bite", "title": "Frost Bite", "rarity": "rare",
		"desc": "Hits chill enemies, slowing them 30%", "corruption": 10, "apply": _apply_frost},
		{"id": "storm_coil", "title": "Storm Coil", "rarity": "rare",
		"desc": "Hits arc lightning to a nearby enemy", "corruption": 14, "apply": _apply_storm},
		{"id": "reapers_mark", "title": "Reaper's Mark", "rarity": "cursed",
		"desc": "Execute enemies below 14% HP", "corruption": 16, "apply": _apply_reaper},
		{"id": "echo_blade", "title": "Echo Blade", "rarity": "rare", "unique": true,
		"desc": "Every swing throws a slash wave (ranged!)", "corruption": 14, "apply": _apply_echo},
		{"id": "whirlwind", "title": "Maelstrom", "rarity": "cursed", "unique": true,
		"desc": "Heavy attack becomes a 360° whirlwind", "corruption": 18, "apply": _apply_whirlwind},
		{"id": "twin_strike", "title": "Twin Fang Curse", "rarity": "rare", "unique": true,
		"desc": "Every melee hit adds a second strike for 50% damage", "corruption": 16, "apply": _apply_twin},
		{"id": "forge_pulse", "title": "Forge Pulse", "rarity": "rare", "unique": true,
		"desc": "E: blast everything around you", "corruption": 10, "apply": _apply_pulse},
		{"id": "phase_step", "title": "Phase Step", "rarity": "rare", "unique": true,
		"desc": "E: blink, briefly invulnerable", "corruption": 10, "apply": _apply_phase},
		{"id": "blood_siphon", "title": "Blood Siphon", "rarity": "cursed", "unique": true,
		"desc": "E: drain an enemy to heal", "corruption": 14, "apply": _apply_siphon},
		

	]

func _apply_sharpened(p: PlayerController) -> void:
	p.quick_bonus_damage += 8.0
	
func _apply_heavy_soul(p: PlayerController) -> void:
	p.heavy_bonus_damage += 12.0
	
	
func _apply_bulwark(p: PlayerController) -> void:
	# Raise the max first, then heal the same amount, so the extra 25 isn't empty bar.
	p.health.set_max_health(p.health.max_health + 25.0)
	p.health.heal(25.0)


func _apply_swift_boots(p: PlayerController) -> void:
	p.move_speed_mult *= 1.12


func _apply_glass(p: PlayerController) -> void:
	# Multiply rather than set: a second copy stacks on the first instead of overwriting.
	p.glass_damage_mult *= 1.25
	p.glass_taken_mult *= 1.15
	
func _apply_rapid_edge(p: PlayerController) -> void:
	p.attack_cooldown_mult *= 0.8
	
func _apply_noop(_p: PlayerController) -> void:
	# Exists because every def needs an "apply". The underscore on _p tells
	# Godot the unused argument is on purpose, so no warning.
	pass
func _player_corruption() -> float:
	# Null-safe read. No player yet, treat it as zero, and Cleansing Light
	# stays out of the pool.
	var p := GameManager.player
	return p.corruption if p != null else 0.0


func _apply_ember(p: PlayerController) -> void:
	p.burn_dps += 6.0

func _apply_frost(p: PlayerController) -> void:
	p.chill_factor = clampf(p.chill_factor + 0.3, 0.0, 0.85)

func _apply_storm(p: PlayerController) -> void:
	p.chain_count = mini(p.chain_count + 1, 8)

func _apply_reaper(p: PlayerController) -> void:
	p.execute_threshold = minf(p.execute_threshold + 0.14, 0.5)
	
func _apply_echo(p: PlayerController) -> void:
	p.echo_level += 1

func _apply_whirlwind(p: PlayerController) -> void:
	p.whirlwind = true

func _apply_twin(p: PlayerController) -> void:
	p.twin_strike = true

func _apply_pulse(p: PlayerController) -> void:
	p.set_active_item("forge_pulse", "Forge Pulse", 6.0)

func _apply_phase(p: PlayerController) -> void:
	p.set_active_item("phase_step", "Phase Step", 5.0)

func _apply_siphon(p: PlayerController) -> void:
	p.set_active_item("blood_siphon", "Blood Siphon", 8.0)
	
	
func get_choices(count: int) -> Array:
	var owned: Array = _owned_unique_ids()
	# The pool is built by hand now. Skip any unique you already own, keep the
	# rest, hand it to the weighted sample.
	var pool: Array = []
	for d in _defs:
		if d.get("unique", false) and owned.has(d["id"]):
			continue
		# Same shape as the unique check. Not enough corruption to be worth purging,
		# skip it out of the pool. The backslash is just a line break.
		if d["id"] == "cleansing_light" \
				and _player_corruption() < CLEANSE_MIN_CORRUPTION:    # ← NEW
			continue                                                  # ← NEW
		pool.append(d)
	return _weighted_sample(pool, count)



func _weighted_sample(pool: Array, count: int) -> Array:
	# Copy: the caller's array survives, we're about to remove things from it.
	pool = pool.duplicate()
	var picks: Array = []
	# Ask for three from a pool of two and you get two, not an error.
	for n in range(mini(count, pool.size())):
		# Total the weights of whatever's left. A rarity not in the table
		# still counts, at weight one.
		var total := 0.0
		for d in pool:
			total += float(RARITY_WEIGHT.get(d["rarity"], 1.0))
		# Roll between zero and that total, then walk the pool adding weights
		# until the roll lands inside one. That's the pick.
		var roll := randf() * total
		var acc := 0.0
		for i in range(pool.size()):
			acc += float(RARITY_WEIGHT.get(pool[i]["rarity"], 1.0))
			if roll <= acc:
				picks.append(pool[i])
				pool.remove_at(i)
				break
	return picks

func _owned_unique_ids() -> Array:
	var ids: Array = []
	var p: Node = GameManager.player
	# Null guard first: this can run before a player exists.
	if p == null:
		return ids
	# None of the five commons have a "unique" key yet, so they read as false
	# and nothing's filtered until a unique exists.
	for it in p.items:
		if it.get("unique", false):
			ids.append(it["id"])
	return ids
	
