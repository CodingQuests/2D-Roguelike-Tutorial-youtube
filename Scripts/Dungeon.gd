class_name Dungeon
extends TileMapLayer

const TILE := 16

const ATLAS := preload("res://Assets/Tilemap/tilemap_packed.png")

const BOULDER_TEX := preload("res://Assets/Tiles/tile_0006.png")
const BRAZIER_TEX := preload("res://Assets/Tiles/tile_0029.png")
const PROP_SCENE := preload("res://Scenes/DestructibleProp.tscn")

const FLOOR := Vector2i(0, 4)
const FLOOR_DECO := [Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]
const WALL := Vector2i(2, 1)

var _walls: StaticBody2D
var _src_id := 0
var _floor: Dictionary = {}
var _decor: Node2D
var _props: Node2D
var _gates: Node2D

var obstacles: Array[Rect2] = []

func _ready() -> void:
	_build_tileset()
	
func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	src.texture = ATLAS
	src.texture_region_size = Vector2i(TILE, TILE)
	for c in [FLOOR, WALL] + FLOOR_DECO:
		src.create_tile(c)
		var data := src.get_tile_data(c, 0)
		if data:
			data.z_index = -10
	_src_id = ts.add_source(src)
	tile_set = ts


func generate() -> void:
	clear()
	_floor.clear()
	_free_helpers()
	
	var rect := Rect2i(0, 0, 24, 14)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			_floor[Vector2i(x, y)] = true
	
	var start := rect.get_center()
	
	_paint()
	_decorate_room(rect)
	_scatter_floor_decor()
	if not _all_floor_reachable(start):
		push_warning("Decoration blocked the floor — clearing props.")
		_free_helpers()
		_paint()
		
func _paint() -> void:
	for cell in _floor.keys():
		set_cell(cell, _src_id, FLOOR)
	# A wall is any 8-neighbour of a floor cell that isn't itself floor.
	var wall_set := {}
	for cell in _floor.keys():
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var n: Vector2i = cell + Vector2i(dx, dy)
				if not _floor.has(n):
					wall_set[n] = true
	for cell in wall_set.keys():
		set_cell(cell, _src_id, WALL)
	
	_build_wall_collision(wall_set)

func _build_wall_collision(wall_set: Dictionary) -> void:
	for cell in wall_set.keys():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE, TILE)
		shape.shape = rect
		shape.position = Vector2(cell) * TILE + Vector2(TILE, TILE) * 0.5
		_walls.add_child(shape)
	
func _scatter_floor_decor() -> void:
	for cell in _floor.keys():
		if randf() < 0.10:
			set_cell(cell, _src_id, FLOOR_DECO.pick_random())

func _decorate_room(rect: Rect2i) -> void:
	var center := rect.get_center()
	var prop_count := randi_range(3, 6)
	for k in range(prop_count + 2):
		var cell := Vector2i(
			randi_range(rect.position.x + 1, rect.end.x - 2),
			randi_range(rect.position.y + 1, rect.end.y - 2)
		)
		if absi(cell.x - center.x) <= 2 or absi(cell.y - center.y) <= 2:
			continue
		if _placement_blocked(cell):
			continue
		if k < 2:
			_place_boulder(cell)
		else:
			_place_prop(cell)
	_place_brazier(Vector2i(rect.position.x + 2, rect.position.y - 1))
	_place_brazier(Vector2i(rect.end.x - 3, rect.position.y - 1))
func _decorate_random(rect: Rect2i) -> void:
	var count := randi_range(8, 20)
	for i in count:
		var cell := Vector2i(
			randi_range(rect.position.x, rect.end.x - 1),
			randi_range(rect.position.y, rect.end.y - 1)
		)
		_place_boulder(cell)

func _add_static_box(rect: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	cs.position = rect.position + rect.size * 0.5
	_walls.add_child(cs)
	
func _place_boulder(cell: Vector2i) -> void:
	var spr := Sprite2D.new()
	spr.texture = BOULDER_TEX
	spr.position = _cell_center(cell)
	spr.scale = Vector2(1.7, 1.7)
	_decor.add_child(spr)
	var rect := Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE)
	_add_static_box(rect)
	obstacles.append(rect)

func _place_prop(cell: Vector2i) -> void:
	var prop := PROP_SCENE.instantiate()
	_props.add_child(prop)
	prop.position = _cell_center(cell)
	obstacles.append(Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE))

func _place_brazier(cell: Vector2i) -> void:
	var spr := Sprite2D.new()
	spr.texture = BRAZIER_TEX
	spr.position = _cell_center(cell)
	spr.modulate = Color(1.15, 1.0, 0.85)
	_decor.add_child(spr)
	# Small, contained flame — a sconce, not a bonfire.
	var flame := CPUParticles2D.new()
	flame.amount = 8
	flame.lifetime = 0.4
	flame.position = Vector2(0, -3)
	flame.direction = Vector2(0, -1)
	flame.spread = 14.0
	flame.gravity = Vector2(0, -14)
	flame.initial_velocity_min = 6.0
	flame.initial_velocity_max = 14.0
	flame.color = Color(1.0, 0.65, 0.25, 0.85)
	flame.emitting = true
	spr.add_child(flame)
	
	
func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x + 0.5, cell.y + 0.5) * TILE



func _free_helpers() -> void:
	for n in [_walls, _decor, _props, _gates]:
		if is_instance_valid(n):
			n.queue_free()
	_walls = StaticBody2D.new()
	_walls.name = "Walls"
	_walls.collision_layer = 1
	_walls.collision_mask = 0
	add_child(_walls)
	_decor = Node2D.new(); _decor.name = "Decor"; add_child(_decor)
	_props = Node2D.new(); _props.name = "Props"; add_child(_props)
	_gates = Node2D.new(); _gates.name = "Gates"; add_child(_gates)
	obstacles.clear()
	
	
func _placement_blocked(cell: Vector2i) -> bool:
	var point := _cell_center(cell)
	for rect in obstacles:
		if rect.grow(24.0).has_point(point):
			return true
	return false

func obstacles_at(cell: Vector2i) -> bool:
	var c := _cell_center(cell)
	for rect in obstacles:
		if rect.has_point(c):
			return true
	return false
func _walkable_count() -> int:
	var n := 0
	for cell in _floor.keys():
		if not obstacles_at(cell):
			n += 1
	return n



func _all_floor_reachable(start: Vector2i) -> bool:
	if not _floor.has(start) or obstacles_at(start):
		return false
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = c + d
			if _floor.has(n) and not seen.has(n) and not obstacles_at(n):
				seen[n] = true
				queue.append(n)
	return seen.size() == _walkable_count()
