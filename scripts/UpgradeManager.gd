class_name UpgradeManager
extends Node
## Holds every weapon upgrade / item and the logic to apply it. Each entry is a
## plain dictionary so it's trivial to read, edit and extend for the course.
##
## Items come in three flavours:
##   - STAT items: flat numeric bumps (common, cheap).
##   - EFFECT items: composable on-hit effects (burn, chill, chain, execute) that
##     stack — picking more compounds the build, Isaac-style.
##   - TRANSFORM items: change *how* the weapon works (ranged echoes, whirlwind,
##     twin strikes). These are `unique` so they only appear once.
##
## Owning the right pair fuses into a synergy (resolved in PlayerController).
## Stronger items cost more corruption — that tension is the heart of the game.

# rarity: "common" | "rare" | "cursed" (drives card colour and rough power).
# unique: true => only ever offered/owned once.
var _defs: Array = []


func _ready() -> void:
	_defs = [
		# --- Stat items (common) ---
		{"id": "sharpened", "title": "Sharpened Edge", "rarity": "common",
			"desc": "+8 quick slash damage", "corruption": 5, "apply": _apply_sharpened},
		{"id": "heavy_soul", "title": "Heavy Soul", "rarity": "common",
			"desc": "+12 heavy attack damage", "corruption": 8, "apply": _apply_heavy_soul},
		{"id": "wider_cleave", "title": "Wider Cleave", "rarity": "common",
			"desc": "+20% attack hitbox size", "corruption": 10, "apply": _apply_wider_cleave},
		{"id": "bulwark", "title": "Bulwark", "rarity": "common",
			"desc": "+25 max HP (and heal 25)", "corruption": 8, "apply": _apply_bulwark},
		{"id": "swift_boots", "title": "Swift Boots", "rarity": "common",
			"desc": "+12% movement speed", "corruption": 6, "apply": _apply_swift_boots},
		{"id": "rapid_edge", "title": "Rapid Edge", "rarity": "common",
			"desc": "-20% attack cooldowns", "corruption": 10, "apply": _apply_rapid_edge},
		{"id": "cursed_speed", "title": "Cursed Speed", "rarity": "common",
			"desc": "-20% dash cooldown", "corruption": 12, "apply": _apply_cursed_speed},

		# --- Sustain / risk items (rare) ---
		{"id": "blood_pact", "title": "Blood Pact", "rarity": "rare",
			"desc": "Heal 3 HP on enemy kill", "corruption": 15, "apply": _apply_blood_pact},
		{"id": "vampiric_edge", "title": "Vampiric Edge", "rarity": "rare",
			"desc": "Heal 1.5 HP on every hit landed", "corruption": 14, "apply": _apply_vampiric_edge},
		{"id": "berserker", "title": "Berserker", "rarity": "rare",
			"desc": "+30% damage while below 40% HP", "corruption": 18, "apply": _apply_berserker},
		{"id": "glass_blade", "title": "Glass Blade", "rarity": "cursed",
			"desc": "+25% damage, but take +15% damage", "corruption": 15, "apply": _apply_glass_blade},
		{"id": "corrupted_aura", "title": "Corrupted Aura", "rarity": "rare",
			"desc": "Damage nearby enemies for 5 every 2s", "corruption": 20, "apply": _apply_corrupted_aura},

		# --- Effect items (stackable on-hit) ---
		{"id": "ember_brand", "title": "Ember Brand", "rarity": "rare",
			"desc": "Hits set enemies on fire (+6 burn/sec)", "corruption": 12, "apply": _apply_ember},
		{"id": "frost_bite", "title": "Frost Bite", "rarity": "rare",
			"desc": "Hits chill enemies, slowing them 30%", "corruption": 10, "apply": _apply_frost},
		{"id": "storm_coil", "title": "Storm Coil", "rarity": "rare",
			"desc": "Hits arc lightning to a nearby enemy", "corruption": 14, "apply": _apply_storm},
		{"id": "reapers_mark", "title": "Reaper's Mark", "rarity": "cursed",
			"desc": "Execute enemies below 14% HP", "corruption": 16, "apply": _apply_reaper},

		# --- Transform items (unique) ---
		{"id": "echo_blade", "title": "Echo Blade", "rarity": "rare", "unique": true,
			"desc": "Every swing throws a slash wave (ranged!)", "corruption": 14, "apply": _apply_echo},
		{"id": "whirlwind", "title": "Maelstrom", "rarity": "cursed", "unique": true,
			"desc": "Heavy attack becomes a 360° whirlwind", "corruption": 18, "apply": _apply_whirlwind},
		{"id": "twin_strike", "title": "Twin Fang Curse", "rarity": "rare", "unique": true,
			"desc": "Every hit strikes a second time", "corruption": 16, "apply": _apply_twin},

		# --- Active abilities ([E], single slot, unique) ---
		{"id": "forge_pulse", "title": "Forge Pulse", "rarity": "rare", "unique": true,
			"desc": "ACTIVE [E]: nova blast — damage & knock back foes", "corruption": 10, "apply": _apply_active_pulse},
		{"id": "phase_step", "title": "Phase Step", "rarity": "rare", "unique": true,
			"desc": "ACTIVE [E]: blink toward your aim (i-frames)", "corruption": 8, "apply": _apply_active_phase},
		{"id": "blood_siphon", "title": "Blood Siphon", "rarity": "cursed", "unique": true,
			"desc": "ACTIVE [E]: drain nearby foes to heal", "corruption": 14, "apply": _apply_active_siphon},

		# --- Relief ---
		{"id": "cleansing_light", "title": "Cleansing Light", "rarity": "common",
			"desc": "Purge 25 corruption from your weapon", "corruption": -25, "apply": _apply_noop},
	]


