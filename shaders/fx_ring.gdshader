// Expanding impact ring. Replaces the old Line2D circle, which read as a
// geometric compass-drawn outline rather than a burst of force.
//
// What makes it look like energy instead of a circle:
//   - additive blending, so it behaves like light on a dark floor;
//   - the band thins and fades as it expands, like a real pressure wave;
//   - the leading edge is hotter than the trailing edge;
//   - a low-frequency angular wobble breaks the perfect circle.
shader_type canvas_item;
render_mode blend_add, unshaded;

const float TAU_ = 6.28318530718;

uniform vec4 color : source_color = vec4(1.0, 0.8, 0.5, 1.0);
// 0 -> 1 over the effect's lifetime.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float thickness : hint_range(0.01, 0.5) = 0.13;
// How much the ring deviates from a perfect circle.
uniform float wobble : hint_range(0.0, 1.0) = 0.35;
// Per-instance variation so two rings never look identical.
uniform float seed = 0.0;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p) * 2.0;             // 0 at centre, 1 at the quad edge
	float a = atan(p.y, p.x);

	// Radius grows; band thins and fades as it goes.
	float r = progress * 0.92;
	r += sin(a * 3.0 + seed) * 0.035 * wobble;
	r += sin(a * 7.0 - seed * 2.0) * 0.018 * wobble;
	float th = thickness * (1.0 - progress * 0.62);

	float band = 1.0 - smoothstep(0.0, max(th, 0.001), abs(d - r));
	band = pow(band, 1.7);

	// Hotter on the outside edge of the band.
	float lead = smoothstep(r - th, r + th * 0.25, d);

	float alpha = band * (1.0 - progress * progress);
	COLOR = vec4(color.rgb * (1.0 + lead * 1.6), alpha * color.a);
}
