// Enemy attack telegraph — the "this area is about to hurt" marker.
//
// The old version was a flat translucent red polygon, which has two problems:
// it doesn't tell you HOW LONG you have, and on a dark lit floor a 35%-alpha
// red shape barely registers. This one fills up as the wind-up progresses, so
// the danger zone is also a timer, and it carries a bright animated rim that
// stays legible over any floor.
//
// mode 0 = circle (slams, novas), mode 1 = rect/beam (charges, laser aims).
// The rect mode fills left-to-right along the quad's +X, so the caller rotates
// the quad to the attack direction.
shader_type canvas_item;
render_mode unshaded;

uniform vec4 color : source_color = vec4(1.0, 0.2, 0.18, 1.0);
// 0 -> 1 across the wind-up.
uniform float fill : hint_range(0.0, 1.0) = 0.0;
uniform int mode : hint_range(0, 1) = 0;
uniform float time_s = 0.0;
// Base opacity of the unfilled zone.
uniform float base_alpha : hint_range(0.0, 1.0) = 0.20;

void fragment() {
	float shape;      // 1 inside the danger zone
	float rim;        // 1 on its border
	float sweep;      // 0..1 position along the fill axis

	if (mode == 0) {
		float d = length(UV - vec2(0.5)) * 2.0;
		shape = 1.0 - smoothstep(0.97, 1.0, d);
		rim = smoothstep(0.86, 0.97, d) * (1.0 - smoothstep(0.97, 1.0, d));
		sweep = d;
	} else {
		vec2 q = abs(UV - vec2(0.5)) * 2.0;
		shape = (1.0 - smoothstep(0.97, 1.0, q.x)) * (1.0 - smoothstep(0.90, 1.0, q.y));
		rim = smoothstep(0.72, 0.92, q.y) * (1.0 - smoothstep(0.92, 1.0, q.y));
		sweep = UV.x;
	}

	// Filled portion: brighter, so the zone visibly "charges".
	float filled = 1.0 - smoothstep(fill - 0.03, fill + 0.03, sweep);

	// Hazard stripes crawling through the filled area — reads as active danger
	// rather than as a static decal.
	float stripes = 0.5 + 0.5 * sin((UV.x + UV.y) * 46.0 - time_s * 7.0);
	stripes = mix(1.0, stripes, 0.35);

	// Rim pulses faster as the attack lands.
	float pulse = 0.65 + 0.35 * sin(time_s * (7.0 + fill * 16.0));

	float a = shape * base_alpha;
	a += shape * filled * 0.34 * stripes;
	a += rim * (0.55 + 0.45 * fill) * pulse;

	vec3 col = color.rgb * (1.0 + filled * 0.5 + rim * 1.2);
	COLOR = vec4(col, clamp(a, 0.0, 1.0) * color.a);
}
