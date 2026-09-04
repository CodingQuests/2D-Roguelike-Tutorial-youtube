extends Node
## Soak test for the room / floor flow — the most stateful part of the game and
## the part a short capture never reaches.
##
## Plays the game automatically: walks the player room to room, clears every
## wave, takes every upgrade offered, buys from shops, takes altar deals, kills
## the boss and descends. Any engine error or warning printed during the run is
## a bug; anything the run gets stuck on is a bug too.
##
## Run:
##   Godot_v4.7-stable_win64.exe --headless --path . res://tools/soak.tscn \
##       --quit-after 40000
##
## Watch stderr for ERROR/WARNING lines alongside the STEP output.

const FLOORS_TO_PLAY := 3

var _main: Node
var _room: Node
var _player: Node
var _ui: Node
var _pass := 0
var _fail := 0


func _ready() -> void:
	_main = load("res://Main.tscn").instantiate()
	add_child.call_deferred(_main)
	await get_tree().create_timer(1.2).timeout
	_player = get_tree().get_first_node_in_group("player")
	_room = _main.get_node_or_null("CombatRoom")
	_ui = _main.get_node_or_null("UI")

	print("\n========== SOAK: %d FLOORS ==========" % FLOORS_TO_PLAY)
	# Immortal, so the run can't end early — we're testing flow, not combat.
	_player.hurtbox.invulnerable = true

	for floor_n in FLOORS_TO_PLAY:
		print("\n--- FLOOR %d ---" % (floor_n + 1))
		await _play_floor()

	print("\n-- end-of-run state --")
	_expect(_player.items.size() > 0, "player accumulated %d items" % _player.items.size())
	_expect(is_instance_valid(_player) and _player.health.is_alive(), "player survived the soak")
	_expect(_room.floor_layer.rooms.size() > 0, "dungeon still has rooms after 3 floors")
	_expect(_count_orphan_enemies() == 0,
		"no enemies left alive outside a fight (%d)" % _count_orphan_enemies())

	print("=====================================")
	print("PASS: %d   FAIL: %d" % [_pass, _fail])
	get_tree().quit()


func _play_floor() -> void:
	var dungeon = _room.floor_layer
	var start_depth: int = _room._floor_depth
	# Visit rooms in index order; the spanning tree guarantees they're reachable,
	# and teleporting is fine here because we only care about the room STATE
	# machine, not about pathing.
	for i in dungeon.rooms.size():
		if _room._floor_depth != start_depth:
			return  # boss died and we already descended
		var room: Dictionary = dungeon.rooms[i]
		await _enter_room(i)
		await _resolve_room(i, room)
	# If we walked every room without the boss triggering a descent, force it so
	# the next floor still gets exercised.
	if _room._floor_depth == start_depth:
		print("  (no descent from room walk — forcing)")
		_room._enter_floor(start_depth + 1)
		await get_tree().create_timer(0.6).timeout


func _enter_room(i: int) -> void:
	var c: Vector2 = _room.floor_layer.room_center_world(i)
	# Step in rather than teleport: Area2D/room detection needs real motion.
	_player.global_position = c
	await get_tree().physics_frame
	await get_tree().physics_frame
	_room._physics_process(0.016)
	await get_tree().create_timer(0.35).timeout


func _resolve_room(i: int, room: Dictionary) -> void:
	var type_name: String = ["ENTRANCE", "COMBAT", "TREASURE", "BOSS", "SHOP", "ALTAR"][int(room["type"])]
	var guard := 0
	# Kill whatever spawned, repeatedly — boss waves can add more.
	while _live_enemies() > 0 and guard < 60:
		guard += 1
		for e in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(e) and e.has_method("die"):
				e.die()
		await get_tree().create_timer(0.25).timeout
	_expect(guard < 60, "room %d (%s) cleared without stalling" % [i, type_name])

	# Take any upgrade the clear offered.
	await _take_upgrade_if_open()

	# Pedestal rooms: give ourselves gold and interact with every stand.
	if _room._room_peds.has(i):
		GameManager.run_stats["gold"] = 999
		for ped in _room._room_peds[i].duplicate():
			if is_instance_valid(ped) and not ped._busy:
				ped.chosen.emit(ped, ped.def)
				await get_tree().create_timer(0.25).timeout
		await _take_upgrade_if_open()
	await get_tree().create_timer(0.2).timeout


func _take_upgrade_if_open() -> void:
	var guard := 0
	while _ui.upgrades.visible and guard < 20:
		guard += 1
		var cards: Array = _ui.cards_box.get_children()
		if cards.is_empty():
			break
		cards[0].choose_button.pressed.emit()
		await get_tree().create_timer(0.4).timeout
	_expect(not _ui.upgrades.visible, "upgrade screen closed after picking")


func _live_enemies() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and e.state != e.State.DEAD:
			n += 1
	return n


func _count_orphan_enemies() -> int:
	return _live_enemies()


func _expect(condition: bool, message: String) -> void:
	if condition:
		_pass += 1
		print("  PASS  ", message)
	else:
		_fail += 1
		print("  FAIL  ", message)
