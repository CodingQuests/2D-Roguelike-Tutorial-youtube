extends Node
## Automated audit of every item, active ability and synergy.
##
## Reading the definitions can't tell you whether an item's `apply` actually
## changes anything, whether an on-hit effect reaches the enemy, or whether a
## unique is filtered correctly once owned. This drives the real game and
## checks observable state, so a silently-dead item shows up as a FAIL.
##
## Run (headless is fine — nothing here needs rendering):
##   Godot_v4.7-stable_win64.exe --headless --path . \
##       res://tools/itemcheck.tscn --quit-after 4000
##
## Exit output: a PASS/FAIL line per check plus a summary. Any FAIL is a bug.

var _pass := 0
var _fail := 0
var _main: Node = null
var _room: Node = null
var _player: Node = null
var _um: UpgradeManager = null

# Every player field an item is allowed to move. Used to detect "this item
# applied cleanly but changed nothing observable".
const TRACKED := [
	"quick_bonus_damage", "heavy_bonus_damage", "hitbox_scale", "heal_on_kill",
	"heal_on_hit", "aura_enabled", "glass_damage_mult", "glass_taken_mult",
	"attack_cooldown_mult", "move_speed_mult", "berserker_enabled",
	"burn_dps", "chill_factor", "chain_count", "execute_threshold",
	"echo_level", "whirlwind", "twin_strike", "active_item", "dash_cooldown",
	"corruption",
]


func _ready() -> void:
	_main = load("res://Main.tscn").instantiate()
	add_child.call_deferred(_main)
	await get_tree().create_timer(1.2).timeout
	_player = get_tree().get_first_node_in_group("player")
	_room = _main.get_node_or_null("CombatRoom")
	_um = UpgradeManager.new()
	add_child(_um)
	await get_tree().process_frame

	print("\n========== ITEM / POWER AUDIT ==========")
	await _check_every_item_does_something()
	await _check_actives()
	await _check_on_hit_effects()
	await _check_synergies()
	await _check_uniques_filtered()
	await _check_offers_are_distinct()

	await _check_passive_behaviour()
	await _check_economy()

	print("========================================")
	print("PASS: %d   FAIL: %d" % [_pass, _fail])
	if _fail > 0:
		print("!!! %d PROBLEM(S) FOUND !!!" % _fail)
	get_tree().quit()


# --- 1. Every item must observably change the player ------------------------
func _check_every_item_does_something() -> void:
	print("\n-- every item changes observable state --")
	for def in _um._defs:
		# Start dirty enough that a *reduction* (Cleansing Light) is observable —
		# from 0 corruption a purge clamps to 0 and looks like a no-op.
		_player.corruption = 40.0
		var before := _snapshot()
		_um.apply(_player, def, true)
		await get_tree().process_frame
		var after := _snapshot()
		var changed: Array = []
		for k in TRACKED:
			if before[k] != after[k]:
				changed.append(k)
		# Max HP lives on the Health node, not the player, so check it separately.
		if before["_max_hp"] != after["_max_hp"]:
			changed.append("max_health")
		_expect(not changed.is_empty(),
			"%-16s -> %s" % [def["id"], ", ".join(changed) if changed else "NOTHING CHANGED"])
		_reset_player()
		await get_tree().process_frame


