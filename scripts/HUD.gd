extends CanvasLayer
## The on-screen UI: health bar, corruption meter (with tier name), dash
## cooldown, room status text, the upgrade selection, and the death screen.
## It pulls live values from the player via update_player_status() and a small
## _process() poll for the dash indicator and the high-corruption screen pulse.

const UPGRADE_CARD := preload("res://scenes/UpgradeCard.tscn")
const UI_THEME := preload("res://ui_theme.tres")

@onready var stats_panel: PanelContainer = $Stats
@onready var health_label: Label = $Stats/Top/HealthRow/HealthLabel
@onready var health_bar: StatBar = $Stats/Top/HealthBar
@onready var corruption_label: Label = $Stats/Top/CorruptionLabel
@onready var corruption_bar: StatBar = $Stats/Top/CorruptionBar
@onready var dash_label: Label = $Stats/Top/DashLabel
@onready var dash_bar: StatBar = $Stats/Top/DashBar
@onready var status_label: Label = $StatusLabel
@onready var upgrades: Control = $Upgrades
@onready var cards_box: HBoxContainer = $Upgrades/Center/Box/Cards
@onready var game_over: Control = $GameOver
@onready var game_over_summary: Label = $GameOver/Center/Box/Summary
@onready var menu_button: Button = $GameOver/Center/Box/MenuButton
@onready var overload_pulse: ColorRect = $OverloadPulse
@onready var screen_fx: ColorRect = $ScreenFX
@onready var grade: ColorRect = $Grade
@onready var shockwave_layer: ColorRect = $Shockwave
@onready var essence_label: Label = $Stats/Top/Purse/EssenceLabel
@onready var gold_label: Label = $Stats/Top/Purse/GoldLabel
@onready var active_label: Label = $Stats/Top/ActiveLabel
@onready var combo_label: Label = $Combo
@onready var boss_bar: Control = $BossBar
@onready var boss_meter: StatBar = $BossBar/Bar
@onready var minimap: Control = $Minimap

var _boss: Node = null
var _item_bar: VBoxContainer = null
var _item_panel: PanelContainer = null

var _choose_callback: Callable
var _status_timer := 0.0
var _time := 0.0

# Animated/lerped HUD state.
var _hp_target := 1.0      # where the health bar wants to be (current ratio)
var _hp_display := 1.0     # the green fill, lerps quickly to target
var _hp_ghost := 1.0       # the red trailing chip, lerps slowly when draining
var _screen_mat: ShaderMaterial
var _grade_mat: ShaderMaterial
var _shock_mat: ShaderMaterial
var _shock_tween_running := false
var _fx_damage := 0.0      # decays each frame
var _fx_impact := 0.0      # decays each frame
var _essence_shown := -1
var _gold_shown := -1
var _combo_shown := 0
var _heartbeat_timer := 0.0
var _corr_shown := -1.0
var _game_over := false
var _pause_panel: Control = null
var _codex_panel: Control = null
var _codex_body: VBoxContainer = null
var _codex_open := false


func _ready() -> void:
	# Keep processing input while the tree is paused (so Esc resumes and the pause
	# buttons work). _process itself bails out when paused (see below).
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.register_hud(self)
	upgrades.visible = false
	game_over.visible = false
	boss_bar.visible = false
	combo_label.visible = false
	overload_pulse.color = Color(0.7, 0.0, 0.1, 0.0)
	status_label.visible = false
	_screen_mat = screen_fx.material as ShaderMaterial
	_grade_mat = grade.material as ShaderMaterial
	_shock_mat = shockwave_layer.material as ShaderMaterial
	if _shock_mat:
		_shock_mat.set_shader_parameter("strength", 0.0)
	menu_button.pressed.connect(_on_menu)
	_build_item_bar()
	_build_pause_menu()
	_build_codex()


