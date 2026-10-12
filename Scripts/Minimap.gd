extends Control

var dungeon: Node = null
var _pulse := 0.0

func set_dungeon(d: Node) -> void:
	dungeon = d
	queue_redraw()

func _room_center_tiles(i: int) -> Vector2:
	var r: Rect2i = dungeon.rooms[i]["rect"]
	return Vector2(r.get_center())


func _process(delta: float) -> void:
	if dungeon != null:
		_pulse += delta * 4.0
		queue_redraw()
		

func _draw() -> void:
	if dungeon == null or dungeon.rooms.is_empty():
		return
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
	
	var pad := 9.0
	var area := size - Vector2(pad * 2, pad * 2)
	var sc: float = minf(area.x / span.x, area.y / span.y)
	var off := (size - span * sc) * 0.5
	
	var to_map := func(tile_pt: Vector2) -> Vector2:
		return (tile_pt - minp) * sc + off
	
	for link in dungeon.links:
		var a: Vector2 = to_map.call(_room_center_tiles(link[0]))
		var b: Vector2 = to_map.call(_room_center_tiles(link[1]))
		draw_line(a, b, Color(0.35, 0.38, 0.46), 2.0)
	
	var cur := -1
	if GameManager.player:
		cur = dungeon.room_at(GameManager.player.global_position)
	
	for i in range(dungeon.rooms.size()):
		var room: Dictionary = dungeon.rooms[i]
		var r: Rect2i = room["rect"]
		var box := Rect2(to_map.call(Vector2(r.position)), Vector2(r.size) * sc)
		draw_rect(box, _colour_for(room, i == cur), true)
		if i == cur:
			var glow := 0.5 + 0.5 * sin(_pulse)
			draw_rect(box, Color(1, 1, 1, glow), false, 2.0)
			
func _colour_for(room: Dictionary, is_current: bool) -> Color:
	if is_current:
		return Color(0.95, 0.85, 0.3)
	match int(room["type"]):
		Dungeon.RoomType.BOSS:     return Color(0.75, 0.2, 0.2)
		Dungeon.RoomType.TREASURE: return Color(0.85, 0.7, 0.25)
		Dungeon.RoomType.SHOP:     return Color(0.3, 0.7, 0.5)
		Dungeon.RoomType.ALTAR:    return Color(0.6, 0.35, 0.8)
		_:
			return Color(0.3, 0.3, 0.34) if not room["cleared"] else Color(0.18, 0.18, 0.2)
			
			