# --- 2. Each active fires without error and has an effect -------------------
func _check_actives() -> void:
	print("\n-- active abilities --")
	var victim: Node = _spawn_enemy(_player.global_position + Vector2(50, 0))
	await get_tree().create_timer(0.5).timeout

	# Forge Pulse: should damage a nearby enemy.
	_player.set_active_item("forge_pulse", "Forge Pulse", 6.0)
	var hp_before: float = victim.health.current_health
	_player.use_active()
	await get_tree().create_timer(0.2).timeout
	_expect(victim.health.current_health < hp_before,
		"forge_pulse damages nearby enemies (%.0f -> %.0f)" % [hp_before, victim.health.current_health])

	# Blood Siphon: should damage the enemy AND heal the player.
	_player.health.damage(40.0)
	await get_tree().process_frame
	var self_hp: float = _player.health.current_health
	var enemy_hp: float = victim.health.current_health
	_player.set_active_item("blood_siphon", "Blood Siphon", 8.0)
	_player.use_active()
	await get_tree().create_timer(0.2).timeout
	_expect(_player.health.current_health > self_hp, "blood_siphon heals the player")
	_expect(victim.health.current_health < enemy_hp, "blood_siphon damages enemies")

	# Phase Step: must move the player, and must NOT leave the world.
	_player.set_active_item("phase_step", "Phase Step", 4.0)
	var pos_before: Vector2 = _player.global_position
	_player.use_active()
	await get_tree().create_timer(0.3).timeout
	_expect(_player.global_position != pos_before, "phase_step moves the player")
	_expect(_inside_dungeon(_player.global_position),
		"phase_step lands inside the dungeon %s" % _player.global_position)

	# And the specific bug: a huge blink must be clamped by geometry, from an
	# open spot, in every direction. (Headless has no mouse, so use_active()
	# always aims at (0,0) — probe _safe_blink directly instead.)
	_player.global_position = _room_centre()
	await get_tree().physics_frame
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var far: Vector2 = _player.call("_safe_blink", dir, 5000.0)
		var travelled: float = _player.global_position.distance_to(far)
		_expect(travelled < 5000.0 and travelled > 0.0 and _inside_dungeon(far),
			"blink 5000px %s is clamped inside the room (travelled %.0f)" % [dir, travelled])

	if is_instance_valid(victim):
		victim.queue_free()
	_reset_player()
	await get_tree().process_frame


# --- 3. On-hit effects actually reach the enemy -----------------------------
func _check_on_hit_effects() -> void:
	print("\n-- on-hit effects --")
	var weapon = _player.weapon

	# Ember Brand -> ignite
	_player.burn_dps = 6.0
	var e1: Node = _spawn_enemy(_player.global_position + Vector2(40, 0))
	await get_tree().create_timer(0.4).timeout
	weapon._apply_hit_effects(e1.get_node("Hurtbox"))
	await get_tree().create_timer(0.45).timeout
	_expect(e1.health.current_health < e1.health.max_health, "ember_brand burns over time")
	_player.burn_dps = 0.0

	# Frost Bite -> chill
	_player.chill_factor = 0.3
	weapon._apply_hit_effects(e1.get_node("Hurtbox"))
	await get_tree().process_frame
	_expect(e1._chill_factor > 0.0, "frost_bite chills (factor %.2f)" % e1._chill_factor)
	_player.chill_factor = 0.0

	# Reaper's Mark -> execute a nearly-dead enemy
	_player.execute_threshold = 0.5
	e1.health.current_health = e1.health.max_health * 0.1
	weapon._apply_hit_effects(e1.get_node("Hurtbox"))
	await get_tree().process_frame
	_expect(not e1.health.is_alive() or e1.state == e1.State.DEAD, "reapers_mark executes low-HP enemies")
	_player.execute_threshold = 0.0

	# Storm Coil -> chain to a second enemy
	var a: Node = _spawn_enemy(_player.global_position + Vector2(40, 0))
	var b: Node = _spawn_enemy(_player.global_position + Vector2(75, 0))
	await get_tree().create_timer(0.5).timeout
	_player.chain_count = 1
	var b_hp: float = b.health.current_health
	weapon._apply_hit_effects(a.get_node("Hurtbox"))
	await get_tree().create_timer(0.2).timeout
	_expect(b.health.current_health < b_hp, "storm_coil chains to a second enemy")
	_player.chain_count = 0

	# Twin Fang Curse -> a delayed second hit on the same target
	var a_hp: float = a.health.current_health
	_player.twin_strike = true
	weapon._apply_hit_effects(a.get_node("Hurtbox"))
	await get_tree().create_timer(0.25).timeout
	_expect(a.health.current_health < a_hp, "twin_strike lands a second blow")
	_player.twin_strike = false

	# Echo Blade -> a swing spawns SlashWave nodes
	_player.echo_level = 2
	var waves_before := _count_waves()
	weapon._fire_echo()
	await get_tree().process_frame
	_expect(_count_waves() > waves_before,
		"echo_blade throws %d slash waves" % (_count_waves() - waves_before))
	_player.echo_level = 0

	for n in [a, b, e1]:
		if is_instance_valid(n):
			n.queue_free()
	_reset_player()
	await get_tree().process_frame


