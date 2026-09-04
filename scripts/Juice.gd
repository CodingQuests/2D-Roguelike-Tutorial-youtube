class_name Juice
extends RefCounted
## Small static helpers for "game feel": hit-flash materials, impact particles,
## directional sparks, squash/stretch, afterimages, decals, rings and floating
## damage/text numbers. Kept in one place so the player and every enemy share the
## exact same polish without copy-pasting.

const SPRITE_SHADER := preload("res://shaders/sprite_fx.gdshader")
const RING_SHADER := preload("res://shaders/fx_ring.gdshader")
const BURST_SHADER := preload("res://shaders/fx_burst.gdshader")
const SPARK_SHADER := preload("res://shaders/fx_spark.gdshader")
const DECAL_SHADER := preload("res://shaders/fx_decal.gdshader")
const FX_QUAD := preload("res://fx_quad.tres")
const LIGHT_TEX := preload("res://light_radial.tres")

# Built once and shared by every dissolving sprite.
static var _dissolve_noise: NoiseTexture2D = null


## Returns the shared per-sprite ShaderMaterial (flash + outline + dissolve).
## Assign it to a sprite once; trigger effects later with flash() / set_outline()
## / dissolve(). Each sprite needs its OWN material — the parameters are per
## instance — so this always returns a fresh one.
static func make_flash_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SPRITE_SHADER
	mat.set_shader_parameter("flash_amount", 0.0)
	mat.set_shader_parameter("outline_width", 0.0)
	mat.set_shader_parameter("dissolve", 0.0)
	mat.set_shader_parameter("dissolve_noise", _noise())
	return mat


static func _noise() -> NoiseTexture2D:
	if _dissolve_noise == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX
		n.frequency = 0.08
		_dissolve_noise = NoiseTexture2D.new()
		_dissolve_noise.noise = n
		_dissolve_noise.width = 64
		_dissolve_noise.height = 64
		_dissolve_noise.seamless = true
	return _dissolve_noise


## Ensure `sprite` has the shared sprite material, and return it.
static func _mat(sprite: CanvasItem) -> ShaderMaterial:
	var mat := sprite.material as ShaderMaterial
	if mat == null or mat.shader != SPRITE_SHADER:
		mat = make_flash_material()
		sprite.material = mat
	return mat


## Turn a coloured rim outline on or off. Used for enemy telegraphs, corrupted
## elites and the interactable you're standing next to.
static func set_outline(sprite: CanvasItem, on: bool, color: Color = Color(1.0, 0.85, 0.3),
		width: float = 1.0, pulse: bool = false) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var mat := _mat(sprite)
	mat.set_shader_parameter("outline_width", width if on else 0.0)
	mat.set_shader_parameter("outline_color", color)
	mat.set_shader_parameter("outline_pulse", 1.0 if pulse else 0.0)


## Burn a sprite away over `duration`. Returns immediately; the caller owns when
## the node is actually freed.
static func dissolve(sprite: CanvasItem, duration: float = 0.35,
		edge: Color = Color(1.0, 0.75, 0.25)) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var mat := _mat(sprite)
	mat.set_shader_parameter("dissolve_edge_color", edge)
	mat.set_shader_parameter("dissolve", 0.0)
	var tw := sprite.create_tween()
	tw.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("dissolve", v),
		0.0, 1.0, duration)


## Pop a sprite white for `duration` seconds, then fade the flash back out.
static func flash(sprite: CanvasItem, color: Color = Color.WHITE, duration: float = 0.08) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var mat := _mat(sprite)
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash_amount", 1.0)
	var tw := sprite.create_tween()
	tw.tween_property(mat, "shader_parameter/flash_amount", 0.0, duration).set_delay(0.0)


## One-shot impact burst at `pos` — radial streaks with a hot collapsing core.
##
## Drawn by a single shader quad rather than a particle system. Twelve square
## particles fading out read as confetti; tapered streaks that shoot out and
## snap back read as force. `amount` now tunes the number of streaks and
## `scale` the burst radius, so every existing call site keeps working.
static func impact(world: Node, pos: Vector2, color: Color = Color.WHITE, amount: int = 10, scale: float = 1.0) -> void:
	var fx := _fx_quad(world, pos, BURST_SHADER, 64.0 * scale * 0.85, 6)
	if fx == null:
		return
	var mat: ShaderMaterial = fx.material
	mat.set_shader_parameter("color", _hdr(color))
	mat.set_shader_parameter("spokes", clampi(amount, 4, 32))
	mat.set_shader_parameter("seed", randf() * 100.0)
	_run_fx(fx, mat, 0.34)


