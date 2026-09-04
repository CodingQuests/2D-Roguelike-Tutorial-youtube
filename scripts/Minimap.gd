extends Control
## Tiny dungeon map. Draws each room as a coloured box (grey = unexplored,
## yellow = current, gold = treasure, red = boss, dimmed = cleared) with a
## Kenney tile icon on special rooms (chest = treasure, skull = boss) plus a dot
## for the player. Reads the live Dungeon data set via set_dungeon().

const TILE := 16
const ICON_BOSS := preload("res://Assets/Tiles/tile_0124.png")
const ICON_TREASURE := preload("res://Assets/Tiles/tile_0089.png")
const ICON_ENTRANCE := preload("res://Assets/Tiles/tile_0008.png")

var dungeon: Node = null
var _pulse := 0.0


func set_dungeon(d: Node) -> void:
	dungeon = d
	queue_redraw()


func _process(delta: float) -> void:
	if dungeon != null:
		_pulse += delta * 4.0
		queue_redraw()


func _draw() -> void:
	if dungeon == null or dungeon.rooms.is_empty():
		return

	# Bounds of the whole dungeon in tile space.
	var minp := Vector2(INF, INF)
	var maxp := Vector2(-INF, -INF)
	for room in dungeon.rooms:
		var r: Rect2i = room["rect"]
		minp.x = minf(minp.x, r.position.x)
		minp.y = minf(minp.y, r.position.y)
		maxp.x = maxf(maxp.x, r.end.x)
		maxp.y = maxf(maxp.y, r.end.y)
	var span := maxp - minp
	if span.x <= 0 or span.y <= 0:
		return

	# Leave headroom at the top for the caption.
	var pad := 9.0
	var head := 18.0
	var area := size - Vector2(pad * 2, pad * 2 + head)
	var sc: float = minf(area.x / span.x, area.y / span.y)
	# Centre the map in the space below the caption.
	var off := (Vector2(size.x, size.y - head) - span * sc) * 0.5 + Vector2(0, head)

	# Framed panel matching the theme's panel style, plus a titled header strip
	# so the map reads as a designed widget instead of a floating black box.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.055, 0.078, 0.88), true)
	draw_rect(Rect2(Vector2(0, 0), Vector2(size.x, head - 3)), Color(0.10, 0.10, 0.14, 0.9), true)
	var caption := "FLOOR %d" % GameManager.run_stats.get("floor", 1)
	# get_theme_default_font() walks this Control's theme chain up to the
	# project-wide theme, so the caption uses the game's pixel font.
	# ThemeDB.get_default_theme() would return Godot's built-in font instead.
	var font := get_theme_default_font()
	if font:
		draw_string(font, Vector2(8, head - 7), caption,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.58, 0.61, 0.69))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.42, 0.47, 0.6), false, 2.0)

	var player := GameManager.player
	var cur := -1
	if player:
		cur = dungeon.room_at(player.global_position)

	# A lambda that maps a tile-space point into panel space.
	var to_map := func(tile_pt: Vector2) -> Vector2:
		return (tile_pt - minp) * sc + off

	# Corridor connections first, so rooms sit on top.
	for link in dungeon.links:
		if link.size() < 2:
			continue
		var a: Vector2 = to_map.call(_room_center_tiles(link[0]))
		var b: Vector2 = to_map.call(_room_center_tiles(link[1]))
		draw_line(a, b, Color(0.38, 0.38, 0.45, 0.7), 2.0)

	for i in range(dungeon.rooms.size()):
		var room: Dictionary = dungeon.rooms[i]
		var r: Rect2i = room["rect"]
		var p: Vector2 = to_map.call(Vector2(r.position))
		var s := Vector2(r.size) * sc
		var col := _room_color(room["type"])
		if room["cleared"]:
			col = col.darkened(0.4)
		draw_rect(Rect2(p, s), col, true)
		# Current room: bright pulsing outline; others: subtle dark edge.
		if i == cur:
			var pulse := 0.6 + 0.4 * (0.5 + 0.5 * sin(_pulse))
			draw_rect(Rect2(p, s).grow(1.0), Color(1.0, 0.95, 0.5, pulse), false, 2.0)
		else:
			draw_rect(Rect2(p, s), Color(0, 0, 0, 0.55), false, 1.0)

		# A small tileset icon marks special rooms.
		var icon: Texture2D = _room_icon(room["type"])
		if icon:
			var isz: float = minf(minf(s.x, s.y) * 0.7, 13.0)
			if isz >= 6.0:
				var ir := Rect2(p + s * 0.5 - Vector2(isz, isz) * 0.5, Vector2(isz, isz))
				var tint := Color(1, 1, 1, 0.5) if room["cleared"] else Color(1, 1, 1, 0.95)
				draw_texture_rect(icon, ir, false, tint)

	if player:
		var pp: Vector2 = to_map.call(player.global_position / TILE)
		draw_circle(pp, 3.5, Color(0.1, 0.2, 0.3, 0.8))
		draw_circle(pp, 2.5, Color(0.5, 0.95, 1.0))


func _room_center_tiles(i: int) -> Vector2:
	var r: Rect2i = dungeon.rooms[i]["rect"]
	return Vector2(r.position) + Vector2(r.size) * 0.5


func _room_color(t: int) -> Color:
	match t:
		Dungeon.RoomType.BOSS:
			return Color(0.75, 0.2, 0.22)
		Dungeon.RoomType.TREASURE:
			return Color(0.82, 0.7, 0.25)
		Dungeon.RoomType.SHOP:
			return Color(0.3, 0.7, 0.6)
		Dungeon.RoomType.ALTAR:
			return Color(0.6, 0.15, 0.55)
		Dungeon.RoomType.ENTRANCE:
			return Color(0.4, 0.55, 0.7)
		_:
			return Color(0.32, 0.32, 0.38)


func _room_icon(t: int) -> Texture2D:
	match t:
		Dungeon.RoomType.BOSS:
			return ICON_BOSS
		Dungeon.RoomType.TREASURE:
			return ICON_TREASURE
		Dungeon.RoomType.ENTRANCE:
			return ICON_ENTRANCE
		_:
			return null
