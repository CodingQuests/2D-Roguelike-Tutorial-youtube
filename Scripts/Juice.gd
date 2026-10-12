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
	