## Directional spark spray fired along `dir` — use it at the exact contact point
## of a hit so debris comes off the blade edge.
static func spark(world: Node, pos: Vector2, dir: Vector2, color: Color = Color.WHITE, amount: int = 8, speed: float = 1.0) -> void:
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	var fx := _fx_quad(world, pos, SPARK_SHADER, 64.0 * speed * 0.7, 6)
	if fx == null:
		return
	# The shader fires along +X; rotate the quad to aim the spray.
	fx.rotation = dir.angle()
	var mat: ShaderMaterial = fx.material
	mat.set_shader_parameter("color", _hdr(color))
	mat.set_shader_parameter("count", clampi(amount, 3, 24))
	mat.set_shader_parameter("seed", randf() * 100.0)
	_run_fx(fx, mat, 0.26)


# --- Shader-quad plumbing ----------------------------------------------------
# Every procedural effect is the same thing: a Sprite2D showing a blank quad,
# with an FX shader that draws from UV, animated by a single `progress`
# uniform and freed when it finishes.
static func _fx_quad(world: Node, pos: Vector2, shader: Shader, size_px: float, z: int) -> Sprite2D:
	if world == null or not is_instance_valid(world):
		return null
	var fx := Sprite2D.new()
	fx.texture = FX_QUAD
	fx.global_position = pos
	fx.z_index = z
	fx.light_mask = 0        # effects are emissive; the room's lights must not dim them
	fx.scale = Vector2.ONE * (size_px / 64.0)
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("progress", 0.0)
	fx.material = mat
	world.add_child(fx)
	return fx


# Drive `progress` 0 -> 1 over `duration`, then free the node.
static func _run_fx(fx: Node2D, mat: ShaderMaterial, duration: float) -> void:
	var tw := fx.create_tween()
	tw.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("progress", v),
		0.0, 1.0, duration)
	tw.tween_callback(fx.queue_free)


# Push a colour above 1.0 so it crosses the WorldEnvironment glow threshold and
# blooms. Effects are light; they should read as brighter than the art.
static func _hdr(c: Color, boost: float = 1.35) -> Color:
	return Color(c.r * boost, c.g * boost, c.b * boost, c.a)


## Quick impact squash: snaps `node` to a wider/shorter scale, then springs back
## to `base_scale`. Reads as a recoil/impact deformation on a hit or a stop.
static func squash(node: Node2D, base_scale: Vector2, amount: float = 0.35, duration: float = 0.22) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.scale = Vector2(base_scale.x * (1.0 + amount), base_scale.y * (1.0 - amount))
	var tw := node.create_tween()
	tw.tween_property(node, "scale", base_scale, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Stretch the other way (taller/thinner) before springing back — good for a
## launch/dash anticipation.
static func stretch(node: Node2D, base_scale: Vector2, amount: float = 0.3, duration: float = 0.2) -> void:
	squash(node, base_scale, -amount, duration)


## Drop a fading ghost copy of `sprite` at its current transform. String several
## together along a dash for a motion-trail.
static func afterimage(world: Node, sprite: Sprite2D, tint: Color = Color(0.7, 0.9, 1.0, 0.5), duration: float = 0.25) -> void:
	if world == null or not is_instance_valid(world) or sprite == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.global_position = sprite.global_position
	ghost.global_rotation = sprite.global_rotation
	ghost.global_scale = sprite.global_scale
	ghost.flip_h = sprite.flip_h
	ghost.modulate = tint
	ghost.z_index = sprite.z_index - 1
	world.add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, duration)
	tw.tween_callback(ghost.queue_free)


## A dark splat left on the ground (blood/scorch). Sits under everything and
## lingers, so a cleared room shows what happened in it.
##
## Noise-shaped rather than a smooth polygon — two overlapping 12-gons read as
## "two polygons", two noise blobs read as mess. Fades by eroding its edge
## instead of dimming, which looks like it's drying rather than being deleted.
static func decal(world: Node, pos: Vector2, color: Color = Color(0.05, 0.0, 0.02, 0.4), radius: float = 9.0, duration: float = 6.0) -> void:
	var fx := _fx_quad(world, pos + Vector2(randf_range(-3, 3), randf_range(-2, 2)),
		DECAL_SHADER, radius * 2.6, -5)
	if fx == null:
		return
	fx.rotation = randf() * TAU
	var mat: ShaderMaterial = fx.material
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("seed", randf() * 100.0)
	mat.set_shader_parameter("erode", 0.0)
	var tw := fx.create_tween()
	tw.tween_interval(duration * 0.55)
	tw.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("erode", v),
		0.0, 1.0, duration * 0.45)
	tw.tween_callback(fx.queue_free)