func _process(delta: float) -> void:
	# Once dead, the death screen owns the view — stop driving the live HUD.
	# While paused, the game is frozen, so there's nothing live to update.
	if _game_over or get_tree().paused:
		return
	_time += delta

	# Auto-hide the status banner.
	if _status_timer > 0.0:
		_status_timer -= delta
		if _status_timer <= 0.0:
			status_label.visible = false

	# Essence counter with a little pop when it ticks up.
	var essence := int(GameManager.run_stats.get("essence", 0))
	essence_label.text = "ESSENCE %d" % essence
	if essence > _essence_shown:
		if _essence_shown >= 0:
			_punch(essence_label, 1.35)
		_essence_shown = essence

	# Gold counter (in-run currency).
	var gold := int(GameManager.run_stats.get("gold", 0))
	gold_label.text = "GOLD %d" % gold
	if gold > _gold_shown and _gold_shown >= 0:
		_punch(gold_label, 1.3)
	_gold_shown = gold

	# Combo counter with a punch each time it climbs.
	if GameManager.combo >= 2:
		combo_label.visible = true
		combo_label.text = "x%d COMBO" % GameManager.combo
		if GameManager.combo > _combo_shown:
			_punch(combo_label, 1.4)
	else:
		combo_label.visible = false
	_combo_shown = GameManager.combo

	# Animate the health bar toward its target: green fill snaps fairly fast,
	# the red "ghost" chip lags behind on damage so you see what you just lost.
	_hp_display = lerpf(_hp_display, _hp_target, 1.0 - exp(-14.0 * delta))
	if _hp_target < _hp_ghost:
		_hp_ghost = lerpf(_hp_ghost, _hp_target, 1.0 - exp(-3.5 * delta))
	else:
		_hp_ghost = maxf(_hp_ghost, _hp_display)  # healing: no red gap
	health_bar.value = _hp_display
	health_bar.ghost = _hp_ghost

	# Drive + decay the full-screen FX shader.
	_fx_damage = maxf(_fx_damage - delta * 2.2, 0.0)
	_fx_impact = maxf(_fx_impact - delta * 3.0, 0.0)
	_update_screen_fx()

	var player := GameManager.player
	if player == null:
		return

	# Dash cooldown indicator.
	var ratio: float = player.get_dash_ratio()
	dash_bar.value = ratio
	if ratio >= 1.0:
		dash_label.text = "DASH READY"
		dash_bar.set_fill_color(Color(0.33, 0.78, 0.88))
	else:
		dash_label.text = "DASH %d%%" % int(ratio * 100)
		dash_bar.set_fill_color(Color(0.24, 0.42, 0.5))

	# Active-ability readout (shows once the player owns an active item).
	if player.active_item != "":
		active_label.visible = true
		var ar: float = player.get_active_ratio()
		if ar >= 1.0:
			active_label.text = "[E] %s READY" % player.active_name.to_upper()
			active_label.modulate = Color(1, 1, 1)
		else:
			active_label.text = "[E] %s %d%%" % [player.active_name.to_upper(), int(ar * 100)]
			active_label.modulate = Color(0.6, 0.6, 0.68)
	else:
		active_label.visible = false

	# Low-health heartbeat: a soft sub-thump while badly wounded.
	if _hp_target < 0.25 and player.health.is_alive():
		_heartbeat_timer -= delta
		if _heartbeat_timer <= 0.0:
			_heartbeat_timer = lerpf(0.5, 0.95, _hp_target / 0.25)
			AudioManager.thump(-18.0)
	else:
		_heartbeat_timer = 0.0

	# High-corruption screen pulse (Overloaded tier).
	if player.corruption >= 75.0:
		overload_pulse.color.a = 0.10 + 0.06 * (0.5 + 0.5 * sin(_time * 6.0))
	else:
		overload_pulse.color.a = lerpf(overload_pulse.color.a, 0.0, 0.2)


# Push the current uniforms into the ScreenFX shader.
func _update_screen_fx() -> void:
	if _screen_mat == null:
		return
	var corr := 0.0
	var low := 0.0
	var player := GameManager.player
	if player:
		corr = clampf(player.corruption / player.max_corruption, 0.0, 1.0)
		low = clampf(smoothstep(0.35, 0.10, _hp_target), 0.0, 1.0)
	_screen_mat.set_shader_parameter("corruption", corr)
	_screen_mat.set_shader_parameter("low_health", low)
	_screen_mat.set_shader_parameter("damage", _fx_damage)
	_screen_mat.set_shader_parameter("impact", _fx_impact)
	_screen_mat.set_shader_parameter("time", _time)


