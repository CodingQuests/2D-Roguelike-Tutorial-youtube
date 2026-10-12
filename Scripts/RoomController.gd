class_name RoomController
extends Node2D


const GRUNT_SCENE := preload("res://Scenes/GruntEnemy.tscn")
const CHARGER_SCENE := preload("res://Scenes/ChargerEnemy.tscn")
const CASTER_SCENE := preload("res://Scenes/CasterEnemy.tscn")
const BRUTE_SCENE := preload("res://Scenes/BruteEnemy.tscn")
const SKITTER_SCENE := preload("res://Scenes/SkitterlingEnemy.tscn")
const BOSS_SCENE := preload("res://Scenes/BossEnemy.tscn")
const GOLD_PICKUP := preload("res://Scenes/GoldPickup.tscn")
const PEDESTAL := preload("res://Scenes/ItemPedestal.tscn")
const SHOP_BASE_PRICE := {"common": 8, "rare": 15, "cursed": 20}

@onready var player: PlayerController = $player
@onready var enemies: Node2D = $Enemies
@onready var floor_layer: Dungeon = $Floor
@onready var _upgrades: UpgradeManager = $Upgrades
@onready var pickups: Node2D = $Pickups
var _alive: int = 0
var _current_room: int = -2
var _active_room: int = -1          # -1 = no fight in progress
var _floor_depth: int = 1
var _busy: bool = false
var _reward_is_boss := false
var _stocked: Dictionary = {}
var _open_stands: Dictionary = {}

func _ready() -> void:
	randomize()
	await get_tree().process_frame
	_enter_floor(1)
	floor_layer.generate()
	player.global_position = floor_layer.entrance_center()


func _physics_process(_delta: float) -> void:
	if _busy or _active_room != -1 or player == null:
		return
	var here := floor_layer.room_at(player.global_position)
	if here < 0:
		return
	var r: Rect2i = floor_layer.rooms[here]["rect"]
	var interior := Rect2(Vector2(r.position) * Dungeon.TILE, Vector2(r.size) * Dungeon.TILE).grow(-16.0)
	if not interior.has_point(player.global_position):
		return
	if here != _current_room:
		_current_room = here
		_on_enter_room(here)
	
func _on_enemy_defeated(_enemy: Node) -> void:
	if randf() < 0.55: 
		_drop_gold(_enemy.global_position, randi_range(1, 3))
	_alive -= 1
	if _alive <= 0:
		_clear_active_room()


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

func _clear_active_room() -> void:
	var i := _active_room
	# Bail if there's no room or we're already busy.
	if i < 0 or _busy:
		return
	_busy = true
	_active_room = -1
	# Mark it cleared, unlock the doors, count it, note whether it was the boss.
	floor_layer.rooms[i]["cleared"] = true
	floor_layer.unlock_room(i)
	GameManager.run_stats["rooms_cleared"] += 1
	_reward_is_boss = floor_layer.rooms[i]["type"] == Dungeon.RoomType.BOSS
	# Deferred so the killing blow finishes resolving before we pause the tree.
	_finish_room_clear.call_deferred()
	
func _finish_room_clear() -> void:
	# Slow-mo to 35% for a third of a second, the clear sound, the banner.
	GameManager.slow_mo(0.35, 0.35)
	AudioManager.play("room_clear")
	_set_status("ROOM CLEARED", 1.5)
	await get_tree().create_timer(0.4, false, false, true).timeout
	# They can still die during that wait.
	if not player.health.is_alive():
		return
	var choices: Array = _upgrades.get_choices(3)
	# An empty pool goes straight to the callback with an empty dict.
	if choices.is_empty():
		_on_upgrade_chosen({})
	else:
		GameManager.hud.show_upgrades(choices, _on_upgrade_chosen)

func _on_upgrade_chosen(def: Dictionary) -> void:
	# Same two guards, so a stale callback can't apply anything.
	if not _busy or not player.health.is_alive():
		return
	if not def.is_empty():
		player.apply_upgrade(def)
	get_tree().paused = false
	# If that was the boss, now we descend.
	if _reward_is_boss:
		_enter_floor(_floor_depth + 1)
	_reward_is_boss = false
	_busy = false
	
