class_name RoomController
extends Node2D
## Drives a run through a connected dungeon: the player walks room-to-room, and
## each combat room locks its doors and spawns a wave until cleared (then offers
## an upgrade). Treasure rooms hand out loot; the boss room ends the floor and
## descends to a deeper, harder dungeon.

const GRUNT_SCENE := preload("res://scenes/GruntEnemy.tscn")
const CHARGER_SCENE := preload("res://scenes/ChargerEnemy.tscn")
const CASTER_SCENE := preload("res://scenes/CasterEnemy.tscn")
const BRUTE_SCENE := preload("res://scenes/BruteEnemy.tscn")
const SKITTER_SCENE := preload("res://scenes/SkitterlingEnemy.tscn")
const BOSS_SCENE := preload("res://scenes/BossEnemy.tscn")

const HEALTH_PICKUP := preload("res://scenes/HealthPickup.tscn")
const CLEANSE_PICKUP := preload("res://scenes/CleansePickup.tscn")
const GOLD_PICKUP := preload("res://scenes/GoldPickup.tscn")
const PEDESTAL_SCENE := preload("res://scenes/ItemPedestal.tscn")

## Base shop price by item rarity (a per-depth surcharge is added on top).
const SHOP_BASE_PRICE := {"common": 8, "rare": 15, "cursed": 20}

@onready var atmosphere: Atmosphere = $Atmosphere
@onready var floor_layer: Dungeon = $Floor
@onready var player: PlayerController = $Player
@onready var enemies: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles
@onready var pickups: Node2D = $Pickups

var _floor_depth: int = 0
var _current_room: int = -2
var _active_room: int = -1
var _alive: int = 0
var _upgrades: UpgradeManager
var _busy: bool = false  # true while an upgrade screen / transition is open
var _stocked: Dictionary = {}     # room_index -> true once its pedestals are placed
var _room_peds: Dictionary = {}   # room_index -> Array[ItemPedestal]


func _ready() -> void:
	randomize()
	# The Projectiles/Pickups containers declare their groups in CombatRoom.tscn.
	_upgrades = UpgradeManager.new()
	add_child(_upgrades)

	await get_tree().process_frame
	GameManager.start_run()
	AudioManager.play_music("combat")
	_enter_floor(1)
	if GameManager.hud and GameManager.hud.has_method("setup_minimap"):
		GameManager.hud.setup_minimap(floor_layer)
	_refresh_hud()
	if GameManager.hud and GameManager.hud.has_method("refresh_items"):
		GameManager.hud.refresh_items(player)


func _physics_process(_delta: float) -> void:
	if _busy or _active_room != -1 or player == null:
		return
	var here := floor_layer.room_at(player.global_position)
	if here != _current_room:
		_current_room = here
		_on_enter_room(here)


# --- Floor / room flow -------------------------------------------------
func _enter_floor(depth: int) -> void:
	_floor_depth = depth
	GameManager.run_stats["floor"] = depth   # read by the minimap caption
	# Leave nothing behind. The descent used to clear projectiles and pickups but
	# NOT enemies, so anything still alive when the floor changed would survive
	# into the new one — at its old coordinates, which are now somewhere else
	# entirely (quite possibly inside a wall). Doing it here rather than in
	# _on_boss_cleared covers every path that changes floors, now and later.
	for group in [enemies, projectiles, pickups]:
		for c in group.get_children():
			c.queue_free()
	_alive = 0
	floor_layer.generate(depth)
	player.global_position = floor_layer.entrance_center()
	_current_room = -2
	_active_room = -1
	_stocked.clear()
	_room_peds.clear()
	_set_status("Floor %d — clear the boss room" % depth, 2.0)


func _on_enter_room(i: int) -> void:
	if i < 0:
		return
	var room: Dictionary = floor_layer.rooms[i]
	# Wash the ambient light toward this room type's tint — a shop reads as
	# candle-lit and an altar as cold violet before you've read any UI.
	if atmosphere:
		atmosphere.set_room_type(int(room["type"]))
	if room["cleared"] or room["type"] == Dungeon.RoomType.ENTRANCE:
		return
	match room["type"]:
		Dungeon.RoomType.COMBAT:
			_start_combat(i)
		Dungeon.RoomType.TREASURE:
			_open_treasure(i)
		Dungeon.RoomType.SHOP:
			_open_shop(i)
		Dungeon.RoomType.ALTAR:
			_open_altar(i)
		Dungeon.RoomType.BOSS:
			_start_boss(i)


func _start_combat(i: int) -> void:
	_active_room = i
	floor_layer.lock_room(i)
	_alive = 0
	for scene in _wave_list(_floor_depth):
		_spawn(scene, i)
	_set_status("Fight!", 1.0)


