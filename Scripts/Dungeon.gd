class_name Dungeon
extends TileMapLayer

enum RoomType { ENTRANCE, COMBAT, TREASURE, BOSS, SHOP, ALTAR }

const SLOT_W := 26
const SLOT_H := 16
const GRID_W := 4
const GRID_H := 4


const TILE := 16

const ATLAS := preload("res://Assets/Tilemap/tilemap_packed.png")
const BOULDER_TEX := preload("res://Assets/Tiles/tile_0006.png")
const BRAZIER_TEX := preload("res://Assets/Tiles/tile_0029.png")
const PROP_SCENE := preload("res://Scenes/DestructibleProp.tscn")
const BRAZIER_LIGHT := preload("res://Scripts/BrazierLight.gd")


const FLOOR := Vector2i(0, 4)
const FLOOR_DECO := [Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]
const WALL := Vector2i(2, 1)

var _walls: StaticBody2D
var _src_id := 0
var _floor: Dictionary = {}
var _decor: Node2D
var _props: Node2D
var _gates: Node2D
var rooms: Array = []
var links: Array = []
var _gate_nodes: Dictionary = {}
var obstacles: Array[Rect2] = []
static var _light_tex: GradientTexture2D = null

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


func generate(depth: int = 1) -> void:
	clear()
	_free_helpers()
	rooms.clear()
	_floor.clear()
	
	var slots := _grow_tree(clampi(5 + depth, 6, 9))
	
	_place_rooms(slots["order"])
	_punch_doorways(slots["order"], slots["links"])
	links = slots["links"]
	_assign_types()
	_paint()
	
	for i in range(rooms.size()):
		if rooms[i]["type"] == RoomType.COMBAT or rooms[i]["type"] == RoomType.BOSS:
			_decorate_room(rooms[i]["rect"])
	if not _all_floor_reachable(rooms[0]["rect"].get_center()):
		_free_helpers()
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
	flame.color = Color(1.9, 1.05, 0.35, 0.85)
	flame.emitting = true
	spr.add_child(flame)
	
	
	var light := PointLight2D.new()
	light.texture = _radial_light_texture()
	light.texture_scale = 1.5
	light.energy = 0.85
	light.color = Color(1.0, 0.6, 0.25)
	light.set_script(BRAZIER_LIGHT)
	spr.add_child(light)
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
	
	


func _grow_tree(target: int) -> Dictionary:
	var start := Vector2i(randi() % GRID_W, randi() % GRID_H)
	var visited := {start: true}
	var order: Array = [start]
	var tree_links: Array = []
	var index_of := {start: 0}
	var guard := 0
	
	while order.size() < target and guard < 400:
		guard += 1
		var open_cells: Array = []
		for c in order:
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n: Vector2i = c + d
				if n.x < 0 or n.y < 0 or n.x >= GRID_W or n.y >= GRID_H:
					continue
				if not visited.has(n):
					open_cells.append(c)
					break
		if open_cells.is_empty():
			break
		var from: Vector2i = open_cells.pick_random()
		var options: Array = []
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = from + d
			if n.x < 0 or n.y < 0 or n.x >= GRID_W or n.y >= GRID_H:
				continue
			if not visited.has(n):
				options.append(n)
		var to: Vector2i = options.pick_random()
		visited[to] = true
		index_of[to] = order.size()
		order.append(to)
		tree_links.append([index_of[from], index_of[to]])
	return {"order": order, "links": tree_links}
		

func _place_rooms(order: Array) -> void:
	rooms.clear()
	for slot in order:
		# Fill the slot minus a 1-tile inset, so neighbours share a wall.
		var rect := Rect2i(
			slot.x * SLOT_W + 1, slot.y * SLOT_H + 1,
			SLOT_W - 2, SLOT_H - 2
		)
		rooms.append({"rect": rect, "type": RoomType.COMBAT, "cleared": false, "doors": []})
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				_floor[Vector2i(x, y)] = true
				
				

func _punch_doorways(order: Array, tree_links: Array) -> void:
	for link in tree_links:
		var i: int = link[0]
		var j: int = link[1]
		var si: Vector2i = order[i]
		var sj: Vector2i = order[j]
		var ri: Rect2i = rooms[i]["rect"]
		var rj: Rect2i = rooms[j]["rect"]
		if si.x != sj.x:
			if si.x < sj.x:
				_door_h(ri, rj)
			else:
				_door_h(rj, ri)
		else:
			if si.y < sj.y:
				_door_v(ri, rj)
			else:
				_door_v(rj, ri)

func _door_h(left: Rect2i, right: Rect2i) -> void:
	var y0: int = maxi(left.position.y, right.position.y)
	var y1: int = mini(left.end.y, right.end.y)
	var cy: int = floori((y0 + y1) * 0.5)
	for x in range(left.end.x, right.position.x):
		_floor[Vector2i(x, cy - 1)] = true
		_floor[Vector2i(x, cy)] = true
		_record_door(left, right, Vector2i(x, cy - 1))
		_record_door(left, right, Vector2i(x, cy))

