// Directional spark spray — sparks thrown along a hit direction. The quad is
// rotated by the caller so +X is the spray direction; this only has to draw a
// cone of streaks pointing right.
//
// Same reasoning as fx_burst: real tapered streaks with per-streak variation
// read as sparks; square particles read as dots.
shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 color : source_color = vec4(1.0, 0.85, 0.5, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int count : hint_range(3, 24) = 9;
// Half-angle of the spray, in radians.
uniform float spread : hint_range(0.05, 1.6) = 0.55;
uniform float seed = 0.0;

float hash1(float n) {
	return fract(sin(n * 91.7 + seed * 173.3) * 43758.5453);
}

void fragment() {
	// Origin at the left-centre edge so the cone fires to the right.
	vec2 p = UV - vec2(0.08, 0.5);
	p.x = max(p.x, 0.0);
	float d = length(p);
	float a = atan(p.y, p.x);          // 0 straight ahead

	if (abs(a) > spread) {
		COLOR = vec4(0.0);
	} else {
		float fc = float(count);
		// Map the angle across the cone into per-streak lanes.
		float lane = (a / spread * 0.5 + 0.5) * fc;
		float idx = floor(lane);
		float within = fract(lane);

		float len = mix(0.35, 0.92, hash1(idx));
		float speed = mix(0.85, 1.4, hash1(idx + 5.1));
		float wide = mix(0.12, 0.36, hash1(idx + 11.7));

		float head = clamp(progress * speed, 0.0, 1.0) * len;
		float tail = max(0.0, head - mix(0.14, 0.3, hash1(idx + 2.3)));

		float radial = smoothstep(tail, tail + 0.025, d) * (1.0 - smoothstep(head - 0.025, head, d));
		float taper = 1.0 - (d / max(len, 0.001)) * 0.6;
		float angular = 1.0 - smoothstep(0.0, wide * max(taper, 0.15), abs(within - 0.5));

		float alpha = radial * angular * (1.0 - progress * progress);
		// Sparks cool as they fly: hot white near the impact, ember at the tip.
		vec3 col = mix(color.rgb * 2.0, color.rgb * 0.7, clamp(d / max(len, 0.001), 0.0, 1.0));
		COLOR = vec4(col, clamp(alpha, 0.0, 1.0) * color.a);
	}
}
