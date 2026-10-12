class_name RoomController
extends Node2D


const GRUNT_SCENE := preload("res://Scenes/GruntEnemy.tscn")
const CHARGER_SCENE := preload("res://Scenes/ChargerEnemy.tscn")
const CASTER_SCENE := preload("res://Scenes/CasterEnemy.tscn")
const BRUTE_SCENE := preload("res://Scenes/BruteEnemy.tscn")
const SKITTER_SCENE := preload("res://Scenes/SkitterlingEnemy.tscn")

@onready var player: PlayerController = $player
@onready var enemies: Node2D = $Enemies
@onready var floor_layer: Dungeon = $Floor

var _alive: int = 0

func _ready() -> void:
	randomize()
	await get_tree().process_frame
	floor_layer.generate()
	player.global_position = floor_layer.entrance_center()

func _start_wave() -> void:
	_alive = 0
	for scene in _wave_list(1):
		_spawn(scene)
		

func _spawn(scene: PackedScene) -> void:
	var e := scene.instantiate()
	enemies.add_child(e)
	e.global_position = _random_spawn_point()
	e.defeated.connect(_on_enemy_defeated)
	_alive += 1
	if e.has_method("spawn_in"):
		e.spawn_in()
func _random_spawn_point() -> Vector2:
	var room := Rect2(Vector2(64, 64), Vector2(320, 200))   # replaced by the real room in ch4
	for attempt in 12:
		var p := Vector2(
			randf_range(room.position.x, room.end.x),
			randf_range(room.position.y, room.end.y)
		)
		if player == null or p.distance_to(player.global_position) > 120.0:
			return p
	# A bounded random search must have a SAFE fallback, not the player’s centre.
	var corners := [room.position, Vector2(room.end.x, room.position.y),
		room.end, Vector2(room.position.x, room.end.y)]
	var best: Vector2 = corners[0]
	for p: Vector2 in corners:
		if p.distance_squared_to(player.global_position) > best.distance_squared_to(player.global_position):
			best = p
	return best
	
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
	GameManager.slow_mo(0.35, 0.35)
	_set_status("ROOM CLEARED", 1.5)
	AudioManager.play("room_clear")
	

func _set_status(text: String, auto_hide: float) -> void:
	if GameManager.hud and GameManager.hud.has_method("show_status"):
		GameManager.hud.show_status(text, auto_hide)
