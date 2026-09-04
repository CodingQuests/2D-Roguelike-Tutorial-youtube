class_name Dungeon
extends TileMapLayer
## A connected dungeon: a PACKED GRID of big rooms joined directly by doorways
## (no long corridors, no empty void to walk through). Built by growing a random
## spanning tree over a coarse slot grid; each visited slot becomes a room that
## fills the slot, and every tree edge punches a doorway through the 2-tile wall
## shared by the two rooms. Rooms are typed (entrance / combat / treasure /
## boss). RoomController walks the player through it and locks doors per room.

const TILE := 16
# Slots are WIDE and SHORT to match the 16:9 screen, so a whole room (all four
# walls + doorways) is visible at once instead of overflowing the view. Rooms
# fill their slot minus a 1-tile inset.
const SLOT_W := 26          # -> rooms 24 tiles wide
const SLOT_H := 16          # -> rooms 14 tiles tall
const GRID_W := 4
const GRID_H := 4

const ATLAS := preload("res://Assets/Tilemap/tilemap_packed.png")
const FLOOR := Vector2i(0, 4)
const FLOOR_DECO := [Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]
const WALL := Vector2i(2, 1)

const BOULDER_TEX := preload("res://Assets/Tiles/tile_0006.png")
const BRAZIER_TEX := preload("res://Assets/Tiles/tile_0029.png")
const LIGHT_TEX := preload("res://light_radial.tres")
const BRAZIER_LIGHT := preload("res://scripts/BrazierLight.gd")
const HEAT_SHADER := preload("res://shaders/fx_heat.gdshader")
const FX_QUAD := preload("res://fx_quad.tres")
const PROP_SCENE := preload("res://scenes/DestructibleProp.tscn")
const PROP_TEX := [
	preload("res://Assets/Tiles/tile_0067.png"),
	preload("res://Assets/Tiles/tile_0063.png"),
	preload("res://Assets/Tiles/tile_0073.png"),
]

enum RoomType { ENTRANCE, COMBAT, TREASURE, BOSS, SHOP, ALTAR }

var _src_id := 0
var _walls: StaticBody2D
var _decor: Node2D
var _props: Node2D
var _gates: Node2D
var _backdrop: Node2D
var _shade: Node2D

## Each room: {rect: Rect2i, type: int, cleared: bool, doors: Array[Vector2i]}
var rooms: Array = []
## Spanning-tree edges as [room_index_a, room_index_b] — drawn as the minimap's
## corridor connections.
var links: Array = []
var _floor: Dictionary = {}    # Vector2i -> true
var obstacles: Array[Rect2] = []
var _gate_nodes: Dictionary = {}  # room_index -> Array[Node]


func _ready() -> void:
	_build_tileset()


func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	src.texture = ATLAS
	src.texture_region_size = Vector2i(TILE, TILE)
	var used := [FLOOR, WALL]
	used.append_array(FLOOR_DECO)
	for c in used:
		src.create_tile(c)
		# The layer is Y-sorted so that Decor/Props (its children) sort against
		# the player by depth. Without this the tiles join that same sort list,
		# and any floor tile below the player's origin gets painted OVER the
		# player's legs. Pinning tiles to a low z_index keeps the ground as
		# ground — Y-sorting only orders within a z_index.
		var data := src.get_tile_data(c, 0)
		if data:
			data.z_index = -10
	_src_id = ts.add_source(src)
	tile_set = ts


# --- Generation --------------------------------------------------------
func generate(depth: int) -> void:
	clear()
	_free_helpers()
	rooms.clear()
	_floor.clear()
	obstacles.clear()
	_gate_nodes.clear()

	_walls = _new_child(StaticBody2D.new(), "Walls")
	_walls.collision_layer = 1
	_walls.collision_mask = 0
	# Y-sorted so props/boulders and the player overlap by depth, not tree order.
	var decor := Node2D.new()
	decor.y_sort_enabled = true
	_decor = _new_child(decor, "Decor")
	var props := Node2D.new()
	props.y_sort_enabled = true
	_props = _new_child(props, "Props")
	_gates = _new_child(Node2D.new(), "Gates")

	var slots := _grow_tree(clampi(5 + depth, 6, 9))
	_place_rooms(slots["order"])
	_punch_doorways(slots["order"], slots["links"])
	links = slots["links"]
	_assign_types()
	_paint()
	_compute_doors()
	_build_wall_collision()
	for i in range(rooms.size()):
		if rooms[i]["type"] == RoomType.COMBAT or rooms[i]["type"] == RoomType.BOSS:
			_decorate_room(i)