# Quick scale-punch on any Control (settles back to 1.0).
func _punch(ctrl: Control, amount: float = 1.3) -> void:
	ctrl.pivot_offset = ctrl.size * 0.5
	ctrl.scale = Vector2(amount, amount)
	var tw := ctrl.create_tween()
	tw.tween_property(ctrl, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Full-screen FX hooks (called via GameManager) ---------------------
func flash_damage() -> void:
	_fx_damage = 1.0


func add_screen_impact(amount: float) -> void:
	_fx_impact = clampf(_fx_impact + amount, 0.0, 1.0)


## Ripple the screen outward from a world position (heavy hits, boss slams).
## Converts the world point to screen UV via the active camera, then animates
## the ring out once. Silently no-ops if the shockwave layer is missing, so the
## effect can be deleted from the scene without touching gameplay code.
func play_shockwave(world_pos: Vector2, strength: float = 1.0) -> void:
	if _shock_mat == null or _shock_tween_running:
		return
	var vp := get_viewport()
	if vp == null:
		return
	var vp_size := vp.get_visible_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return
	var screen_pos: Vector2 = vp.get_canvas_transform() * world_pos
	_shock_mat.set_shader_parameter("center", screen_pos / vp_size)
	_shock_mat.set_shader_parameter("aspect", vp_size.x / vp_size.y)
	_shock_mat.set_shader_parameter("strength", clampf(strength, 0.0, 1.0))
	_shock_mat.set_shader_parameter("progress", 0.0)
	_shock_tween_running = true
	# ignore_time_scale so the ripple still plays out during hit-stop/slow-mo —
	# which is exactly when it fires.
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_method(
		func(v: float) -> void: _shock_mat.set_shader_parameter("progress", v),
		0.0, 1.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		_shock_mat.set_shader_parameter("strength", 0.0)
		_shock_tween_running = false)


## Called by player/room whenever health or corruption changes.
func update_player_status(player: Node) -> void:
	var hp: float = player.health.current_health
	var max_hp: float = player.health.max_health
	health_label.text = "%d/%d" % [ceili(hp), ceili(max_hp)]
	_hp_target = clampf(hp / max_hp, 0.0, 1.0)
	# One tick per 25 max HP, so the bar reads as "how many hits left" rather
	# than as an abstract percentage. Clamped so a huge max HP doesn't turn the
	# bar into a solid block of dividers.
	health_bar.ticks = clampi(int(round(max_hp / 25.0)), 1, 12)

	var corr: float = player.corruption
	var max_corr: float = player.max_corruption
	var tier: String = player.get_corruption_tier()
	corruption_label.text = "CORRUPTION %d/%d %s" % [int(corr), int(max_corr), tier.to_upper()]
	corruption_bar.value = clampf(corr / max_corr, 0.0, 1.0)
	corruption_bar.set_fill_color(_tier_color(tier))
	# Punch the meter when corruption climbs (the upgrade tax should be felt).
	if _corr_shown >= 0.0 and corr > _corr_shown + 0.5:
		_punch(corruption_label, 1.2)
	_corr_shown = corr


func _tier_color(tier: String) -> Color:
	match tier:
		"Stable":
			return Color(0.5, 0.8, 0.5)
		"Tainted":
			return Color(0.85, 0.8, 0.4)
		"Corrupted":
			return Color(0.85, 0.45, 0.85)
		_:
			return Color(0.95, 0.2, 0.3)


# --- Status banner -----------------------------------------------------
func show_status(text: String, auto_hide: float = 0.0) -> void:
	status_label.text = text
	status_label.visible = true
	_status_timer = auto_hide
	_punch(status_label, 1.25)


func hide_status() -> void:
	status_label.visible = false


# --- Upgrade selection -------------------------------------------------
func show_upgrades(defs: Array, callback: Callable) -> void:
	_choose_callback = callback
	for child in cards_box.get_children():
		child.queue_free()
	for def in defs:
		var card := UPGRADE_CARD.instantiate()
		cards_box.add_child(card)
		card.setup(def)
		card.chosen.connect(_on_card_chosen)
	upgrades.visible = true


func hide_upgrades() -> void:
	upgrades.visible = false
	for child in cards_box.get_children():
		child.queue_free()


func _on_card_chosen(def: Dictionary) -> void:
	if _choose_callback.is_valid():
		_choose_callback.call(def)


# --- Item bar (the player's collected build) ---------------------------
func _build_item_bar() -> void:
	# A framed panel pinned bottom-left, so the build list reads as real UI
	# instead of floating debug text.
	_item_panel = PanelContainer.new()
	_item_panel.name = "ItemPanel"
	_item_panel.theme_type_variation = &"Inset"
	_item_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_item_panel.offset_left = 12.0
	_item_panel.offset_bottom = -44.0
	_item_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_item_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_item_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_panel.add_child(col)
	var header := Label.new()
	header.text = "BUILD"
	header.theme_type_variation = &"StatDim"
	col.add_child(header)

	_item_bar = VBoxContainer.new()
	_item_bar.name = "ItemBar"
	_item_bar.add_theme_constant_override("separation", 1)
	_item_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_item_bar)
	_item_panel.visible = false


