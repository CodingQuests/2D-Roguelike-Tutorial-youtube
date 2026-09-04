extends Node
## Autoload singleton (registered as "GameManager" in project settings).
## Acts as the glue between systems that don't otherwise know about each other:
## camera shake, hit-stop, and run/restart control. Nodes register themselves
## here in their _ready() so anyone can reach them.

var camera: Camera2D = null
var hud: CanvasLayer = null
var player: Node = null

## Per-run stats, shown on the death screen and the hub.
## `essence` is the META currency (banked on death, spent in the Forge hub);
## `gold` is the IN-RUN currency, spent at shops and lost when the run ends.
const DEFAULT_RUN_STATS := {
	"rooms_cleared": 0, "enemies_killed": 0, "essence": 0, "gold": 0,
	"score": 0, "max_combo": 0, "started_ms": 0, "floor": 1,
}
var run_stats := DEFAULT_RUN_STATS.duplicate()

# Combo / style multiplier.
const COMBO_WINDOW := 3.0
var combo: int = 0
var combo_timer: float = 0.0

var _hitstop_token := 0

## Crosshair cursor (Kenney cursor pack) — fits the mouse-aim combat.
const CURSOR_TEX := preload("res://Assets/cursor/Tiles/tile_0190.png")


func _ready() -> void:
	_apply_cursor()


func _apply_cursor() -> void:
	var img := CURSOR_TEX.get_image()
	img.resize(32, 32, Image.INTERPOLATE_NEAREST)  # 16px source is too small on-screen
	Input.set_custom_mouse_cursor(ImageTexture.create_from_image(img), Input.CURSOR_ARROW, Vector2(16, 16))


func _process(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0


## Reset stats at the start of a new run (called by RoomController).
func start_run() -> void:
	Engine.time_scale = 1.0  # safety: clear any leftover hit-stop
	combo = 0
	combo_timer = 0.0
	run_stats = DEFAULT_RUN_STATS.duplicate()
	run_stats["started_ms"] = Time.get_ticks_msec()


## In-run currency earned from kills/props, spent at shops.
func register_gold(amount: int) -> void:
	run_stats["gold"] = int(run_stats.get("gold", 0)) + amount


## Try to spend `amount` gold. Returns true if the player could afford it.
func spend_gold(amount: int) -> bool:
	if int(run_stats.get("gold", 0)) < amount:
		return false
	run_stats["gold"] -= amount
	return true


## A kill: bump the combo, score by the multiplier, refresh the window.
func register_kill() -> void:
	combo += 1
	combo_timer = COMBO_WINDOW
	run_stats["score"] += 10 * combo
	run_stats["max_combo"] = maxi(run_stats["max_combo"], combo)


## Taking damage drops the combo.
func break_combo() -> void:
	combo = 0
	combo_timer = 0.0


## Elapsed run time in seconds.
func get_run_time() -> float:
	return maxf(0.0, (Time.get_ticks_msec() - run_stats["started_ms"]) / 1000.0)


func register_camera(cam: Camera2D) -> void:
	camera = cam


func register_hud(h: CanvasLayer) -> void:
	hud = h


func register_player(p: Node) -> void:
	player = p


## Add screen shake. `amount` is "trauma" in the 0..1 range; small hits ~0.2,
## heavy hits ~0.6.
func shake_camera(amount: float) -> void:
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(amount)


## Freeze the game for a few real-time milliseconds to sell an impact.
func hit_stop(duration: float) -> void:
	if duration <= 0.0:
		return
	Engine.time_scale = 0.0
	_hitstop_token += 1
	var my_token := _hitstop_token
	# 4th arg `ignore_time_scale` = true so the timer keeps ticking while frozen.
	var timer := get_tree().create_timer(duration, true, false, true)
	await timer.timeout
	# Only the most recent hit-stop is allowed to unfreeze.
	if my_token == _hitstop_token:
		Engine.time_scale = 1.0


## Slow the whole game down to `scale` for `duration` real seconds, then snap
## back to normal. Used for kill flourishes, wave clears and the death beat.
## Shares the hit-stop token so the most recent time effect always wins.
func slow_mo(scale: float, duration: float) -> void:
	scale = clampf(scale, 0.02, 1.0)
	Engine.time_scale = scale
	_hitstop_token += 1
	var my_token := _hitstop_token
	AudioManager.duck_music(-12.0, duration)
	var timer := get_tree().create_timer(duration, true, false, true)
	await timer.timeout
	if my_token == _hitstop_token:
		Engine.time_scale = 1.0


## Directional camera punch (distinct from random shake): kicks the view a few
## pixels along `dir`, then springs home.
func camera_kick(dir: Vector2, amount: float) -> void:
	if camera and camera.has_method("add_kick"):
		camera.add_kick(dir, amount)


## Quick zoom-in pop that eases back out — sells a heavy hit or a kill.
func zoom_punch(amount: float) -> void:
	if camera and camera.has_method("add_zoom_punch"):
		camera.add_zoom_punch(amount)


## Ripple the screen outward from a WORLD position. Reserved for heavy hits and
## boss slams — it's the loudest effect in the game and cheapens fast if it
## fires on every swing.
func shockwave(world_pos: Vector2, strength: float = 1.0) -> void:
	if hud and hud.has_method("play_shockwave"):
		hud.play_shockwave(world_pos, strength)


# --- Full-screen FX (driven by the HUD's ScreenFX shader) --------------
## Brief red full-screen flash when the player is hurt.
func screen_damage() -> void:
	if hud and hud.has_method("flash_damage"):
		hud.flash_damage()


## Soft white/impact vignette pop (heavy hits, tier-ups).
func screen_impact(amount: float) -> void:
	if hud and hud.has_method("add_screen_impact"):
		hud.add_screen_impact(amount)


func restart_game() -> void:
	Engine.time_scale = 1.0
	Transitions.reload_scene()