## Expanding shockwave ring. Used for spawn telegraphs, wave-clear pops, dashes
## and big impacts.
##
## Was a Line2D circle, which read as a geometric outline. The shader version
## thins and fades as it expands, runs hotter on its leading edge, and carries a
## slight angular wobble, so it reads as a pressure wave instead of a compass
## circle. `width` now tunes the band thickness.
static func ring(world: Node, pos: Vector2, color: Color = Color.WHITE, radius: float = 28.0, duration: float = 0.35, width: float = 2.0) -> void:
	var fx := _fx_quad(world, pos, RING_SHADER, radius * 2.2, 6)
	if fx == null:
		return
	var mat: ShaderMaterial = fx.material
	mat.set_shader_parameter("color", _hdr(color))
	mat.set_shader_parameter("thickness", clampf(width / 18.0, 0.04, 0.4))
	mat.set_shader_parameter("seed", randf() * 100.0)
	_run_fx(fx, mat, duration)


## Floating, rising, fading damage number. `crit` makes it bigger and punches in
## with an overshoot so heavy hits read as a different beat.
static func damage_number(world: Node, pos: Vector2, amount: float, color: Color = Color.WHITE, crit: bool = false) -> void:
	if world == null or not is_instance_valid(world):
		return
	var label := Label.new()
	label.text = str(roundi(amount))
	label.z_index = 100
	# Sizes are in WORLD units and multiplied by the camera zoom, so these are
	# deliberately small: 8px at zoom 3 is 24 screen px.
	var font_size := 12 if crit else 8
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3 if crit else 2)
	label.global_position = pos + Vector2(randf_range(-6, 6), -10)
	world.add_child(label)
	var rise := -22.0 if crit else -16.0
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "global_position", label.global_position + Vector2(0, rise), 0.5)
	tw.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.15)
	if crit:
		# Punch-scale in from big -> settle.
		label.scale = Vector2(1.6, 1.6)
		tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(label.queue_free)


## Generic floating text ("+30 HP", "ROOM CLEAR", a tier name). Pops in and
## drifts up.
static func floating_text(world: Node, pos: Vector2, text: String, color: Color = Color.WHITE, font_size: int = 10, rise: float = 20.0) -> void:
	if world == null or not is_instance_valid(world):
		return
	var label := Label.new()
	label.text = text
	label.z_index = 100
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.global_position = pos + Vector2(-text.length() * font_size * 0.3, -12)
	world.add_child(label)
	label.scale = Vector2(0.4, 0.4)
	var tw := label.create_tween()
	tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(label, "global_position", label.global_position + Vector2(0, -rise), 0.7)
	tw.tween_property(label, "modulate:a", 0.0, 0.35)
	tw.tween_callback(label.queue_free)


## A soft dark ellipse parented under a moving sprite so it reads as standing on
## the floor rather than floating above it. Sits below everything else in the
## room (z_index -4, just above decals) and is deliberately NOT affected by the
## 2D lights — a shadow that brightens when you walk past a torch looks wrong.
static func contact_shadow(parent: Node2D, rx: float = 8.0, ry: float = 3.5,
		y_offset: float = 7.0, alpha: float = 0.30) -> Polygon2D:
	var shadow := Polygon2D.new()
	shadow.name = "ContactShadow"
	shadow.polygon = ellipse_points(rx, ry)
	shadow.color = Color(0, 0, 0, alpha)
	shadow.position = Vector2(0, y_offset)
	shadow.z_index = -4
	shadow.light_mask = 0
	parent.add_child(shadow)
	return shadow


## A short-lived PointLight2D — a muzzle-flash for melee hits, casts, and
## impacts. Much more readable in a dark room than another particle burst.
static func light_flash(world: Node, pos: Vector2, color: Color = Color(1.0, 0.85, 0.6),
		energy: float = 0.9, scale: float = 0.7, duration: float = 0.16) -> void:
	if world == null or not is_instance_valid(world):
		return
	var light := PointLight2D.new()
	light.texture = LIGHT_TEX
	light.texture_scale = scale
	light.energy = energy
	light.color = color
	light.global_position = pos
	world.add_child(light)
	var tw := light.create_tween()
	tw.tween_property(light, "energy", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(light.queue_free)


# Points of a circle (radius `r`) as a PackedVector2Array — shared by decals/rings.
static func _circle_points(r: float, steps: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps):
		var a := TAU * float(i) / steps
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


## Points of an ellipse — contact shadows and prop drop-shadows.
static func ellipse_points(rx: float, ry: float, steps: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps):
		var a := TAU * float(i) / steps
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts
