class_name Dungeon
extends TileMapLayer

const TILE := 16

const ATLAS := preload("res://Assets/Tilemap/tilemap_packed.png")
const FLOOR := Vector2i(0, 4)
const FLOOR_DECO := [Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]
const WALL := Vector2i(2, 1)

var _walls: StaticBody2D
var _src_id := 0
var _floor: Dictionary = {}
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
	if is_instance_valid(_walls):
		_walls.queue_free()
	_walls = StaticBody2D.new()
	_walls.name = "Walls"
	_walls.collision_layer = 1     # World
	_walls.collision_mask = 0
	add_child(_walls)
	
	var rect := Rect2i(0, 0, 24, 14)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			_floor[Vector2i(x, y)] = true
	
	_paint()
	_scatter_floor_decor()
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