# Grow a random spanning tree across the slot grid.
func _grow_tree(target: int) -> Dictionary:
	var start := Vector2i(randi() % GRID_W, randi() % GRID_H)
	var visited := {start: true}
	var order: Array = [start]
	var tree_links: Array = []  # [from_index, to_index]
	var index_of := {start: 0}
	var guard := 0
	while order.size() < target and guard < 400:
		guard += 1
		# Collect visited cells that still have an unvisited neighbour.
		var open_cells: Array = []
		for c in order:
			for n in _neighbours(c):
				if not visited.has(n):
					open_cells.append(c)
					break
		if open_cells.is_empty():
			break
		var from: Vector2i = open_cells.pick_random()
		var choices: Array = []
		for n in _neighbours(from):
			if not visited.has(n):
				choices.append(n)
		var to: Vector2i = choices.pick_random()
		visited[to] = true
		index_of[to] = order.size()
		tree_links.append([index_of[from], order.size()])
		order.append(to)
	return {"order": order, "links": tree_links}


func _neighbours(c: Vector2i) -> Array:
	var out: Array = []
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = c + d
		if n.x >= 0 and n.x < GRID_W and n.y >= 0 and n.y < GRID_H:
			out.append(n)
	return out


func _place_rooms(order: Array) -> void:
	# Each room fills its slot with a 1-tile inset, so two adjacent rooms are
	# separated by a 2-tile wall (1 border each) that a doorway punches through.
	for slot in order:
		var rect := Rect2i(slot.x * SLOT_W + 1, slot.y * SLOT_H + 1, SLOT_W - 2, SLOT_H - 2)
		rooms.append({"rect": rect, "type": RoomType.COMBAT, "cleared": false, "doors": []})
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				_floor[Vector2i(x, y)] = true


func _punch_doorways(order: Array, links: Array) -> void:
	for link in links:
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


# 2x2 doorway through the vertical wall between a left and a right room.
func _door_h(left: Rect2i, right: Rect2i) -> void:
	var y0: int = maxi(left.position.y, right.position.y)
	var y1: int = mini(left.end.y, right.end.y)
	var cy: int = floori((y0 + y1) * 0.5)
	for x in range(left.end.x, right.position.x):
		_floor[Vector2i(x, cy - 1)] = true
		_floor[Vector2i(x, cy)] = true


# 2x2 doorway through the horizontal wall between a top and a bottom room.
func _door_v(top: Rect2i, bot: Rect2i) -> void:
	var x0: int = maxi(top.position.x, bot.position.x)
	var x1: int = mini(top.end.x, bot.end.x)
	var cx: int = floori((x0 + x1) * 0.5)
	for y in range(top.end.y, bot.position.y):
		_floor[Vector2i(cx - 1, y)] = true
		_floor[Vector2i(cx, y)] = true


func _assign_types() -> void:
	rooms[0]["type"] = RoomType.ENTRANCE
	if rooms.size() > 1:
		rooms[rooms.size() - 1]["type"] = RoomType.BOSS
	# Some middle rooms become special (shop / treasure / forge altar), but always
	# reserve at least one middle room for combat so a floor still has fights.
	var middle: Array = []
	for i in range(1, rooms.size() - 1):
		middle.append(i)
	middle.shuffle()
	var budget: int = maxi(0, middle.size() - 1)
	var specials: Array = []
	if budget >= 1:
		specials.append(RoomType.SHOP)
	if budget >= 2:
		specials.append(RoomType.TREASURE)
	if budget >= 3:
		specials.append(RoomType.ALTAR)
	if budget >= 4:
		specials.append(RoomType.TREASURE)
	for k in range(specials.size()):
		rooms[middle[k]]["type"] = specials[k]


func _paint() -> void:
	for cell in _floor.keys():
		set_cell(cell, _src_id, FLOOR)
	_scatter_floor_decor()
	# Walls = any 8-neighbour of a floor cell that isn't floor.
	var wall_set := {}
	for cell in _floor.keys():
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n: Vector2i = cell + Vector2i(dx, dy)
				if not _floor.has(n):
					wall_set[n] = true
	for cell in wall_set.keys():
		set_cell(cell, _src_id, WALL)
	_build_backdrop()
	_build_wall_depth(wall_set)