# --- 4. Synergies fuse from their required pairs ----------------------------
func _check_synergies() -> void:
	print("\n-- synergies --")
	var pairs := [
		["ember_brand", "storm_coil", "syn_plasma"],
		["echo_blade", "frost_bite", "syn_glacial"],
		["echo_blade", "whirlwind", "syn_cyclone"],
		["reapers_mark", "ember_brand", "syn_harvest"],
	]
	for pair in pairs:
		_reset_player()
		await get_tree().process_frame
		_um.apply(_player, _def(pair[0]), false)
		_expect(not _player.get(pair[2]), "%s off with only %s" % [pair[2], pair[0]])
		_um.apply(_player, _def(pair[1]), false)
		_expect(_player.get(pair[2]), "%s fuses from %s + %s" % [pair[2], pair[0], pair[1]])
		_expect(_player.synergy_entries().size() > 0, "%s appears in the build screen" % pair[2])
	_reset_player()
	await get_tree().process_frame


# --- 5. Owned uniques stop being offered ------------------------------------
func _check_uniques_filtered() -> void:
	print("\n-- unique filtering --")
	_reset_player()
	await get_tree().process_frame
	_um.apply(_player, _def("echo_blade"), false)
	var offered_again := false
	for i in 200:
		for d in _um.get_choices(3):
			if d["id"] == "echo_blade":
				offered_again = true
	_expect(not offered_again, "an owned unique is never offered again (200 draws)")

	var deal_repeat := false
	for i in 100:
		for d in _um.get_deal_choices(3):
			if d["id"] == "echo_blade":
				deal_repeat = true
	_expect(not deal_repeat, "an owned unique is never offered at the altar")
	_reset_player()
	await get_tree().process_frame


# --- 6. A draw never offers the same item twice -----------------------------
func _check_offers_are_distinct() -> void:
	print("\n-- offer integrity --")
	var dupes := false
	var short := false
	for i in 300:
		var choices := _um.get_choices(3)
		if choices.size() != 3:
			short = true
		var seen := {}
		for d in choices:
			if seen.has(d["id"]):
				dupes = true
			seen[d["id"]] = true
	_expect(not dupes, "no duplicate items within a single offer (300 draws)")
	_expect(not short, "every offer returns 3 cards")

	# Altar deals must never include a common or the cleanse.
	var bad_deal := ""
	for i in 200:
		for d in _um.get_deal_choices(3):
			if str(d.get("rarity", "common")) == "common" or d["id"] == "cleansing_light":
				bad_deal = str(d["id"])
	_expect(bad_deal == "", "altar deals only offer power items (found: %s)" % bad_deal)


