class_name UpgradeManager
extends Node


# rarity: "common" | "rare" | "cursed"
var _defs: Array = []
const RARITY_WEIGHT := {"common": 3.0, "rare": 1.6, "cursed": 1.0}

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


func _apply_rapid_edge(p: PlayerController) -> void:
	p.attack_cooldown_mult *= 0.8
	
	
func get_choices(count: int) -> Array:
	var owned: Array = _owned_unique_ids()
	# The pool is built by hand now. Skip any unique you already own, keep the
	# rest, hand it to the weighted sample.
	var pool: Array = []
	for d in _defs:
		if d.get("unique", false) and owned.has(d["id"]):
			continue
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
	var p := GameManager.player
	# Null guard first: this can run before a player exists.
	if p == null:
		return ids
	# None of the five commons have a "unique" key yet, so they read as false
	# and nothing's filtered until a unique exists.
	for it in p.items:
		if it.get("unique", false):
			ids.append(it["id"])
	return ids
	
