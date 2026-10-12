class_name Juice
extends RefCounted


const SPRITE_SHADER := preload("res://shaders/sprite_fx.gdshader")


static func make_flash_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SPRITE_SHADER
	mat.set_shader_parameter("flash_amount", 0.0)
	mat.set_shader_parameter("outline_width", 0.0)
	mat.set_shader_parameter("outline_pulse", 0.0)
	return mat

static func flash(sprite: CanvasItem, color: Color = Color.WHITE, duration: float = 0.08) -> void:
	if sprite == null:
		return
	var mat := sprite.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash_amount", 1.0)
	var tw := sprite.create_tween()
	tw.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("flash_amount", v),
		1.0, 0.0, duration
	)
static func impact(world: Node, pos: Vector2, color: Color = Color.WHITE,
		amount: int = 10, scale: float = 1.0) -> void:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = 60.0 * scale
	p.initial_velocity_max = 160.0 * scale
	p.scale_amount_min = 1.5 * scale
	p.scale_amount_max = 3.0 * scale
	p.color = color
	p.global_position = pos
	world.add_child(p)
	p.finished.connect(p.queue_free)
	

static func squash(node: Node2D, base_scale: Vector2,
		amount: float = 0.35, duration: float = 0.22) -> void:
	if node == null or not is_instance_valid(node):
		return
	var tw := node.create_tween()
	node.scale = base_scale * Vector2(1.0 + amount, 1.0 - amount)
	tw.tween_property(node, "scale", base_scale, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	

static func damage_number(world: Node, pos: Vector2, amount: float,
		color: Color = Color.WHITE, crit: bool = false) -> void:
	var label := Label.new()
	label.text = str(int(round(amount)))
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 16 if crit else 11)
	label.global_position = pos + Vector2(randf_range(-6, 6), -8)
	label.z_index = 100
	world.add_child(label)
	
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 22.0, 0.5)
	tw.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.15)
	tw.chain().tween_callback(label.queue_free)
	

static func _mat(sprite: CanvasItem) -> ShaderMaterial:
	var mat := sprite.material as ShaderMaterial
	if mat == null or mat.shader != SPRITE_SHADER:
		mat = make_flash_material()
		sprite.material = mat
	return mat
	
static func set_outline(sprite: CanvasItem, on: bool, color: Color = Color(1.0, 0.85, 0.3),
		width: float = 1.0, pulse: bool = false) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var mat := _mat(sprite)
	mat.set_shader_parameter("outline_width", width if on else 0.0)
	mat.set_shader_parameter("outline_color", color)
	mat.set_shader_parameter("outline_pulse", 1.0 if pulse else 0.0)
	
	
static func ring(world: Node, pos: Vector2, color: Color = Color.WHITE,
		radius: float = 28.0, duration: float = 0.35, width: float = 2.0) -> void:
	if world == null or not is_instance_valid(world):
		return
	var line := Line2D.new()
	line.closed = true
	line.width = width
	line.default_color = color
	line.z_index = 90
	world.add_child(line)
	line.global_position = pos

	var tw := line.create_tween()
	tw.tween_method(
		func(r: float) -> void: line.points = _circle_points(r),
		radius * 0.2, radius, duration)
	tw.parallel().tween_property(line, "modulate:a", 0.0, duration)
	tw.chain().tween_callback(line.queue_free)
	
static func _circle_points(r: float, steps: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps):
		var a := TAU * float(i) / steps
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts
	
	


# Juice.gd
static func floating_text(world: Node, pos: Vector2, text: String,
		color: Color = Color.WHITE, font_size: int = 10, rise: float = 20.0) -> void:
	# Same guard as the other Juice helpers. No world, no label.
	if world == null or not is_instance_valid(world):
		return
	var label := Label.new()
	label.text = text
	label.z_index = 100    # draws on top
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	# A 2 px black outline, so it reads over anything.
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	# So it can never sit in front of a button and eat a click.
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Into the tree first: global_position only means something once it's in there.
	world.add_child(label)
	# Nudged left by roughly half the text width, so it's centred on the point.
	label.global_position = pos + Vector2(-text.length() * font_size * 0.3, -12)
	label.scale = Vector2(0.4, 0.4)    # starts at 40%

	var tw := label.create_tween()
	# Pop up to full size. The back ease overshoots a bit and settles.
	tw.tween_property(label, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# parallel(): the rise runs at the same time, over 0.7 s.
	tw.parallel().tween_property(
		label, "global_position", label.global_position + Vector2(0, -rise), 0.7)
	# Then fade out, then free.
	tw.tween_property(label, "modulate:a", 0.0, 0.35)
	tw.tween_callback(label.queue_free)