## Rebuild the owned-items list. Same item stacks show "Name xN"; colour is rarity.
func refresh_items(player: Node) -> void:
	if _item_bar == null:
		return
	for c in _item_bar.get_children():
		c.queue_free()
	if player == null or not ("items" in player):
		if _item_panel:
			_item_panel.visible = false
		return
	var order: Array = []
	var counts := {}
	var meta := {}
	for d in player.items:
		var id: String = str(d.get("id", ""))
		if not counts.has(id):
			counts[id] = 0
			order.append(id)
			meta[id] = d
		counts[id] += 1
	for id in order:
		var d: Dictionary = meta[id]
		var n: int = counts[id]
		var lbl := Label.new()
		lbl.text = str(d.get("title", "?")).to_upper() + ("  x%d" % n if n > 1 else "")
		lbl.add_theme_color_override("font_color", UpgradeCard.RARITY_COLORS.get(str(d.get("rarity", "common")), Color.WHITE))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_item_bar.add_child(lbl)
	if _item_panel:
		_item_panel.visible = order.size() > 0


## Flashy banner when two items fuse into a synergy.
func show_synergy(synergy_name: String) -> void:
	show_status("SYNERGY — %s" % synergy_name, 2.2)


# --- Minimap / boss bar ------------------------------------------------
func setup_minimap(dungeon: Node) -> void:
	if minimap and minimap.has_method("set_dungeon"):
		minimap.set_dungeon(dungeon)


func show_boss_bar(boss: Node) -> void:
	_boss = boss
	boss_bar.visible = true
	boss_meter.value = 1.0
	boss_meter.ghost = 1.0
	if boss.has_node("Health"):
		boss.get_node("Health").damaged.connect(_on_boss_damaged)


func hide_boss_bar() -> void:
	_boss = null
	boss_bar.visible = false


func _on_boss_damaged(_amount: float, current: float, maximum: float) -> void:
	if maximum <= 0.0:
		return
	boss_meter.value = clampf(current / maximum, 0.0, 1.0)
	# The ghost chip drains behind the fill, so a big hit reads as a chunk taken
	# off rather than as a number quietly changing.
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_method(func(v: float) -> void: boss_meter.ghost = v,
		boss_meter.ghost, boss_meter.value, 0.35)


# --- Death -------------------------------------------------------------
func show_game_over() -> void:
	_game_over = true
	_hide_gameplay_ui()
	var s: Dictionary = GameManager.run_stats
	MetaProgression.bank_run(int(s["essence"]))  # keep the essence you earned
	var corr := 0
	if GameManager.player:
		corr = int(GameManager.player.corruption)
	game_over_summary.text = "Rooms cleared: %d     Enemies slain: %d     Score: %d\nFinal corruption: %d     Max combo: x%d     Essence: %d     Time: %.0fs" % [
		s["rooms_cleared"], s["enemies_killed"], s["score"], corr, s["max_combo"], s["essence"], GameManager.get_run_time()
	]
	# Fade the death screen in over a clean, dark backdrop.
	game_over.modulate.a = 0.0
	game_over.visible = true
	var tw := create_tween()
	tw.tween_property(game_over, "modulate:a", 1.0, 0.5)


# Strip the live HUD so the death screen reads cleanly (no clipped stats, no
# minimap, no pulsing screen FX behind "YOU DIED").
func _hide_gameplay_ui() -> void:
	stats_panel.visible = false
	var hint := get_node_or_null("Hint")
	if hint:
		(hint as CanvasItem).visible = false
	minimap.visible = false
	combo_label.visible = false
	boss_bar.visible = false
	status_label.visible = false
	overload_pulse.color.a = 0.0
	if _item_panel:
		_item_panel.visible = false
	# Settle the full-screen shader so its red low-HP / corruption pulse stops.
	if _screen_mat:
		_screen_mat.set_shader_parameter("corruption", 0.0)
		_screen_mat.set_shader_parameter("low_health", 0.0)
		_screen_mat.set_shader_parameter("damage", 0.0)
		_screen_mat.set_shader_parameter("impact", 0.0)


