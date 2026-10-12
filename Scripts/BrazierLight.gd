extends PointLight2D

@export var flicker: float = 0.18

var _base_energy := 0.85
var _phase := 0.0

func _ready() -> void:
	_phase = randf() * TAU
	_base_energy = energy

func _process(delta: float) -> void:
	_phase += delta
	var f := sin(_phase * 6.1) * 0.6 + sin(_phase * 11.3) * 0.4
	energy = _base_energy * (1.0 + flicker * f)