## Rarity weighting: commons show up most, cursed least, so a rare/cursed card
## feels like a find. Used for the offered draws below.
const RARITY_WEIGHT := {"common": 3.0, "rare": 1.6, "cursed": 1.0}


## Cleansing Light's entire value is removing corruption. Offered while you're
## near zero it purges nothing — a wasted third of the choice. Hold it back
## until there's actually something to burn off.
const CLEANSE_MIN_CORRUPTION := 12.0


## Pick `count` distinct items to offer, weighted by rarity. Unique items the
## player already owns are filtered out so they never appear twice, and dead
## picks (see above) are held back.
func get_choices(count: int) -> Array:
	var owned: Array = _owned_unique_ids()
	var pool: Array = []
	for d in _defs:
		if d.get("unique", false) and owned.has(d["id"]):
			continue
		if d["id"] == "cleansing_light" and _player_corruption() < CLEANSE_MIN_CORRUPTION:
			continue
		pool.append(d)
	return _weighted_sample(pool, count)


func _player_corruption() -> float:
	var p: Node = GameManager.player
	return float(p.corruption) if (p and "corruption" in p) else 0.0


# Weighted sampling without replacement, by rarity.
func _weighted_sample(pool: Array, count: int) -> Array:
	pool = pool.duplicate()
	var picks: Array = []
	for n in range(mini(count, pool.size())):
		var total := 0.0
		for d in pool:
			total += float(RARITY_WEIGHT.get(str(d.get("rarity", "common")), 1.0))
		var r := randf() * total
		var chosen: Dictionary = pool[0]
		for d in pool:
			r -= float(RARITY_WEIGHT.get(str(d.get("rarity", "common")), 1.0))
			if r <= 0.0:
				chosen = d
				break
		picks.append(chosen)
		pool.erase(chosen)
	return picks


func _owned_unique_ids() -> Array:
	var ids: Array = []
	var p: Node = GameManager.player
	if p and ("items" in p):
		for d in p.items:
			ids.append(d.get("id", ""))
	return ids


## Forge Altar deals only offer POWER (no common stat bumps, no cleanse) — the
## price is paid in flesh (max HP), not corruption.
func get_deal_choices(count: int) -> Array:
	var owned: Array = _owned_unique_ids()
	var pool: Array = []
	for d in _defs:
		if d.get("unique", false) and owned.has(d["id"]):
			continue
		if str(d.get("rarity", "common")) == "common" or d["id"] == "cleansing_light":
			continue
		pool.append(d)
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))


## Apply a chosen item: run its effect, optionally charge corruption, and record
## ownership (which also recomputes synergies on the player). Altar deals pass
## `charge_corruption = false` because their cost is max HP instead.
func apply(player: Node, def: Dictionary, charge_corruption: bool = true) -> void:
	var apply_fn: Callable = def["apply"]
	apply_fn.call(player)
	if charge_corruption:
		player.add_corruption(float(def["corruption"]))
	if player.has_method("add_item"):
		player.add_item(def)
	player.on_stats_changed()


# --- Stat items --------------------------------------------------------
func _apply_sharpened(p: Node) -> void:
	p.quick_bonus_damage += 8.0


func _apply_heavy_soul(p: Node) -> void:
	p.heavy_bonus_damage += 12.0


func _apply_wider_cleave(p: Node) -> void:
	p.hitbox_scale *= 1.2


func _apply_bulwark(p: Node) -> void:
	p.health.set_max_health(p.health.max_health + 25.0)
	p.health.heal(25.0)


func _apply_swift_boots(p: Node) -> void:
	p.move_speed_mult *= 1.12


func _apply_rapid_edge(p: Node) -> void:
	p.attack_cooldown_mult *= 0.8


func _apply_cursed_speed(p: Node) -> void:
	p.dash_cooldown *= 0.8


# --- Sustain / risk ----------------------------------------------------
func _apply_blood_pact(p: Node) -> void:
	p.heal_on_kill += 3.0


func _apply_vampiric_edge(p: Node) -> void:
	p.heal_on_hit += 1.5


func _apply_berserker(p: Node) -> void:
	p.berserker_enabled = true


func _apply_glass_blade(p: Node) -> void:
	p.glass_damage_mult *= 1.25
	p.glass_taken_mult *= 1.15


func _apply_corrupted_aura(p: Node) -> void:
	p.aura_enabled = true


# --- Effect items (stack) ----------------------------------------------
func _apply_ember(p: Node) -> void:
	p.burn_dps += 6.0


func _apply_frost(p: Node) -> void:
	p.chill_factor = clampf(p.chill_factor + 0.3, 0.0, 0.7)


func _apply_storm(p: Node) -> void:
	p.chain_count += 1


func _apply_reaper(p: Node) -> void:
	# First pick sets the threshold; further picks raise it.
	p.execute_threshold = maxf(p.execute_threshold, 0.0) + (0.14 if p.execute_threshold == 0.0 else 0.05)


# --- Transform items (unique) ------------------------------------------
func _apply_echo(p: Node) -> void:
	p.echo_level += 1


func _apply_whirlwind(p: Node) -> void:
	p.whirlwind = true


func _apply_twin(p: Node) -> void:
	p.twin_strike = true


# --- Active abilities (single [E] slot — picking one replaces it) -------
func _apply_active_pulse(p: Node) -> void:
	p.set_active_item("forge_pulse", "Forge Pulse", 6.0)


func _apply_active_phase(p: Node) -> void:
	p.set_active_item("phase_step", "Phase Step", 4.0)


func _apply_active_siphon(p: Node) -> void:
	p.set_active_item("blood_siphon", "Blood Siphon", 8.0)


# Cleansing Light has no stat effect — its benefit is the negative corruption
# cost applied by apply().
func _apply_noop(_p: Node) -> void:
	pass
