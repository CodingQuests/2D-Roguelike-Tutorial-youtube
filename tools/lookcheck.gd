extends Node
## Repeatable look-check. Lighting, shaders and UI are all invisible to the
## normal `--headless` validation, so this drives the real game with rendering
## on and writes named PNGs you can eyeball or diff between passes.
##
## Run:
##   Godot_v4.7-stable_win64.exe --path . res://tools/lookcheck.tscn \
##       --resolution 1280x720 --quit-after 4000
##
## Output: user://shots/*.png
## (Windows: %APPDATA%\Godot\app_userdata\<project>\shots)

const OUT := "user://shots"

var _main: Node = null
var _player: Node = null


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_main = load("res://Main.tscn").instantiate()
	add_child.call_deferred(_main)
	await get_tree().create_timer(1.5).timeout
	_player = get_tree().get_first_node_in_group("player")

	await _walk(Vector2(120, 40), 40)
	await _shot("01_room")

	# Mid-swing, so the weapon trail and contact sparks are on screen.
	if _player and _player.get("weapon"):
		_player.weapon.try_quick_attack()
		await get_tree().create_timer(0.07).timeout
	await _shot("02_attack")

	# --- VFX: spawn enemies next to the player and drive real combat, which is
	# --- the only way to see the slash arc, telegraphs, sparks and death burst.
	var room: Node = _main.get_node_or_null("CombatRoom")
	var enemies: Node = room.get_node_or_null("Enemies") if room else null
	var victims: Array = []
	if enemies:
		for i in 3:
			var e: Node = load("res://scenes/GruntEnemy.tscn").instantiate()
			enemies.add_child(e)
			e.global_position = _player.global_position + Vector2(66 + i * 26, -14 + i * 20)
			# Keep them from actually hitting us: a damage flash red-washes the
			# whole frame and makes the VFX impossible to judge.
			e.attack_damage = 0.0
			victims.append(e)
		await get_tree().create_timer(0.9).timeout

	# Mid-swing with enemies in range: slash arc + contact sparks + hit flash.
	if _player.get("weapon"):
		_player.weapon.try_heavy_attack()
		await get_tree().create_timer(0.30).timeout
	await _shot("03a_slash")

	# A telegraph mid-charge.
	if victims.size() > 0 and is_instance_valid(victims[0]):
		victims[0].show_telegraph_circle(52.0)
		victims[0].state_timer = 0.5
		await get_tree().create_timer(0.28).timeout
		await _shot("03b_telegraph")

	# Death: dissolve + burst + ring + light flash.
	for v in victims:
		if is_instance_valid(v):
			v.die()
	await get_tree().create_timer(0.12).timeout
	await _shot("03c_death")
	await get_tree().create_timer(0.8).timeout

	# Corruption high enough to sour the ambient and tint the weapon.
	if _player and _player.has_method("add_corruption"):
		_player.add_corruption(70.0)
		await get_tree().create_timer(1.2).timeout
	await _shot("03_corrupted")

	# The upgrade screen — the busiest UI in the game.
	var ui: Node = _main.get_node_or_null("UI")
	if ui and ui.has_method("show_upgrades"):
		var um := UpgradeManager.new()
		add_child(um)
		ui.show_upgrades(um.get_choices(3), func(_u): pass)
		await get_tree().create_timer(0.7).timeout
		await _shot("04_upgrades")
		ui.hide_upgrades()
		await get_tree().create_timer(0.3).timeout

	# Pause menu.
	if ui and ui.has_method("_set_paused"):
		ui._set_paused(true)
		await get_tree().create_timer(0.4).timeout
		await _shot("05_pause")
		ui._set_paused(false)
		await get_tree().create_timer(0.3).timeout

	# --- States the main loop rarely reaches in a short capture ---------------
	var enemies2: Node = room.get_node_or_null("Enemies") if room else null
	var pickups: Node = room.get_node_or_null("Pickups") if room else null
	var ui2: Node = _main.get_node_or_null("UI")

	# Boss + boss bar. The boss sprite is scale 4, so this is also the check for
	# anything parented to it that scales along (contact shadow, telegraph).
	if enemies2:
		var boss: Node = load("res://scenes/BossEnemy.tscn").instantiate()
		enemies2.add_child(boss)
		boss.global_position = _player.global_position + Vector2(150, -30)
		if ui2 and ui2.has_method("show_boss_bar"):
			ui2.show_boss_bar(boss)
		await get_tree().create_timer(1.0).timeout
		await _shot("09_boss")
		if ui2 and ui2.has_method("hide_boss_bar"):
			ui2.hide_boss_bar()
		boss.queue_free()
		await get_tree().process_frame

	# Caster projectiles + the pickups the player actually walks over.
	if enemies2:
		var caster: Node = load("res://scenes/CasterEnemy.tscn").instantiate()
		enemies2.add_child(caster)
		caster.global_position = _player.global_position + Vector2(190, 10)
	if pickups:
		for spec in [["res://scenes/HealthPickup.tscn", Vector2(-70, 20)],
				["res://scenes/GoldPickup.tscn", Vector2(-40, 44)],
				["res://scenes/CleansePickup.tscn", Vector2(-100, -14)]]:
			var pu: Node = load(spec[0]).instantiate()
			pickups.add_child(pu)
			pu.global_position = _player.global_position + spec[1]
	await get_tree().create_timer(1.6).timeout
	await _shot("10_projectiles_pickups")

	# An item pedestal (shop/treasure/altar rooms).
	if pickups:
		var ped: Node = load("res://scenes/ItemPedestal.tscn").instantiate()
		pickups.add_child(ped)
		ped.def = {"title": "Ember Brand", "desc": "Hits set enemies alight",
			"rarity": "rare", "corruption": 10}
		ped.price = 24
		ped.global_position = _player.global_position + Vector2(0, -70)
		await get_tree().create_timer(0.7).timeout
		await _shot("11_pedestal")

	# The [Tab] build screen, with a few items and an active so it has content.
	if ui2 and ui2.has_method("_toggle_codex"):
		var um2 := UpgradeManager.new()
		add_child(um2)
		for d in um2.get_choices(3):
			um2.apply(_player, d)
		_player.set_active_item("phase_step", "Phase Step", 4.0)
		ui2._toggle_codex()
		await get_tree().create_timer(0.4).timeout
		await _shot("13_codex")
		ui2._toggle_codex()
		await get_tree().create_timer(0.2).timeout

	# Blink into a wall: the destination must stay inside the room.
	if _player.has_method("_safe_blink"):
		var before: Vector2 = _player.global_position
		var probe: Vector2 = _player.call("_safe_blink", Vector2.UP, 4000.0)
		print("BLINK_TEST from ", before, " -> ", probe, "  travelled ",
			before.distance_to(probe))

	# The status banner (room clear / floor text).
	if ui2 and ui2.has_method("show_status"):
		ui2.show_status("ROOM CLEAR", 3.0)
		await get_tree().create_timer(0.4).timeout
		await _shot("12_banner")

	# Death screen.
	if ui and ui.has_method("show_game_over"):
		ui.show_game_over()
		await get_tree().create_timer(0.9).timeout
		await _shot("06_death")

	# Title + hub, so the menus get checked against the same theme too. Tear the
	# game down first — leaving Main loaded renders the menus on top of a live
	# HUD and makes the shots useless.
	_main.queue_free()
	_main = null
	await get_tree().process_frame
	await get_tree().process_frame
	for scene in [["res://TitleScreen.tscn", "07_title"], ["res://Hub.tscn", "08_hub"]]:
		var s: Node = load(scene[0]).instantiate()
		add_child(s)
		await get_tree().create_timer(0.8).timeout
		await _shot(scene[1])
		s.queue_free()
		await get_tree().process_frame

	print("SHOTS -> ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()


func _walk(vel: Vector2, frames: int) -> void:
	if _player == null:
		return
	for i in frames:
		_player.velocity = vel
		_player.move_and_slide()
		await get_tree().process_frame
	_player.velocity = Vector2.ZERO
	await get_tree().create_timer(0.4).timeout


func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [OUT, tag])
	print("saved ", tag)