func _set_status(text: String, auto_hide: float) -> void:
	if GameManager.hud and GameManager.hud.has_method("show_status"):
		GameManager.hud.show_status(text, auto_hide)
		
func _enter_floor(depth: int) -> void:
	_floor_depth = depth
	GameManager.run_stats["floor"] = depth
	_alive = 0
	for c in pickups.get_children():
		c.queue_free()
	_stocked.clear()
	_open_stands.clear()
	floor_layer.generate(depth)
	player.global_position = floor_layer.entrance_center()
	_current_room = -2
	_active_room = -1
	_set_status("Floor %d — clear the boss room" % depth, 2.0)
	var mm := get_tree().get_first_node_in_group("Minimap")
	if mm and mm.has_method("set_dungeon"):
		mm.set_dungeon(floor_layer)

func _on_enter_room(i: int) -> void:
	if i < 0:
		return
	var room: Dictionary = floor_layer.rooms[i]
	if room["cleared"] or room["type"] == Dungeon.RoomType.ENTRANCE:
		return
	match room["type"]:
		Dungeon.RoomType.COMBAT:
			_start_combat(i)
		Dungeon.RoomType.BOSS:
			_start_boss(i)
		Dungeon.RoomType.TREASURE:
			_open_treasure(i)
		Dungeon.RoomType.SHOP:
			_stock_shop(i)
		Dungeon.RoomType.ALTAR:
			_open_altar(i)


func _start_combat(i: int) -> void:
	_active_room = i
	floor_layer.lock_room(i)
	_alive = 0
	for scene in _wave_list(_floor_depth):
		_spawn(scene, i)
	_set_status("Fight!", 1.0)

func _spawn(scene: PackedScene, room_index: int) -> void:
	var e := scene.instantiate()
	enemies.add_child(e)
	e.global_position = floor_layer.random_point_in_room(
		room_index, player.global_position, 120.0)
	e.defeated.connect(_on_enemy_defeated)
	_maybe_corrupt(e)
	if e.has_method("spawn_in"):
		e.spawn_in()
	_alive += 1
	
func _start_boss(i: int) -> void:
	_active_room = i
	floor_layer.lock_room(i)
	_alive = 0
	var boss := BOSS_SCENE.instantiate()
	enemies.add_child(boss)
	boss.global_position = floor_layer.room_center_world(i)
	if boss.has_method("set_level"):
		boss.set_level(_floor_depth)
	boss.defeated.connect(_on_enemy_defeated)
	if boss.has_method("spawn_in"):
		boss.spawn_in()
	_alive += 1
	_set_status("The Forge Warden", 2.0)
func _maybe_corrupt(enemy: Node) -> void:
	# Anything spawned that isn't an EnemyBase just gets skipped.
	if not enemy.has_method("make_corrupted"):
		return
	var corr: float = player.corruption
	# Chance from the player's corruption band. Same thresholds as the tiers.
	var chance := 0.0
	if corr >= 75.0:   chance = 0.6
	elif corr >= 50.0: chance = 0.38
	elif corr >= 25.0: chance = 0.18
	# randf() is 0..1, so under the chance means corrupt it.
	if randf() < chance:
		enemy.make_corrupted()
		
func _drop_gold(pos: Vector2, amount: int) -> void:
	for i in amount:
		var coin := GOLD_PICKUP.instantiate()
		# add_child first, then global_position. It means nothing before the
		# coin is in the tree.
		pickups.add_child(coin)
		coin.global_position = pos
		# Random direction, random speed between 60 and 140: three coins from
		# one kill land in three different places.
		coin.toss(Vector2.RIGHT.rotated(randf() * TAU) * randf_range(60.0, 140.0))

func _make_pedestal(def: Dictionary, price: int, is_reroll: bool, room: int) -> ItemPedestal:
	# Instantiate, configure, set the room, hand it back. Not added to anything yet.
	var ped: ItemPedestal = PEDESTAL.instantiate()
	ped.configure(def, price, is_reroll)
	ped.room = room
	return ped
	
