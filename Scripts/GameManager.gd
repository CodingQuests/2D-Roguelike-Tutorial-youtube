extends Node

var hud: CanvasLayer = null
var player: Node = null
var camera: Camera2D = null

var _hitstop_token := 0
const COMBO_WINDOW := 3.0
const DEFAULT_RUN_STATS := {
	"rooms_cleared": 0, "enemies_killed": 0, "essence": 0, "gold": 0,
	"score": 0, "max_combo": 0, "started_ms": 0, "floor": 1,
}
var run_stats := DEFAULT_RUN_STATS.duplicate()
var combo: int = 0
var combo_timer: float = 0.0

func _process(delta: float) -> void:
	# Only runs while the timer is up: most frames this is one comparison.
	if combo_timer > 0.0:
		combo_timer -= delta
		# The moment it crosses zero, the chain resets.
		if combo_timer <= 0.0:
			combo = 0
			
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


func register_gold(amount: int) -> void:
	# run_stats is already wiped when a run ends, so gold dies with the run for
	# free. .get("gold", 0): the key isn't there until the first coin.
	run_stats["gold"] = int(run_stats.get("gold", 0)) + amount

func register_kill() -> void:
	# One more on the chain, and the window refills.
	combo += 1
	combo_timer = COMBO_WINDOW
	# Ten times the combo: the fifth kill in a chain is worth fifty.
	run_stats["score"] += 10 * combo
	# The best chain. This is the number the death screen shows.
	run_stats["max_combo"] = maxi(run_stats["max_combo"], combo)
func break_combo() -> void:
	combo = 0
	combo_timer = 0.0

func spend_gold(amount: int) -> bool:
	# Only takes the money when it can. The caller decides what a no looks like.
	if int(run_stats.get("gold", 0)) < amount:
		return false
	run_stats["gold"] -= amount
	return true

func start_run() -> void:
	# Otherwise a hit-stop timer pending from the last run fires into this one.
	_hitstop_token += 1        # invalidate timers from the previous run
	# Time scale and pause back to normal, chain cleared.
	Engine.time_scale = 1.0
	get_tree().paused = false
	combo = 0
	combo_timer = 0.0
	# A fresh copy of the stats, and the start time stamped in milliseconds.
	run_stats = DEFAULT_RUN_STATS.duplicate()
	run_stats["started_ms"] = Time.get_ticks_msec()
	
func get_run_time() -> float:
	# Now minus the stamp, in seconds. maxf so it can never come back negative.
	return maxf(0.0, (Time.get_ticks_msec() - run_stats["started_ms"]) / 1000.0)
