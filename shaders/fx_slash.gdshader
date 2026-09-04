// The swing arc. This is the single most-seen effect in the game — it fires on
// every attack — so it's worth more than a flat translucent wedge.
//
// The quad is centred on the player and rotated to the aim direction; the
// shader draws a crescent that SWEEPS across the arc rather than appearing all
// at once, with a hot leading edge and a soft trailing smear. That reading of
// "the blade travelled through here" is what a static polygon can never give.
shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 color : source_color = vec4(0.9, 0.95, 1.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Total swept angle, radians.
uniform float arc : hint_range(0.2, 3.2) = 1.7;
// Inner/outer radius of the crescent, as a fraction of the quad's half-size.
uniform float inner : hint_range(0.0, 1.0) = 0.34;
uniform float outer : hint_range(0.0, 1.0) = 0.94;
// How much of the arc stays lit behind the leading edge.
uniform float trail : hint_range(0.05, 1.0) = 0.55;
uniform float seed = 0.0;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p) * 2.0;
	float a = atan(p.y, p.x);

	float half_arc = arc * 0.5;
	// Where the leading edge currently is, sweeping from one end to the other.
	float edge = mix(-half_arc, half_arc, progress);

	// Angular mask: lit from the sweep start up to the leading edge, fading
	// out behind it.
	float behind = edge - a;
	float ang = step(0.0, behind) * step(a, half_arc) * step(-half_arc, a);
	float trail_len = trail * arc;
	float trail_fade = 1.0 - smoothstep(0.0, trail_len, behind);

	// A crescent is a band at a CONSTANT radius whose thickness tapers to
	// nothing at the ends of the arc. (Varying the radius instead produces a
	// filled wedge — a solid cone rather than a blade path.)
	float taper = 1.0 - pow(abs(a) / max(half_arc, 0.001), 2.0);
	taper = clamp(taper, 0.0, 1.0);
	float mid = mix(inner, outer, 0.66);
	float half_thick = (outer - inner) * 0.34 * taper;
	float band = 1.0 - smoothstep(0.0, max(half_thick, 0.001), abs(d - mid));
	band = pow(band, 1.4);

	// Hot leading edge.
	float lead = 1.0 - smoothstep(0.0, arc * 0.12, behind);

	float alpha = ang * band * trail_fade * (1.0 - progress * 0.35);
	vec3 col = color.rgb * (0.75 + lead * 1.1);
	COLOR = vec4(col, clamp(alpha, 0.0, 1.0) * color.a);
}
