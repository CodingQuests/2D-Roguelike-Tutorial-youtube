extends PointLight2D
## Procedural flicker for a wall sconce. Two out-of-phase sines rather than one,
## so the pattern doesn't read as an obvious loop, plus a per-instance phase
## offset so a room full of braziers doesn't pulse in unison.
##
## Deliberately NOT a looping Tween: an infinite `create_tween().set_loops()`
## never finishes, and Godot reports it as a leaked ObjectDB instance at exit.

@export var base_energy: float = 0.85
@export var flicker: float = 0.18

var _phase := 0.0


func _ready() -> void:
	_phase = randf() * TAU
	base_energy = energy


## The sconce's heat shimmer shares this node's clock, so the light flicker and
## the plume breathe together instead of drifting apart.
var haze_material: ShaderMaterial = null


func _process(delta: float) -> void:
	_phase += delta
	var f := sin(_phase * 6.1) * 0.6 + sin(_phase * 11.3) * 0.4
	energy = base_energy * (1.0 + flicker * f)
	if haze_material:
		haze_material.set_shader_parameter("time_s", _phase)
		haze_material.set_shader_parameter("intensity", 0.85 + 0.25 * f)