func _shop_price(def: Dictionary) -> int:
	# Rarity looked up in the price table, ten if it's something odd.
	return int(SHOP_BASE_PRICE.get(String(def.get("rarity", "common")), 10))

func _place_pedestals(peds: Array, i: int) -> void:
	var c := floor_layer.room_center_world(i)
	for k in peds.size():
		# Spread from -128 to +128 across the room centre. maxi stops a single
		# stand dividing by zero.
		var off := lerpf(-128.0, 128.0, float(k) / float(maxi(peds.size() - 1, 1)))
		# Deferred add and deferred position, so the position lands after the
		# node is actually in the tree. Set it before that and it's thrown away.
		pickups.add_child.call_deferred(peds[k])
		peds[k].set_deferred("global_position", c + Vector2(off, -34))

func _open_treasure(i: int) -> void:
	# Guard, mark it stocked, three free stands at price zero, each wired to
	# _on_treasure_take, and remember the set.
	if _stocked.has(i):
		return
	_stocked[i] = true
	var peds: Array = []
	for def in _upgrades.get_choices(3):
		var ped := _make_pedestal(def, 0, false, i)
		ped.chosen.connect(_on_treasure_take)
		peds.append(ped)
	_open_stands[i] = peds
	_place_pedestals(peds, i)

func _on_treasure_take(ped: ItemPedestal, item_def: Dictionary) -> void:
	if not _open_stands.has(ped.room): return
	# Apply the item, free the other two, forget the set, and let the one you
	# picked do its pop.
	player.apply_upgrade(item_def)
	for other in _open_stands.get(ped.room, []):
		if is_instance_valid(other) and other != ped:
			other.queue_free()
	_open_stands.erase(ped.room)
	ped.consume()

func _stock_shop(i: int) -> void:
	if _stocked.has(i):
		return
	_stocked[i] = true
	var peds: Array = []
	for def in _upgrades.get_choices(3):
		var ped := _make_pedestal(def, _shop_price(def), false, i)
		ped.chosen.connect(_on_shop_buy)
		peds.append(ped)
	_place_pedestals(peds, i)

func _on_shop_buy(ped: ItemPedestal, item_def: Dictionary) -> void:
	# Try to spend first. False: status line, refuse() so the stand opens back
	# up, and return before the item is ever applied.
	if not GameManager.spend_gold(ped.price):
		_set_status("Not enough gold", 1.2)
		ped.refuse()
		return
	player.apply_upgrade(item_def)
	ped.consume()


func _open_altar(i: int) -> void:
	if _stocked.has(i):
		return
	_stocked[i] = true
	var choices: Array = _upgrades.get_choices(2)   # two, not three
	# 18% of current max, rounded down.
	var cost := int(player.health.max_health * 0.18)
	# Refuse the deal outright if paying would leave the player under 40: the
	# altar doesn't open at all.
	if player.health.max_health - cost < 40.0:
		_set_status("The altar is silent", 2.0)
		return
	var peds: Array = []
	for item_def in choices:
		# apply_upgrade still charges corruption off the def. Without the zero
		# below, the altar would charge you twice.
		var altar_item: Dictionary = item_def.duplicate()
		altar_item["corruption"] = 0 # max HP is the entire price here
		var ped := _make_pedestal(altar_item, 0, false, i)
		# Same reason as configure(). It is how the label knows to say HP, not gold.
		ped.hp_cost = cost # before add_child; _ready builds its price label
		ped.chosen.connect(_on_altar_take)
		peds.append(ped)
	_open_stands[i] = peds
	_place_pedestals(peds, i)
func _on_altar_take(ped: ItemPedestal, item_def: Dictionary) -> void:
	if not _open_stands.has(ped.room): return
	# Check the floor again at the moment of the take. Your max might have
	# changed since the room opened.
	if player.health.max_health - ped.hp_cost < 40.0:
		ped.refuse()
		return
	player.health.set_max_health(player.health.max_health - ped.hp_cost)
	# _on_treasure_take() already does the apply, the dismiss and the pop.
	_on_treasure_take(ped, item_def)