func _door_v(top: Rect2i, bottom: Rect2i) -> void:
	var x0: int = maxi(top.position.x, bottom.position.x)
	var x1: int = mini(top.end.x, bottom.end.x)
	var cx: int = floori((x0 + x1) * 0.5)
	for y in range(top.end.y, bottom.position.y):
		_floor[Vector2i(cx - 1, y)] = true
		_floor[Vector2i(cx, y)] = true
		_record_door(top, bottom, Vector2i(cx - 1, y))
		_record_door(top, bottom, Vector2i(cx, y))
	
	
func _record_door(a: Rect2i, b: Rect2i, cell: Vector2i) -> void:
	for i in range(rooms.size()):
		var r: Rect2i = rooms[i]["rect"]
		if r == a or r == b:
			rooms[i]["doors"].append(cell)
			


func _farthest_room() -> int:
	var distances := {0: 0}
	var pending: Array[int] = [0]
	var head := 0
	var farthest := 0
	while head < pending.size():
		var here := pending[head]
		head += 1
		for edge in links:
			var next: int = -1
			if edge[0] == here: next = edge[1]
			elif edge[1] == here: next = edge[0]
			if next < 0 or distances.has(next): continue
			distances[next] = int(distances[here]) + 1
			pending.append(next)
			if int(distances[next]) > int(distances[farthest]): farthest = next
	return farthest



func _assign_types() -> void:
	rooms[0]["type"] = RoomType.ENTRANCE
	var boss_index := _farthest_room()
	
	if boss_index != 0:
		rooms[boss_index]["type"] = RoomType.BOSS

	# Some middle rooms become special, but always reserve at least one for
	# combat so a floor still has a fight in it.
	var middle: Array = []
	for i in range(1, rooms.size()):
		if i != boss_index:
			middle.append(i)
	middle.shuffle()

	var budget: int = maxi(0, middle.size() - 1)
	var specials: Array = []
	if budget >= 1: specials.append(RoomType.SHOP)
	if budget >= 2: specials.append(RoomType.TREASURE)
	if budget >= 3: specials.append(RoomType.ALTAR)
	if budget >= 4: specials.append(RoomType.TREASURE)

	for k in range(specials.size()):
		rooms[middle[k]]["type"] = specials[k]
		
		
func room_at(world_pos: Vector2) -> int:
	var cell := local_to_map(to_local(world_pos))
	for i in range(rooms.size()):
		if (rooms[i]["rect"] as Rect2i).has_point(cell):
			return i
	return -1


func room_center_world(i: int) -> Vector2:
	return to_global(_cell_center((rooms[i]["rect"] as Rect2i).get_center()))


func entrance_center() -> Vector2:
	return room_center_world(0)
	


func random_point_in_room(i: int, avoid: Vector2, min_dist: float = 60.0) -> Vector2:
	var r: Rect2i = rooms[i]["rect"]
	var candidates: Array[Vector2] = []
	for x in range(r.position.x + 1, r.end.x - 1):
		for y in range(r.position.y + 1, r.end.y - 1):
			var p := to_global(_cell_center(Vector2i(x, y)))
			if not _blocked(p):
				candidates.append(p)
	candidates.shuffle()
	for p in candidates:
		if p.distance_to(avoid) >= min_dist:
			return p
	# Relax distance only, never obstacle safety. Centre is reserved clear.
	var best := room_center_world(i)
	for p in candidates:
		if p.distance_squared_to(avoid) > best.distance_squared_to(avoid):
			best = p
	return best
	
func _blocked(pos: Vector2) -> bool:
	for rect in obstacles:
		if rect.grow(10.0).has_point(pos):
			return true
	return false

func lock_room(i: int) -> void:
	if _gate_nodes.has(i):
		return                       # already locked — never stack gates
	var gates: Array = []
	# One box per recorded door cell, so it works for horizontal and vertical
	# doorways without knowing which it is.
	for door_cell in rooms[i]["doors"]:
		var gate := StaticBody2D.new()
		gate.collision_layer = 1
		gate.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE, TILE)
		shape.shape = rect
		gate.add_child(shape)
		var picture := Polygon2D.new()
		picture.polygon = PackedVector2Array([Vector2(-8,-8), Vector2(8,-8), Vector2(8,8), Vector2(-8,8)])
		picture.color = Color(0.55, 0.25, 0.12)
		gate.add_child(picture)
		gate.position = _cell_center(door_cell)
		_gates.add_child(gate)
		gates.append(gate)
	_gate_nodes[i] = gates
	if not gates.is_empty():
		AudioManager.play("door_close", -2.0)

func unlock_room(i: int) -> void:
	if not _gate_nodes.has(i):
		return
	for g in _gate_nodes[i]:
		if is_instance_valid(g):
			g.queue_free()
	_gate_nodes.erase(i)
	AudioManager.play("door_open", -2.0)



static func _radial_light_texture() -> GradientTexture2D:
	if _light_tex != null:
		return _light_tex
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 128
	t.height = 128
	_light_tex = t
	return _light_tex
	
