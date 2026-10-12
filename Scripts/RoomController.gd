class_name RoomController
extends Node2D


const GRUNT_SCENE := preload("res://Scenes/GruntEnemy.tscn")
const CHARGER_SCENE := preload("res://Scenes/ChargerEnemy.tscn")
const CASTER_SCENE := preload("res://Scenes/CasterEnemy.tscn")
const BRUTE_SCENE := preload("res://Scenes/BruteEnemy.tscn")
const SKITTER_SCENE := preload("res://Scenes/SkitterlingEnemy.tscn")
const BOSS_SCENE := preload("res://Scenes/BossEnemy.tscn")

@onready var player: PlayerController = $player
@onready var enemies: Node2D = $Enemies
@onready var floor_layer: Dungeon = $Floor

var _alive: int = 0
var _current_room: int = -2
var _active_room: int = -1          # -1 = no fight in progress
var _floor_depth: int = 1
var _busy: bool = false

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
	if i < 0:
		return
	_active_room = -1
	floor_layer.rooms[i]["cleared"] = true
	floor_layer.unlock_room(i)
	GameManager.slow_mo(0.35, 0.35)
	AudioManager.play("room_clear")
	GameManager.run_stats["rooms_cleared"] += 1
	_set_status("ROOM CLEARED", 1.5)
	if floor_layer.rooms[i]["type"] == Dungeon.RoomType.BOSS:
		_busy = true
		await get_tree().create_timer(1.5).timeout
		_enter_floor(_floor_depth + 1)
		_busy = false

func _set_status(text: String, auto_hide: float) -> void:
	if GameManager.hud and GameManager.hud.has_method("show_status"):
		GameManager.hud.show_status(text, auto_hide)
		
func _enter_floor(depth: int) -> void:
	_floor_depth = depth
	GameManager.run_stats["floor"] = depth
	_alive = 0
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