## Floor decoration in CLUSTERS rather than an even 10% scatter. Evenly spread
## noise reads as dirt on the lens; a few dirty patches with clean stone between
## them reads as texture, because the contrast is what makes it legible.
func _scatter_floor_decor() -> void:
	for room in rooms:
		var rect: Rect2i = room["rect"]
		for _seed in range(randi_range(2, 4)):
			var origin := Vector2i(
				randi_range(rect.position.x + 1, rect.end.x - 2),
				randi_range(rect.position.y + 1, rect.end.y - 2))
			for _blot in range(randi_range(3, 7)):
				var cell := origin + Vector2i(randi_range(-2, 2), randi_range(-1, 1))
				if _floor.has(cell):
					set_cell(cell, _src_id, FLOOR_DECO.pick_random())


## A dark slab under the whole dungeon. Without it the camera sees the window's
## clear colour wherever it looks past a room edge, which reads as an unfinished
## level no matter how good the room itself looks.
func _build_backdrop() -> void:
	if _floor.is_empty():
		return
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := Vector2i(-(1 << 30), -(1 << 30))
	for cell in _floor.keys():
		lo.x = mini(lo.x, cell.x)
		lo.y = mini(lo.y, cell.y)
		hi.x = maxi(hi.x, cell.x)
		hi.y = maxi(hi.y, cell.y)
	var pad := 24 * TILE
	var origin := Vector2(lo.x * TILE - pad, lo.y * TILE - pad)
	var size := Vector2((hi.x - lo.x + 1) * TILE + pad * 2, (hi.y - lo.y + 1) * TILE + pad * 2)
	var slab := Polygon2D.new()
	slab.name = "Bedrock"
	slab.polygon = PackedVector2Array([
		origin,
		origin + Vector2(size.x, 0),
		origin + size,
		origin + Vector2(0, size.y),
	])
	slab.color = Color(0.055, 0.05, 0.07)
	slab.z_index = -100
	slab.z_as_relative = false
	slab.light_mask = 0   # bedrock stays black regardless of nearby torches
	_backdrop = _new_child(slab, "Bedrock")


## A soft shadow cast down onto the floor from the base of every wall. This is
## what gives flat top-down wall tiles apparent height — without it walls and
## floor sit in the same visual plane.
func _build_wall_depth(wall_set: Dictionary) -> void:
	var shade := Node2D.new()
	shade.z_index = -6
	shade.light_mask = 0
	_shade = _new_child(shade, "WallShade")
	const DROP := 7.0
	for cell in wall_set.keys():
		var below: Vector2i = cell + Vector2i(0, 1)
		if not _floor.has(below):
			continue
		var x := float(below.x * TILE)
		var y := float(below.y * TILE)
		var quad := Polygon2D.new()
		quad.polygon = PackedVector2Array([
			Vector2(x, y),
			Vector2(x + TILE, y),
			Vector2(x + TILE, y + DROP),
			Vector2(x, y + DROP),
		])
		# Fade to nothing downward so it reads as a soft cast shadow.
		quad.vertex_colors = PackedColorArray([
			Color(0, 0, 0, 0.42),
			Color(0, 0, 0, 0.42),
			Color(0, 0, 0, 0.0),
			Color(0, 0, 0, 0.0),
		])
		shade.add_child(quad)


func _compute_doors() -> void:
	for room in rooms:
		var rect: Rect2i = room["rect"]
		var ring := rect.grow(1)
		var doors: Array = []
		for x in range(ring.position.x, ring.end.x):
			for y in [ring.position.y, ring.end.y - 1]:
				var c := Vector2i(x, y)
				if _floor.has(c):
					doors.append(c)
		for y in range(ring.position.y, ring.end.y):
			for x in [ring.position.x, ring.end.x - 1]:
				var c := Vector2i(x, y)
				if _floor.has(c):
					doors.append(c)
		room["doors"] = doors