func _start_boss(i: int) -> void:
	_active_room = i
	floor_layer.lock_room(i)
	_alive = 0
	var boss := BOSS_SCENE.instantiate()
	enemies.add_child(boss)
	boss.global_position = floor_layer.room_center_world(i) - Vector2(0, 40)
	if boss.has_method("set_level"):
		boss.set_level(_floor_depth)
	boss.defeated.connect(_on_enemy_defeated)
	_alive += 1
	if GameManager.hud and GameManager.hud.has_method("show_boss_bar"):
		GameManager.hud.show_boss_bar(boss)
	_set_status("THE FORGE WARDEN", 1.5)
	AudioManager.play("charge", 0.0)


# --- Treasure: choose one of three free items --------------------------
func _open_treasure(i: int) -> void:
	if _stocked.has(i):
		return
	_stocked[i] = true
	var c := floor_layer.room_center_world(i)
	var choices: Array = _upgrades.get_choices(3)
	var peds: Array = []
	for k in choices.size():
		var off := 0.0 if choices.size() == 1 else lerpf(-128.0, 128.0, float(k) / float(choices.size() - 1))
		var ped := _make_pedestal(choices[k], 0, false, i)
		ped.chosen.connect(_on_treasure_pick)
		pickups.add_child.call_deferred(ped)
		ped.set_deferred("global_position", c + Vector2(off, -8))
		peds.append(ped)
	_room_peds[i] = peds
	AudioManager.play("pickup", 2.0)
	_set_status("Treasure — stand on one and press F to take", 2.4)


func _on_treasure_pick(ped: ItemPedestal, def: Dictionary) -> void:
	if ped == null or not is_instance_valid(ped):
		return
	var i: int = ped.room
	# Choosing one dismisses the rest.
	if _room_peds.has(i):
		for p in _room_peds[i]:
			if is_instance_valid(p) and p != ped:
				p.consume()
		_room_peds.erase(i)
	_apply_item(def)
	ped.consume()
	if i >= 0 and i < floor_layer.rooms.size():
		floor_layer.rooms[i]["cleared"] = true
	_set_status("Taken!", 1.2)


# --- Shop: spend gold; reroll the stock --------------------------------
func _open_shop(i: int) -> void:
	if _stocked.has(i):
		return
	_stocked[i] = true
	_stock_shop(i)
	_set_status("Shop — stand on an item and press F to buy", 2.6)


func _stock_shop(i: int) -> void:
	var c := floor_layer.room_center_world(i)
	var choices: Array = _upgrades.get_choices(3)
	var peds: Array = []
	# Wares in a row across the upper part of the room...
	for k in choices.size():
		var off := 0.0 if choices.size() == 1 else lerpf(-128.0, 128.0, float(k) / float(choices.size() - 1))
		var ped := _make_pedestal(choices[k], _shop_price(choices[k]), false, i)
		ped.chosen.connect(_on_shop_buy)
		pickups.add_child.call_deferred(ped)
		ped.set_deferred("global_position", c + Vector2(off, -34))
		peds.append(ped)
	# ...and the reroll stand well below them, so labels never collide.
	var rp := _make_pedestal({}, 5 + _floor_depth, true, i)
	rp.chosen.connect(_on_shop_reroll)
	pickups.add_child.call_deferred(rp)
	rp.set_deferred("global_position", c + Vector2(0, 62))
	peds.append(rp)
	_room_peds[i] = peds


func _on_shop_buy(ped: ItemPedestal, def: Dictionary) -> void:
	if ped == null or not is_instance_valid(ped):
		return
	if GameManager.spend_gold(ped.price):
		_apply_item(def)
		ped.consume()
		AudioManager.play("upgrade")
	else:
		ped.deny()


func _on_shop_reroll(ped: ItemPedestal, _def: Dictionary) -> void:
	if ped == null or not is_instance_valid(ped):
		return
	if not GameManager.spend_gold(ped.price):
		ped.deny()
		return
	var i: int = ped.room
	if _room_peds.has(i):
		for p in _room_peds[i]:
			if is_instance_valid(p):
				p.consume()
		_room_peds.erase(i)
	AudioManager.play("dash", -2.0)
	_stock_shop(i)
	_refresh_hud()


func _shop_price(def: Dictionary) -> int:
	var base: int = SHOP_BASE_PRICE.get(str(def.get("rarity", "common")), 10)
	return base + _floor_depth * 2


func _make_pedestal(def: Dictionary, price: int, reroll: bool, room: int) -> ItemPedestal:
	var ped: ItemPedestal = PEDESTAL_SCENE.instantiate()
	ped.configure(def, price, reroll)
	ped.room = room
	return ped


