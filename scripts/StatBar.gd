class_name StatBar
extends Control
## A framed meter with an optional trailing "ghost" chip and segment ticks.
##
## Replaces the stacks of raw ColorRects the HUD used to draw bars with. Drawn
## in _draw() rather than assembled from child nodes because every edge then
## lands on a whole pixel at any size, and because ticks would otherwise need a
## node each.
##
## Ticks matter more than they look: a segmented bar tells you "three hits left"
## at a glance, where a continuous fill only tells you "some left".

@export var fill_color := Color(0.37, 0.75, 0.42)
## Draw the trailing "what you just lost" chip. Only meaningful for bars that
## drain (health, boss HP) — on a bar that *fills*, like corruption or a dash
## cooldown, the chip would sit at full width behind an empty fill and read as
## a completely full red bar.
@export var show_ghost: bool = false
@export var ghost_color := Color(0.85, 0.3, 0.3, 0.85)
@export var track_color := Color(0.05, 0.05, 0.07, 0.92)
@export var border_color := Color(0.42, 0.47, 0.6)
## Number of segments to score the bar into. 0 = smooth.
@export var ticks: int = 0
## Extra dividers at fixed ratios (corruption tier thresholds, for example).
@export var marks: PackedFloat32Array = PackedFloat32Array()

var value: float = 1.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()
var ghost: float = 1.0:
	set(v):
		ghost = clampf(v, 0.0, 1.0)
		queue_redraw()


func set_fill_color(c: Color) -> void:
	if c != fill_color:
		fill_color = c
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), track_color, true)

	# Ghost first, so the live fill sits on top of it.
	if show_ghost and ghost > value:
		draw_rect(Rect2(1, 1, (w - 2) * ghost, h - 2), ghost_color, true)
	if value > 0.0:
		var fill_w := (w - 2) * value
		draw_rect(Rect2(1, 1, fill_w, h - 2), fill_color, true)
		# A lighter top line reads as a highlight and stops the fill looking
		# like a flat sticker.
		draw_rect(Rect2(1, 1, fill_w, 1), fill_color.lightened(0.35), true)

	# Segment ticks: gaps punched through the fill.
	if ticks > 1:
		for i in range(1, ticks):
			var x := roundf(1 + (w - 2) * (float(i) / ticks))
			draw_rect(Rect2(x, 1, 1, h - 2), track_color, true)

	# Fixed threshold marks (drawn brighter so they read as scale, not segments).
	for m in marks:
		var mx := roundf(1 + (w - 2) * clampf(m, 0.0, 1.0))
		draw_rect(Rect2(mx, 0, 1, h), border_color, true)

	# 1px frame last so nothing overdraws it.
	draw_rect(Rect2(Vector2.ZERO, size), border_color, false, 1.0)