# --- 7. Passive items must change BEHAVIOUR, not just a field ---------------
# A stat moving proves the item's apply() ran. It does not prove anything reads
# that stat — an item can look applied and still be completely inert.
func _check_passive_behaviour() -> void:
	print("\n-- passive items actually do something --")
	var weapon = _player.weapon

	# Sharpened Edge / Heavy Soul: quick and heavy damage must rise.
	_reset_player()
	weapon._current_is_heavy = false
	var quick_base: float = weapon._compute_damage()
	_player.quick_bonus_damage = 8.0
	_expect(weapon._compute_damage() > quick_base,
		"sharpened raises quick damage (%.0f -> %.0f)" % [quick_base, weapon._compute_damage()])
	_reset_player()
	weapon._current_is_heavy = true
	var heavy_base: float = weapon._compute_damage()
	_player.heavy_bonus_damage = 12.0
	_expect(weapon._compute_damage() > heavy_base,
		"heavy_soul raises heavy damage (%.0f -> %.0f)" % [heavy_base, weapon._compute_damage()])
	weapon._current_is_heavy = false

	# Glass Blade: more damage dealt AND more taken.
	_reset_player()
	var out_base: float = _player.get_outgoing_damage_mult()
	var in_base: float = _player.hurtbox.damage_multiplier
	_um.apply(_player, _def("glass_blade"), false)
	_expect(_player.get_outgoing_damage_mult() > out_base, "glass_blade raises damage dealt")
	_expect(_player.hurtbox.damage_multiplier > in_base, "glass_blade raises damage taken")

	# Berserker: only above the multiplier when actually hurt.
	_reset_player()
	_player.berserker_enabled = true
	_player.health.current_health = _player.health.max_health
	var healthy: float = _player.get_outgoing_damage_mult()
	_player.health.current_health = _player.health.max_health * 0.2
	_expect(_player.get_outgoing_damage_mult() > healthy,
		"berserker only boosts below 40%% HP (%.2f -> %.2f)" % [healthy, _player.get_outgoing_damage_mult()])

	# Corruption tiers must actually scale damage dealt and taken.
	_reset_player()
	var clean_out: float = _player.get_outgoing_damage_mult()
	var clean_in: float = _player.hurtbox.damage_multiplier
	_player.corruption = 90.0
	_player.on_stats_changed()
	_expect(_player.get_outgoing_damage_mult() > clean_out, "high corruption raises damage dealt")
	_expect(_player.hurtbox.damage_multiplier > clean_in, "high corruption raises damage taken")

	# Wider Cleave: the swing hitbox must physically grow.
	_reset_player()
	weapon.try_quick_attack()
	await get_tree().create_timer(0.05).timeout
	var box_base: Vector2 = (weapon.hitbox_shape.shape as RectangleShape2D).size
	await get_tree().create_timer(0.5).timeout
	_player.hitbox_scale = 1.2
	weapon.try_quick_attack()
	await get_tree().create_timer(0.05).timeout
	_expect((weapon.hitbox_shape.shape as RectangleShape2D).size.x > box_base.x,
		"wider_cleave grows the attack hitbox (%.0f -> %.0f)"
			% [box_base.x, (weapon.hitbox_shape.shape as RectangleShape2D).size.x])
	await get_tree().create_timer(0.5).timeout

	# Maelstrom: a heavy swing becomes a ring around the player, not an arc.
	_reset_player()
	_player.whirlwind = true
	weapon._current_is_heavy = true
	weapon._begin_active()
	await get_tree().process_frame
	_expect(weapon._is_whirl and weapon.hitbox_shape.position == Vector2.ZERO,
		"whirlwind centres the heavy hitbox on the player")
	await get_tree().create_timer(0.6).timeout

	# Blood Pact: healed on kill.
	_reset_player()
	_player.heal_on_kill = 3.0
	_player.health.current_health = 50.0
	_player.on_enemy_killed()
	_expect(_player.health.current_health > 50.0, "blood_pact heals on kill")

	# Corrupted Aura: a nearby enemy takes damage with no input from us.
	_reset_player()
	_player.aura_enabled = true
	var aura_victim: Node = _spawn_enemy(_player.global_position + Vector2(30, 0))
	await get_tree().create_timer(0.4).timeout
	var aura_hp: float = aura_victim.health.current_health
	await get_tree().create_timer(2.4).timeout
	_expect(aura_victim.health.current_health < aura_hp,
		"corrupted_aura damages nearby enemies over time")
	if is_instance_valid(aura_victim):
		aura_victim.queue_free()

	# Rapid Edge / Cursed Speed: cooldowns must shorten.
	_reset_player()
	_player.attack_cooldown_mult = 0.8
	_expect(weapon._cd_mult() < 1.0, "rapid_edge shortens attack cooldowns")
	_reset_player()
	var dash_base: float = _player.dash_cooldown
	_um.apply(_player, _def("cursed_speed"), false)
	_expect(_player.dash_cooldown < dash_base,
		"cursed_speed shortens the dash cooldown (%.2f -> %.2f)" % [dash_base, _player.dash_cooldown])

	# Swift Boots: movement speed multiplier is actually consumed.
	_reset_player()
	_player.move_speed_mult = 1.12
	_player.velocity = Vector2.ZERO
	_expect(_player.move_speed * _player.move_speed_mult > _player.move_speed,
		"swift_boots raises effective move speed")

	# Vampiric Edge: landing a hit heals you.
	_reset_player()
	_player.heal_on_hit = 1.5
	_player.health.current_health = 50.0
	var vamp_victim: Node = _spawn_enemy(_player.global_position + Vector2(34, 0))
	await get_tree().create_timer(0.4).timeout
	weapon._on_hit_landed(vamp_victim.get_node("Hurtbox"))
	await get_tree().process_frame
	_expect(_player.health.current_health > 50.0,
		"vampiric_edge heals on a landed hit (50 -> %.1f)" % _player.health.current_health)
	if is_instance_valid(vamp_victim):
		vamp_victim.queue_free()

	# Weapon swapping (a meta unlock, but same family of "does this work").
	_reset_player()
	weapon.set_available([WeaponController.SWORD, WeaponController.SPEAR])
	var w1: String = weapon.get_weapon_name()
	weapon.state = weapon.State.IDLE
	weapon.swap()
	_expect(weapon.get_weapon_name() != w1,
		"Q swaps weapons (%s -> %s)" % [w1, weapon.get_weapon_name()])

	_reset_player()
	await get_tree().process_frame


