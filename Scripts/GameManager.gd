extends Node

var hud: CanvasLayer = null
var player: Node = null
var camera: Camera2D = null

var _hitstop_token := 0

const DEFAULT_RUN_STATS := {
	"rooms_cleared": 0, "enemies_killed": 0, "essence": 0, "gold": 0,
	"score": 0, "max_combo": 0, "started_ms": 0, "floor": 1,
}
var run_stats := DEFAULT_RUN_STATS.duplicate()

func register_camera(cam: Camera2D) -> void:
	camera = cam

func shake_camera(amount: float) -> void:
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(amount)
	

func hit_stop(duration: float) -> void:
	if duration <= 0.0:
		return
	Engine.time_scale = 0.0
	_hitstop_token += 1
	var my_token := _hitstop_token
	var timer := get_tree().create_timer(duration, true, false, true)
	await timer.timeout
	# Only the most recent hit-stop is allowed to unfreeze.
	if my_token == _hitstop_token:
		Engine.time_scale = 1.0
	
func slow_mo(scale: float, duration: float) -> void:
	scale = clampf(scale, 0.02, 1.0)
	Engine.time_scale = scale
	_hitstop_token += 1
	var my_token := _hitstop_token
	var timer := get_tree().create_timer(duration, true, false, true)
	await timer.timeout
	if my_token == _hitstop_token:
		Engine.time_scale = 1.0
	
func register_hud(h: CanvasLayer) -> void:
	hud = h


func register_player(p: Node) -> void:
	player = p


	