func _on_menu() -> void:
	Engine.time_scale = 1.0
	AudioManager.play("click")
	Transitions.change_scene("res://TitleScreen.tscn")


# --- Pause menu --------------------------------------------------------
func _build_pause_menu() -> void:
	var panel := Control.new()
	panel.name = "PauseMenu"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.theme = UI_THEME
	panel.visible = false
	panel.process_mode = Node.PROCESS_MODE_ALWAYS  # interactive while paused
	add_child(panel)
	_pause_panel = panel

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.02, 0.05, 0.74)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = "PAUSED"
	title.theme_type_variation = &"Hero"
	title.add_theme_color_override("font_color", Color(0.8, 0.66, 0.95))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	box.add_child(gap)

	_add_pause_button(box, "Resume", func() -> void: _set_paused(false))
	_add_pause_button(box, "Restart Run", func() -> void:
		_set_paused(false)
		AudioManager.play("click")
		Transitions.reload_scene())
	_add_pause_button(box, "Return to Title", func() -> void:
		_set_paused(false)
		AudioManager.play("click")
		Transitions.change_scene("res://TitleScreen.tscn"))

	# Volume controls live here rather than in a separate options screen: the
	# pause menu is where you actually are when the music is bothering you.
	var audio_gap := Control.new()
	audio_gap.custom_minimum_size = Vector2(0, 10)
	box.add_child(audio_gap)
	var audio_panel := PanelContainer.new()
	audio_panel.theme_type_variation = &"Inset"
	audio_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	box.add_child(audio_panel)
	var audio_box := VBoxContainer.new()
	audio_box.add_theme_constant_override("separation", 6)
	audio_panel.add_child(audio_box)
	var audio_header := Label.new()
	audio_header.text = "AUDIO"
	audio_header.theme_type_variation = &"StatDim"
	audio_box.add_child(audio_header)
	_add_volume_slider(audio_box, "MASTER", "master")
	_add_volume_slider(audio_box, "SFX", "sfx")
	_add_volume_slider(audio_box, "MUSIC", "music")


func _add_pause_button(box: VBoxContainer, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 44)
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.pressed.connect(cb)
	box.add_child(b)


## One labelled 0-100% slider bound to a MetaProgression volume key. Writes on
## release rather than on every drag frame, so dragging doesn't hammer the save
## file.
func _add_volume_slider(box: VBoxContainer, text: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.process_mode = Node.PROCESS_MODE_ALWAYS
	box.add_child(row)

	var name_label := Label.new()
	name_label.text = text
	name_label.custom_minimum_size = Vector2(96, 0)
	name_label.theme_type_variation = &"StatDim"
	row.add_child(name_label)

	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(150, 20)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = MetaProgression.get_volume(key)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.process_mode = Node.PROCESS_MODE_ALWAYS
	row.add_child(slider)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(52, 0)
	value_label.text = "%d%%" % int(slider.value * 100.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	slider.value_changed.connect(func(v: float) -> void:
		MetaProgression.set_volume(key, v)
		value_label.text = "%d%%" % int(v * 100.0))
	slider.drag_ended.connect(func(changed: bool) -> void:
		if changed:
			MetaProgression.save_game())


func _set_paused(p: bool) -> void:
	# Never pause over the death screen, the upgrade choice, or the build screen.
	if _game_over or upgrades.visible or _codex_open:
		return
	get_tree().paused = p
	if _pause_panel:
		_pause_panel.visible = p
	AudioManager.play("click")


## Tab is handled in _input rather than _unhandled_input because Tab is also
## Godot's built-in `ui_focus_next`: if any Control has focus (which it does the
## moment you've opened the pause menu once), the GUI layer eats the key before
## _unhandled_input ever sees it. _input runs first, so the build screen always
## opens.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("codex"):
		if _game_over or upgrades.visible:
			return
		_toggle_codex()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _game_over or upgrades.visible:
			return
		# Esc closes the build screen first, rather than stacking a pause on it.
		if _codex_open:
			_toggle_codex()
			get_viewport().set_input_as_handled()
			return
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


# --- Build screen ([Tab]) ----------------------------------------------
## A full reference for the run you're currently having: weapon, active ability,
## every item you own with what it actually does, live synergies, and what your
## corruption tier is costing you.
##
## The upgrade cards explain an item once, at the moment you take it, and then
## the information is gone — by floor three you're carrying eight items and can
## only remember the names. This is the screen that answers "what does Ember
## Brand do again?".
func _toggle_codex() -> void:
	_codex_open = not _codex_open
	if _codex_open:
		_populate_codex()
	_codex_panel.visible = _codex_open
	get_tree().paused = _codex_open
	AudioManager.play("click", -6.0)


func _build_codex() -> void:
	var panel := Control.new()
	panel.name = "Codex"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.visible = false
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(panel)
	_codex_panel = panel

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.015, 0.03, 0.8)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(760, 0)
	center.add_child(frame)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	frame.add_child(col)

	var title := Label.new()
	title.text = "YOUR BUILD"
	title.theme_type_variation = &"Heading"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	# Scrolls, because a long run can own more items than fit on screen.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(736, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_codex_body = VBoxContainer.new()
	_codex_body.add_theme_constant_override("separation", 10)
	_codex_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_codex_body)

	var hint := Label.new()
	hint.text = "TAB OR ESC TO CLOSE"
	hint.theme_type_variation = &"Hint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


