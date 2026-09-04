// Corpse splat / scorch mark left on the floor.
//
// The old decal was a smooth 12-gon, which reads as "a polygon" the moment two
// of them overlap. This breaks the edge up with layered value noise and eats
// holes out of the middle, so each splat is a different irregular shape from
// the same quad.
//
// Normal blend (not additive) — this is grime, not light.
shader_type canvas_item;
render_mode unshaded;

uniform vec4 color : source_color = vec4(0.06, 0.0, 0.02, 1.0);
uniform float seed = 0.0;
// Shrinks the blob; used to fade it out by eroding rather than dimming.
uniform float erode : hint_range(0.0, 1.0) = 0.0;

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
	vec2 p = UV - vec2(0.5);
	float d = length(p) * 2.0;

	// Two octaves of noise pushing the edge in and out.
	float n = noise2(UV * 5.0) * 0.6 + noise2(UV * 11.0) * 0.4;
	float edge = 0.72 + (n - 0.5) * 0.55 - erode * 0.9;

	float blob = 1.0 - smoothstep(edge - 0.18, edge, d);
	// Speckle: a few holes so it looks splattered rather than poured.
	blob *= smoothstep(0.18, 0.42, noise2(UV * 17.0 + 3.0));

	COLOR = vec4(color.rgb, clamp(blob, 0.0, 1.0) * color.a);
}