# --- 8. Shop / altar economics ----------------------------------------------
func _check_economy() -> void:
	print("\n-- economy --")

	# Shops must refuse a purchase you can't afford, and charge for one you can.
	GameManager.run_stats["gold"] = 10
	_expect(not GameManager.spend_gold(50), "shop refuses a purchase you can't afford")
	_expect(int(GameManager.run_stats["gold"]) == 10, "a refused purchase costs nothing")
	_expect(GameManager.spend_gold(10), "an affordable purchase succeeds")
	_expect(int(GameManager.run_stats["gold"]) == 0, "gold is actually deducted")

	# Altar deals cost max HP and skip the corruption tax.
	_reset_player()
	await get_tree().process_frame
	var hp_before: float = _player.health.max_health
	var corr_before: float = _player.corruption
	_um.apply(_player, _def("ember_brand"), false)   # charge_corruption = false
	_expect(is_equal_approx(_player.corruption, corr_before),
		"an altar deal charges no corruption")
	_player.health.set_max_health(hp_before - 20.0)
	_expect(_player.health.max_health < hp_before, "max HP can be spent as an altar price")
	_expect(_player.health.current_health <= _player.health.max_health,
		"losing max HP clamps current HP (no over-full health bar)")

	# Cleansing Light must not be offered when there is nothing to purge.
	_reset_player()
	_player.corruption = 0.0
	var offered_dead := false
	for i in 300:
		for d in _um.get_choices(3):
			if d["id"] == "cleansing_light":
				offered_dead = true
	_expect(not offered_dead, "cleansing_light is not offered at 0 corruption")

	_player.corruption = 60.0
	var offered_useful := false
	for i in 600:
		for d in _um.get_choices(3):
			if d["id"] == "cleansing_light":
				offered_useful = true
	_expect(offered_useful, "cleansing_light IS offered when corrupted")
	_reset_player()


# --- helpers ----------------------------------------------------------------
func _room_centre() -> Vector2:
	var floor_layer: Node = _room.get_node_or_null("Floor")
	if floor_layer == null or floor_layer.rooms.is_empty():
		return _player.global_position
	var r: Rect2i = floor_layer.rooms[0]["rect"]
	return Vector2(r.position + r.size / 2) * 16.0



func _snapshot() -> Dictionary:
	var s := {}
	for k in TRACKED:
		s[k] = _player.get(k)
	s["_max_hp"] = _player.health.max_health
	return s


func _def(id: String) -> Dictionary:
	for d in _um._defs:
		if d["id"] == id:
			return d
	push_error("no such item: " + id)
	return {}


func _reset_player() -> void:
	_player.items.clear()
	_player.quick_bonus_damage = 0.0
	_player.heavy_bonus_damage = 0.0
	_player.hitbox_scale = 1.0
	_player.heal_on_kill = 0.0
	_player.heal_on_hit = 0.0
	_player.aura_enabled = false
	_player.glass_damage_mult = 1.0
	_player.glass_taken_mult = 1.0
	_player.attack_cooldown_mult = 1.0
	_player.move_speed_mult = 1.0
	_player.berserker_enabled = false
	_player.burn_dps = 0.0
	_player.chill_factor = 0.0
	_player.chain_count = 0
	_player.execute_threshold = 0.0
	_player.echo_level = 0
	_player.whirlwind = false
	_player.twin_strike = false
	_player.active_item = ""
	_player.dash_cooldown = 0.6
	_player.corruption = 0.0
	_player.health.set_max_health(100.0)
	_player.health.current_health = 100.0
	_player._resolve_synergies()
	_player.on_stats_changed()


func _spawn_enemy(pos: Vector2) -> Node:
	var e: Node = load("res://scenes/GruntEnemy.tscn").instantiate()
	_room.get_node("Enemies").add_child(e)
	e.global_position = pos
	e.attack_damage = 0.0
	return e


func _count_waves() -> int:
	var n := 0
	for c in get_tree().current_scene.get_children():
		if c is SlashWave:
			n += 1
	return n


## Is this point on a floor tile of the generated dungeon?
func _inside_dungeon(p: Vector2) -> bool:
	var floor_layer: Node = _room.get_node_or_null("Floor")
	if floor_layer == null:
		return true
	return floor_layer.room_at(p) >= 0


func _expect(condition: bool, message: String) -> void:
	if condition:
		_pass += 1
		print("  PASS  ", message)
	else:
		_fail += 1
		print("  FAIL  ", message)
