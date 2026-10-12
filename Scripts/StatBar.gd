class_name StatBar
extends Control



@export var fill_color: Color = Color(0.85, 0.2, 0.2)
@export var ghost_color: Color = Color(0.6, 0.1, 0.1)
@export var ghost_lerp: float = 4.0
@export var show_ghost: bool = true

var _ratio: float = 1.0
var _ghost: float = 1.0

func set_ratio(v: float) -> void:
	_ratio = clampf(v, 0.0, 1.0)
	if _ratio > _ghost:
		_ghost = _ratio          # healing: snap up, no lag
	queue_redraw()
	
	
func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if _ghost > _ratio:
		_ghost = lerpf(_ghost, _ratio, 1.0 - exp(-ghost_lerp * delta))
		queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.1, 0.1, 0.12))
	if show_ghost:
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _ghost, size.y)), ghost_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _ratio, size.y)), fill_color)
	
	