# --- Forge Altar: trade max HP for power (the Devil Deal) ---------------
func _open_altar(i: int) -> void:
	if _stocked.has(i):
		return
	_stocked[i] = true
	var c := floor_layer.room_center_world(i)
	var choices: Array = _upgrades.get_deal_choices(2)
	var cost := 18 + _floor_depth * 2
	var peds: Array = []
	for k in choices.size():
		var off := 0.0 if choices.size() == 1 else lerpf(-72.0, 72.0, float(k) / float(choices.size() - 1))
		var ped := _make_pedestal(choices[k], 0, false, i)
		ped.hp_cost = cost
		ped.chosen.connect(_on_altar_take)
		pickups.add_child.call_deferred(ped)
		ped.set_deferred("global_position", c + Vector2(off, 0))
		peds.append(ped)
	_room_peds[i] = peds
	AudioManager.play("telegraph", -4.0, 0.6)
	_set_status("Forge Altar — stand on a deal and press F to offer flesh", 2.8)


func _on_altar_take(ped: ItemPedestal, def: Dictionary) -> void:
	if ped == null or not is_instance_valid(ped):
		return
	var hp: HealthComponent = player.health
	# Refuse the deal if it would leave the player too frail.
	if hp.max_health - ped.hp_cost < 20.0:
		ped.deny("Too frail for this pact")
		return
	var i: int = ped.room
	# Taking one deal dismisses the other.
	if _room_peds.has(i):
		for p in _room_peds[i]:
			if is_instance_valid(p) and p != ped:
				p.consume()
		_room_peds.erase(i)
	# The blood price: permanent max-HP loss.
	hp.set_max_health(hp.max_health - ped.hp_cost)
	hp.current_health = minf(hp.current_health, hp.max_health)
	_apply_item(def, false)  # power without the corruption tax — HP was the cost
	ped.consume()
	if i >= 0 and i < floor_layer.rooms.size():
		floor_layer.rooms[i]["cleared"] = true
	GameManager.screen_damage()
	GameManager.shake_camera(0.3)
	Juice.floating_text(self, player.global_position, "PACT SEALED", Color(0.95, 0.2, 0.3), 18)
	_set_status("A pact is struck.", 1.4)
	_refresh_hud()


# Apply a chosen item (shared by post-combat cards, treasure, shops and altar
# deals): run the effect, refresh the HUD/item bar, and celebrate any new synergy.
# `charge_corruption` is false for altar deals (their price is max HP).
func _apply_item(def: Dictionary, charge_corruption: bool = true) -> void:
	_upgrades.apply(player, def, charge_corruption)
	_refresh_hud()
	var hud := _get_hud()
	if hud and hud.has_method("refresh_items"):
		hud.refresh_items(player)
	if player and ("last_new_synergies" in player):
		for sname in player.last_new_synergies:
			if hud and hud.has_method("show_synergy"):
				hud.show_synergy(sname)
			GameManager.zoom_punch(0.05)
			Juice.floating_text(self, player.global_position, str(sname).to_upper(), Color(1.0, 0.85, 0.3), 18)


# --- Spawning ----------------------------------------------------------
func _wave_list(depth: int) -> Array:
	var list: Array = []
	for i in clampi(2 + depth, 3, 7):
		list.append(GRUNT_SCENE)
	for i in 1 + int(depth / 3.0):
		list.append(CASTER_SCENE)
	for i in 1 + int(depth / 2.0):
		list.append(CHARGER_SCENE)
	if depth >= 1:
		for i in 2:
			list.append(SKITTER_SCENE)
	if depth >= 2:
		for i in int(depth / 2.0):
			list.append(BRUTE_SCENE)
	return list


func _spawn(scene: PackedScene, room_index: int) -> void:
	var e := scene.instantiate()
	enemies.add_child(e)
	e.global_position = floor_layer.random_point_in_room(room_index, player.global_position)
	_maybe_corrupt(e)
	# Telegraphed fade/scale-in so enemies don't pop into existence.
	if e.has_method("spawn_in"):
		e.spawn_in()
	e.defeated.connect(_on_enemy_defeated)
	_alive += 1


# Corruption risk/reward: at higher corruption, enemies may spawn "corrupted".
func _maybe_corrupt(enemy: Node) -> void:
	if not enemy.has_method("make_corrupted"):
		return
	var corr: float = player.corruption
	var chance := 0.0
	if corr >= 75.0:
		chance = 0.6
	elif corr >= 50.0:
		chance = 0.38
	elif corr >= 25.0:
		chance = 0.16
	if randf() < chance:
		enemy.make_corrupted()


func _spawn_pickup(scene: PackedScene, pos: Vector2, toss := Vector2.ZERO) -> void:
	var p := scene.instantiate()
	# Deferred: enemy drops happen inside the death/hurtbox signal flush, where
	# adding an Area2D directly errors on its monitoring state.
	pickups.add_child.call_deferred(p)
	p.set_deferred("global_position", pos)
	# Burst it outward if asked (toss only sets a var, safe before it's in-tree).
	if toss != Vector2.ZERO and p.has_method("toss"):
		p.toss(toss)


