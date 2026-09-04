// Rising heat shimmer over a brazier.
//
// Deliberately NOT a screen-space refraction. There are already two
// screen-reading shaders (grade, shockwave) in the UI layer; a third one in
// WORLD space would trigger the single 2D back-buffer copy early, and the grade
// would then sample a stale frame missing everything drawn after the first
// brazier. Fixing that needs BackBufferCopy nodes and careful ordering, for an
// effect that occupies ~20px above a wall sconce.
//
// This gets most of the read — a warm, wobbling, rising plume — additively, with
// no screen access and no ordering hazard at all.
shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 color : source_color = vec4(1.0, 0.55, 0.18, 1.0);
uniform float time_s = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float seed = 0.0;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x),
		mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	// Narrow toward the top, so the plume tapers as it rises.
	float rise = 1.0 - uv.y;
	float width = mix(0.42, 0.16, rise);
	float horiz = 1.0 - smoothstep(0.0, width, abs(uv.x - 0.5));

	// Two noise layers scrolling upward at different rates.
	float n = noise2(vec2(uv.x * 4.0, uv.y * 3.0 - time_s * 0.9)) * 0.6
		+ noise2(vec2(uv.x * 9.0, uv.y * 6.0 - time_s * 1.6)) * 0.4;

	// Fade in just above the flame and out at the top.
	float vert = smoothstep(1.0, 0.72, uv.y) * smoothstep(0.0, 0.45, uv.y);

	float a = horiz * vert * smoothstep(0.35, 0.85, n) * intensity;
	COLOR = vec4(color.rgb, clamp(a, 0.0, 1.0) * color.a * 0.5);
}