func _build_wall_collision() -> void:
	# Merge wall cells into horizontal spans per row for fewer colliders.
	var wall_rows := {}
	var wall_set := {}
	for cell in _floor.keys():
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n: Vector2i = cell + Vector2i(dx, dy)
				if not _floor.has(n):
					wall_set[n] = true
	for cell in wall_set.keys():
		if not wall_rows.has(cell.y):
			wall_rows[cell.y] = []
		wall_rows[cell.y].append(cell.x)
	for y in wall_rows.keys():
		var xs: Array = wall_rows[y]
		xs.sort()
		var run_start: int = xs[0]
		var prev: int = xs[0]
		for i in range(1, xs.size()):
			if xs[i] == prev + 1:
				prev = xs[i]
			else:
				_add_wall_span(run_start, prev, y)
				run_start = xs[i]
				prev = xs[i]
		_add_wall_span(run_start, prev, y)


func _add_wall_span(x0: int, x1: int, y: int) -> void:
	var span := (x1 - x0 + 1) * TILE
	var centre := Vector2(x0 * TILE + span * 0.5, y * TILE + TILE * 0.5)

	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(span, TILE)
	cs.shape = shape
	cs.position = centre
	_walls.add_child(cs)

	# The same merged span doubles as a light occluder, so the torch stops at
	# walls instead of glowing through them. Reusing the already-merged row
	# spans matters: one occluder per wall TILE would be hundreds of polygons
	# per floor.
	var occ := LightOccluder2D.new()
	var poly := OccluderPolygon2D.new()
	var hw := span * 0.5
	var hh := TILE * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	occ.occluder = poly
	occ.position = centre
	_walls.add_child(occ)


# --- Decoration --------------------------------------------------------
func _decorate_room(i: int) -> void:
	var rect: Rect2i = rooms[i]["rect"]
	var center := rect.get_center()
	# Braziers mounted ON the top wall, so the stone frame reads as built-in
	# rather than a box dropped on the floor.
	_place_brazier(Vector2i(rect.position.x + 2, rect.position.y - 1))
	_place_brazier(Vector2i(rect.end.x - 3, rect.position.y - 1))
	# A few props + a couple of boulders, away from the centre and doorways.
	var prop_count := randi_range(3, 6)
	for k in range(prop_count + 2):
		var cell := Vector2i(randi_range(rect.position.x + 1, rect.end.x - 2), randi_range(rect.position.y + 1, rect.end.y - 2))
		if absi(cell.x - center.x) <= 1 and absi(cell.y - center.y) <= 1:
			continue
		if k < 2:
			_place_boulder(cell)
		else:
			_place_prop(cell)


func _place_boulder(cell: Vector2i) -> void:
	var node := Node2D.new()
	node.position = _cell_center(cell)
	_decor.add_child(node)
	var shadow := Polygon2D.new()
	shadow.position = Vector2(0, 6)
	shadow.color = Color(0, 0, 0, 0.28)
	shadow.polygon = _ellipse(9.0, 4.0)
	shadow.light_mask = 0
	node.add_child(shadow)
	var spr := Sprite2D.new()
	spr.texture = BOULDER_TEX
	spr.position = Vector2(0, -2)
	spr.scale = Vector2(1.7, 1.7)
	node.add_child(spr)
	var rect := Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE)
	_add_static_box(rect)
	obstacles.append(rect)


func _place_prop(cell: Vector2i) -> void:
	var prop := PROP_SCENE.instantiate()
	_props.add_child(prop)
	prop.position = _cell_center(cell)
	prop.set_texture(PROP_TEX.pick_random())
	obstacles.append(Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE))