# A random outward impulse for loot bursting off a dead enemy.
func _loot_toss() -> Vector2:
	return Vector2.RIGHT.rotated(randf() * TAU) * randf_range(80.0, 150.0)


# --- Enemy death / clear ----------------------------------------------
func _on_enemy_defeated(enemy: Node) -> void:
	_alive -= 1
	GameManager.run_stats["enemies_killed"] += 1
	GameManager.run_stats["essence"] += 1
	GameManager.register_kill()
	if player:
		player.on_enemy_killed()
	# Corrupted elites are worth more and always drop something.
	if "is_corrupted" in enemy and enemy.is_corrupted:
		GameManager.run_stats["essence"] += 3
		_spawn_pickup(HEALTH_PICKUP, enemy.global_position, _loot_toss())
		_drop_gold(enemy.global_position, randi_range(4, 7))
	else:
		_maybe_drop(enemy.global_position)
		if randf() < 0.55:
			_drop_gold(enemy.global_position, randi_range(1, 3))
	_refresh_hud()
	if _alive <= 0 and _active_room != -1:
		_clear_active_room()


func _maybe_drop(pos: Vector2) -> void:
	var r := randf()
	if r < 0.14:
		_spawn_pickup(HEALTH_PICKUP, pos, _loot_toss())
	elif r < 0.20:
		_spawn_pickup(CLEANSE_PICKUP, pos, _loot_toss())


# Burst a gold coin worth `value` off a kill/prop.
func _drop_gold(pos: Vector2, value: int) -> void:
	var p := GOLD_PICKUP.instantiate()
	p.amount = float(value)
	pickups.add_child.call_deferred(p)
	p.set_deferred("global_position", pos)
	if p.has_method("toss"):
		p.toss(_loot_toss())


func _clear_active_room() -> void:
	var i := _active_room
	floor_layer.rooms[i]["cleared"] = true
	floor_layer.unlock_room(i)
	var is_boss: bool = floor_layer.rooms[i]["type"] == Dungeon.RoomType.BOSS
	_active_room = -1

	if is_boss:
		_on_boss_cleared()
	else:
		GameManager.run_stats["rooms_cleared"] += 1
		AudioManager.play("room_clear")
		# Clearing the last enemy gets a short slow-mo flourish + a burst on the player.
		GameManager.slow_mo(0.3, 0.35)
		GameManager.zoom_punch(0.06)
		GameManager.screen_impact(0.4)
		if player:
			Juice.ring(self, player.global_position, Color(1.0, 0.9, 0.5, 0.9), 70.0, 0.5, 3.0)
			Juice.impact(self, player.global_position, Color(1.0, 0.85, 0.4), 20, 1.4)
		_busy = true
		_set_status("Room Cleared!", 0.0)
		await get_tree().create_timer(0.6, true, false, true).timeout
		var hud := _get_hud()
		if hud and hud.has_method("show_upgrades"):
			hud.show_upgrades(_upgrades.get_choices(3), _on_upgrade_chosen)
		else:
			_busy = false


func _on_upgrade_chosen(def: Dictionary) -> void:
	AudioManager.play("upgrade")
	var hud := _get_hud()
	if hud and hud.has_method("hide_upgrades"):
		hud.hide_upgrades()
	_set_status("Find the next room", 1.5)
	_apply_item(def)  # applies effect, refreshes items, celebrates synergies
	_busy = false


func _on_boss_cleared() -> void:
	GameManager.run_stats["rooms_cleared"] += 1
	GameManager.run_stats["essence"] += 25
	if GameManager.hud and GameManager.hud.has_method("hide_boss_bar"):
		GameManager.hud.hide_boss_bar()
	AudioManager.play("room_clear", 3.0)
	_busy = true
	_set_status("Floor Cleared! Descending…", 0.0)
	await get_tree().create_timer(1.6).timeout
	# _enter_floor clears enemies/projectiles/pickups for us.
	_enter_floor(_floor_depth + 1)
	if GameManager.hud and GameManager.hud.has_method("setup_minimap"):
		GameManager.hud.setup_minimap(floor_layer)
	_busy = false


# --- HUD helpers -------------------------------------------------------
func _get_hud() -> CanvasLayer:
	return GameManager.hud


func _set_status(text: String, auto_hide: float) -> void:
	var hud := _get_hud()
	if hud and hud.has_method("show_status"):
		hud.show_status(text, auto_hide)


func _refresh_hud() -> void:
	var hud := _get_hud()
	if hud and hud.has_method("update_player_status"):
		hud.update_player_status(player)