func _populate_codex() -> void:
	for c in _codex_body.get_children():
		c.queue_free()
	var player := GameManager.player
	if player == null:
		return

	# Loadout: the two things you're holding right now.
	_codex_section("LOADOUT")
	if player.weapon:
		_codex_entry("Weapon — %s" % player.weapon.get_weapon_name(),
			"Press Q to swap between unlocked weapons", Color(0.85, 0.88, 0.92))
	if player.active_item != "":
		_codex_entry("[E] %s" % player.active_name, player.active_description(),
			Color(0.7, 0.5, 0.92))
	else:
		_codex_entry("[E] No active ability", "Find one on a pedestal or in an upgrade",
			Color(0.55, 0.58, 0.65))

	# Corruption: spell out what the current tier is actually doing to you,
	# since the numbers are invisible during play.
	var tier: String = player.get_corruption_tier()
	_codex_section("CORRUPTION — %s" % tier.to_upper())
	_codex_entry("%d / %d" % [int(player.corruption), int(player.max_corruption)],
		_corruption_effect_text(tier), _tier_color(tier))

	# Items, stacked.
	var order: Array = []
	var counts := {}
	var meta := {}
	for d in player.items:
		var id: String = str(d.get("id", ""))
		if not counts.has(id):
			counts[id] = 0
			order.append(id)
			meta[id] = d
		counts[id] += 1
	_codex_section("ITEMS (%d)" % player.items.size())
	if order.is_empty():
		_codex_entry("Nothing yet", "Clear a room to be offered your first upgrade",
			Color(0.55, 0.58, 0.65))
	for id in order:
		var d: Dictionary = meta[id]
		var n: int = counts[id]
		var name_text: String = str(d.get("title", "?"))
		if n > 1:
			name_text += "  x%d" % n
		_codex_entry(name_text, str(d.get("desc", "")),
			UpgradeCard.RARITY_COLORS.get(str(d.get("rarity", "common")), Color.WHITE))

	# Synergies.
	var syn: Array = player.synergy_entries() if player.has_method("synergy_entries") else []
	if not syn.is_empty():
		_codex_section("SYNERGIES")
		for entry in syn:
			_codex_entry(str(entry[0]), str(entry[1]), Color(1.0, 0.82, 0.35))


func _corruption_effect_text(tier: String) -> String:
	match tier:
		"Stable":
			return "No bonus, no penalty"
		"Tainted":
			return "+8% damage dealt, +12% damage taken"
		"Corrupted":
			return "+15% damage dealt, +25% damage taken, elites appear"
		_:
			return "+22% damage dealt, +40% damage taken, elites are common"


func _codex_section(text: String) -> void:
	# Breathing room above every section but the first, so headers group with the
	# entries below them rather than crowding the entry above.
	if _codex_body.get_child_count() > 0:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 12)
		_codex_body.add_child(gap)
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"StatDim"
	_codex_body.add_child(l)
	var rule := HSeparator.new()
	_codex_body.add_child(rule)


func _codex_entry(name_text: String, desc: String, color: Color) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 1)
	_codex_body.add_child(row)
	var n := Label.new()
	n.text = name_text.to_upper()
	n.add_theme_color_override("font_color", color)
	row.add_child(n)
	if desc != "":
		var d := Label.new()
		d.text = desc
		d.theme_type_variation = &"CardBody"
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(700, 0)
		row.add_child(d)