func _place_brazier(cell: Vector2i) -> void:
	var node := Node2D.new()
	node.position = _cell_center(cell)
	_decor.add_child(node)
	var spr := Sprite2D.new()
	spr.texture = BRAZIER_TEX
	spr.scale = Vector2(1.0, 1.0)
	spr.modulate = Color(1.15, 1.0, 0.85)
	node.add_child(spr)
	# Small, contained flame so it reads as a wall sconce, not a bonfire.
	var flame := CPUParticles2D.new()
	flame.amount = 8
	flame.lifetime = 0.4
	flame.position = Vector2(0, -3)
	flame.direction = Vector2(0, -1)
	flame.spread = 14.0
	flame.gravity = Vector2(0, -14)
	flame.initial_velocity_min = 6.0
	flame.initial_velocity_max = 14.0
	flame.scale_amount_min = 1.0
	flame.scale_amount_max = 1.6
	# Over 1.0 on purpose: with hdr_2d on, this is what pushes the flame past the
	# glow threshold so it blooms while the floor around it doesn't.
	flame.color = Color(1.9, 1.05, 0.35, 0.85)
	flame.emitting = true
	node.add_child(flame)
	# The sconce actually lights the room. Flicker is driven procedurally by
	# BrazierLight rather than a looping tween — looping tweens that never stop
	# show up as leaked ObjectDB instances at exit.
	var light := PointLight2D.new()
	light.texture = LIGHT_TEX
	light.texture_scale = 1.5
	light.energy = 0.85
	light.color = Color(1.0, 0.6, 0.25)
	light.set_script(BRAZIER_LIGHT)
	node.add_child(light)

	# Heat plume rising off the flame, driven by the light's own clock so the
	# shimmer and the flicker breathe together.
	var haze := Sprite2D.new()
	haze.texture = FX_QUAD
	haze.light_mask = 0
	haze.z_index = 3
	haze.scale = Vector2(20.0 / 64.0, 34.0 / 64.0)
	haze.position = Vector2(0, -20)
	var haze_mat := ShaderMaterial.new()
	haze_mat.shader = HEAT_SHADER
	haze_mat.set_shader_parameter("seed", randf() * 100.0)
	haze.material = haze_mat
	node.add_child(haze)
	light.haze_material = haze_mat


func _add_static_box(rect: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	cs.position = rect.position + rect.size * 0.5
	_walls.add_child(cs)


# --- Gates (room locks) ------------------------------------------------
func lock_room(i: int) -> void:
	if _gate_nodes.has(i):
		return
	var nodes: Array = []
	for cell in rooms[i]["doors"]:
		var gate := StaticBody2D.new()
		gate.collision_layer = 1
		gate.collision_mask = 0
		gate.position = _cell_center(cell)
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(TILE, TILE)
		cs.shape = shape
		gate.add_child(cs)
		var vis := Polygon2D.new()
		vis.color = Color(0.8, 0.2, 0.9, 0.5)
		vis.polygon = PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
		gate.add_child(vis)
		_gates.add_child(gate)
		nodes.append(gate)
	_gate_nodes[i] = nodes
	if not nodes.is_empty():
		AudioManager.play("door_close", -2.0)


func unlock_room(i: int) -> void:
	if not _gate_nodes.has(i):
		return
	for gate in _gate_nodes[i]:
		if is_instance_valid(gate):
			gate.queue_free()
	_gate_nodes.erase(i)
	AudioManager.play("door_open", -2.0)


# --- Queries -----------------------------------------------------------
func room_at(world_pos: Vector2) -> int:
	var cell := Vector2i(floori(world_pos.x / TILE), floori(world_pos.y / TILE))
	for i in range(rooms.size()):
		if (rooms[i]["rect"] as Rect2i).has_point(cell):
			return i
	return -1


func room_rect_world(i: int) -> Rect2:
	var r: Rect2i = rooms[i]["rect"]
	return Rect2(r.position.x * TILE, r.position.y * TILE, r.size.x * TILE, r.size.y * TILE)


func room_center_world(i: int) -> Vector2:
	var r: Rect2i = rooms[i]["rect"]
	return Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5) * TILE


func entrance_center() -> Vector2:
	return room_center_world(0)


func random_point_in_room(i: int, avoid: Vector2, min_dist: float = 60.0) -> Vector2:
	var r: Rect2i = rooms[i]["rect"]
	var pos := room_center_world(i)
	for attempt in range(20):
		var cx := randi_range(r.position.x + 1, r.end.x - 2)
		var cy := randi_range(r.position.y + 1, r.end.y - 2)
		pos = _cell_center(Vector2i(cx, cy))
		if pos.distance_to(avoid) >= min_dist and _is_free(pos):
			break
	return pos


func _is_free(pos: Vector2) -> bool:
	for rect in obstacles:
		if rect.grow(10.0).has_point(pos):
			return false
	return true


# --- Helpers -----------------------------------------------------------
func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x + 0.5, cell.y + 0.5) * TILE


func _ellipse(rx: float, ry: float, steps: int = 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps):
		var a := TAU * float(i) / steps
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _new_child(node: Node, nm: String) -> Node:
	node.name = nm
	add_child(node)
	return node


func _free_helpers() -> void:
	for n in [_walls, _decor, _props, _gates, _backdrop, _shade]:
		if n and is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_walls = null
	_decor = null
	_props = null
	_gates = null
	_backdrop = null
	_shade = null
